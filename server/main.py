"""
Orin Duel/Leaderboard backend.

Turn-based/async 1v1 word & grammar quiz duel + global leaderboard.
See ../docs/02-SOCIAL.md (Söz oyunu 1v1) and the implementation plan for the
design rationale.

Anti-cheat model (`_safe_questions()` strips secrets before any HTTP response):
- Grammar questions: the correct option TEXT is withheld from the client until
  it submits an answer — the client has no legitimate need to know it upfront,
  so it's a genuine secret.
- Word questions: the target item's id IS sent as `prompt_item_id`, because the
  UI must render that item's *localized* gloss (the actual question text) and
  the server intentionally stores no translated text at all (see export_catalog.py
  docstring — this keeps one shared catalog working across all 8 UI languages).
  Resolving "which id is being asked about" therefore has to happen, and hiding
  it isn't possible without also hiding the question itself. This mirrors how
  any client-rendered trivia UI (Kahoot etc.) works: the rendered DOM always
  contains the answer before it's clicked. What the server DOES still guarantee
  is that `correct`/`points` are computed authoritatively here, never trusted
  from the client — so a modified client can misrepresent what a *human* saw,
  but cannot forge a duel result the server didn't independently verify.
"""
import asyncio
import base64
import json
import logging
import os
import random
import sys
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db import get_conn, init_db

app = FastAPI(title="Orin Duel API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

log = logging.getLogger("orin")

BANDS = ["Pre-A1", "A1", "A2", "B1", "B2", "C1", "C2"]
QUESTIONS_PER_DUEL = 10
OPEN_DUEL_TTL_MIN = 30
SPEED_WINDOW_MS = 5000  # correct answers under this get a sliding bonus, 0 beyond it

# ---- Web Push (honest reminders only — see docs/02-SOCIAL.md §0) ----
# The reminder fires ONLY off a real FSRS due-count the client itself computed and
# synced (see /api/activity/sync) — never a fake "come back!" nudge on a timer.
VAPID_PRIVATE_KEY_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "vapid_private.pem")
VAPID_CLAIMS_SUB = os.environ.get("ORIN_VAPID_SUB", "mailto:orin-app@example.com")
PUSH_CHECK_INTERVAL_SEC = 3600  # how often the background loop scans for reminders to send
PUSH_MIN_GAP_HOURS = 20         # never notify the same user more than once/day
REMINDER_TEXT = {
    "az": "{n} söz təkrar üçün gözləyir",
    "hi": "{n} शब्द दोहराने के लिए तैयार हैं",
    "zh": "{n}个单词正等待复习",
    "es": "{n} palabras están esperando repaso",
    "pt": "{n} palavras estão esperando revisão",
    "id": "{n} kata sedang menunggu untuk diulas",
    "ar": "{n} كلمة في انتظار المراجعة",
    "vi": "{n} từ đang chờ ôn tập",
    "ko": "{n}개의 단어가 복습을 기다리고 있어요",
}


def _vapid_public_key_b64url():
    from cryptography.hazmat.primitives.serialization import load_pem_private_key, Encoding, PublicFormat
    with open(VAPID_PRIVATE_KEY_PATH, "rb") as f:
        priv = load_pem_private_key(f.read(), password=None)
    raw = priv.public_key().public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def _send_push(subscription_info, payload: dict):
    from pywebpush import webpush, WebPushException
    try:
        webpush(
            subscription_info=subscription_info,
            data=json.dumps(payload),
            vapid_private_key=VAPID_PRIVATE_KEY_PATH,
            vapid_claims={"sub": VAPID_CLAIMS_SUB},
        )
        return True
    except WebPushException as e:
        log.warning("push send failed: %s", e)
        return False


