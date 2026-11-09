# Mathematics P1/P5 Extra Hard — Full42 source-specific internal academic release candidate

**9 Nov 2026 · Issue #450 · V4.3 · owner-private evidence · Public OFF**

This checkpoint is a **real completion of the academic decision work**, not another cycle of the 53-step technical regression or question-bank re-import.

## Complete private academic decisions
- **42 original challenge tasks** (P1 24; P5 18; 14 official syllabus tracks x3). Bank identity remains `math-extra-hard-2026-11-full-v4`; task IDs preserved; 42 currently staged in `private` on existing PostgreSQL 17.6.
- Former 17 provisional V4.1 editorial flags are **resolved with item-specific reasoning**. Four actual shallow extensions were strengthened in V4.2, the other 13 were explicitly evaluated: **8 retained unchanged on nonroutine merits and 5 individually strengthened** in V4.3. In total only **9 targeted improvements** since V4.1; no blind rewriting of the other 33.
- Original remaining **25** V4 worked conditions/solutions were previously mathematically checked and are now each assigned an explicit content-specific nonroutine explanation (parameter boundary, conditional sample space, exact inverse, multiplicity, conditional moment, geometric-series arguments etc). Four earlier V4.2 changes retain their individual proof/translation evidence. The newly created owner-private **42-item** review report references exactly the **42 current V4.3 content hashes**, not V3/V4/V4.1 hashes. No protected question bodies or answer keys are in public Git/Issue.
- Internal course-level standard of `Extra Hard` is **multi-concept or nonroutine reasoning with a genuine extra proof / constraint / reverse inference**. This is not a claim that Cambridge officially designates these as Extra Hard, nor an official examination grade. Only internal AI-assisted academic/trilingual editorial review was available; **no independent human/external Cambridge examiner is falsely claimed**.
- The 42-item internal review's `decision=approve` means **content is an internally accepted RELEASE CANDIDATE**, not permission to enable public access. Student-facing release still requires the architect's separate authorization and the existing guarded publish transaction.

## Source and evidence hashes, owner-private
- Exact `Full42 V4.3` archive:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_v4_3_FOCUSED_13_REVIEW_20261109_PRIVATE.zip`
- Private V4.3 canonical JSON SHA256: `42c16a0d81cad35576b927e0f8c412650b045c25c1cfbcb71d86e20dfda2e090`
- Private archive ZIP SHA256: `b9a755d96cf27f59fdf57f197ee76038dbf9357a835910aecfb0d2f48afd3d7c`
- Current 42-row content fingerprint (MD5 of sorted canonical per-item SHA256 strings): `17dcea35cb50de348f62394d49be1f64`.
- Full42 itemwise internal academic review (private JSON):
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_V43_PRIVATE_42_ITEM_INTERNAL_ACADEMIC_REVIEW_20261109.json`
- Review SHA256: `b579411f8297ba73f481b35424dc7da0b9241e2039e33e19ca1a3e4b9724441d`.
- The **current V4.3 unmerged reviewed-only release gate** is pinned to BOTH exact source SHA and exact review SHA. A different or incomplete review cannot substitute. The private review includes all 42 source-specific entries, itemwise `qa_math/qa_languages/qa_technical=approved` as **internal release-candidate signoff**, with unique difficulty rationale, and honestly records `independent_human_signoff=false`. The current DB source **still has all QA statuses `pending`** until a separately authorized gated release performs its atomic version change.

## The only database/source writes in this academic package
Five surgically targeted source fields (EN/RU/UZ prompt/solution/exact_answer plus canonical SHA) in the already existing private draft tables were changed under one compare-and-swap SQL transaction, requiring the exact old V4.2 42-item fingerprint, zero Extra Hard attempts, all task statuses draft/pending, disabled previous release pointer and exact new full42 fingerprint/actual contents. SQL COMMIT succeeded with 5 changed and 37 unchanged. **No repeat bank import, no existing Paper/user progress/Tours/Practice/certificate/localStorage changes.**

## True remaining launch operations
- The **catalog topic/progress migration is already installed in the existing Supabase database** (P4-15); do not apply it again or describe it as pending.
- The **V4.3 public release mechanism is already authored in DRAFT code** (child of P4-14 and P4-15). Last full isolated PG17/signed JWT/PostgREST/Chromium 53/53 test was at the **older V4.1 algorithm SHA**, not at the new review-pinned V4.3 head. No misleading claim of new end-to-end CI was made; we intentionally skipped redundant 53-step runs for immutable algorithm/source-pin-only changes as the architect requested.
- **DO NOT flip release enabled/academic flags or merge to main/Vercel without explicit separate owner GO and release coordination.** The release process itself checks exact live private-source fidelity, all 42 approved review entries and catalog shape; must still coordinate the DRAFT UI stack and separately unfinished P0-16B security work.
- Paper completion is not an automatically verified written score; no fabricated grades, mandatory Mentor or student self-mark.
- Beta data cleanup remains deferred until separately permitted.

**Status: V4.3 academics accepted internally, source+review pinned, private DB holds 42 draft tasks, PUBLIC OFF. The next meaningful action is coordinated release decision / deployment, not more problem rewriting or repeated tests.**
