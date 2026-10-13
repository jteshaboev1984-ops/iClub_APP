# iClub AI Layer v2.1 — Deno/Supabase Edge technical QA bridge

**Date:** 2026-10-13 · **Project:** iClub APP · **Environment:** private QA branch only  
**Status:** **native Deno and Node QA GREEN; NOT a deployed Supabase Edge function.**

## Scope boundary

This workstream builds AI **technology only**. Cards, exam questions, lessons, feedback texts, source rights/editorial approvals, translations and academic mapping are produced in the separate content workflow. Content publishing through the future technical receiver will be independently reviewed and must not activate AI without topic, language, learner and owner release gates.

Existing production `supabase/functions/global-ai/index.ts` and `supabase/functions/exam-prep-ai/index.ts` are **unchanged**. The new files live only under `qa/edge_v21/`, and no production Vercel/Edge routing references them. Existing Mathematics Exam Prep and learner progress/localStorage remain independent.

## Delivered Deno-native QA package

| File | Technical responsibility |
|---|---|
| `qa/edge_v21/http.ts` | Native Web Request/Response transport: strict QA origin allowlist, POST/OPTIONS only, JSON-only, 4 KiB maximum request, malformed UTF-8 denial, safe no-store headers and generic no-secret failures |
| `qa/edge_v21/supabase_services.ts` | Server-only adapter: Supabase Auth verification using **learner bearer + anon key**, privileged RPCs with a service-role key never sent to browser, timeouts, no unsafe retries, exact v2 route/request parameters, no client-submitted user ID or source authority |
| `qa/edge_v21/runtime.ts` | Native Deno compatibility bridge to the existing 382-test QA Node/CommonJS request core. No code copied into production Math Tutor |
| `qa/edge_v21/index.ts` | QA-only service entrypoint; entirely disabled unless `ICLUB_AI_V21_EXPLICIT_QA=isolated-preview-only` and a valid **explicit** `ICLUB_AI_V21_QA_ORIGIN` are supplied. Wrong or absent configuration returns HTTP 503 without any backend call |
| `qa/edge_v21/http_test.ts` | 10 transport/CORS/size/UTF-8/privacy checks |
| `qa/edge_v21/supabase_services_test.ts` | 11 real adapter Auth/RPC wiring tests, including missing-schema fail-closed and no provider |
| `qa/edge_v21/runtime_test.ts` | 4 actual Deno-integrated synthetic user-route tests: not-ready, automatically published ready, protected exam, published prepared reply |

### Server adapter contracts grounded in known schema

**Already present/verified:** Supabase `/auth/v1/user`; `public.subjects(subject_key,is_active)`; existing `private.iclub_global_ai_runtime_config`; original Maths P1/P5 Tutor and its separate guarded `exam-prep-ai` endpoint. None of their production SQL schemas, beta access rules or active functions were modified.

**Prepared and tested in local PostgreSQL, but NOT installed in real Supabase:** `get_iclub_ai_topic_release_service_v21`, `reserve_iclub_ai_usage_service_v2`, `claim_iclub_ai_delivery_service_v21`, `finish_iclub_ai_delivery_service_v21`; related release/tariff/unique-tombstone tables. These RPC calls currently fail CLOSED in the QA adapter if attempted against an unprepared database.

**Designed, not yet implemented in any real Supabase deployment:** read-only service RPCs `get_iclub_ai_v21_runtime_service`, `get_iclub_ai_v21_protected_service`, `get_iclub_ai_v21_scoped_context_service`, `get_iclub_ai_v21_rollout_service`, `get_iclub_ai_v21_source_proof_service`, `get_iclub_ai_v21_source_bundle_service`, `get_iclub_ai_v21_entitlement_service`, `get_iclub_ai_v21_provider_budget_service`. Their names in the adapter are **proposed interface contracts**, not claims that these database functions already exist.

Missing protected/context/rollout/budget/source RPCs always fail to unauthorized/unavailable; no fallback to an unverified card, a browser-selected topic or the original Mathematics AI entitlement. `generateSynthetic()` in the Deno adapter **always throws**, so no provider calls or AI-generated academic content can occur even if the QA entrypoint is accidentally launched.

## Exact behavior by state

- **No independently published and rights-verified topic:** localized **«В разработке» / «Ishlab chiqilmoqda» / “In development”**, zero allowance, no provider.
- **Global AI OFF or backend unavailable:** generic unavailable; no source or tariff calls following denial.
- **Active protected assessment:** AI hidden, including status; no answer.
- **Approved topic:** the general gate can give a readiness signal only if current Auth, context revision, source hash, locale, cohort and release pass. Successful AI replies still require server-owned entitlement, actual source integrity, quota and explicit beta/provider approval. **No real user rollout exists.**
- **Network retry or double request:** the SQL claim and atomic settlement are tested under real PostgreSQL. No attempted recovery by calling provider twice. A lost HTTP response after finalization cannot yet be replayed; review of private encrypted short-lived receipt is pending.

## Verified, reproducible non-production evidence

[**GitHub Actions run 38351457995**](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38351457995) — SUCCESS with Node/Deno/PostgreSQL in the QA branch.

- **Node.js 22:** 382/382 tests PASS, plus 8/8 additional synthetic tariff smoke cases and existing Mathematics subject-isolation regression PASS.
- **Deno 2.9.7:** strict TypeScript check PASS for all QA Edge modules; **25/25** HTTP/Auth/RPC and integrated request cases PASS with no permissions for Internet access or production environment secrets.
- **PostgreSQL 16:** six/ six independent local scratch test suites PASS; concurrent two-client delivery race and forced billing transaction rollback PASS. Databases were disposable and deleted after checks.
- GitHub Actions workflow uses read-only repo token. No Supabase or provider credentials are injected, no deployment jobs run, no Vercel builds are performed. Protected-file comparison against the pinned production baseline PASS.

## NO-GO before one protected Preview

1. **Implement and audit server-created opaque session-context storage** and ownership/current-screen invalidation, together with read-only runtime/protected/rollout RPCs based on actual schema. Never trust browser progress, course membership, request-selected subject or marked topic ready.
2. **Implement service-only approved source proof/bundle contract** and connect it to separately produced editorial content. Require source hash/rights/version/locale and QA row; no direct generic topic fallback for exact exam or Practice question.
3. **Review production-safe database migration plan** separately, with explicit architect approval, local scratch dry run, transaction/RLS/GRANT tests, reversible rollback and no modification of original Maths data.
4. **Replace blocked provider adapter** only after provider budget, model safety, price estimates, operational timeout and output schema are reviewed; never call a paid provider merely because content was published.
5. **Validate Supabase Edge bundler compatibility** (Deno CLI success is not sufficient), guarded endpoint permission model, CORS, reauthorization across async work, minimal request receipt privacy and logging, under one protected Preview.
6. **Browser/mobile RU/UZ/EN user-journey QA** and single deliberate Preview, followed by explicit architect go/no-go. Keep actual new AI kill switch ON throughout development.

**No real users, existing progress, academic answers or content records were read or modified to run this checkpoint.**
