# Exam Prep Production Release Marker

**Date:** 2026-09-17  
**Release merge commit:** `f1ae6b0abbd580a46fdfd5411fda202d714583f5`  
**Validated release head:** `76d059fc9a11726f3130bf1635ebd2467a9fa6e9`  
**Progress UX release gate:** 21/21 PR workflows — SUCCESS  
**Independent A-to-Z release audit:** GitHub Actions run `35217905338` — SUCCESS  
**Core engineering dress rehearsal:** GitHub Actions run `35217905051` — SUCCESS  
**Browser controlled-beta activation gate:** GitHub Actions run `35217905142` — SUCCESS

This marker intentionally changes no application behavior. It creates a distinct push on the Vercel production branch after the validated Progress UX v1 release was merged into `main`, following the existing iClub production deployment mechanism where a merge can reuse an already-deployed preview tree without automatically advancing the production alias.

Progress UX v1 production schema was installed before this marker through three additive migrations. Immediate verification showed RLS enabled, no direct anonymous/authenticated access to the private snapshot table, zero initial snapshot rows, both governed RPCs present, and all legacy learner/Practice/Tour/certificate/history counts unchanged.

The presentation layer is controlled-beta gated. It loads only after authenticated Exam Prep capabilities return `coreAccess=true`, `killSwitch=false`, and `rolloutState=controlled_beta`. Existing cohort/entitlement governance remains authoritative. This release does not expand the cohort and does not enable AI Assist or Mentor Care.

Rollback remains non-destructive: disable through the existing Exam Prep kill switch / controlled-access boundary. Do not delete learner snapshots, sessions, evidence, corrections, weekly plans, Practice, Tours, ratings or certificates merely to disable the presentation layer.

## 2026-09-24 Weekly-flow bootstrap + learner-copy hotfix marker

**Weekly bootstrap merge commit:** `318e75f11b1fdf606cf2884d06bff6cfe382b3b3`  
**Learner-copy follow-up merge commit:** `4a47e557c8f047108a08d38a41dcbe212e070ec9`  
**Latest-main deep mobile flow:** GitHub Actions run `35990554223` — SUCCESS  
**Weekly bootstrap regression suite:** all PR #166 required workflows — SUCCESS  
**Progress UX learner-copy regression suite:** all PR #167 workflows — SUCCESS

This marker intentionally changes no application behavior. It creates the distinct push required by the existing iClub Vercel production deployment mechanism after the validated runtime fixes were merged into `main`.

The runtime fix serializes concurrent capability refreshes and makes the optional weekly-flow assets recoverable when server-side weekly enrollment becomes available after the initial Progress UX bootstrap. The presentation follow-up keeps Russian weekly goal titles on the existing learner-safe copy contract instead of exposing canonical mixed RU/EN descriptions.

There are no Supabase schema or data writes in these changes, no learner-progress reset, no localStorage migration, and no changes to legacy Tours, Practice, ratings or certificates. Existing controlled-beta capability checks and the Exam Prep kill switch remain authoritative and fail closed.

## 2026-09-24 Projection RPC serialization marker

**Concurrency fix merge commit:** `f1ee946c3d80ea2d6fb682bae2f40138d1a8d91b`  
**Isolated serialization regression:** Exam Prep profile recovery plan preservation run `35995504821` — SUCCESS  
**Required PR #168 regression gates:** all reported workflows — SUCCESS

This marker intentionally changes no application behavior. It creates the distinct production push required by the existing iClub Vercel deployment mechanism after the validated frontend concurrency fix was merged into `main`.

The browser now orders only the Exam Prep RPCs whose nominal read paths rebuild learner projections: diagnostic progress, placement and derived state. This prevents competing Exam Prep surfaces in one browser context from rebuilding the same learner projection concurrently. The server contracts, academic rules and stored learner evidence remain unchanged.

There is no Supabase migration or schema/data write in this release, no learner-progress reset, no localStorage migration, and no changes to legacy Tours, Practice, ratings or certificates. Existing controlled-beta access and fail-closed behavior remain authoritative.


## 2026-10-02 P2-04 / P2-05 Cambridge-reference and readiness marker

**P2-05 merge commit:** `2be052ddd4172e9c89eeba409df1439429fa5942`  
**Validated P2-05 PR head:** `91a5882da348705a0743f7eacd8c9490d5aa2be7`  
**PR #268 validation:** 40/40 workflows — SUCCESS  
**P2-80 independent A-to-Z audit:** SUCCESS  
**P2-73 Core engineering dress rehearsal:** SUCCESS

This marker intentionally changes no application behavior. It creates the distinct push required by the existing iClub Vercel production deployment mechanism after the validated P2-04/P2-05 learner surfaces were merged into `main`.

The learner UI now preserves the official Cambridge 9709 June 2026 reference with an explicit reference-only label. The June 2026 P1/P5 threshold data and special incident handling remain historical context only; they are not promoted into an approved future-series Stage-5 readiness threshold. App Readiness remains an iClub evidence estimate, not an official Cambridge grade or a prediction of a future grade.

The P2-05 production schema was installed before this marker through the additive `20261002060000_exam_prep_p2_05_readiness_summary_safe_v1.sql` migration. Immediate production verification showed the learner-safe readiness RPC present for authenticated users only, zero approved Stage-5 future-series thresholds, all 10 official Cambridge June 2026 reference rows intact, and unchanged legacy counts: users 1442, Practice answers 8770, Tour answers 6267, certificates 157.

This release does not expand the cohort and does not enable AI Assist or Mentor Care. The controlled-beta Core boundary remains authoritative: Core ON, AI OFF, Mentor OFF, kill switch OFF. No learner progress, localStorage, Practice/Tour history, ratings or certificates are rewritten.

## 2026-10-05 Tutor follow-up UX production marker

**Tutor follow-up merge commit:** `5762eac81eac9c6759ac40fc8e4de8612de47de7`  
**PR #315 validation:** 32/32 workflows — SUCCESS  
**P3-17 Tutor Provider-Free Canary:** SUCCESS  
**P1-04 AI Safety Gate:** SUCCESS

This marker intentionally changes no application behavior. It creates the distinct push required by the existing iClub GitHub-to-production deployment mechanism after the validated Tutor follow-up UX fix was merged into `main`.

The release makes each prepared Tutor follow-up option single-use in the current thread, preserves up to two learner-written provider-backed clarification questions, keeps prepared Tutor variants provider-free, makes exhausted limits explicit instead of silently ignoring taps, and increases mobile follow-up tap targets. The whole Tutor thread remains bounded.

There is no Supabase schema/data migration in this marker, no entitlement/cohort expansion, no learner-progress reset, no localStorage migration, and no changes to legacy Tours, Practice, ratings or certificates. The active-assessment blackout, component/skill/locale/source binding and `academic_state_changed=false` boundary remain unchanged.

