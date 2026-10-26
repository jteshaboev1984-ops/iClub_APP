# iClub Economics 9708 — AS-3 (P1, Units 5–6) content checkpoint
**Date:** 2026-10-26. **Stage:** first meaningful academic content pass complete, **NO Exam Prep release/approval**.
**Primary source:** Cambridge 9708 Economics 2026–2028 syllabus v2, printed pp. 21–23, https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf.

## Approved architecture constraint (do not reopen)
- Live iClub already has real learners. Do **not** modify legacy public questions, Practice/Tours, Math Exam Prep, scores, user progress, or localStorage.
- NO new tables, NO new branches; existing unnecessary empty vault was already removed in migration `20261026054023`. No need to recreate it.
- No external academic experts; apply one meaningful internal academic audit and deterministic structural tests. Do not re-review finished AS-1/AS-2 absent a specific defect.
- Public GitHub is **not a safe place for new full exam questions, answer keys or new marking rubrics**. Exact six originals are only in personal ChatGPT Library (details below); public repo contains only review metadata.
- No database inserts, no new Exam Prep question mappings or academic QA status changes during this AS-3 pass. Economics remains `draft/off`.

## Actual AS-3 work

Read-only inventory from `public.questions` filtered strictly to topics named `Government macroeconomic intervention (AS Level)` and `International economic issues (AS Level)`. Excluded active Practice/Tours items and old `-T-` source-provenance tags. Did **not** automatically treat generically labelled `International economic issues` or `(A Level)` questions as AS sources.

**28** active published legacy MCQ met the inventory/source-reuse conditions. **24** selected for the batch after reviewing economic purpose and repetition:
- Unit 5: **10 legacy** — policy objectives, budget/debt, taxation, monetary policy and credit controls.
- Unit 6: **14 legacy** — comparative advantage, terms of trade, protection, current account, floating FX.
- Four not selected: `8813` (flood barrier/public-good near-repeats AS-2 original case), `8791` (skills/infrastructure shifting LRAS repeats AS-2 legacy 8704), `8860` (very basic currency multiplication with limited additional examination discrimination), `8821` (tariff-identification near-overlap with deeper retained examples).
- All **24/24** selected legacy items have nonempty EN/RU/UZ stems and explanations and four options per language, are still active+published in old source, and have no active Practice/Tour assignment. These are *mechanical/first-pass checks*, not an assertion that every distractor translation was independently certified.
- First-pass economics: monetary-policy direction and credit limits; debt-stock/budget-flow arithmetic; specific tariff revenue, imports quotas, floating-exchange direction, comparative advantage, terms-of-trade and external-account balances. No material answer conflict found in inspected source. Revisit an item only with a concrete flaw.
- Proposed direct Paper1 canonical skill mapping for **all 24** is recorded with ID/point/skill/review notes **without answer keys** in `exam-prep/academic/economics-9708-mcq/AS3-P1-Units5-6-24-item-review-shortlist-v0.1.json`.
- Beware constructing mini-mocks from mirror-image questions (rate increases vs decreases, FX appreciation mechanism) or multiple similarly structured external-account calculations; spread their presence across assessments.

**Six new original EN/RU/UZ draft MCQs** created *only* to cover gaps:
1. `EC9708-AS3-ORIG-001`: 5.2.4 marginal vs average income-tax rates.
2. `EC9708-AS3-ORIG-002`: 5.2.7 expansionary fiscal policy in an AD/AS setting.
3. `EC9708-AS3-ORIG-003`: 5.4.4 long-run supply-side change in AD/AS.
4. `EC9708-AS3-ORIG-004`: 6.3.2 full current-account calculation with income flows.
5. `EC9708-AS3-ORIG-005`: 6.4.5 exchange-rate depreciation affecting AD and SRAS.
6. `EC9708-AS3-ORIG-006`: 6.5.2 structural/export competitiveness and current-account policy.

**Private file:** `/iClub APP/Exam Prep/iClub_Economics_AS3_6_original_drafts_PRIVATE_2026-10-26.json` in personal ChatGPT Library; upload succeeded.
File SHA256: `5d094abdfb6bd60a6106b9a38b44b66db0913510a1368589d013e848e5d15633`.
- Deterministic QA 6/6 PASS: three languages per item, four distinct answers in each, one A-D answer key, three wrong-answer rationale notes, explanation text, per-item canonical SHA256 matching, no duplicated keys. Compared all six *new* stems with twelve earlier AS1/AS2 originals locally; none exceeded the selected near-duplicate textual-similarity threshold.
- These six are **not** imported to Supabase, public questions, Exam Prep mapping or web resources. For future use, safely import to existing content architecture only after release design; do not manufacture new tables.
- All six have preliminary internally reasoned correct responses, but no Exam Prep release flags / validated marking evidence. No outside expert is planned or necessary for this working phase.

## AS Paper1 content progress

| Area | Legacy selected, no new database copies | New original private drafts | Working total |
|---|---:|---:|---:|
| AS-1 (Units1–2) | 30 | 6 | 36 |
| AS-2 (Units3–4) | 24 | 6 | 30 |
| **AS-3 (Units5–6)** | **24** | **6** | **30** |
| **AS first content sweep** | **78** | **18** | **96** |

**96 is a source *review inventory*, not 96 approved exam questions**, not a validated full Cambridge P1 mock, and not an estimate of readiness. Four AS-1 legacy items remain exposed in Practice; selected AS-2 and AS-3 items have no active Practice/Tour links. Further unseen-set/reserve planning and content release gates are separate.

## Next meaningful block (keep batching)

Start **A-1 / Paper3 / A Level syllabus Units 7–8**, 24–36 original/legacy candidates in one meaningful source pass. Preserve strict AS prerequisite versus direct A-content distinction. Prefer available A Level labelled legacy questions with correct source provenance, avoid active Practice/Tour and near-duplicates; only author original private drafts for genuine coverage gaps.

The complete long-running handoff remains `docs/exam-prep-economics-working-plan.md` (latest appended checkpoint supersedes older dates). Before eventual activation: academic release governance, source integrity, written Paper2/Paper4 architecture, verified personalised evidence, permissions and end-to-end learner QA.
