# Exam Prep AW1-4 alternate learning — independent QA pass v1

Date: 2026-09-28  
Scope: `p1_aw01_04_alt_learning_draft_v1` + `p5_aw01_04_alt_learning_draft_v1` and draft written-understanding checks `8901..8909`.

Status: **QA REVIEW COMPLETE; CORRECTIONS REQUIRED BEFORE APPROVAL/PUBLICATION.**

This review is a separate re-solve/source/language/technical pass after authoring. It does not publish content and does not change learner academic state.

## 1. Source and scope verification

Verified against the canonical 81-skill registry and the project source hierarchy.

- P1-QUA-01/02/03: Cambridge 9709 P1 1.1 Quadratics; Complete Pure Mathematics 1 Ch1 pp.2-20.
- P1-FUN-01/02: Cambridge 9709 P1 1.2 Functions; Complete Pure Mathematics 1 Ch2 pp.24-42.
- P5-DAT-01: Cambridge 9709 P5 5.1 Representation of data; canonical mapping Ch2-3 pp.14-59.
- P5-DAT-02/04: P5 5.1; Complete Probability & Statistics 1 Ch3 pp.34-59.
- P5-DAT-06: P5 5.1; Complete Probability & Statistics 1 Ch2 pp.14-29.

The coursebook syllabus-matching grids were visually rechecked: Quadratics maps to pp.2-20, Functions to pp.24-42, representation diagrams to pp.34-59, and central tendency/grouped-data calculations to pp.14-29.

No item expands the canonical P1/P5 scope. No P2/P3/P6 or enrichment-only topic is used for mastery.

## 2. Independent mathematics re-solve

All 27 machine-checkable items were independently re-solved. All answer semantics and explanations are mathematically correct.

The nine written tasks were independently checked against their rubrics. Required results and method expectations are correct, including:

- completed-square/vertex/minimum work;
- discriminant parameter intervals and boundary interpretation;
- exact quadratic roots with verification;
- domain/range, one-one, inverse and composition restrictions;
- restricted-domain range;
- representation choice and critique;
- ordered stem-and-leaf with retained repeated observations;
- frequency-density histogram construction;
- raw/frequency-table mean, median and mode reasoning.

The nine written-understanding checks are mathematically correct and remain non-credit companion checks.

## 3. Language QA

EN/RU/UZ preserve the same numerical conditions, inequalities, domains, answer space and reasoning.

One Uzbek terminology issue was found in P1-FUN-01: the written prompt used a weaker phrase for the one-one property than the established project wording. The correction migration changes it to the existing `bir-biriga bir qiymatli` terminology and aligns the related explanation. No mathematical meaning changes.

## 4. MCQ quality / answer-position QA

A release-blocking authoring pattern was found in the stored draft:

- machine MCQ positions before correction: A=17, B=2, C=3, D=0 across 22 MCQs;
- written-understanding positions before correction: 0=3, 1=5, 2=1, 3=0 across 9 checks.

Production already has server-owned frozen per-session MCQ permutation enabled, so this stored pattern is not relied on for learner display. However, draft content should remain safe under rollback and should not depend on runtime shuffling for basic authoring quality.

The correction migration therefore reorders options identically in EN/RU/UZ without changing the option multiset or mathematical answer:

- machine MCQs after correction: A=5, B=6, C=5, D=6;
- new written-understanding checks after correction: 0=2, 1=2, 2=2, 3=3.

This is a non-semantic draft-only option permutation. No exposed/history-bearing item is edited.

## 5. Independence / reserve-role review

The alternate pack is sufficiently independent for the **learning** role:

- no exact draft stem duplicates the current published learning stem;
- several skills use a different representation, method emphasis, sign/shape, domain restriction or response type;
- repeated calculation structures remain acceptable because learning items are allowed to provide varied repeated practice.

This pack is **not** classified as diagnostic, retest, timed or unseen evidence. It therefore does not consume or weaken those protected reserves.

## 6. Technical and history safety

Before correction:

- content versions: draft;
- assessments: draft;
- question metadata: draft + withheld;
- public question rows: inactive + quality_status=draft;
- learner sessions on these assessments: 0;
- Practice/Tour answers referencing these questions: 0;
- QA statuses: pending.

The correction migration aborts if any target content has gained learner/session/legacy history or left the draft/withheld state.

## 7. QA decision

After the correction migration and contracts are GREEN, the content is suitable to move through the project lifecycle:

`DRAFT -> QA PASS -> APPROVED -> PUBLISHED`

Publication must remain a separate guarded migration. It must:

1. revalidate exact content snapshots and source mappings;
2. mark scope/math/language/technical/copyright statuses pass;
3. approve/publish the nine learning assessments and nine written tasks/checks;
4. keep `public.questions` inactive/draft as the server-governed source objects;
5. preserve P1/P5 isolation and existing learner history;
6. run full CI/rollback checks before production application.
