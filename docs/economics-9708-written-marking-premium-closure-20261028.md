# Economics 9708 — Written criteria and premium UI closure

**Date:** 28 October 2026. **Status:** deployed on production.
GitHub PR #381 merge commit `f5f4accf3675d3510114fca5f909f9a35db71779`. Vercel deployment READY. Dedicated Economy Written Consent Beta Isolated Gate run #40637833846 PASS. No preview was required.

## Product correction
- Four matching Paper 1–4 cards remain on the shared Economics home.
- Removed redundant user-facing "agree to participate" invite/banner. A clearly labelled **Start written practice** action activates the existing owner-scoped beta plan only on explicit click. Server cohort/eligibility/sequence and 3-seat cap stay unchanged, so nobody is auto-enrolled.
- Written task: question first, source and data table below it, then aligned **Marking scheme** (secondary) and **Next** (primary). All source/marking views remain protected by existing authenticated and task-version gates.
- On request, marking scheme now shows max marks, AO1+AO2 budget, AO3 budget (where relevant), actual levels and mark ranges for essay questions, and task-specific creditworthy content, with translated RU/UZ/EN labels. The scheme may be expanded/collapsed. No AI auto-marking, self-marking fiction, or bogus mastery.
- CSS scoped to the Exam Prep written component; responsive single-column actions and AO breakdown on mobile; same border/radius/primary tokens as canonical iClub Exam Prep.

## Academic basis and limitations
Cambridge Economics 9708 syllabus for 2026–2028: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf
2025 published level-based marking examples: https://pastpapers.papacambridge.com/directories/CAIE/CAIE-pastpapers/upload/9708_w25_ms_41.pdf and https://pastpapers.co/api/file/caie/A-Level/Economics-9708/2025-May-June/9708_s25_ms_24.pdf?download=true

The **22 questions are original iClub exercises**, not Cambridge-issued papers. The *practice mark schemes* are Cambridge-aligned but bespoke: P2 Section A six parts total 20, P4 Section A four parts total 20; P2 essay part (a) 8 and (b) 12 (AO1/AO2 8 + AO3 4 on the 12-mark part); P4 essays 20 (AO1/AO2 14 + AO3 6). Levels are expressed as mark ranges for the two essay assessment objectives; mark-scheme points are indicative, not an automatic one-point-per-bullet checklist. No claim of official Cambridge endorsement.

## Database
Applied migration ledger `20261028052330_iclub_econ_written_mark_scheme_v1`, tracked at `supabase/migrations/20261028052330_iclub_econ_written_mark_scheme_v1.sql`.
New private RLS-enabled version-bound `private.iclub_exam_written_mark_scheme_v1` has 22 rows and SHA-256 binding to task wording + original answer requirements. Private direct reads denied to anon and authenticated. `public.iclub_exam_written_criteria_v1` adds marking metadata only **after** the prior private criteria and source-readiness/ownership/plan checks succeed. Original historical questions and plan rows are untouched.

## QA evidence
- First full migration + auth E2E test in PostgreSQL transaction, then ROLLBACK: a current enrolled user could read locale-specific scheme on the current owned task; unrelated user could not; no progress changed.
- Dedicated JS CI: 22 allocation checks, both Section A 20-mark sums, essay AO splits, corrupted mark-scheme rejection, criteria request caching, interactive on-click show/hide RU/UZ/EN, regression of all four Paper cards, beta Start gating, responsive CSS selectors and refreshed JS/CSS cache pins. PASS.
- Post-application: 22 new v3 task versions + 22 original drafts preserved; 22 private marking rows; 12 beta release-eligible questions; 1 voluntarily enrolled beta learner; 1 plan with 12 steps and **1 advanced step preserved**; Mathematics active version still 1; no private rubric SELECT for authenticated; anon criteria EXECUTE denied.
- This is **not** a claim of real learner browser interaction/screenshot approval after deploy. Observe the actual UI with real beta learners, no automatic student activity simulation or data clearing.

## Rollback boundary
If the new presentation is problematic, revert the JS/CSS/cache-pin changes only; private scoring metadata is additive, and user progress remains. Do not delete marking rows or rewrite historical beta plans to roll back cosmetic changes.
