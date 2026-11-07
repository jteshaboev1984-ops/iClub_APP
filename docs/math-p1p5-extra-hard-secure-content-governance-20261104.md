# Mathematics P1/P5 Extra Hard — governed original bank v2

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


## LATEST 2026-11-06 — protected Full42 v3 staging implementation (DRAFT)

**Exact owner-private source is now pinned to JSON SHA-256 `28b8872f499b8f2a79d680675a5fb7083b5f0b734bc05fd4b13dd41ca6c79a78`.**
Editorial review identified and corrected **two ambiguous Russian math
notations** in the P5 binomial→normal approximation task, where decimal
commas could be misread as function-argument separators. This changes
neither mathematical answers nor skill coverage, no learner data, and
does **not** imply that all 30 additional problems are language-approved.

**Actual next code milestone delivered:** a new `v3` protected 42-row importer
`scripts/ops/p1p5-extra-hard-private-full42-stage-v3.cjs`,
which requires exact private content SHA, 14×3 syllabus strands, 24 P1/18 P5,
12 reviewed + 30 unpublished draft tasks and separate owner GO for staging.
A separate CI-only synthetic data mode exercises the same PostgreSQL
`COPY` + verification path under a transaction and **ROLLBACK**.
The current v2 public release pointer stays **OFF**; it is intentionally
**not switched to v3** and the first 12-task importer remains untouched.
No protected text or worked solution is committed or logged in public GitHub.

Staging and publishing are different decisions. The 30 drafts remain withheld.
The full release will require explicit 30-task editorial acceptance and a
separate version switch. No current production SQL or data change.


## LATEST 2026-11-06 — COMPLETE 42/42 authored, not published

The full 42-problem protected JSON is privately archived and independently
mathematically checked; source SHA256
`28b8872f499b8f2a79d680675a5fb7083b5f0b734bc05fd4b13dd41ca6c79a78`.
All 8 P1 and 6 P5 syllabus strands now have 3 distinct tasks. Original
12 internal QA statuses are retained; 30 additional tasks still require
language/technical editorial signoff, so private release remains OFF.
The 12-only v2 importer must not be reused for 42. See
[complete bank checkpoint](math-p1p5-extra-hard-42-question-coverage-plan-wave2-20261106.md).

## HISTORICAL 2026-11-06 — full-course scale decision

The first private **12 original tasks** remain the unchanged limited-use
pilot cohort (6 P1 + 6 P5); the architect requested a sufficient sustained
course bank. The new **full-course target is 42** (24 P1/18 P5), giving
3 distinct optional challenges per 8 P1 syllabus strands and 6 P5
statistical strands, with geometric/binomial counted separately.
**12 additional tasks** are now authored privately, so **24 prepared / 18
still missing**. Wave 2 translation editorial QA is pending, and its
protected JSON must not be imported by the existing exactly-12 CLI.
See [the governing scope and QA plan](math-p1p5-extra-hard-42-question-coverage-plan-wave2-20261106.md).
The existing bank version, import gate and live release flags stay OFF.


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
