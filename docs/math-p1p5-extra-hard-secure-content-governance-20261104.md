# Mathematics P1/P5 Extra Hard — governed original bank v2

**Architect decision: 2026-11-06 (CURRENT, supersedes the 2026-11-04 source-recovery instruction).**

Earlier 12 missing Extra Hard drafts are **retired as a source requirement**.
Do not spend time recovering their lost text, reconstructing old Git blobs or
pretending that any past payload was imported. The architect explicitly
authorized a **fresh original bank**: 6 P1 and 6 P5, authored from scratch.

**Prepared:** exactly 12 protected, unique, trilingual written challenge tasks,
each with step-by-step EN/RU/UZ worked solution and exact answer; all mapped to
Cambridge International AS Mathematics 9709 P1/P5 official area, canonical
iClub skill, and relevant Complete textbook chapter **as a mapping only**.
This work does not copy textbook exercises or examiner answer keys.

- Bank: `math-extra-hard-2026-11-original-v2`
- Bundle: owner's **private Library** `/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_12_NEW_PRIVATE_20261106.zip`
- Canonical JSON SHA-256: `7ba74982694365b11ade713f952c4aa8af9219cb9fbc0cb7ec6bf6e3e2da0e6d`
- Mathematics: 12/12 independently calculated symbolic/combinatorial results;
  each result also receives a manual method check. All language versions
  and structural fields checked. No external Cambridge examiner or human mentor
  confirmation is claimed.
- Package lifecycle: `approved` for **private staging**, **NOT published**.
  Release remains OFF and academic_approved=false; no learner sees protected text.
- Safe private importer: `scripts/ops/p1p5-extra-hard-private-bank-v2.cjs`.
  `check` validates structure, 12 individual content hashes and 6+6 ownership
  locally, without contacting a database. `stage` requires a separate explicit
  owner approval and connection; it inserts immutable **new rows only** with
  the release OFF, and rolls back the full transaction if the 12-row proof fails.
  Never run the private import in public CI logs or commit JSON/ZIP to Git.

## Runtime governance retained from v1

- Tasks, solutions, and written attempts live in private tables. No shared
  `public.questions`, Papers, diagnostic reserve, Tours, Practice v3, mastery
  scores or learner stage data is modified.
- Authenticated Math Core owners only can list, start, submit and resume.
  Answers and full worked solutions are returned only to the attempt owner
  AFTER durable submission, never with the pre-submit problem.
- All Extra Hard work is **optional, ungraded and noncredit**. No mandatory
  mentor or additional exam score.
- Separate content-review/publish decision will turn new private versions
  `published` and grant release flag when authorised. This cannot be
  inferred from mere authorship, checksums or preparation.
- One-time prelaunch **identified test-data-only** cleanup remains separate,
  does not delete real learners, and requires a new architect GO.

## Obsolete references cleaned

The old instructions “retain/recover the SAME original 12”, “do not create
replacement questions”, “restore exact lost source”, and pending old
`secure-bank-v1-pending` **as an active bank version** are superseded. The
v1 database table/RPC names persist because they are stable technical
contracts, not old question bodies. Git history is not rewritten.
No protected tasks or solution keys are inserted in public migrations.

**Status:** original new bank prepared privately; metadata migration and import
validation code are DRAFT, 12 task rows not staged to production, publication
OFF, public Mathematics Exam Prep release still NO_GO.
