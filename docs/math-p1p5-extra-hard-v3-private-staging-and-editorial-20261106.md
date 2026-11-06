# Full42 Extra Hard: protected importer v3 and actual editorial correction

**2026-11-06 · Issue #450 · DRAFT · NO LIVE DATABASE OR PUBLIC GO**

## Source state

The archived private JSON for the complete 42-question Mathematics challenge
bank was read locally and checked against the official 2026–2027
Cambridge International AS & A Level Mathematics 9709 Paper 1 sections
1.1–1.8 and Paper 5 sections 5.1–5.5. The 14 challenge tracks are an
**iClub teaching subdivision**, with geometric and binomial distributions
both within official section 5.4. Mathematics content checks on all 42
were previously completed; this pass also inspected new EN/RU/UZ tasks
and solutions and identified two ambiguities in the Russian notation
for a binomial distribution and its normal approximation. Both were
corrected in the private bundle **without changing parameter values,
solutions or correct answers**.

The exact source now used by the importer is SHA-256:
`28b8872f499b8f2a79d680675a5fb7083b5f0b734bc05fd4b13dd41ca6c79a78`.
Private Library canonical path:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_PRIVATE_20261106.zip`.
No question text or answer key is stored in public source.

**Editorial honesty:** 12 first-wave original tasks are internally approved
at the source level; 30 newer tasks are still marked
`qa_languages=pending`, `qa_technical=pending`,
`lifecycle_status=draft`. Their review must not be claimed as fully
approved just because math checks, comparative checks, or import
integrity checks pass. No external examiner review is claimed.

## Real implementation

New `scripts/ops/p1p5-extra-hard-private-full42-stage-v3.cjs`:
- `check` authenticates the owner-private SHA and independently verifies
  all 42 per-item hashes, trilingual completeness, exact 24/18 split,
  all 14×3 mapped course tracks and honest 12/30 lifecycle statuses.
- `stage` requires a separately explicit owner GO plus an identified
  DB target. It imports immutable **new private v3 rows only** via
  client-side `COPY FROM STDIN` into a temporary table and a single
  transaction; exact source fingerprints and all 42 states are verified
  before commit. The original v2 release pointer stays
  `enabled=false / academic_approved=false`, and **no v3 task becomes
  visible**. Student attempts, grades, Tours, Practice, other subjects
  and localStorage are never updated.
- `dry-run-isolated` only in known two-user PostgreSQL17 CI and only
  with deterministic CI dummy problems. It uses the same SQL import,
  then `ROLLBACK`. Corrupted source hashes, using actual questions
  in CI, repeated task keys, state escalation and missing owner GO
  are refused.

The old 12-task importer **must not be used** on full42. The new import
and final release/switch are two separate actions. New code does not
set `published`, change bank selection or grant any AI/Mentor entitlement.

## Pending real milestones

1. Finish independent trilingual/technical QA for the 30 new tasks,
   fix exact defects in the owner-private source with new SHA,
   and explicitly approve each question before publication.
2. Run one owner-authorized protected private v3 staging and integrity
   verification; no test users or other subject row deletion.
3. Prepare separate audited release migration that switches to v3
   only after all 42 are approved, reconciled and safely published.
4. One short real Math-only public access check and separately authorized
   identified **test-data-only** cleanup/production release.

**PUBLIC NO_GO** remains. No production write or launch authorization
is implied by this DRAFT.