async def _reminder_loop():
    """Background task: every PUSH_CHECK_INTERVAL_SEC, nudge users who (a) have a
    real due-count synced from their own client, (b) have a stored push subscription,
    (c) haven't been notified in the last PUSH_MIN_GAP_HOURS, and (d) haven't had the
    app open in that window either (no point notifying someone mid-session)."""
    while True:
        try:
            cutoff = (datetime.now(timezone.utc) - timedelta(hours=PUSH_MIN_GAP_HOURS)).isoformat()
            with get_conn() as conn:
                rows = conn.execute(
                    """SELECT u.device_id, u.due_count, u.lang, p.endpoint, p.p256dh, p.auth
                       FROM users u JOIN push_subscriptions p ON p.device_id=u.device_id
                       WHERE u.due_count > 0
                         AND (u.last_activity_at IS NULL OR u.last_activity_at < ?)
                         AND (u.last_notified_at IS NULL OR u.last_notified_at < ?)""",
                    (cutoff, cutoff),
                ).fetchall()
                for r in rows:
                    text = REMINDER_TEXT.get(r["lang"], REMINDER_TEXT["az"]).replace("{n}", str(r["due_count"]))
                    ok = _send_push(
                        {"endpoint": r["endpoint"], "keys": {"p256dh": r["p256dh"], "auth": r["auth"]}},
                        {"title": "Orin", "body": text},
                    )
                    if ok:
                        conn.execute("UPDATE users SET last_notified_at=? WHERE device_id=?", (now_iso(), r["device_id"]))
                    else:
                        # 410/404 from the push service means the subscription is dead — drop it
                        conn.execute("DELETE FROM push_subscriptions WHERE device_id=?", (r["device_id"],))
        except Exception as e:
            log.warning("reminder loop iteration failed: %s", e)
        await asyncio.sleep(PUSH_CHECK_INTERVAL_SEC)


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def current_month_key():
    n = datetime.now(timezone.utc)
    return f"{n.year:04d}-{n.month:02d}"


def current_day_key():
    return datetime.now(timezone.utc).date().isoformat()


def _award_points(conn, device_id, points, result):
    """Add points to both the all-time total and the current-month bucket,
    resetting the month bucket first if the user's last activity was a
    previous month (docs/02-SOCIAL.md §5: monthly reset = fresh start)."""
    row = conn.execute("SELECT month_key FROM users WHERE device_id=?", (device_id,)).fetchone()
    mk = current_month_key()
    if not row or row["month_key"] != mk:
        conn.execute("UPDATE users SET month_key=?, month_points=0 WHERE device_id=?", (mk, device_id))
    col = {"win": "wins", "loss": "losses", "draw": "draws"}[result]
    conn.execute(
        f"UPDATE users SET points=points+?, month_points=month_points+?, {col}={col}+1 WHERE device_id=?",
        (points, points, device_id),
    )


def band_index(band: str) -> int:
    return BANDS.index(band) if band in BANDS else 1  # default A1


@app.on_event("startup")
async def _startup():
    init_db()
    if os.path.exists(VAPID_PRIVATE_KEY_PATH):
        asyncio.create_task(_reminder_loop())
    else:
        log.warning("vapid_private.pem not found — push reminders disabled; run generate_vapid.py once to enable")


# ---------------------------------------------------------------- models ---

class RegisterBody(BaseModel):
    device_id: str
    display_name: str


class ProfileBody(BaseModel):
    device_id: str
    display_name: str


class JoinBody(BaseModel):
    device_id: str
    mode: str  # 'word' | 'grammar'
    band: str
    friend_id: str = None  # set = private challenge to this specific friend, skip open matchmaking


class AddFriendBody(BaseModel):
    device_id: str
    invite_code: str


class ActivitySyncBody(BaseModel):
    device_id: str
    due_count: int
    today_points: int = 0
    today_mastered: int = 0
    lang: str = "az"


class PushKeys(BaseModel):
    p256dh: str
    auth: str


class PushSubscribeBody(BaseModel):
    device_id: str
    endpoint: str
    keys: PushKeys


class PushUnsubscribeBody(BaseModel):
    device_id: str


class AnswerBody(BaseModel):
    device_id: str
    qid: str
    chosen: str


class FinishBody(BaseModel):
    device_id: str


# ------------------------------------------------------------- helpers -----

def _get_pool(conn, item_type: str, band: str, min_size: int):
    """Fetch catalog items for (type, band); widen to neighbouring bands if the
    exact band doesn't have enough items yet (small content pools at the CEFR
    extremes)."""
    order = sorted(BANDS, key=lambda b: abs(band_index(b) - band_index(band)))
    seen = []
    for b in order:
        rows = conn.execute(
            "SELECT * FROM catalog_items WHERE type=? AND band=?", (item_type, b)
        ).fetchall()
        seen.extend(rows)
        if len(seen) >= min_size:
            break
    return seen


