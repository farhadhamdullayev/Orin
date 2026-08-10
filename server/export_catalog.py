"""
One-time / re-runnable extraction: pulls a language-independent answer-key
catalog (word ids+ranks, grammar drill question/options/answer) out of
Orin/web/index.html and (re)populates the `catalog_items` table.

Only structural/English data is stored server-side (see main.py module
docstring for why this is safe across all 8 UI languages) — no translated
text, no full pedagogical content (glosses, examples) is duplicated here.

Usage:
    PythonEmbed312\\python.exe export_catalog.py [path-to-index.html]

Re-run whenever CONTENT/GRAMMAR word/drill counts change materially (e.g.
after a content-expansion pass) to keep the duel catalog in sync.
"""
import json
import os
import re
import sqlite3
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from db import DB_PATH, init_db

DEFAULT_HTML = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "web", "index.html"
)

WORD_BANDS = [("Pre-A1", 0), ("A1", 700), ("A2", 1500), ("B1", 2500), ("B2", 3250), ("C1", 4000), ("C2", 4800)]


def band_for_rank(rank: int) -> str:
    band = WORD_BANDS[0][0]
    for name, threshold in WORD_BANDS:
        if rank >= threshold:
            band = name
    return band


def find_match(text: str, open_idx: int) -> int:
    """Bracket-match starting at text[open_idx] (a '[' or '{'), honouring
    quoted strings and backslash escapes, same algorithm used throughout this
    project's PowerShell extraction scripts."""
    open_ch = text[open_idx]
    close_ch = {"[": "]", "{": "}"}[open_ch]
    depth = 0
    in_str = False
    str_ch = ""
    i = open_idx
    n = len(text)
    while i < n:
        c = text[i]
        if in_str:
            if c == "\\":
                i += 2
                continue
            if c == str_ch:
                in_str = False
            i += 1
            continue
        if c in ('"', "'"):
            in_str = True
            str_ch = c
            i += 1
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError(f"no matching bracket found from index {open_idx}")


TUPLE_RE = re.compile(
    r'\["((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)",(\d+)\]'
)


def word_id(english_word: str) -> str:
    return "i_" + re.sub(r"[^a-zA-Z]", "", english_word).lower()


def extract_words(html: str):
    marker = "const CONTENT=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    chunk = html[open_idx : close_idx + 1]

    rows = []
    seen_ids = set()
    dupes = 0
    for m in TUPLE_RE.finditer(chunk):
        english, _gloss, _ex_en, _ex_az, rank_s = m.groups()
        rank = int(rank_s)
        wid = word_id(english)
        if wid in seen_ids:
            # CONTENT has ~1400 duplicate English words sharing the same derived id
            # (a pre-existing content-authoring issue, not something this export
            # script should silently paper over) — keep first occurrence only so
            # the catalog has one row per id, but surface the count.
            dupes += 1
            continue
        seen_ids.add(wid)
        rows.append((wid, "word", band_for_rank(rank), rank, None, None, None))
    if dupes:
        print(f"  NOTE: skipped {dupes} duplicate-id word entries in CONTENT (kept first occurrence of each).")
    return rows


DRILL_RE = re.compile(
    r'\["((?:[^"\\]|\\.)*)",\[((?:[^\]\\]|\\.)*)\],"((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)"\]'
)
OPT_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')


def extract_grammar(html: str):
    marker = "const GRAMMAR=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    topics_text = html[open_idx : close_idx + 1]

    # split into individual topic objects by bracket-matching each "{id:...}" entry
    rows = []
    i = topics_text.index("[") + 1
    n = len(topics_text)
    while i < n:
        while i < n and topics_text[i] in " \n\r\t,":
            i += 1
        if i >= n or topics_text[i] == "]":
            break
        if topics_text[i] != "{":
            i += 1
            continue
        obj_end = find_match(topics_text, i)
        obj = topics_text[i : obj_end + 1]
        i = obj_end + 1

        id_m = re.search(r'id:"((?:[^"\\]|\\.)*)"', obj)
        lvl_m = re.search(r'lvl:"((?:[^"\\]|\\.)*)"', obj)
        if not id_m or not lvl_m:
            continue
        topic_id, lvl = id_m.group(1), lvl_m.group(1)

        drills_marker = "drills:["
        di = obj.find(drills_marker)
        if di < 0:
            continue
        d_open = di + len(drills_marker) - 1
        d_close = find_match(obj, d_open)
        drills_text = obj[d_open : d_close + 1]

        for j, dm in enumerate(DRILL_RE.finditer(drills_text)):
            question, opts_raw, correct, _gloss = dm.groups()
            options = [o for o in OPT_RE.findall(opts_raw)]
            if correct not in options:
                continue  # defensive: skip malformed drill rather than store a broken answer key
            item_id = f"{topic_id}_{j}"
            rows.append((item_id, "grammar", lvl, None, question, json.dumps(options), correct))
    return rows


def main():
    html_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_HTML
    html_path = os.path.abspath(html_path)
    print(f"Reading {html_path} ...")
    with open(html_path, "r", encoding="utf-8") as f:
        html = f.read()

    words = extract_words(html)
    grammar = extract_grammar(html)
    print(f"Parsed {len(words)} word items, {len(grammar)} grammar drill items.")

    if len(words) < 100:
        raise SystemExit(f"Sanity check failed: only {len(words)} word items parsed (expected thousands) — aborting.")
    if len(grammar) < 50:
        raise SystemExit(f"Sanity check failed: only {len(grammar)} grammar items parsed (expected hundreds) — aborting.")

    init_db()
    conn = sqlite3.connect(DB_PATH)
    conn.execute("DELETE FROM catalog_items")
    conn.executemany(
        "INSERT INTO catalog_items(item_id,type,band,rank,question,options,correct_answer) VALUES (?,?,?,?,?,?,?)",
        words + grammar,
    )
    conn.commit()

    for band, _ in WORD_BANDS:
        c = conn.execute("SELECT COUNT(*) FROM catalog_items WHERE type='word' AND band=?", (band,)).fetchone()[0]
        print(f"  word band {band}: {c}")
    for band in ("A1", "A2", "B1", "B2", "C1", "C2"):
        c = conn.execute("SELECT COUNT(*) FROM catalog_items WHERE type='grammar' AND band=?", (band,)).fetchone()[0]
        print(f"  grammar band {band}: {c}")

    conn.close()
    print("Catalog export complete.")


if __name__ == "__main__":
    main()
