# Economics 9708 — Atomic candidate register v2, verification and next gates

**Date:** 2026-10-09
**Status:** STAGE 1 IN PROGRESS; draft-only skills model, NOT an academically approved iClub skills denominator.
**Primary academic source:** official [Cambridge AS & A Level Economics 9708 syllabus, exams 2026–2028 v2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf).
**Secondary:** uploaded *Economics for Cambridge International AS & A Level*, Bamford & Grant, 4th edition. Book contents confirm coursebook chapters 1–29 for AS and 30–53 for A Level additions; chapter 54 is assessment preparation, **not** the 54th official syllabus topic.

## Verified working dataset
File: `docs/economics-9708-atomic-candidate-register-v2.csv`.

| Check | Result |
|---|---:|
| Distinct official Cambridge topic subpoints represented | 253/253 |
| AS parent subpoints | 131 |
| A Level additional parent subpoints | 122 |
| Parents decomposed into *provisional* distinct skills | 29 |
| Provisional split-skill records from those parents | 132 |
| Remaining original one-to-one placeholders needing atomicity review | 224 |
| Total distinct **draft candidate** skill records | 356 |
| Duplicate internal IDs | 0 |
| Syllabus/chapter/tour/qualification mismatches | 0 |
| Academic approval status | None approved |
| Validated precise question-to-skill links | 0 claimed |
| RU/UZ learner material | Not yet authored |
| Learner runtime enabled | 0 |

### Meaning of the 356 count
This number is **NOT** the final number of Economics skills. It is a structurally complete *working decomposition*, with 224 one-to-one placeholders yet to be evaluated for further splitting. The 132 proposed child skills from 29 parents include methods and evidence types that will require independent academic validation; never inflate product coverage or claim full Tutor readiness on this number. The 45 v1 original split prototypes remain unchanged, and v2 adds 87 provisional split actions from 24 additional syllabus parents.

### Data provenance and referential checks
- All 253 exact parent codes match the official numeric point registry; no absent/extra parent IDs.
- Per-row book chapter, tour and qualification level match the versioned 53-topic crosswalk.
- All 356 provisional skill IDs are unique; no historical `public.questions` IDs are repurposed as permanent skill IDs.
- Parent-level Practice IDs in the file are **unverified candidate links only**, not passed skill mastery, and are not propagated into `verified_precise_question_ids`.
- All learner-facing flags remain false; `runtime_allowed=false` and language states are `not_started`.
- Vercel deployments/builds were **not requested** and Vercel API was not called for this version.

## Priority subject-content findings
Additional read-only full-bank search, see `docs/economics-9708-bank-gap-keyword-triage-v1.md`:
- The legacy Economics bank includes 809 question records, with sparse keyword results for several official skills, including Pareto optimality, moral hazard, transfer earnings/economic rent, long-run Phillips, MEW, MPI, Kuznets and World Bank role.
- Some plausible candidates exist outside their tour's 70 Practice questions, e.g. IMF conditionality Q6244 and loanable funds Q6167 in Season 2 Tour sets; do not use a protected Tour item for runtime AI while its review is closed.
- Some advanced material was historically placed in AS labelled banks (e.g. multiplier, Marshall–Lerner, quantity theory). Do not rewrite learner grades/history or assume the historic current bank perfectly follows syllabus boundaries.
- Tour 7 has 24 ranged `book_ref` tags, so the first chapter number is not definitive for a precise syllabus map.

## Outstanding Stage 1 quality gates
1. Academic examiner-level review of all **224 unsplit placeholders**; either approve indivisibility with stated rationale or split into distinct original skills.
2. Validate the **132 child skills** against official examination scope: merge overlaps, reject unnecessary granularity, confirm skill performance form and source.
3. Review exact original question stems and marking/answer logic for syllabus point, difficulty level, correctness, and whether evidence is **primary, secondary or incidental**. Do not include answer keys or private active-Tour content in learner/public docs.
4. Triaging 61 official parent subpoints without a selected in-tour Practice candidate: inspect the full question inventory, but **no claim of missing content until audit is complete**.
5. Validate representative diagrams, formulae, graphs and numeric methods. Require credible RU/UZ/EN academic and pedagogical checks; no copied source examples.
6. **Only after teacher/architect sign-off** create draft theory and four-variant Tutor source cards in a private versioned structure; separate QA and runtime release approval.

## Required safety and cost policy
Current live learner data, question banks, examinations, Tour eligibility, answer keys, scores, ratings, certificates, localStorage, Exam Prep mastery/evidence, entitlements and global AI kill switch are untouched. Work stays documentation-only in the non-default GitHub branch and in a service-only Supabase project-status row. No Vercel invocation and no intentional preview deployments.