def _build_word_questions(conn, band: str):
    pool = _get_pool(conn, "word", band, QUESTIONS_PER_DUEL * 4)
    if len(pool) < 4:
        raise HTTPException(400, "Not enough word catalog items for this band")
    targets = random.sample(pool, min(QUESTIONS_PER_DUEL, len(pool)))
    questions = []
    for i, t in enumerate(targets):
        distractor_pool = [r for r in pool if r["item_id"] != t["item_id"]]
        distractors = random.sample(distractor_pool, min(3, len(distractor_pool)))
        options = [t["item_id"]] + [d["item_id"] for d in distractors]
        random.shuffle(options)
        questions.append({"qid": f"q{i}", "type": "word", "target": t["item_id"], "options": options})
    return questions


def _build_grammar_questions(conn, band: str):
    pool = _get_pool(conn, "grammar", band, QUESTIONS_PER_DUEL)
    if not pool:
        raise HTTPException(400, "Not enough grammar catalog items for this band")
    picks = random.sample(pool, min(QUESTIONS_PER_DUEL, len(pool)))
    questions = []
    for i, p in enumerate(picks):
        questions.append({
            "qid": f"q{i}", "type": "grammar",
            "question": p["question"], "options": json.loads(p["options"]),
            "correct": p["correct_answer"],
        })
    return questions


def _safe_questions(questions):
    """Strip the correct-answer secret before sending to a client — except for word
    questions, where `target`/`prompt_item_id` must be sent (see module docstring:
    the client needs it to render the item's localized gloss; there is no server-side
    translated text to send instead)."""
    out = []
    for q in questions:
        if q["type"] == "word":
            out.append({"qid": q["qid"], "type": "word", "prompt_item_id": q["target"], "options": q["options"]})
        else:
            out.append({"qid": q["qid"], "type": "grammar", "question": q["question"], "options": q["options"]})
    return out


def _score_answer(question, chosen: str):
    if question["type"] == "word":
        return chosen == question["target"]
    return chosen == question["correct"]


def _points_for(correct: bool, time_ms: int) -> int:
    if not correct:
        return 0
    bonus = max(0, round(10 * (SPEED_WINDOW_MS - min(time_ms, SPEED_WINDOW_MS)) / SPEED_WINDOW_MS))
    return 10 + bonus


INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # no 0/O/1/I — avoids look-alike mixups


def _gen_invite_code(conn) -> str:
    for _ in range(20):
        code = "".join(random.choice(INVITE_ALPHABET) for _ in range(6))
        if not conn.execute("SELECT 1 FROM users WHERE invite_code=?", (code,)).fetchone():
            return code
    raise HTTPException(500, "could not generate a unique invite code")


def _ensure_user(conn, device_id: str, display_name: str = None):
    row = conn.execute("SELECT * FROM users WHERE device_id=?", (device_id,)).fetchone()
    if row is None:
        code = _gen_invite_code(conn)
        conn.execute(
            "INSERT INTO users(device_id, display_name, created_at, invite_code) VALUES (?,?,?,?)",
            (device_id, display_name or "Player", now_iso(), code),
        )
        row = conn.execute("SELECT * FROM users WHERE device_id=?", (device_id,)).fetchone()
    elif not row["invite_code"]:
        # user created before invite codes existed (migration backfill)
        code = _gen_invite_code(conn)
        conn.execute("UPDATE users SET invite_code=? WHERE device_id=?", (code, device_id))
        row = conn.execute("SELECT * FROM users WHERE device_id=?", (device_id,)).fetchone()
    return row


# ------------------------------------------------------------- endpoints ---

@app.post("/api/register")
def register(body: RegisterBody):
    with get_conn() as conn:
        row = _ensure_user(conn, body.device_id, body.display_name)
        conn.execute(
            "UPDATE users SET display_name=? WHERE device_id=?",
            (body.display_name, body.device_id),
        )
        return {"ok": True, "invite_code": row["invite_code"]}


@app.patch("/api/profile")
def update_profile(body: ProfileBody):
    with get_conn() as conn:
        _ensure_user(conn, body.device_id, body.display_name)
        conn.execute(
            "UPDATE users SET display_name=? WHERE device_id=?",
            (body.display_name, body.device_id),
        )
    return {"ok": True}


