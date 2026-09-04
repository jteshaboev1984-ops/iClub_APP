# Exam Prep Production Release Marker

**Date:** 2026-09-04  
**Release merge commit:** `3378001718e3fe76315d35e9b7056a31247800b8`  
**Validated release head:** `0993bb1af34fd2ddafa19e320da654fd7fb214af`  
**P0-14 host regression:** GitHub Actions run `33860188997` — SUCCESS  
**P0-15 current-schema alpha:** GitHub Actions run `33856650388` — SUCCESS  
**P0-16 controlled-beta / hold-point gate:** GitHub Actions run `33859567306` — SUCCESS

This marker intentionally changes no application behavior. It exists to create a distinct push on the Vercel production branch after the validated Exam Prep release was merged into `main`, because the merge commit reused the already-deployed preview tree and did not automatically advance the production alias.

The production release remains fail-closed for real learners until the governed beta allowlist is populated and wave 1 is explicitly activated. The staged production cohort is draft-only with zero members and zero entitlements.
