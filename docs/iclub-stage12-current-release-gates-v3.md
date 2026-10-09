# iClub APP — Current Stage 12 release gates v3
Updated 2026-10-09. Operational QA; no automatic production authorization.

## Non-negotiable state
- Production stays on existing main until one explicitly authorized candidate ships.
- Preserve ALL learner data, local drafts, Tours, certificates, Exam Prep, and published Practice records.
- Mathematics Practice v2 **already published** on 2026-10-08; do not republish, reset or clean up.
- Existing Exam Prep Mathematics P1/P5 AI was previously launched and tested.
  Do not repeat that acceptance. Global AI remains OFF; other academic subject AI content
  is incomplete and not a release dependency.
- PR #327 is merged. Do NOT merge it again.

## Observed no-write live baseline (2026-10-09)
- Database publication audit: published, old memberships 490, new memberships 495,
  Tour before/after snapshot equal.
- Active Mathematics Practice bank: 495 memberships / 495 approved published meta.
- Registered users 1845; Tour attempts 365; certificates 157.
- Mathematics protected Tour snapshot MD5:
  c96dc7868b2a79c16b13592af604d721.
- New existing post-publication Mathematics learner records:
  Practice attempts 1; Practice sessions v4 1; Practice drill sessions v4 1.
  These counts are *snapshots*, not guaranteed static.
- Global AI generation/gateway OFF, kill switch ON; Practice AI OFF.

## Current QA source
QA branch qa/iclub-stage09-preview-20261009. Stage09 signed build first,
then Stage03 Practice + Exam Prep presentation, topic-choice decisions, Global UI
context and Mathematics AI contracts. All added files are QA-only until final
source-level incorporation.

### Required before any final merge
1. Re-check main, QA and Vercel exact SHAs. The existing READY Preview from
   42569c8 is **older** than current QA. Do not claim it tests current changes.
2. Final code must retire obsolete post-publish Mathematics local reset
   **in tracked source** and replace its cache pin. Preview stage03-retire-legacy-reset.cjs
   is only a build-time protection. Its implementation must not delete drafts.
3. Practice topic-choice UX: RU/UZ/EN, Resume / Discard / close preserving draft;
   finalized results untouched, idempotent retry after network error.
4. Server function replace_practice_topic_drill_choice_safe_v1 is NOT installed.
   Its migration is additive and uses a single transaction, but installing in the
   production project needs a narrow explicit approval and an authorized isolated
   authenticated test account. **Do not activate/delete/reset any real rows**.
5. Run the full exact candidate's GitHub checks and one protected Preview acceptance.
   Match browser UI, authenticated Practice and Exam Prep Core, mobile layouts,
   refresh, log out and back in. Source/static/synthetic tests alone are not enough.
6. Final switch checks: Global AI OFF, Practice AI OFF, commercial/checkout OFF,
   no subject-access enforcement changes; previously tested Exam Prep AI behavior preserved.
7. Compare pre/post users, protected Tour snapshot, Tour attempts/certificates,
   Practice new records and source SHA. Changes in mutable counts must be explained.
8. Only architect-approved *one* final production release, after GREEN. No silent merge.

### Absolute STOP conditions
- Any attempt to re-run PR #327 merge, Math Practice v2 bank switch,
  local reset, legacy cleanup, or script that clears progress.
- Unexpected mutations to learners, Tours, certificates, Supabase policies or bank.
- No authorized safe test account for new server RPC.
- New preview build not GREEN, incorrect SHA, cache version mismatch.
- Real authenticated state is untested or any live flag activates unintentionally.

Historical instructions retained only for audit:
[SUPERSEDED historical v2 checklist](iclub-unified-release-go-no-go.md).
