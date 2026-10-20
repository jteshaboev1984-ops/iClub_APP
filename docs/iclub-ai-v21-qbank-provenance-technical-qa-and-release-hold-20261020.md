# iClub Global AI v2.1 — reusable qbank provenance gate, QA result
**20 October 2026 · outcome: TECHNICAL QA PASS / PRODUCT RELEASE HOLD**

## Objective
The first 70 newly staged questions (210 EN/RU/UZ entries) actually belong to active Chemistry/Economics Practice pools, unlike 27 of the 37 previously admitted question IDs. Build one generic and reversible provenance path without copying legacy approvals or changing Study/Tours, UI, Math Exam Prep Tutor, student evidence or tariff rules.

## Implemented only in existing QA branch
- `qa/live_candidate/iclub_ai_v21_qbank_owner_provenance_GATE_ONLY_UNAPPLIED_20261020.sql`
- `qa/live_candidate/iclub-ai-v21-qbank-provenance.contract.test.cjs`
- `qa/live_candidate/iclub-ai-v21-qbank-provenance.pgtest.cjs`
- Modified the **existing** `.github/workflows/iclub-ai-v21-offline-qa.yml` with a disposable-PostgreSQL-only test; no new branch, production deployment or external provider request.

The source admission function retains its earlier 111-card legacy authorization predicate unchanged. A new branch (not installed live) would accept a qbank explanation only if:
1. a distinct **private owner-specific release** exists with an enabled record, release time and separately recorded owner/rights/academic/locale evidence refs; default is OFF with **zero** entries;
2. the exact question is active, published, in an active Practice pool and its verified subject ID matches the academic source;
3. source key/version/locale/text/SHA256 and target-question fingerprint match the real live iClub question; the released localized text must equal the versioned original `questions.explanation_{en,ru,uz}`;
4. **all three** EN/RU/UZ release records for the question are simultaneously enabled and mutually version/hash aligned. One locale's refusal closes the new three-locale set.
5. existing prepared-service guards still separately enforce signed-in beta consent, finalized **wrong and answered** question, authorized owner/enrollment, protected-assessment exclusion, subscription where applicable, replay constraints and 3-per-5-hour quota. The new function only decides source admissibility; it never changes a result or awards marks.

No fabricated independent publication flag is set. An evidence reference stored in a database does NOT establish that human/editorial review actually occurred. The operational review needs real records; the app must stay closed for these 210 drafts until that occurs.

## Evidence from automated QA
- [**Real scratch PostgreSQL + full offline QA: PASS**](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39426708422) at commit `f164c14c8f65d7304f5023e428c8ad92b34f0602`.
- [**Current-main integration parity: PASS**](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39426708458) at same commit.
- Negative tests: zero new releases; partial-language release; revocation of RU; exact-text tamper; version drift; changed live question; inactive Practice pool; release without current subject; false editorial-flag checks; no client table write/reader privileges. Previously authorized legacy source remains readable under the synthetic test model.
- Initial CI run failed on a Javascript test-harness string literal *before* running SQL; fixed in `f164c14`, then all real scratch PostgreSQL and other QA jobs passed. No live failure occurred.

## Technical academic triage of current 70 questions
Production is READ ONLY for this section. Of the 70 question IDs:
- Chemistry: 35 (28 MCQ, 7 input); Economics: 35 (all MCQ), **5 in each of the seven active Practice pools for each subject**.
- All 70 are published/active, contain a question statement in EN/RU/UZ, contain all three explanatory texts, and have valid A-D MCQ keys where applicable. Structural scan found 0 invalid MCQ keys and 0 malformed option-string openings.
- The 35 Economics candidates avoid English "Selected answer:" or "Selected:" templates, which would misleadingly sound like a student's submitted answer.
- **Known metadata/content-alignment review flags** in Chemistry: `10073` subtopic claims magnesium oxide while question asks C/H/O combustion and molecular formula; `10077` subtopic claims sulfate sulfur but question asks permanganate half-reaction balancing; `10063` subtopic claims buffer action but question asks quantitative electrolysis. These are flagged for independent academic/content review, **not proof that the keyed answer or calculation is incorrect**.
- This is machine/AI-assisted screening; it does NOT certify the scientific correctness of all 70, authenticity/license for use in new AI delivery, proper full RU/UZ equivalence, original question-history eligibility or human review. Review remains PENDING.

## Final live-read-back after CI
| Production invariant | Read-only observation |
| --- | --- |
| Existing main + Vercel | Earlier deployed main `7ea6c2960e6be1b1c46bf7b8506ee3106ad974e7` unchanged by these QA commits |
| Existing academic source rows | 321 |
| Closed new locale drafts | 210 |
| Sources actually admissible to beta | 111 (original owner-beta only) |
| Existing owner-beta allowlist entries enabled | 111 |
| Academic deliveries to real accounts | 0 |
| Academic policy | ON for existing closed beta |
| Provider | OFF |
| New generic qbank provenance table in production | **NOT INSTALLED** (NULL) |
| Live legacy admission function MD5 | `3189bbb8332cc1604f381a6b2e984c81` (unchanged) |
| Student questions/pools/history/Math Tutor/tariffs | Not modified |

## Release boundary and continuation
A real production schema install requires a separately approved low-risk release window, review evidence and backward-compatible production monitoring. Installing the empty/disabled gate alone would not increase student coverage. Separate GO is needed before even one of the new 210 cards is owner-released. A new owner-beta allowlist is not a substitute for real rights and academic evidence; never fabricate reviewer attestations. To achieve positive student E2E, use only a real consenting learner's naturally finalized incorrect question; never alter genuine answers/marks to stage a demo.

Owner beta may be paused independently using the existing `qa/live_candidate/iclub_ai_v21_owner_beta_PAUSE_20261020.sql` if any live issue is discovered. Existing approved Option A panel, old Math Tutor and all legacy learner progression remain unchanged.
