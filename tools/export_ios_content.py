"""
Content export for the native iOS rebuild (see the approved plan at
project root memory / plan file "Orin native iOS app").

Phase 0/1 (vocab): extracts the vocabulary catalog (CONTENT + AWL_WORDS +
the 8 non-Azerbaijani LP.<lang>.vocab override packs) out of
Orin/web/index.html and writes vocab.json with one VocabItem-shaped record
per word:

    {"id": "i_because", "target": "because", "frequencyRank": 40,
     "exampleTarget": "I stayed home because it was raining.",
     "gloss": {"az": "...", "hi": "...", ...9 languages...},
     "exampleGloss": {"az": "...", "hi": "...", ...9 languages...},
     "awl": false}

Azerbaijani is the *native* language baked directly into CONTENT; the other
8 languages live in sparse LP.<lang>.vocab[id]={g,e} override packs and fall
back to the Azerbaijani text when a translation is missing — this mirrors the
exact runtime behaviour of applyLangPack() in index.html, so the exported
JSON needs no fallback logic on the Swift side.

Phase 2 (grammar/listening/visual): extracts GRAMMAR, LISTENING, and PICSETS.
Unlike CONTENT, none of the 8 LP.<lang> packs currently carry `grammar`,
`listen`, or `vis` sections (verified against the live file — only `vocab`
exists in all 8) — so applyLangPack() always falls back to the Azerbaijani
text for these three content types today, regardless of the selected UI
language. grammar.json/listening.json/visual_vocab.json are exported as
plain Azerbaijani text accordingly (no per-language dict) to match actual
current behaviour; if the web app gains translations for these later, this
script and the Swift models should both grow a `[lang:String]` dict the same
way vocab.json already has.

Phase 3 (reading/writing): extracts PASSAGES and WRITING_PROMPTS. Same
Azerbaijani-only reasoning as grammar/listening/visual for the prompt text;
passage bodies are English-only (no translation needed to read them).

Usage:
    PythonEmbed312\\python.exe export_ios_content.py [path-to-index.html]
"""
import json
import os
import re
import sys

DEFAULT_HTML = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "web", "index.html")
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ios", "Orin", "Resources", "Content")

LANGS = ["hi", "zh", "es", "pt", "id", "ar", "vi", "ko"]  # az is the CONTENT-native base, not a pack


def find_match(text: str, open_idx: int) -> int:
    """Bracket-match starting at text[open_idx] (a '[', '{', or '('), honouring
    quoted strings and backslash escapes. Same algorithm as server/export_catalog.py."""
    pairs = {"[": "]", "{": "}", "(": ")"}
    open_ch = text[open_idx]
    close_ch = pairs[open_ch]
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


def split_top_level(text: str) -> list:
    """Split a comma-separated sequence at bracket-depth 0 (honouring quoted
    strings), e.g. the arguments of a picCat(...) call or the elements of the
    PICSETS array (which mixes {...} literals and picCat(...) calls)."""
    parts = []
    depth = 0
    in_str = False
    str_ch = ""
    start = 0
    i = 0
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
        elif c in "[{(":
            depth += 1
        elif c in "]})":
            depth -= 1
        elif c == "," and depth == 0:
            parts.append(text[start:i])
            start = i + 1
        i += 1
    tail = text[start:].strip()
    if tail:
        parts.append(tail)
    return [p.strip() for p in parts]


def walk_top_level_objects(array_text: str):
    """Yield each top-level {...} object literal's text from a JS array-literal
    body (the array's outer brackets already stripped by the caller)."""
    i = 0
    n = len(array_text)
    while i < n:
        while i < n and array_text[i] in " \n\r\t,":
            i += 1
        if i >= n or array_text[i] != "{":
            i += 1
            continue
        end = find_match(array_text, i)
        yield array_text[i : end + 1]
        i = end + 1


TUPLE_RE = re.compile(
    r'\["((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)",(\d+)\]'
)


def word_id(english_word: str, prefix: str = "i_") -> str:
    return prefix + re.sub(r"[^a-zA-Z]", "", english_word).lower()


