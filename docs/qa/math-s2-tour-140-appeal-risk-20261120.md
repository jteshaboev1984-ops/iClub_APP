# Mathematics Season 2 Tours — 140-question appeal-risk checkpoint (2026-11-20)

Scope: source-based academic and server read-only audit for canonical Issue #574. Current checked main 296bf21df09a808152b4ae4e153ddcec8aec85cd. Merged original content audit #7 is historical evidence, not today's launch authorization. The controlling current curriculum is Cambridge 9709 P1 (2026–2027) and the approved Complete Pure Mathematics 1 source map: Tour 1 Ch1; Tour 2 Ch2; Tour 3 Ch3; Tour 4 Ch4–5; Tour 5 Ch6–7; Tour 6 Ch8–9; Tour 7 Ch10. Do not revert to obsolete Tour Map v1.

## Existing bank was REUSED; no new 140-item generation
Fresh Supabase SELECT-only facts: seven Season 2 Mathematics Tour containers, all inactive and undated; 140 live links, 140 unique IDs, exactly 20 per Tour, 6 easy / 9 medium / 5 hard, 16 MCQ / 4 input, one hard image per Tour. Missing EN/RU/UZ stems, explanations, reference, time limit: 0. Missing or malformed MCQ options: 0. Direct question-ID overlap with Season 1 or current Math Practice: 0; repeated normalized English stem in this 140: 0.

All 140 English stems/option arrays/keys/explanations received an additional model-assisted first-pass read; no new confirmed wrong EN key was found. This is NOT independent human mathematics or trilingual academic signoff. Numeric signatures matched across 140 EN/RU/UZ stem/options. Restricted mathematical-symbol check flagged ten explanatory notation differences; direct inspection showed shortened RU/UZ derivations or localized units in these ten. That is not proof of perfect semantics in all 140.

Answer key frequencies A/B/C/D: Tour1 4/4/4/4; Tour2 4/4/4/4; Tour3 5/4/3/4; Tour4 4/4/4/4; Tour5 4/4/4/4; Tour6 4/4/4/4; Tour7 4/5/3/4. The blanket 4/4/4/4 claim in merged historical PR #7 no longer matches current source. Do not rearrange published choices just to change distribution.

Approximate English stem cross-match against 655 previous Season1/Practice records produced 32 candidate pairs at normalized character 3-gram Dice >=0.80, including within-S2 pairs. A high similarity is a manual-independence review candidate, not proof of the same question/answer. Some known examples have different parameters and keys.

### Non-secret question/order manifest fingerprints
Tour1 daba380760f5ab182accf732871bbd32
Tour2 1c6407c1f524068d60ee0a3ccd8b5c5d
Tour3 86d1de9ccf5d25557246c2b15f347f54
Tour4 08191ccaba6206f67c6c87d5e077e9fa
Tour5 9384683bc6e9e25c2864b0365c41a872
Tour6 c8061f853325d7c9c0fec4f045e6c5e4
Tour7 dcadbf7a270335ac7d3d8acb7aec1b5e

## Confirmed scoring defect (learner-impacting)
Live public.iclub_eval_tour_question_safe_v4 source MD5: 7f564255956fbe61ab8d1a14cade9389.
Live public.iclub_tour_input_is_correct_v4 source MD5: b1d4ca1a333c05c3018f0d71cd1b0cd1.

The current general input scorer compares fractions as literal normalized strings instead of equal rational values. On actual Math S2 stored inputs, live SELECT-only score evidence: 28/28 canonical accepted, 0/4 mathematically equivalent doubled numerator/denominator fractions accepted, 0/1 equivalent fractional representation of a decimal accepted. Affected IDs: 6047, 6089, 6121, 6126, 6136. This is a justified potential appeal, not speculation.

This isolated Draft stages an uninstalled SQL candidate at supabase/candidates/math_s2_tour_input_equivalence_v1_hold.sql and a read-only test at supabase/candidates/math_s2_tour_input_equivalence_v1_readonly_test.sql. The SQL candidate adds a private rational equivalence function and limits its use to current Season 2 Mathematics Tour membership. It pins the original evaluator source hash and preserves the original Chemistry branches, all other subjects, MCQ and Season1 behavior. No answer keys or protected stems in GitHub.

## Release prerequisites (not silently waived)
1. Execute the uninstalled candidate and test on DISPOSABLE PG17, with real signed JWT/PostgREST and Chromium; verify numeric equivalence, malformed and wrong input denial, cross-user access, retry and versioned history. **Superseded: isolated PG17 signed-HTTP/Chromium PASS at tested code SHA 5b8f1a56 (details below).**
2. Independent EN/RU/UZ academic checking of all 140 key/distractor uniqueness, diagrams, precision/format and the 32 similarity candidates; correct any found ambiguity in a history-safe future-only version. Do not manufacture new questions before checking existing valid content.
3. Verify the seven live visual assets/rendering and actual Math-only 7x20 Tour gate: unique attempt, timers, anti-cheat, scores, ratings, certificates, season isolation, rollback. Owner alone chooses Tour dates and grants production GO.
4. Keep Season 2 draft/undated. No main merge, live migration, learner history change, source publication or paid service authorized by this checkpoint.

**Verdict: structural bank PASS; current production rational-input scoring FAIL (isolated fix PASS, NOT deployed); final academic acceptance PENDING; Season2 release HOLD.**

## Continuation 2026-11-20 (metadata-only; no protected source or keys)