@app.post("/api/duel/join")
def duel_join(body: JoinBody):
    if body.mode not in ("word", "grammar"):
        raise HTTPException(400, "mode must be 'word' or 'grammar'")
    band = body.band if body.band in BANDS else "A1"
    cutoff = (datetime.now(timezone.utc) - timedelta(minutes=OPEN_DUEL_TTL_MIN)).isoformat()

    with get_conn() as conn:
        _ensure_user(conn, body.device_id)
        conn.execute("UPDATE users SET current_band=? WHERE device_id=?", (band, body.device_id))

        if body.friend_id:
            if body.friend_id == body.device_id:
                raise HTTPException(400, "cannot challenge yourself")
            is_friend = conn.execute(
                "SELECT 1 FROM friends WHERE device_id=? AND friend_id=?", (body.device_id, body.friend_id)
            ).fetchone()
            if not is_friend:
                raise HTTPException(400, "not friends with this device_id")
            # did this friend already challenge me? claim it instead of opening a second one
            existing = conn.execute(
                """SELECT * FROM duels WHERE status='open' AND mode=? AND player2_id IS NULL
                   AND player1_id=? AND target_friend_id=? AND created_at > ?""",
                (body.mode, body.friend_id, body.device_id, cutoff),
            ).fetchone()
            if existing:
                conn.execute(
                    "UPDATE duels SET player2_id=?, status='active' WHERE duel_id=?",
                    (body.device_id, existing["duel_id"]),
                )
                opp = conn.execute("SELECT display_name FROM users WHERE device_id=?", (body.friend_id,)).fetchone()
                questions = json.loads(existing["questions"])
                return {
                    "duel_id": existing["duel_id"], "role": "matched",
                    "opponent_name": opp["display_name"] if opp else "Player",
                    "questions": _safe_questions(questions),
                }
            questions = _build_word_questions(conn, band) if body.mode == "word" else _build_grammar_questions(conn, band)
            duel_id = str(uuid.uuid4())
            conn.execute(
                """INSERT INTO duels(duel_id, mode, band, questions, player1_id, status, created_at, target_friend_id)
                   VALUES (?,?,?,?,?, 'open', ?, ?)""",
                (duel_id, body.mode, band, json.dumps(questions), body.device_id, now_iso(), body.friend_id),
            )
            return {"duel_id": duel_id, "role": "waiting", "opponent_name": None, "questions": _safe_questions(questions)}

        existing = conn.execute(
            """SELECT * FROM duels WHERE status='open' AND mode=? AND band=?
               AND player2_id IS NULL AND player1_id != ? AND target_friend_id IS NULL AND created_at > ?
               ORDER BY created_at ASC LIMIT 1""",
            (body.mode, band, body.device_id, cutoff),
        ).fetchone()

        if existing:
            conn.execute(
                "UPDATE duels SET player2_id=?, status='active' WHERE duel_id=?",
                (body.device_id, existing["duel_id"]),
            )
            opp = conn.execute(
                "SELECT display_name FROM users WHERE device_id=?", (existing["player1_id"],)
            ).fetchone()
            questions = json.loads(existing["questions"])
            return {
                "duel_id": existing["duel_id"], "role": "matched",
                "opponent_name": opp["display_name"] if opp else "Player",
                "questions": _safe_questions(questions),
            }

        questions = _build_word_questions(conn, band) if body.mode == "word" else _build_grammar_questions(conn, band)
        duel_id = str(uuid.uuid4())
        conn.execute(
            """INSERT INTO duels(duel_id, mode, band, questions, player1_id, status, created_at)
               VALUES (?,?,?,?,?, 'open', ?)""",
            (duel_id, body.mode, band, json.dumps(questions), body.device_id, now_iso()),
        )
        return {"duel_id": duel_id, "role": "waiting", "opponent_name": None, "questions": _safe_questions(questions)}