def _extract_tuples(html: str, marker: str, id_prefix: str, awl: bool):
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    chunk = html[open_idx : close_idx + 1]

    items = []
    for m in TUPLE_RE.finditer(chunk):
        english, gloss_az, ex_en, exg_az, rank_s = m.groups()
        items.append(
            {
                "id": word_id(english, id_prefix),
                "target": english,
                "frequencyRank": int(rank_s),
                "exampleTarget": ex_en,
                "gloss": {"az": gloss_az},
                "exampleGloss": {"az": exg_az},
                "awl": awl,
            }
        )
    return items


def extract_content(html: str):
    """CONTENT + AWL_WORDS, merged and sorted exactly like the web app does at
    runtime (`AWL_WORDS.forEach(a=>CONTENT.push({...,awl:true})); CONTENT.sort(...)`,
    index.html ~line 6478-6479) — AWL words are full vocab items, just flagged,
    not a separate catalog. Missing this merge would silently drop ~200 AWL
    words from the exported deck."""
    items = _extract_tuples(html, "const CONTENT=[", "i_", awl=False)
    items += _extract_tuples(html, "const AWL_WORDS=[", "a_", awl=True)

    deduped = []
    seen_ids = set()
    dupes = 0
    for it in items:
        if it["id"] in seen_ids:
            dupes += 1
            continue
        seen_ids.add(it["id"])
        deduped.append(it)
    if dupes:
        print(f"  NOTE: skipped {dupes} duplicate-id CONTENT/AWL entries (kept first occurrence of each).")
    deduped.sort(key=lambda it: it["frequencyRank"])
    return deduped


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


DRILL_RE = re.compile(
    r'\["((?:[^"\\]|\\.)*)",\[((?:[^\]\\]|\\.)*)\],"((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)"\]'
)
OPT_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
EX_PAIR_RE = re.compile(r'\["((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)"\]')


def extract_grammar(html: str):
    marker = "const GRAMMAR=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    array_text = html[open_idx + 1 : close_idx]

    topics = []
    for obj in walk_top_level_objects(array_text):
        id_m = re.search(r'id:"((?:[^"\\]|\\.)*)"', obj)
        icon_m = re.search(r'icon:"((?:[^"\\]|\\.)*)"', obj)
        title_m = re.search(r'title:"((?:[^"\\]|\\.)*)"', obj)
        lvl_m = re.search(r'lvl:"((?:[^"\\]|\\.)*)"', obj)
        note_m = re.search(r'note:"((?:[^"\\]|\\.)*)"', obj)
        if not (id_m and title_m and lvl_m):
            continue

        examples = []
        ei = obj.find("ex:[")
        if ei >= 0:
            e_open = ei + len("ex:[") - 1
            e_close = find_match(obj, e_open)
            for m in EX_PAIR_RE.finditer(obj[e_open : e_close + 1]):
                examples.append({"english": m.group(1), "gloss": m.group(2)})

        drills = []
        di = obj.find("drills:[")
        if di >= 0:
            d_open = di + len("drills:[") - 1
            d_close = find_match(obj, d_open)
            for j, dm in enumerate(DRILL_RE.finditer(obj[d_open : d_close + 1])):
                question, opts_raw, correct, gloss = dm.groups()
                options = OPT_RE.findall(opts_raw)
                if correct not in options:
                    continue  # defensive: skip malformed drill rather than store a broken answer key
                drills.append(
                    {
                        "id": f"{id_m.group(1)}_{j}",
                        "question": question,
                        "options": options,
                        "correctIndex": options.index(correct),
                        "gloss": gloss,
                    }
                )

        topics.append(
            {
                "id": id_m.group(1),
                "icon": icon_m.group(1) if icon_m else "",
                "title": title_m.group(1),
                "level": lvl_m.group(1),
                "note": note_m.group(1) if note_m else "",
                "examples": examples,
                "drills": drills,
            }
        )
    return topics


LISTEN_ITEM_RE = re.compile(
    r'\{en:"((?:[^"\\]|\\.)*)",az:"((?:[^"\\]|\\.)*)",q:"((?:[^"\\]|\\.)*)",'
    r'opts:\[((?:[^\]\\]|\\.)*)\],a:"((?:[^"\\]|\\.)*)"\}'
)


