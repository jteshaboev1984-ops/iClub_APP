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