1. Exact tested code SHA: 5b8f1a56f7d500a55330ded25895061c7aeba6c0. [Target CI #44695294152](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/44695294152) SUCCESS. Real PostgreSQL 17/PostgREST signed synthetic JWT, actual deployed Tour RPC source, Chromium fetch, history-preserving rollback. Exact rational cross-multiplication: 18/18 synthetic including 100-digit equivalent fractions and rejection of near-correct answers; 28/28 synthetic canonical, 4/4 equivalent fractions and 1/1 decimal equivalent. Anonymous, expired, cross-user, and out-of-session writes rejected; original Season1 Mathematics/Chemistry behavior unchanged. This is NOT a real learner session or full application Tour UI run.

2. The separate Academy-only UX531 source allowlist still FAILS on this non-UX scoped branch ([run #44695294192](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/44695294192)); do not claim all workflow gates passed.

3. An independent SELECT-only **Mathematics-only 7-tour** readiness query verified 7/7 containers, 140/140 valid link structure, 6/9/5, EN/RU/UZ, one hard diagram per Tour, no direct old-season/Practice ID overlap, all undated/inactive. Saved source: supabase/preflight/math_s2_7tour_subject_scoped_readiness_select_only.sql. This is structural evidence, **not GO** or permission to set dates.

4. Confirmed semantic repetition despite distinct IDs: S2 #6083 repeats Season1 #3283 (same mathematical binomial task); S2 #6032 repeats Season1 #2616 (same domain after equivalent radicand transformation); S2 #6091 repeats active Practice #7742 (same trigonometric angle in degrees/radians). A private-only owner file holds three original proposed EN/RU/UZ future-only revisions and independent algebra calculations. No protected stem/key or candidate text in public Git, no production item overwritten, no new question ID activated. Language/academic QA remains pending. Other 32 similarity signals are NOT automatically duplicates.

5. All seven existing SVG source files were read; labels and safety markers were checked without changing them. Source check does not prove live authenticated rendering or independent full diagram proof. Need real Tour UI smoke and separate academic review.

6. Remaining HOLD: professional independent mathematical/distractor and RU/UZ/EN review, source rights and triple-duplicate replacement with immutable history/new IDs, 32 similarity review disposition, one-attempt/timer/anti-cheat/score/rating/certificate season-specific acceptance, owner dates and owner permission to publish/merge/deploy. Host Supabase, public main, learner records, production and paid services untouched.

## 2026-11-20 latest: confidential MCQ integrity + four semantic replacements

- Fresh live **SELECT-only** Mathematics S2: all seven Tours still inactive/undated. Exactly 112 MCQ and 28 typed inputs; **zero** S2 Tour attempts, session rows, MCQ saved answers, and existing version links at preflight. Existing 140 original IDs have NOT been changed.
- A confidential source-only positioning check detected a severe **predictable correct-option placement** issue in the existing MCQ bank. For security, **no source key strings, per-item permutations or answer-position sequences belong in this public repo or CI logs**. This blocks launch independently of structural green.
- Private owner-only bundle now specifies **112 future-only immutable MCQ versions**: original question content reused for 108; **four confirmed mathematical equivalences** replaced by original EN/RU/UZ variants (S2 IDs `6023`, `6032`, `6083`, `6091`). Option permutations preserve correct semantic choice and all three localized option arrays; seven 16-MCQ Tour groups remain 4/A,4/B,4/C,4/D without short repeated periods. Candidate new IDs not created/activated. The private file and raw keys remain outside public GitHub.
- The 32 stem-similarity candidates were checked itemwise in a **model-assisted** comparison: **four** confirmed equivalent/identical mathematical tasks, **28** judged materially different in data or task operation. This is NOT independent professional academic QA, and the approximate detector cannot guarantee absence of other semantic equivalents below its threshold.
- The four new private candidate answer keys received independent symbolic recalculation using SymPy; all localized stems, explanations and four distinct options were checked for presence and synchronized option placement. Professional Cambridge P1 and RU/UZ/EN semantic/distractor signoff remains mandatory. Verified Cambridge 9709 2026–2027 P1 syllabus includes connected rates and simple improper integrals (https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf, p.22).
- Source-only private plan integrity validator and nine invented-data failure/positive tests added to [Draft PR #610](https://github.com/jteshaboev1984-ops/iClub_APP/pull/610). Exact source-commit SHA `2695f39411bf4e89f1b19557d665a6ddab8efc5a`, [target CI #44704668677 SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/44704668677): private-plan contract synthetic PASS; established PostgreSQL17, signed JWT/PostgREST, Chromium and safe-rollback scoring regression PASS. No private owner-only data entered CI.
- The independent UX531 source allowlist is [#44704668709 FAIL](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/44704668709), due to this non-UX source scope; do not bypass it or claim whole PR green. Actual academic bank activation/option switch has **not** run in PG17 or Supabase, only source validator and scoring candidate have passed.
- **No GO:** the 112 future-only versions still need a protected staging/atomic Tour-membership switch and safe rollback (existing Practice future-version mechanism is design precedent, NOT an authorized Tour migration). Current live original rows remain unchanged. Whole-Tour pre-start access/attempt gating, timers, anti-cheat, history, results, ranking and certificates still need independent security and browser acceptance, with #450 coordination. Dates and deployment need separate explicit owner approval.

**Current decision: structural bank PASS, staged rational-equality scorer PASS on disposable PG17, private 112/4 source proposal PASS on synthetic validator, independent academic QA PENDING, protected Tour version activation E2E NOT RUN, release HOLD.**