def extract_listening(html: str):
    marker = "const LISTENING=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    array_text = html[open_idx + 1 : close_idx]

    topics = []
    for obj in walk_top_level_objects(array_text):
        id_m = re.search(r'id:"((?:[^"\\]|\\.)*)"', obj)
        icon_m = re.search(r'icon:"((?:[^"\\]|\\.)*)"', obj)
        title_m = re.search(r'title:"((?:[^"\\]|\\.)*)"', obj)
        lvl_m = re.search(r'lvl:"((?:[^"\\]|\\.)*)"', obj)
        if not (id_m and title_m and lvl_m):
            continue

        items = []
        ii = obj.find("items:[")
        if ii >= 0:
            i_open = ii + len("items:[") - 1
            i_close = find_match(obj, i_open)
            for k, im in enumerate(LISTEN_ITEM_RE.finditer(obj[i_open : i_close + 1])):
                english, az, q, opts_raw, a = im.groups()
                items.append(
                    {
                        "id": f"{id_m.group(1)}_{k}",
                        "english": english,
                        "gloss": az,
                        "question": q,
                        "options": OPT_RE.findall(opts_raw),
                        "correctAnswer": a,
                    }
                )

        topics.append(
            {
                "id": id_m.group(1),
                "icon": icon_m.group(1) if icon_m else "",
                "title": title_m.group(1),
                "level": lvl_m.group(1),
                "items": items,
            }
        )
    return topics


PIC_ITEM_OBJ_RE = re.compile(r'\{id:"((?:[^"\\]|\\.)*)",word:"((?:[^"\\]|\\.)*)",gloss:"((?:[^"\\]|\\.)*)"\}')
PIC_TRIPLE_RE = re.compile(r'\["((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)","((?:[^"\\]|\\.)*)"\]')


def extract_picsets(html: str):
    """PICSETS mixes plain {...} category objects (e.g. "body") with calls to
    the picCat(id,icon,title,items) JS helper (every other category) — walk
    top-level comma-separated elements and handle each shape."""
    marker = "const PICSETS=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    array_text = html[open_idx + 1 : close_idx]

    categories = []
    for elem in split_top_level(array_text):
        if not elem:
            continue
        if elem.startswith("{"):
            obj = elem
            id_m = re.search(r'id:"((?:[^"\\]|\\.)*)"', obj)
            icon_m = re.search(r'icon:"((?:[^"\\]|\\.)*)"', obj)
            title_m = re.search(r'title:"((?:[^"\\]|\\.)*)"', obj)
            if not (id_m and title_m):
                continue
            items = []
            ii = obj.find("items:[")
            if ii >= 0:
                i_open = ii + len("items:[") - 1
                i_close = find_match(obj, i_open)
                for m in PIC_ITEM_OBJ_RE.finditer(obj[i_open : i_close + 1]):
                    iid, word, gloss = m.groups()
                    items.append({"id": iid, "emoji": "", "word": word, "gloss": gloss})
            categories.append(
                {"id": id_m.group(1), "icon": icon_m.group(1) if icon_m else "", "title": title_m.group(1), "items": items}
            )
        elif elem.startswith("picCat("):
            paren_open = elem.index("(")
            paren_close = find_match(elem, paren_open)
            args = split_top_level(elem[paren_open + 1 : paren_close])
            if len(args) != 4:
                print(f"  WARNING: skipping malformed picCat(...) call: {elem[:60]}...")
                continue
            cat_id = args[0].strip('"')
            icon = args[1].strip('"')
            title = args[2].strip('"')
            items = []
            for k, m in enumerate(PIC_TRIPLE_RE.finditer(args[3])):
                emoji, word, gloss = m.groups()
                items.append({"id": f"{cat_id}_{k}", "emoji": emoji, "word": word, "gloss": gloss})
            categories.append({"id": cat_id, "icon": icon, "title": title, "items": items})
    return categories


PASSAGE_RE = re.compile(r'\["((?:[^"\\]|\\.)*)",(\d+),"((?:[^"\\]|\\.)*)"\]')


def extract_reading(html: str):
    """PASSAGES: [title, band, text] triples. `band` is unused at runtime on
    the web (only the dynamic coverage() computation matters — verified this
    session) — dropped here too; `wordCount` is computed instead, useful for
    the native CoverageEngine/UI without re-tokenizing every render."""
    marker = "const PASSAGES=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    chunk = html[open_idx : close_idx + 1]

    passages = []
    for i, m in enumerate(PASSAGE_RE.finditer(chunk)):
        title, _band, text = m.groups()
        passages.append(
            {
                "id": f"p_{i}",
                "title": title,
                "text": text,
                "wordCount": len(text.split()),
            }
        )
    return passages