@app.post("/api/duel/{duel_id}/answer")
def duel_answer(duel_id: str, body: AnswerBody):
    with get_conn() as conn:
        duel = conn.execute("SELECT * FROM duels WHERE duel_id=?", (duel_id,)).fetchone()
        if duel is None:
            raise HTTPException(404, "duel not found")
        if body.device_id not in (duel["player1_id"], duel["player2_id"]):
            raise HTTPException(403, "not a participant in this duel")
        if duel["status"] == "done":
            raise HTTPException(400, "duel already finished")

        questions = json.loads(duel["questions"])
        question = next((q for q in questions if q["qid"] == body.qid), None)
        if question is None:
            raise HTTPException(400, "unknown qid")

        already = conn.execute(
            "SELECT * FROM duel_answers WHERE duel_id=? AND device_id=? AND qid=?",
            (duel_id, body.device_id, body.qid),
        ).fetchone()
        if already:
            return {"ok": True, "correct": bool(already["correct"]), "points": already["points"]}

        last = conn.execute(
            """SELECT answered_at FROM duel_answers WHERE duel_id=? AND device_id=?
               ORDER BY answered_at DESC LIMIT 1""",
            (duel_id, body.device_id),
        ).fetchone()
        baseline = last["answered_at"] if last else duel["created_at"]
        time_ms = int((datetime.now(timezone.utc) - datetime.fromisoformat(baseline)).total_seconds() * 1000)
        time_ms = max(0, time_ms)

        correct = _score_answer(question, body.chosen)
        points = _points_for(correct, time_ms)

        conn.execute(
            """INSERT INTO duel_answers(duel_id, device_id, qid, chosen, correct, time_ms, points, answered_at)
               VALUES (?,?,?,?,?,?,?,?)""",
            (duel_id, body.device_id, body.qid, body.chosen, int(correct), time_ms, points, now_iso()),
        )
        return {"ok": True, "correct": correct, "points": points}


@app.post("/api/duel/{duel_id}/finish")
def duel_finish(duel_id: str, body: FinishBody):
    with get_conn() as conn:
        duel = conn.execute("SELECT * FROM duels WHERE duel_id=?", (duel_id,)).fetchone()
        if duel is None:
            raise HTTPException(404, "duel not found")
        if body.device_id not in (duel["player1_id"], duel["player2_id"]):
            raise HTTPException(403, "not a participant in this duel")

        is_p1 = body.device_id == duel["player1_id"]
        col = "p1_finished_at" if is_p1 else "p2_finished_at"
        if not duel[col]:
            conn.execute(f"UPDATE duels SET {col}=? WHERE duel_id=?", (now_iso(), duel_id))
            duel = conn.execute("SELECT * FROM duels WHERE duel_id=?", (duel_id,)).fetchone()

        my_score = conn.execute(
            "SELECT COALESCE(SUM(points),0) s FROM duel_answers WHERE duel_id=? AND device_id=?",
            (duel_id, body.device_id),
        ).fetchone()["s"]

        opponent_id = duel["player2_id"] if is_p1 else duel["player1_id"]
        opponent_finished = bool(duel["p2_finished_at" if is_p1 else "p1_finished_at"])
        done = False

        if opponent_id and duel["p1_finished_at"] and duel["p2_finished_at"] and duel["status"] != "done":
            p1_score = conn.execute(
                "SELECT COALESCE(SUM(points),0) s FROM duel_answers WHERE duel_id=? AND device_id=?",
                (duel_id, duel["player1_id"]),
            ).fetchone()["s"]
            p2_score = conn.execute(
                "SELECT COALESCE(SUM(points),0) s FROM duel_answers WHERE duel_id=? AND device_id=?",
                (duel_id, duel["player2_id"]),
            ).fetchone()["s"]

            if p1_score > p2_score:
                winner, loser, draw = duel["player1_id"], duel["player2_id"], False
            elif p2_score > p1_score:
                winner, loser, draw = duel["player2_id"], duel["player1_id"], False
            else:
                winner, loser, draw = None, None, True

            conn.execute(
                "UPDATE duels SET status='done', winner_id=? WHERE duel_id=?",
                (winner, duel_id),
            )
            if draw:
                for pid, sc in ((duel["player1_id"], p1_score), (duel["player2_id"], p2_score)):
                    _award_points(conn, pid, sc, "draw")
            else:
                _award_points(conn, winner, p1_score if winner == duel["player1_id"] else p2_score, "win")
                _award_points(conn, loser, p2_score if winner == duel["player1_id"] else p1_score, "loss")
            done = True

        return {"ok": True, "my_score": my_score, "done": done, "opponent_finished": opponent_finished}


