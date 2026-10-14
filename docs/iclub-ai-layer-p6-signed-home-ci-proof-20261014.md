# iClub AI v2.1 — P6 Home signed evidence and real CI verification, 2026-10-14

**Scope:** QA branch only. **Live Global AI release:** NO-GO. User data and legacy Exam Prep left intact.

## Real Actions evidence

A deliberately isolated draft PR #342, from `qa/iclub-ai-v21-ci-verification-20261014` to `qa/iclub-ai-layer-v21-20261012`, enabled observation of the complete QA workflow without creating a pull request toward `main`. The PR is not to be merged for release.

- Initial workflow #203: Node **617/619**, two test regressions were identified from actual logs. Corrected the literal-whitespace assertion in the navigation test and separated delayed-JWT pre-dispatch cancellation from already-dispatched mint revocation in the transport test. Security guards were NOT weakened.
- Workflow #206 (run ID `38589514037`): **GREEN**, Node **619/619**, native Chromium, Deno tests/typecheck, **14 independent disposable PostgreSQL suites**, two independent two-worker race suites, and protected app/Exam Prep diff.
- Workflow #209: new signed-plan module tests passed Node, but full job encountered `ENOTEMPTY` while the Chromium test cleaned its temporary profile after all three locale accessibility tests had passed. Bounded retry for Chromium cleanup was added, without suppressing actual accessibility assertions.
- Workflow #211 (run ID `38590672176`): **GREEN** including the clean Chromium teardown and complete QA matrix. Its merge snapshot predates the stricter §89 commercial proof change, so it must not be used as final GREEN for the §89 commit.

Source: GitHub Actions on the QA-only PR (not a production release). No node, Deno or PG test was run against real student data.

## Signed server-plan boundary (§88)

`qa/ai-layer-v21-p6-home-signed-server-bridge.cjs` accepts a real-schema *scratch* scanner result only if:
1. It has the exact authenticated owner, current screen revision, current server Home handle, server-supplied complete scan and policy version.
2. Every proposed subject action is independently verified by a trusted commercial subject authorization service and by a separate academic evidence service.
3. The corresponding RU/UZ/EN editorial source is published, integrity-checked, rights-approved and non-conflicting in the **trusted test services**.
4. The exact scanner result and current screen survive a final asynchronous re-read, with subject authorizations rechecked before signing.
5. The server signs the minimal plan with a 32+-byte secret HMAC; a modified plan/subject/source fails signature verification. No secret leaves the server. All outputs explicitly forbid beta, production and provider actions.

This code is a QA-only proof boundary, not a deployed production Home planner or new Supabase service. Positive tests use synthetic independent publication and rights replies; no rights approval has actually been granted for live iClub sources.

## Commercial source audit and requirement (§89)

Metadata-only schema inspection of live Supabase confirmed `user_subjects.mode` is constrained to `study` / `competitive`, and existing server `public.get_iclub_subject_access_guard_service_v1(uuid,text,text)` implements nuanced access modes. In its source, `allowed=true` may occur for `legacy_passthrough` / `shadow` as transitional compatibility, **not** as the new AI feature grant. The legacy browser-side `commercial-access-ui.js` can also return permissive fallback when its RPC is unavailable. Neither is acceptable authority for the new unified AI.

§89 therefore requires explicit authenticated service-originated proof bound to owner, subject, requested `study` / `competitive` action, revision, and verified commercial or separately grandfathered right. Competitive Tour also requires independent positive selection verification; simply checking an available competitive slot is insufficient. `shadow` and `legacy_passthrough` never authorize new AI. No production commercial function, subscription, learner entitlement or schema was modified.

## Remaining non-negotiable release gates

Even after GREEN: a separately authorized nonproduction Supabase environment for actual integrated DB validation, production-grade atomic owner-bound server planner and commercial source reader (current QA uses trusted mocks and guarded scratch tables), independent editorial/rights/source publication for 18 texts, real app + Edge integrated Preview and signed-in end-to-end QA, explicit owner cohort consent, provider money/billing consent, and legacy Mathematics parity before any release. Current Vercel Preview deployment `dpl_BswWrQATQYEL86vEAxaECgQhs27r` is an SSO-protected **one-file network-disabled demonstration**, not a fully integrated production candidate.

**Never changed:** `main`, production, Supabase records, localStorage/progress, legacy Mathematics Tutor, billing, paid providers or production domains. Global AI stays OFF / NO-GO.
