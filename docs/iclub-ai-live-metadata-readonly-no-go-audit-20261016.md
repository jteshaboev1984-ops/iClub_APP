# iClub AI v2.1 — live production metadata read-only cross-check and hard NO-GO

**Observed:** 16 October 2026. **QA branch:** `qa/iclub-ai-layer-v21-20261012`.
**Production project:** `iClub_APP`; **observation ONLY** (Edge inventory and Postgres `pg_catalog.pg_proc` names), no production database writes, no learner records, no Auth tokens or signing keys, no changes to production services or subscription.

## The architect's visual decision

The accepted protected AI Preview remains visually identical after the latest security-only steps. **No new Preview deployment is needed** until there is a real screen change. Preserved user-approved iClub AI Tutor icon Option A and natural one-click demo UI:
https://i-club-202bcs130-jasurbeks-projects-c5451f97.vercel.app/

## What was actually observed from live production READ ONLY

- Existing independent Edge functions `exam-prep-ai` and `practice-ai` are `ACTIVE` with `verify_jwt=true`. This observation does **not** prove their full entitlement/security logic; it only confirms deployed metadata.
- A query limited to `pg_catalog.pg_proc` *function names* found legacy Global AI foundation/gateway v1 functions, but **zero** candidate `get_iclub_ai_v21_*` functions and **no** `resolve_iclub_ai_v21_practice_attempt_service` resolver.
- The prior P9 release preflight already enumerates 24 required Global AI v2.1 RPC contracts. The proposed exact Practice V4 resolver is an **additional 25th**. None has been approved/installed in production for this candidate.
- No proposed Global AI v2.1 Edge is deployed; the visual QA shell uses local prepared synthetic response and cannot be treated as a genuine personalized tutor.
- The locally cryptographically signed HS256 test JWT is **not** verified by hosted Supabase Auth. No real learner token was obtained, requested, read or tested.
- Actual approved rights/source release for three-language learner explanations has **not** happened.

## New QA-only safeguards

- `qa/ai-v21-live-release-metadata-observation-20261016.json`: limited, non-personal observed metadata with explicit `releaseAuthorized=false`, `realHostedSignedJwtAuthVerified=false` and `noStudentRowsRead=true`.
- `qa/ai-v21-live-release-safety-gate.cjs`: read-only supplement to existing frozen P9 preflight that checks the 24+1 RPC count, the actual exact local resolver startup guard, existing exam tutoring separation, rights absence and signed-test-token limitations. Output has **no "GO" state** and cannot initiate a release.
- `qa/ai-v21-live-release-safety-gate.test.cjs`: rejects missing/forged metadata, fake external issuer/JWT status, fake deployed RPC flags, altered existing Tutor protections or simulated owner approval.
- `.github/workflows/iclub-ai-real-preview-qa.yml`: additional mandatory tests; preserves browser safety, source-change checksum and synthetic PostgreSQL/HTTP integrations.

## Verification

[QA GitHub Actions run 38855985015](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38855985015):
- `offline-preview-acceptance`: GREEN, including the new release NO-GO gate.
- `isolated-practice-mapping-postgres`: GREEN.
- `real-http-postgres-resolver`: GREEN.

**No production code, migration, tariff, real learner progress, Exam Prep, localStorage, image mark or learner academic source was modified**. Only this QA branch received code and test additions.

## Next bounded milestone

Prepare stronger run-once read-only review of hosted Auth's *configuration/behavior without learner tokens*, and the independent exact Practice context + editorial/source publication requirements. Do not deploy candidate Edge, make a paid Supabase branch, or activate AI to real students until user-architect approval and complete verified release evidence.
