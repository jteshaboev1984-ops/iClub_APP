# P1/P5 Mathematics — AI academic/content review, pass 1

**Review date:** 2026-10-29. **Reviewer type:** AI-assisted analytical review only; **not an independent human academic/language signoff**. **Status:** partial review with confirmed findings; NOT approved as a whole bank. **Production:** no content, locale, mark, learner-state, entitlement, or release-flag changes.

**Benchmark:** Cambridge International AS & A Level Mathematics (9709), official **2026–2027 syllabus, version 4**, https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf. Paper 1 syllabus pp.19–22, Paper 5 syllabus pp.34–36. The official syllabus establishes topic and assessment requirements, **not the correctness of each newly authored iClub mark scheme**. The actual iClub English question and criterion, task/version, RU and UZ prompt/criteria were compared in private read-only SQL.

## Coverage and limits

- Published in-scope: **328** QA-passed written tasks; **1,704** distinct criteria, each with RU and UZ approved locale values (3,408 locale records).
- Automated mathematical notation/number-symbol screening: **all 1,704** EN/RU/UZ criteria and **all 328** EN/RU/UZ prompts. The initial deliberately sensitive linter identified **35 distinct criterion rows** and **64 individual prompt-language pairs** for examination; these are **candidates, not 35/64 confirmed errors**. Some are harmless equivalents (decimal point vs comma, `pi` vs `π`, `sum` vs `∑`, `integral` vs `∫`, superscripts, comma-vs-semicolon in distribution parameters, or explicit statements of an equivalent inequality). Never blindly patch these.
- Semantic review: **15 published example tasks**, one across each of eight P1 topic families (quadratics, functions, coordinate geometry, circular measure, trigonometry, series, differentiation, integration) and each of seven P5 topic families (data, counting, probability, discrete random variables, binomial, geometric, normal). Read **all 62** criteria of these 15 tasks alongside all three prompts and checked their substantive mathematical claims and translation equivalence. This is a sampled first pass, **not** semantic review of the entire 1,704-rule bank.
- Targeted follow-up reviewed specific flagged tasks outside this stratified sample (below), including scoring rubrics. A formally independent specialist review remains unverified (see prior provenance audit).
- No private source/translation text is stored in this public repository file. Identifiers and summaries below are for an authorized reviewer to locate in the private DB.

## Confirmed historical translation omissions, existing later fixes (version-routing check OPEN)

| Old published task | Corrected later published task | Finding on old version | New-version finding | Exposure status |
|---|---|---|---|---|
| **58**, `P1DIF04-W01`, `wtv1` | **163**, same key, `wtv2` | RU/UZ prompt omits the explicit two-part verification: both lines through the common point **and** gradient product −1, despite a 1-mark criterion. | **Both RU/UZ prompts explicitly include the two checks in wtv2.** No duplicate wording fix is needed for wtv2. | Both versions are `published`, each attached to a published assessment (`154` vs `359`); neither task appears in any current `exam_prep_session_items`. The source-selection route was not proven here. |
| **60**, `P5BIN03-W01`, `wtv1` | **164**, same key, `wtv2` | RU/UZ prompt omits the explanation that `variance/mean = 1−p`, although the explanation receives 1 mark. | **Both RU/UZ prompts restore the explanation in wtv2.** | Both versions are `published`, attached to assessments (`161` vs `360`); neither appears in current `exam_prep_session_items`. Source-selection route unverified. |

**Correction to initial review classification:** these are two **confirmed older-version content defects**, **not yet confirmed learner-facing defects in the current route**. They must not be described as uncorrected in the current latest version. The remaining question is whether older published assessments can still be selected for NEW sessions. Do not turn off/delete earlier assessments without a route-level and session-compatibility review. No existing sessions were changed.

## Academic/rubric completeness review (OPEN, needs scoring decision)

