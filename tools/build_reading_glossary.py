"""
Builds Resources/Content/reading_glossary.json — a supplementary
word -> Azerbaijani-translation map covering every unique word that appears
across the 1200 reading passages (reading.json) but isn't already resolvable
from the curated vocab catalog (vocab.json, direct match or common
inflection-suffix strip). ReadingView.swift merges this with the vocab
catalog so tapping ANY word in a passage resolves to a translation — this
was an explicit requirement (no "not found" gaps), and the vocab catalog
alone only covers a curated subset of English, not the free text used in
1200 independently-written passages.

Two-step process (translation quality needs a real translator, not a
dictionary lookup, so this script doesn't do that part itself):

  1. `python build_reading_glossary.py extract`
     Writes the list of missing words (real_missing_words.json) and the
     list of words detected as likely proper nouns (proper_nouns.json,
     excluded from translation — names don't need one) to OUT_DIR. Split
     real_missing_words.json into chunks and translate each chunk (e.g. via
     LLM agents) into a {word: azerbaijani_translation} JSON object.

  2. `python build_reading_glossary.py merge <chunk1.json> <chunk2.json> ...`
     Merges the translated chunks + the proper-noun list (mapped to
     "<Capitalized> (ad)", not a fabricated translation) into the final
     reading_glossary.json, validating that every real_missing_words.json
     entry got translated.

Usage:
    PythonEmbed312\\python.exe build_reading_glossary.py extract
    PythonEmbed312\\python.exe build_reading_glossary.py merge translated_*.json
"""
import json
import os
import re
import sys

CONTENT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ios", "Orin", "Resources", "Content")
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "_glossary_work")


def tokenize_lower(text):
    return [w for w in re.split(r"[^a-zA-Z]+", text.lower()) if w]


def strip_variants(word):
    cands = set()
    if word.endswith("ies"):
        cands.add(word[:-3] + "y")
    if word.endswith("ing"):
        stem = word[:-3]
        cands.add(stem)
        cands.add(stem + "e")
    if word.endswith("ed"):
        cands.add(word[:-2])
        cands.add(word[:-1])
    if word.endswith("es"):
        cands.add(word[:-2])
    if word.endswith("s"):
        cands.add(word[:-1])
    return cands


def extract():
    vocab = json.load(open(os.path.join(CONTENT_DIR, "vocab.json"), encoding="utf-8"))
    reading = json.load(open(os.path.join(CONTENT_DIR, "reading.json"), encoding="utf-8"))

    vocab_words = set()
    for item in vocab:
        toks = tokenize_lower(item["target"])
        if len(toks) == 1:
            vocab_words.add(toks[0])

    lower_seen = set()
    midsentence_cap_seen = set()
    for p in reading:
        for sent in re.split(r"(?<=[.!?])\s+", p["text"]):
            raw_tokens = re.findall(r"[A-Za-z]+(?:'[A-Za-z]+)?", sent)
            for i, tok in enumerate(raw_tokens):
                lw = tok.lower()
                if tok == lw:
                    lower_seen.add(lw)
                elif tok[0].isupper() and i > 0:
                    midsentence_cap_seen.add(lw)
    likely_proper_nouns = midsentence_cap_seen - lower_seen

    passage_words = set()
    for p in reading:
        for w in tokenize_lower(p["text"]):
            passage_words.add(w)

    missing = [w for w in passage_words if w not in vocab_words and not any(c in vocab_words for c in strip_variants(w))]
    missing_set = set(missing)
    proper_nouns = sorted(missing_set & likely_proper_nouns)
    real_missing = sorted(missing_set - likely_proper_nouns)

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "real_missing_words.json"), "w", encoding="utf-8") as f:
        json.dump(real_missing, f, ensure_ascii=False, indent=2)
    with open(os.path.join(OUT_DIR, "proper_nouns.json"), "w", encoding="utf-8") as f:
        json.dump(proper_nouns, f, ensure_ascii=False, indent=2)

    print(f"{len(passage_words)} unique passage words; {len(real_missing)} need translation, {len(proper_nouns)} treated as proper nouns.")
    print(f"Wrote real_missing_words.json and proper_nouns.json to {OUT_DIR}")


def merge(chunk_paths):
    expected = json.load(open(os.path.join(OUT_DIR, "real_missing_words.json"), encoding="utf-8"))
    proper_nouns = json.load(open(os.path.join(OUT_DIR, "proper_nouns.json"), encoding="utf-8"))

    glossary = {}
    for path in chunk_paths:
        chunk = json.load(open(path, encoding="utf-8"))
        glossary.update(chunk)

    missing_after_merge = [w for w in expected if w not in glossary]
    if missing_after_merge:
        raise SystemExit(f"{len(missing_after_merge)} words still untranslated after merge, e.g. {missing_after_merge[:10]}")

    for name in proper_nouns:
        if name not in glossary:
            glossary[name] = f"{name.capitalize()} (ad)"

    out_path = os.path.join(CONTENT_DIR, "reading_glossary.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(glossary, f, ensure_ascii=False, indent=None, separators=(",", ":"))
    print(f"Wrote {len(glossary)} entries to {out_path}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("Usage: build_reading_glossary.py extract | merge <chunk1.json> [chunk2.json ...]")
    if sys.argv[1] == "extract":
        extract()
    elif sys.argv[1] == "merge":
        merge(sys.argv[2:])
    else:
        raise SystemExit(f"Unknown command: {sys.argv[1]}")