@app.get("/api/duel/{duel_id}/status")
def duel_status(duel_id: str, device_id: str):
    with get_conn() as conn:
        duel = conn.execute("SELECT * FROM duels WHERE duel_id=?", (duel_id,)).fetchone()
        if duel is None:
            raise HTTPException(404, "duel not found")
        if device_id not in (duel["player1_id"], duel["player2_id"]):
            raise HTTPException(403, "not a participant in this duel")

        is_p1 = device_id == duel["player1_id"]
        opponent_id = duel["player2_id"] if is_p1 else duel["player1_id"]
        opponent_name = None
        if opponent_id:
            row = conn.execute("SELECT display_name FROM users WHERE device_id=?", (opponent_id,)).fetchone()
            opponent_name = row["display_name"] if row else "Player"

        my_score = conn.execute(
            "SELECT COALESCE(SUM(points),0) s FROM duel_answers WHERE duel_id=? AND device_id=?",
            (duel_id, device_id),
        ).fetchone()["s"]

        resp = {
            "status": duel["status"], "opponent_name": opponent_name, "my_score": my_score,
            "i_finished": bool(duel["p1_finished_at" if is_p1 else "p2_finished_at"]),
            "opponent_finished": bool(duel["p2_finished_at" if is_p1 else "p1_finished_at"]),
        }
        if duel["status"] == "done" and opponent_id:
            opp_score = conn.execute(
                "SELECT COALESCE(SUM(points),0) s FROM duel_answers WHERE duel_id=? AND device_id=?",
                (duel_id, opponent_id),
            ).fetchone()["s"]
            resp["opponent_score"] = opp_score
            resp["winner"] = "me" if duel["winner_id"] == device_id else ("opponent" if duel["winner_id"] else "draw")
        return resp


@app.get("/api/leaderboard")
def leaderboard(band: str = None, period: str = "all", limit: int = 50):
    """period='all' ranks by lifetime points; period='month' ranks by the current
    calendar month's points and only includes users active this month (a stale
    month_key means they simply don't appear — see docs/02-SOCIAL.md §5)."""
    score_col = "month_points" if period == "month" else "points"
    with get_conn() as conn:
        where = []
        params = []
        if period == "month":
            where.append("month_key=?")
            params.append(current_month_key())
        if band and band in BANDS:
            where.append("current_band=?")
            params.append(band)
        clause = ("WHERE " + " AND ".join(where)) if where else ""
        params.append(limit)
        rows = conn.execute(
            f"SELECT display_name, {score_col} AS points, wins, losses, draws FROM users {clause} ORDER BY {score_col} DESC LIMIT ?",
            params,
        ).fetchall()
        return {"entries": [dict(r) for r in rows], "period": period}


@app.get("/api/leaderboard/me")
def leaderboard_me(device_id: str, period: str = "all"):
    score_col = "month_points" if period == "month" else "points"
    with get_conn() as conn:
        row = conn.execute("SELECT * FROM users WHERE device_id=?", (device_id,)).fetchone()
        if row is None:
            raise HTTPException(404, "unknown device_id")
        my_score = row[score_col] if period != "month" or row["month_key"] == current_month_key() else 0
        global_rank = conn.execute(
            f"SELECT COUNT(*)+1 r FROM users WHERE {score_col} > ?" + (" AND month_key=?" if period == "month" else ""),
            (my_score, current_month_key()) if period == "month" else (my_score,),
        ).fetchone()["r"]
        band_rank = conn.execute(
            f"SELECT COUNT(*)+1 r FROM users WHERE {score_col} > ? AND current_band=?" + (" AND month_key=?" if period == "month" else ""),
            (my_score, row["current_band"], current_month_key()) if period == "month" else (my_score, row["current_band"]),
        ).fetchone()["r"]
        return {
            "display_name": row["display_name"], "points": my_score, "wins": row["wins"],
            "losses": row["losses"], "draws": row["draws"], "current_band": row["current_band"],
            "global_rank": global_rank, "band_rank": band_rank, "period": period,
            "invite_code": row["invite_code"],
        }


