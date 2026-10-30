# Exam Prep — independent same-skill retest across all subjects (v1.0)

**Decision recorded 30 October 2026.** This is an implementation checkpoint for future subject-bank work, not a claim of an enabled feature. Canonical task: [GitHub issue #432](https://github.com/jteshaboev1984-ops/iClub_APP/issues/432). Economics reference: [PR #430](https://github.com/jteshaboev1984-ops/iClub_APP/pull/430) (Draft, feature OFF, no source import).

## Product rule

After a learner completes an owned assessment and receives a verified wrong-skill attribution, offer guided correction and an **independently authored, previously unseen** task for the **exact same versioned skill and relevant paper/component**. Preserve proof of source identity and all previous exposures. A repeated already-seen question, a same-unit-but-different-skill question, or a mere correct guess must not independently confirm mastery.

## Subject implementation order (when working with each bank)

| Subject | Must adapt (do not copy Economics IDs or scoring rules) |
|---|---|
| Mathematics 9709 | P1 and P5 strictly separate, 45+36 internal skills, own error ledger and component evidence, method/working verification where required |
| Chemistry | Actual AS/A-Level syllabus and Paper structure; conceptual, calculation, mechanism and practical/data evidence as appropriate |
| Biology | Data interpretation, graphs, diagrams, explanations and questions mapped to actual syllabus and examination components |
| Computer Science | Pseudocode/trace-table/algorithm reasoning plus knowledge, paper-specific method evidence; no unjustified auto-award for written code |
| Economics 9708 | P1/P3 native MCQ retests; P2/P4 written tasks remain non-grading unless separately designed and approved |
| Any later subject | Same protection contract; subject-specific authority and tested evidence requirements |

## Mandatory checklist per subject-bank iteration

- [ ] Read official syllabus and the subject's academic map before writing or linking questions.
- [ ] Enumerate existing approved skill keys; do not equate shared chapter labels with an exact skill.
- [ ] Create separately versioned, reviewed EN/RU/UZ questions and clear academic/provenance checks; verify correct answer and distractors.
- [ ] Compare to all previously delivered legacy/Tour/Practice/exam and draft items for **semantic** overlap, not only exact hashes.
- [ ] Preserve second/third unseen alternatives for subsequent delayed correction cycles; fail closed if exhausted.
- [ ] Check ownership of original **finalized** wrong answer, session, paper and skill; validate current authenticated role/session and exclude all previous exposures.
- [ ] Store answer keys and canonical sources privately; all scoring, idempotency, expiry, ownership and original source linkage server-side.
- [ ] Keep original learner sessions, scores, certificates, ratings, practice state and localStorage untouched. Additive tables only; feature OFF by default; reversible issuance without deleting history.
- [ ] Model both MCQ evidence and written/manual evidence accurately; AI can explain but never certify independently.
- [ ] Run static + authenticated negative/positive + concurrency + revocation + isolation + backup/recovery tests **outside production**; publish only with explicit release authority and scope.

**Release constraint:** This checklist becomes mandatory when the corresponding subject bank is edited, audited or integrated. Do not open or block live legacy content merely because the new future retest feature is incomplete. Do not roll out draft secret banks through public GitHub, static assets, exposed Supabase tables or learner browsers before authorized server issuance.
