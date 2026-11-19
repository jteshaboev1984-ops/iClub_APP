# Mathematics Practice v2 — AI-assisted itemwise 495 review checkpoint · 19 Nov 2026

**Scope:** 495 already-published P1 Practice questions, seven active pools and 45 canonical skills. The reviewed *live* content remains unchanged in Supabase; the proposed 31 academic edits are in Draft #577, the prior safe preflight is Draft #582, and this work is an additional source-only draft. No active bank, Tour, key, learner attempt, grade, certificate, migration or feature has been changed.

## Evidence and precise limits

- Read-only hosted SQL selected **495/495 individual English stems, correct-answer keys, and option sets**; a second itemwise pass inspected **495/495 English worked explanations**. This is a ChatGPT reasoning/content reading pass, **not a mathematical proof engine, independently signed human review, or a guarantee of error-free content**.
- Repeated structured scan of RU/UZ/EN stems and options for **all 495**, checking non-empty trilingual payloads, keyed MCQs, input contracts, numeric literals, option equality, arithmetic signs and mathematical markers; reused previously passed full-bank editorial/technical source regression in #577. Semantic vocabulary spot-check for 13 important command concepts (minimum, maximum, increasing, decreasing, parallel, perpendicular, positive, negative, radians, degrees, repeated roots, larger/smaller) found **0 missing equivalent concept markers** in the current live stems.
- Deliberately did **not** label every RU/UZ explanatory sentence as exhaustively retranslated/independently human verified. The machine's 162 math-symbol discrepancies were dominated by words such as English "x-axis" (hyphen vs Russian/Uzbek phrasing) and abridged intermediate calculations; they are **heuristic signals**, not 162 errors. A second targeted read of numerical-explanation mismatches found omitted intermediate steps but no newly confirmed wrong answer.
- Five known numeric-token mismatches (#7828, #7957, #7959, #7963, #7964) correspond to "triples"/"three times" being expressed in words in translated stems; their meaning was directly reviewed and found equivalent. Do not blindly rewrite these.
- **Itemwise ledger:** `docs/qa/math-practice-v2-all495-itemwise-review-ledger-20261119.csv` has one metadata-only row per verified live ID (7485–7979), per-pool/skill/type and QA scope. No stems, options, keys or user identities. Previous QA statuses are database provenance, NOT newly re-certified independent academic marks.

## Confirmed defects / corrections

1. **#7573 (source Q089)**: two wrong MCQ distractors collapse to the same expression. Existing #577 candidate separates them; answer key unchanged, future-only version required by governed history-safe publishing policy.
2. **#7686 (source Q202)**: "could contain the centre" made the geometry choice logically ambiguous. Existing #577 candidate replaces this with an unambiguous perpendicular-bisector / "must" statement; key unchanged, future-only version required.
3. **NEW #7965 (source Q481, P1-INT-04)**: the three printed explanations stated `x=(6±√36−24)/2=3±√3`. This visually leaves the discriminant's subtraction outside the square-root sign, although the answer/key and prior quadratic equation were correct. New source correction is `x=(6±√(36−24))/2=3±√3` in EN, RU and UZ. This is an editorial **explanation-only** correction; old/live key, MCQ distractors, diagnoses and all seven pools remain unchanged. Read-only live history query: 0 classic, 0 safe-v4 and 0 drill answers for this item at checkpoint.
4. The other **29** editorial fixes already present in #577 address the decimal-entry instructions and injectivity terminology / function-definition wording, including history-bearing #7710, #7714 and #7754. They were not recreated or silently published.

## Sources and CI

- Main currently verified `74e291b0fba989084387a6fe137871db07f10fbd`; all review candidate files derived from #582's exact `259108c4fb8ef9db59174912ed215f78f1097111` (parent #577 original source HEAD `eb06fa9ee93f80d91ebc14a8f12e9c3d9814c6af`).
- Previously merged scorer #575 / hosted migration `20261119073117_math_practice_v2_literal_answer_delimiter_v1` is already applied; do **not** rerun it.
- Hosted SELECT-only 32-ID preflight: 32/32 published eligible; all in exactly one active Math pool, 0 Tour links, 3 distinct history-bearing questions (2 classic, 2 safe-v4 and 1 drill answer rows across those three); `preflight_ready=true`. It performs no writes or protected-content export.
- This child source candidate carries a pinned 32-ID before/after source-diff guard (30 editorial + 2 meaning/option changes), a trilingual Q481 discriminant formula test, the existing 495-item language/technical regression, a metadata ledger consistency gate, and read-only SQL preflight.

## Unfinished publication work (separate owner GO)

- An independent exhaustive line-by-line mathematical and RU/UZ semantic signoff is **not** proven merely by this AI pass or by machine comparators.
- Before publication, pin source JSON↔live content digests and preserve all history. For #7573/#7686 create **future-only versioned replacements**; do not overwrite historical answers/options. Confirm the correction of #7965 with an individually authorized forward-serving path.
- Validate a proposed cutover on isolated PostgreSQL17 with signed JWT/PostgREST, existing Practice selector/submit correctness and multilingual Chromium. No merged Draft, hosted SQL, production deployment, season or new bank generation is permitted from this checkpoint.