@app.post("/api/friends/add")
def friends_add(body: AddFriendBody):
    code = body.invite_code.strip().upper()
    with get_conn() as conn:
        _ensure_user(conn, body.device_id)
        target = conn.execute("SELECT * FROM users WHERE invite_code=?", (code,)).fetchone()
        if target is None:
            raise HTTPException(404, "no user with this invite code")
        if target["device_id"] == body.device_id:
            raise HTTPException(400, "that's your own invite code")
        now = now_iso()
        conn.execute(
            "INSERT OR IGNORE INTO friends(device_id, friend_id, created_at) VALUES (?,?,?)",
            (body.device_id, target["device_id"], now),
        )
        conn.execute(
            "INSERT OR IGNORE INTO friends(device_id, friend_id, created_at) VALUES (?,?,?)",
            (target["device_id"], body.device_id, now),
        )
        return {"ok": True, "friend_name": target["display_name"]}


@app.get("/api/friends")
def friends_list(device_id: str):
    today = current_day_key()
    with get_conn() as conn:
        rows = conn.execute(
            """SELECT u.device_id, u.display_name, u.current_band, u.points,
                      u.today_points, u.today_mastered, u.activity_day_key
               FROM friends f JOIN users u ON u.device_id=f.friend_id
               WHERE f.device_id=? ORDER BY u.display_name""",
            (device_id,),
        ).fetchall()
        out = []
        for r in rows:
            d = dict(r)
            # stale activity (yesterday or older) reads as "no activity today", not a lie
            fresh = d.pop("activity_day_key") == today
            d["today_points"] = d["today_points"] if fresh else 0
            d["today_mastered"] = d["today_mastered"] if fresh else 0
            out.append(d)
        return {"friends": out}


@app.get("/api/duel/pending")
def duel_pending(device_id: str):
    """Open challenges a friend has sent me that I haven't joined yet."""
    with get_conn() as conn:
        rows = conn.execute(
            """SELECT d.duel_id, d.mode, d.band, d.created_at, d.player1_id AS from_device_id, u.display_name AS from_name
               FROM duels d JOIN users u ON u.device_id=d.player1_id
               WHERE d.status='open' AND d.target_friend_id=? AND d.player2_id IS NULL
               ORDER BY d.created_at DESC""",
            (device_id,),
        ).fetchall()
        return {"pending": [dict(r) for r in rows]}


@app.post("/api/activity/sync")
def activity_sync(body: ActivitySyncBody):
    """Lightweight, privacy-scoped signal — NOT the full SRS schedule. Just enough
    to (a) show friends an honest "today" number and (b) know who has real due
    items so the reminder loop doesn't nag someone with nothing to review."""
    today = current_day_key()
    with get_conn() as conn:
        _ensure_user(conn, body.device_id)
        conn.execute(
            """UPDATE users SET due_count=?, lang=?, last_activity_at=?,
                                 activity_day_key=?, today_points=?, today_mastered=?
               WHERE device_id=?""",
            (body.due_count, body.lang, now_iso(), today, body.today_points, body.today_mastered, body.device_id),
        )
        return {"ok": True}


@app.get("/api/push/vapid_public_key")
def push_vapid_public_key():
    if not os.path.exists(VAPID_PRIVATE_KEY_PATH):
        raise HTTPException(503, "push not configured on this server yet")
    return {"key": _vapid_public_key_b64url()}


@app.post("/api/push/subscribe")
def push_subscribe(body: PushSubscribeBody):
    with get_conn() as conn:
        _ensure_user(conn, body.device_id)
        conn.execute(
            """INSERT INTO push_subscriptions(device_id, endpoint, p256dh, auth, created_at)
               VALUES (?,?,?,?,?)
               ON CONFLICT(device_id) DO UPDATE SET endpoint=excluded.endpoint,
                 p256dh=excluded.p256dh, auth=excluded.auth""",
            (body.device_id, body.endpoint, body.keys.p256dh, body.keys.auth, now_iso()),
        )
        return {"ok": True}


@app.post("/api/push/unsubscribe")
def push_unsubscribe(body: PushUnsubscribeBody):
    with get_conn() as conn:
        conn.execute("DELETE FROM push_subscriptions WHERE device_id=?", (body.device_id,))
        return {"ok": True}


@app.get("/api/health")
def health():
    return {"ok": True}