- **Task 17** / `P1TRI01-W01` / `wtv1`, English/RU/UZ prompts: the requested graph must identify the exact zero-crossings of the transformed sine curve. The rubric separately checks key standard positions, extrema/midline, graph shape and amplitude/translation, **but does not explicitly reference the two zeros**. For the stated function the zero positions are `π/6` and `5π/6` on the given interval. Verify whether the two `shape` marks are deliberately intended to include them. If not, a revised version should align what the learner is instructed to do with what earns credit. This is a **rubric completeness concern**, not proof that the answer is being marked incorrectly today.

## Language clarity follow-ups (OPEN, lower priority)

- **Task 72** / `P1INT01-W01` / `wtv1`, UZ prompt: an English `chain rule` phrase remains within the Uzbek instruction. Mathematics criterion for reverse chain-rule integration itself is correct in the manually reviewed example; revise wording under a new reviewed task version.
- **Task 36** / `P5PRO02-W01` / `wtv1`, UZ prompt: English `Complement` appears untranslated in a probability instruction, whereas a later published version (task 158) uses an Uzbek description. Verify which version is served before any change; do not assume the old row is unused.
- **Task 22** / `P5PRO01-W01` / `wtv1`, UZ prompt: the coin's tail outcome is identified indirectly as not the coat-of-arms side without naming the `T` symbol used in the criterion. A later version (task 156) defines H/T explicitly. Treat as clarity risk, not a proven wrong probability.
- **Task 34** / `P5DAT07-W01` / `wtv1`, UZ prompt: English terms `range` and `SD` are retained without full explanation. This is a localization-readability candidate, not a demonstrated mathematical miscalculation.

## Checked example computations (no confirmed mathematical mismatch in this sample)

- P1 task 4: completing square and vertex; task 13: slope and both line forms; task 16: degree ↔ radian conversion; task 43: binomial expansion; task 45: derivative by first principles; task 72: reverse chain-rule antiderivative.
- P5 task 18: combinations vs permutations; task 22: 8 equiprobable outcomes and event set; task 48: valid discrete distribution and event probability; task 51: binomial independence conditions; task 52: geometric trial-number convention; task 63: variance vs standard deviation of normal curves.
- This **does not** establish correctness of all unreviewed criteria, mark allocation, or every published task. It also does not identify any AI-assisted approval as a human reviewer signoff.

## Further review procedure

1. **Immediate scope:** do not edit existing published `approved` rows or `wtv1` versions. Keep access, scoring, written flags, and active sessions stable.
2. **Continue batches:** review each P1/P5 task as **prompt_en + prompt_ru + prompt_uz + full criteria/marks**. Check numerical answer independently; test domain/inequality/sign/unit/rounding; verify no translated condition is dropped; check mark-to-prompt consistency. Record per-task statuses `PASS_AI_SAMPLE`, `ISSUE_CONFIRMED`, `NEEDS_HUMAN_REVIEW`, or `UNREVIEWED`. Do **not** report `PASS_AI_SAMPLE` as independent academic approval.
3. **Prioritize high-stakes prompts** (normal approximation and continuity correction, inverse-normal quantiles, compound probability, differentiation/integration, inequalities and boundary values) and identified earlier version duplicates. Avoid public disclosure of private rubrics.
4. **Fixes:** prepare each candidate corrected question as a *new* draft task version under controlled migration, never retroactively changing published task versions, user evidence, session pins, marks or learning mastery.
5. **Owner-authorized validation** of genuine external mathematics/language specialist attestation remains a separate governance requirement. Academic edits must not trigger the deferred real-learner E2E, weekly beta review, or mass-launch switches.

**Decision after pass 1:** source-checksum and language coverage = technically complete; detailed semantic bank approval = **NOT YET ESTABLISHED**. Two **historical published** translation omissions are confirmed, and their `wtv2` counterparts already correct the omissions. Live routing of old vs new assessments must be verified before any remediation. Task 17/184 rubric completeness remains OPEN. Production remains unchanged.
