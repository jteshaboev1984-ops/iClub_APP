# Full42 Extra Hard: protected importer v3 and actual editorial correction

## LATEST 2026-11-07 — 42/42 internal academic/editorial QA complete (NOT PUBLISHED)

The protected source was reviewed for all **30 previously pending** original
multistep challenges. A fresh **independent SymPy/SciPy second-pass**
recalculated all 30 reported results (**30/30 PASS**). English/Russian/Uzbek
problem conditions and worked solutions were compared directly; printed math
values, parameter domains, units, interval endpoints, and answer semantics
were checked. Owner's **internal AI editorial review**, not independent
human or Cambridge examiner certification.

The **new separately archived source** includes exact per-task QA evidence:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_INTERNAL_QA_20261107.zip`.
Its canonical protected JSON SHA256 is
`2283f0a35697349dac6825accd199e85fc72bb61d4ac5f8b4aca9e5adaeea77b`.
**No 42 question texts, worked solutions, mathematical answers or
individual content hashes have changed** from the previous private source:
only QA statuses and review-evidence metadata. The 12 existing approvals
remained intact; **30 changed from internal draft to internal approved**.
Every task has `qa_math=qa_languages=qa_technical=approved` and
`lifecycle_status=approved` in the **private source file ONLY**.
There are still **0 published tasks**, no staging, and the live v2 bank
release remains OFF. The old `28b8872f499b8f2a79d680675a5fb7083b5f0b734bc05fd4b13dd41ca6c79a78` SHA is a
historical pre-review snapshot, not a currently authorized staging source.

The new DRAFT code updates the read-only local validator, strictly scoped
full42 owner-GO private importer and disposable CI synthetic proof to
expect **42 approved/0 draft without publishing**. Any old 12-approved
file or tampered problem remains rejected by the new exact SHA check.
No production SQL, Vercel deployment, user records, mastery, Practice,
Tours, certs, AI, Mentor, or localStorage changed.


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
