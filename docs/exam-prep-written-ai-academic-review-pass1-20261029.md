# P1/P5 Mathematics — AI academic/content review, pass 1

**Review date:** 2026-10-29. **Reviewer type:** AI-assisted analytical review only; **not an independent human academic/language signoff**. **Status:** partial review with confirmed findings; NOT approved as a whole bank. **Production:** no content, locale, mark, learner-state, entitlement, or release-flag changes.

**Benchmark:** Cambridge International AS & A Level Mathematics (9709), official **2026–2027 syllabus, version 4**, https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf. Paper 1 syllabus pp.19–22, Paper 5 syllabus pp.34–36. The official syllabus establishes topic and assessment requirements, **not the correctness of each newly authored iClub mark scheme**. The actual iClub English question and criterion, task/version, RU and UZ prompt/criteria were compared in private read-only SQL.

## Coverage and limits

- Published in-scope: **328** QA-passed written tasks; **1,704** distinct criteria, each with RU and UZ approved locale values (3,408 locale records).
- Automated mathematical notation/number-symbol screening: **all 1,704** EN/RU/UZ criteria and **all 328** EN/RU/UZ prompts. The initial deliberately sensitive linter identified **35 distinct criterion rows** and **64 individual prompt-language pairs** for examination; these are **candidates, not 35/64 confirmed errors**. Some are harmless equivalents (decimal point vs comma, `pi` vs `π`, `sum` vs `∑`, `integral` vs `∫`, superscripts, comma-vs-semicolon in distribution parameters, or explicit statements of an equivalent inequality). Never blindly patch these.
- Semantic review: **15 published example tasks**, one across each of eight P1 topic families (quadratics, functions, coordinate geometry, circular measure, trigonometry, series, differentiation, integration) and each of seven P5 topic families (data, counting, probability, discrete random variables, binomial, geometric, normal). Read **all 62** criteria of these 15 tasks alongside all three prompts and checked their substantive mathematical claims and translation equivalence. This is a sampled first pass, **not** semantic review of the entire 1,704-rule bank.
- Targeted follow-up reviewed specific flagged tasks outside this stratified sample (below), including scoring rubrics. A formally independent specialist review remains unverified (see prior provenance audit).
- No private source/translation text is stored in this public repository file. Identifiers and summaries below are for an authorized reviewer to locate in the private DB.

## Confirmed substantive translation omissions (OPEN)

| Priority | Published task ID / key / version | Locales | Verified issue | Why it matters | Non-destructive remediation |
|---|---|---|---|---|---|
| **HIGH** | **58**, `P1DIF04-W01`, `wtv1` | RU and UZ prompt | EN explicitly requests verification that **both lines pass through the same point AND tangent/normal gradients multiply to −1**. Both translated prompts shorten this to a generic “verify”. The `verification` criterion is worth **1 mark** and expects those exact checks. | A student receiving only RU/UZ is not explicitly told the full 1-mark checking requirement. | Draft a **new task version** carrying explicit equivalent requirements, verify mathematically/linguistically, then stage safely with active-session version pinning. Do not mutate the existing published `wtv1`. |
| **HIGH** | **60**, `P5BIN03-W01`, `wtv1` | RU and UZ prompt | EN explicitly asks the student to **explain why variance divided by mean gives 1−p**. The translated prompts omit this subtask. English rubric `explanation` is worth **1 mark** (proof: np(1−p)/(np)=1−p). | Missing mathematical explanation requirement in two languages, while the scoring rubric still expects it. | New task version with equivalent explicit explanation requirement, plus academic/locale signoff and separate closed test. Preserve old version for active attempts. |

**These two findings are directly confirmed by juxtaposition of EN/RU/UZ prompts and the corresponding live published task's rubric.** Do not infer that the published task can be safely overwritten.

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

**Decision after pass 1:** source-checksum and language coverage = technically complete; detailed semantic bank approval = **NOT YET ESTABLISHED**; first two translated-prompt omissions = **CONFIRMED OPEN**. Production remains unchanged.
