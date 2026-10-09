# iClub APP — Clean release candidate (Stage 12)
Date: 2026-10-09
Base commit: `4bff6f2e9c9a78f6b44dafbea8b318d506f944fc`
Verified QA Preview: `60da7e1ba33f567864fece50c68a91aec10505dd` (protected, READY)
Status: **candidate only, no merge or production deployment**.

## Boundaries
- Final user-facing source: regular root HTML, JS and CSS. Reconstructed from signed Stage09 source patch and previously accepted Stage03 Preview output, then promoted directly to tracked files.
- **Removed from release**: all `stage09-*.cjs`, `stage03-*.cjs`, encoded payloads, no-op override guard, Vercel QA buildCommand and prototypes for deferred Global AI.
- Normal Vercel static deployment from root; the release does not depend on temporary QA reconstruction.
- Practice: seven Tour chips, "By tour / By topic", selected Tour styling, saved attempt, in-place topic selection, RU/UZ/EN, safe pause/back to Practice. Exam Prep P1/P5 behavior unchanged. Other subjects show localized "In development" without a server enrollment request.
- Mathematics Practice v2 bank **already published** on 2026-10-08; no repeat bank switch, removal of current attempts, Tour resets, certificates changes or other destructive operations.
- Local cleanup removes *only* the retired `practice_history_v2:mathematics:tour_*` namespace after server proof and only once; the old global no-op guard is not shipped. `practice_history_v3`, drafts, recommendations, Tour and certificate data survive. **The source-level release adds the server-proven one-time call at login** (previous QA preview had only the safe function, not the boot invocation). This delta is separately contract-tested; it must also be verified in the clean Preview.
- Source-level cache versions are changed for `app.js`, translated topic script, narrow cleanup, Exam Prep host and tabs.
- Global AI and Practice AI remain OFF. Existing tested Mathematics Exam Prep AI is not rerun or re-enabled.
- **No user notification sent**. The Mathematics Practice mail campaign remains prepared separately under the QA branch; do not send without release authorization.

## Supabase schema reconciliation
The additive topic-switch function is **already installed** as migration version `20261009120533` / `practice_topic_switch_atomic_v1`.
The release repository tracks the same SQL under `supabase/migrations/20261009120533_practice_topic_switch_atomic_v1.sql`. The production database recognizes this version as applied. Do **not** install the older QA filename `20261008150000_...` or run both migrations.
The function uses owner checks, row-level lock and atomic replacement; unauthenticated callers lack EXECUTE.

## Release GO conditions
1. GitHub release PR shows no unrelated or QA-generated files, no conflicts, all required checks GREEN.
2. Clean release branch independently builds in **protected Preview** (not previous QA build). Confirm no buildCommand or cache mismatch.
3. Authenticated Practice pause/resume and topic change tested without touching another user's data.
4. Mathematics Exam Prep Core, Tours and certificates remain available; Global AI/Practice AI/payment switches OFF.
5. Read-only user/Tour/certificate counters and protected Mathematics Tour fingerprint unchanged beyond normal user activity.
6. Architect explicitly approves the PR merge after this GO/NO-GO.

## NO-GO
Any failed check, missing clean Preview, changed Tour fingerprint, destructive reset, unauthorized enrollment/AI activation, or uncertain identity isolation. Keep `main` untouched until fixed.

## Rollback
Revert the source commit if release is blocked after deployment; do not roll back with a Practice bank reset. The function is additive and can remain installed unused. Capture pre- and post-release read-only snapshots.
