"""
Phase-0 content export for the native iOS rebuild (see the approved plan at
project root memory / plan file "Orin native iOS app").

Extracts the vocabulary catalog (CONTENT + the 8 non-Azerbaijani LP.<lang>.vocab
override packs) out of Orin/web/index.html and writes a single, Swift-ready
vocab.json with one VocabItem-shaped record per word:

    {"id": "i_because", "target": "because", "frequencyRank": 40,
     "exampleTarget": "I stayed home because it was raining.",
     "gloss": {"az": "...", "hi": "...", ...9 languages...},
     "exampleGloss": {"az": "...", "hi": "...", ...9 languages...}}

Azerbaijani is the *native* language baked directly into CONTENT; the other
8 languages live in sparse LP.<lang>.vocab[id]={g,e} override packs and fall
back to the Azerbaijani text when a translation is missing — this mirrors the
exact runtime behaviour of applyLangPack() in index.html, so the exported
JSON needs no fallback logic on the Swift side.

Usage:
    PythonEmbed312\\python.exe export_ios_content.py [path-to-index.html]
"""
import json
import os
import re
import sys

DEFAULT_HTML = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "web", "index.html")
OUT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "ios", "Orin", "Resources", "Content", "vocab.json"
)

LANGS = ["hi", "zh", "es", "pt", "id", "ar", "vi", "ko"]  # az is the CONTENT-native base, not a pack


def find_match(text: str, open_idx: int) -> int:
    """Bracket-match starting at text[open_idx] (a '[' or '{'), honouring
    quoted strings and backslash escapes. Same algorithm as server/export_catalog.py."""
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


def extract_content(html: str):
    marker = "const CONTENT=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    chunk = html[open_idx : close_idx + 1]

    items = []
    seen_ids = set()
    dupes = 0
    for m in TUPLE_RE.finditer(chunk):
        english, gloss_az, ex_en, exg_az, rank_s = m.groups()
        wid = word_id(english)
        if wid in seen_ids:
            dupes += 1
            continue
        seen_ids.add(wid)
        items.append(
            {
                "id": wid,
                "target": english,
                "frequencyRank": int(rank_s),
                "exampleTarget": ex_en,
                "gloss": {"az": gloss_az},
                "exampleGloss": {"az": exg_az},
            }
        )
    if dupes:
        print(f"  NOTE: skipped {dupes} duplicate-id CONTENT entries (kept first occurrence of each).")
    items.sort(key=lambda it: it["frequencyRank"])
    return items


VOCAB_ENTRY_RE = re.compile(
    r'"((?:[^"\\]|\\.)*)":\{g:"((?:[^"\\]|\\.)*)"(?:,e:"((?:[^"\\]|\\.)*)")?\}'
)


def extract_lp_vocab(html: str, lang: str):
    marker = f"LP.{lang}={{"
    start = html.find(marker)
    if start < 0:
        print(f"  WARNING: no LP.{lang} block found — language '{lang}' will fall back to Azerbaijani for all words.")
        return {}
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    pack = html[open_idx : close_idx + 1]

    vmarker = "vocab:{"
    vi = pack.find(vmarker)
    if vi < 0:
        print(f"  WARNING: LP.{lang} has no vocab:{{}} section.")
        return {}
    v_open = vi + len(vmarker) - 1
    v_close = find_match(pack, v_open)
    vocab_text = pack[v_open : v_close + 1]

    out = {}
    for m in VOCAB_ENTRY_RE.finditer(vocab_text):
        wid, g, e = m.groups()
        out[wid] = (g, e or "")
    return out


def main():
    html_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_HTML
    html_path = os.path.abspath(html_path)
    print(f"Reading {html_path} ...")
    with open(html_path, "r", encoding="utf-8") as f:
        html = f.read()

    items = extract_content(html)
    print(f"Parsed {len(items)} CONTENT words.")
    if len(items) < 100:
        raise SystemExit(f"Sanity check failed: only {len(items)} words parsed (expected thousands) — aborting.")

    by_id = {it["id"]: it for it in items}

    fallback_counts = {lang: 0 for lang in LANGS}
    for lang in LANGS:
        pack = extract_lp_vocab(html, lang)
        matched = 0
        for it in items:
            entry = pack.get(it["id"])
            if entry is not None:
                g, e = entry
                it["gloss"][lang] = g
                it["exampleGloss"][lang] = e or it["exampleGloss"]["az"]
                matched += 1
            else:
                it["gloss"][lang] = it["gloss"]["az"]
                it["exampleGloss"][lang] = it["exampleGloss"]["az"]
                fallback_counts[lang] += 1
        print(f"  {lang}: {matched}/{len(items)} words translated, {fallback_counts[lang]} fell back to Azerbaijani")

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=None, separators=(",", ":"))

    all_langs = ["az"] + LANGS
    incomplete = [it["id"] for it in items if any(l not in it["gloss"] for l in all_langs)]
    if incomplete:
        raise SystemExit(f"Sanity check failed: {len(incomplete)} items missing a language key entirely, e.g. {incomplete[:5]}")

    print(f"Wrote {len(items)} vocab items to {OUT_PATH}")
    print("Content export complete.")


if __name__ == "__main__":
    main()