WRITING_PROMPT_RE = re.compile(
    r'\{id:"((?:[^"\\]|\\.)*)",lvl:"((?:[^"\\]|\\.)*)",kind:"((?:[^"\\]|\\.)*)",'
    r'prompt:"((?:[^"\\]|\\.)*)",min:(\d+)\}'
)


def extract_writing_prompts(html: str):
    marker = "const WRITING_PROMPTS=["
    start = html.index(marker)
    open_idx = start + len(marker) - 1
    close_idx = find_match(html, open_idx)
    chunk = html[open_idx : close_idx + 1]

    prompts = []
    for m in WRITING_PROMPT_RE.finditer(chunk):
        pid, lvl, kind, prompt, min_words = m.groups()
        prompts.append(
            {
                "id": pid,
                "level": lvl,
                "kind": kind,
                "prompt": prompt,
                "minWords": int(min_words),
            }
        )
    return prompts


def write_json(name: str, data):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=None, separators=(",", ":"))
    print(f"  wrote {path}")


def main():
    html_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_HTML
    html_path = os.path.abspath(html_path)
    print(f"Reading {html_path} ...")
    with open(html_path, "r", encoding="utf-8") as f:
        html = f.read()

    print("== vocab.json ==")
    items = extract_content(html)
    awl_count = sum(1 for it in items if it["awl"])
    print(f"Parsed {len(items)} CONTENT+AWL words ({awl_count} AWL-flagged).")
    if len(items) < 100:
        raise SystemExit(f"Sanity check failed: only {len(items)} words parsed (expected thousands) — aborting.")

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

    all_langs = ["az"] + LANGS
    incomplete = [it["id"] for it in items if any(l not in it["gloss"] for l in all_langs)]
    if incomplete:
        raise SystemExit(f"Sanity check failed: {len(incomplete)} items missing a language key entirely, e.g. {incomplete[:5]}")
    write_json("vocab.json", items)

    print("== grammar.json ==")
    grammar = extract_grammar(html)
    total_drills = sum(len(t["drills"]) for t in grammar)
    print(f"Parsed {len(grammar)} grammar topics, {total_drills} drills.")
    if len(grammar) < 10 or total_drills < 50:
        raise SystemExit(f"Sanity check failed: only {len(grammar)} topics / {total_drills} drills parsed — aborting.")
    write_json("grammar.json", grammar)

    print("== listening.json ==")
    listening = extract_listening(html)
    total_listen_items = sum(len(t["items"]) for t in listening)
    print(f"Parsed {len(listening)} listening topics, {total_listen_items} items.")
    if len(listening) < 5 or total_listen_items < 30:
        raise SystemExit(f"Sanity check failed: only {len(listening)} topics / {total_listen_items} items parsed — aborting.")
    write_json("listening.json", listening)

    print("== visual_vocab.json ==")
    visual = extract_picsets(html)
    total_visual_items = sum(len(c["items"]) for c in visual)
    print(f"Parsed {len(visual)} visual categories, {total_visual_items} items.")
    if len(visual) < 5 or total_visual_items < 50:
        raise SystemExit(f"Sanity check failed: only {len(visual)} categories / {total_visual_items} items parsed — aborting.")
    write_json("visual_vocab.json", visual)

    print("== reading.json ==")
    reading = extract_reading(html)
    print(f"Parsed {len(reading)} reading passages.")
    if len(reading) < 100:
        raise SystemExit(f"Sanity check failed: only {len(reading)} passages parsed (expected ~1200) — aborting.")
    write_json("reading.json", reading)

    print("== writing_prompts.json ==")
    writing = extract_writing_prompts(html)
    print(f"Parsed {len(writing)} writing prompts.")
    if len(writing) < 20:
        raise SystemExit(f"Sanity check failed: only {len(writing)} prompts parsed (expected ~120) — aborting.")
    write_json("writing_prompts.json", writing)

    print("Content export complete.")


if __name__ == "__main__":
    main()
