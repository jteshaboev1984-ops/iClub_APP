# Economics 9708 — Stage 1 v8: syllabus fidelity, assessment separation and release gate

**9 October 2026 | Status: IN_PROGRESS | Live learner release: BLOCKED**

## What changed, and what did not
Against the official [Cambridge Economics 9708 syllabus for examination 2026–2028 (Version 2)](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf), source-checked **20 previously unreviewed AS syllabus points** in the approved book/Tour order. Compared the syllabus's exact teaching level and numbered wording, rather than treating a long draft label as evidence that many new skills were needed. The supplied fourth-edition Economics coursebook supports the explanation and chapter placement; the approved seven-Tour Map supports chapter sequence. No external or textbook question stems have been copied.

- **10 points retained as one integrated competency** (e.g., inflation/deflation/disinflation as one paired distinction, definition-only monetary policy, resource allocation in market/planned/mixed economies, arguments for and against protection).
- **10 points split into 27 individually testable provisional actions** (separate max/min price controls, open/closed circular flow, AD/AS curve shifts, unemployment measures vs limitations, government debt meaning vs significance, tax types/rates/motives, spending categories/motives, expansionary/contractionary fiscal diagrams, five distinct trade restrictions, and four current-account policy types).
- Thus v7 had 462 provisional actions; **v8 has 479** (net +17) across the same **253 official numbered Cambridge points**; **135** unreviewed one-to-one placeholders remain. This is **not** the final approved skill count.
- Individual decisions including old action, new draft child keys, Cambridge point ID, qualification, chapter, Tour and source-scope rationale are preserved in `docs/economics-9708-v8-source-checked-decision-log-v1.csv`; the 135 untouched items are in `docs/economics-9708-remaining-atomic-review-queue-v5.csv`.
- **Academic scope corrections** recorded: §1.4.2 concerns resource allocation rather than a new compulsory economic-system evaluation; §2.4.1 only defines equilibrium/disequilibrium; §3.2.3 concerns public direct provision, not a separately compulsory welfare evaluation; §5.3.1 only defines monetary policy; §4.5.2 covers measures and measurement limitations without inventing a compulsory calculation task; §6.3.3 does not prescribe a mandatory domestic/foreign cause split.
- Strict AS/A-Level boundaries remain: the multiplier is **not required** at AS 4.2.2; policy trade-offs are **not required** at AS 5.1.1; the A Level quantity theory `MV=PT` must not be silently transferred into AS due to an old pool entry.

## Separate identity and production compatibility guarantee
Read `docs/economics-9708-curriculum-practice-runtime-separation-contract-v1.md` before any future implementation. It explicitly distinguishes official syllabus point, coursebook chapter/Tour, provisional skill, immutable live question ID + pool membership, and versioned approved academic Tutor sources. **Never remap protected student scores or historical question placement because a draft skill was split or a question has outdated topic metadata.**

### Actual live Practice count vs historical Tour Map
The uploaded `Tour Map v1.0 — Economics (по книге) для 7 туров.docx` explicitly planned **60 Practice questions per Tour**. However, a new **read-only production Supabase SELECT** on subject_id 7 verified **70 active distinct Practice questions in each of seven active pools** (total 490), with **seven additional inactive Tour 2 pool entries**.

**Unresolved, not a bug fix:** Original planned 60 and current live 70 must stay distinct. User/architect decision is required before altering policy or teaching documentation. **We preserved existing 70-per-Tour live behaviour, all question IDs/ordering and all past progress.** No SQL changes to Practice or question tables.

## Quality checks and caveats
Retrieved v8, the v8 decision log, unreviewed queue and compatibility contract from GitHub. Local structural assertions found **0 violations**: 479 unique candidate keys, all 253 official numbered parents, 20 decision records (10 splits / 10 retained), 135 remaining unreviewed parents, every existing chapter-to-Tour range consistent, all `runtime_allowed=false`, all `verified_precise_question_ids=NONE_VERIFIED`. The 60-vs-70 difference is preserved as an explicit unresolved gate.

**Structural QA only.** Educator/examiner correctness, standalone skill decomposition, exact question answer-key mapping, RU/UZ language review, diagram mobile accessibility/translation, source originality/rights and learner-facing usability have **NOT** passed yet.

## Safe order of next tasks
1. Review the next 135 syllabus parent points for retain/split/overlap; especially check AS exclusions and A Level coverage without broadening the exam.
2. Reconcile near-duplicate candidate skills across different official points without losing source provenance; determine the final approved skill denominator **only after** reconciliation and academic signoff.
3. Review and link versioned theory/Tutor content per final child skill and locale. The pre-existing 40 parent-level overview draft topics must **not** count as independent approved cards for 479 candidate actions.
4. Review exact question and correct-answer evidence **separately**, preserving original assessment IDs, active pool members and learners' past records.
5. Complete safety and QA before any separate user-authorised runtime integration. Do not deploy, use Vercel, merge Draft PR, enable AI or edit protected user/assessment data.

**Canonical current working artifacts:** `docs/economics-9708-atomic-candidate-register-v8.csv`, `docs/economics-9708-v8-source-checked-decision-log-v1.csv`, `docs/economics-9708-remaining-atomic-review-queue-v5.csv`, and the separation contract named above. Economics Stage 1 stays `in_progress`; Chemistry follows after Economics academic readiness. Informatics deferred.
