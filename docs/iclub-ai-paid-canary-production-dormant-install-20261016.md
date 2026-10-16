# iClub AI paid canary: live dormant infrastructure

**Installed 16 October 2026. Status: LIVE INFRASTRUCTURE, NO PROVIDER REQUESTS, NO STUDENT ACCESS.**

## Production changes actually completed
- Supabase project `mmmduffgpvwjdpruzikw`: additive migration `iclub_ai_paid_canary_operator_ledger_v1_20261016` returned success. This creates **only** `private.iclub_ai_paid_canary_control_v1`, `private.iclub_ai_paid_canary_ledger_v1`, and four new operator-only `public.*_iclub_ai_paid_canary_v1` RPCs. No existing app table is modified and no student row accessed.
- Live read-only postmigration audit: `enabled=false`; lifetime=1,000,000 microUSD ($1), UTC day=500,000 ($0.50), operator day=50,000 ($0.05), hold=10,000 ($0.01), max parallel=2; ledger entries=0, liability=0. Direct table writes by `service_role` are denied. `anon`/`authenticated` cannot execute spend RPC. Private tables have RLS.
- New separate Supabase Edge Function `iclub-ai-paid-canary` version 1, **ACTIVE and verify_jwt=true**; ID `c237b38a-f9c6-43b0-83f9-315e2e6217e4`. It does NOT replace `exam-prep-ai`, `practice-ai` or the general app functions.
- Edge function source from `qa/funded_canary_edge/index.ts` and `qa/funded_canary_edge/policy.ts` on QA branch, whose Deno typecheck and SQL PostgreSQL tests have passed. It accepts ONLY an exact service-role authorization and a fixed internal public navigation question; never accepts learner input, user records or arbitrary academic source. `store:false`, 220 max output, no tools, no automatic retry. Cash reservation is required before any paid provider HTTP. Unknown provider invoices hold worst-case liability.

## Double kill switch, zero cost
1. Edge flag `ICLUB_AI_PAID_CANARY_ENABLED` must be exactly `true`. This unique flag is **not set by deployment**.
2. Independent SQL `private.iclub_ai_paid_canary_control_v1.enabled` remains **false** after installation. The SQL refuses any paid reservation.
3. Public Global AI flags remain OFF: `ui=false`, `gateway=false`, `generation=false`, `kill_switch=true`. This operator canary is not tied to the app UI.
4. This canary is separate from existing Tutor provider spend. The $1 ceiling limits only this operator pilot, not the legacy Tutor account's aggregate invoice.

**Total new paid model calls: 0; newly incurred pilot cost: $0.**

## Remaining execution hinge (requires UI access not exposed by connected Supabase actions)
Before enabling a single paid HTTP call, validate the operator endpoint's `status` response from Supabase Dashboard with a service-role authorization; no secrets should be copied into chat. Body: `{"intent":"status"}`. It must return `edgeEnabled=false`, `moneyEnabled=false`, and show whether the server has an available `OPENAI_API_KEY` (boolean only).

Once runtime checks are confirmed:
- Supabase Dashboard > Edge Functions > Secrets: set `ICLUB_AI_PAID_CANARY_ENABLED=true`, only in the controlled runtime. The owner/Admin can change Edge secrets; this connector does not expose secret-write actions.
- The assistant rechecks production state, enables ONLY the independent pilot financial switch if all proof is satisfied, not Global AI flags.
- Use Supabase Dashboard > Edge Functions > `iclub-ai-paid-canary` > Test with a service-role operator token; send `{"intent":"run","request_id":"<new UUID>"}`. One guarded paid provider invocation is permitted. Do not reuse UUID, do not send provider keys or service-role tokens into ChatGPT. Dashboard tester supports method/authorization/body but operator must keep keys private.
- Immediately read back lifetime liability, request count and provider reply usage, then disable both pilot switches again and review answer quality.

**Do not** flip general Global AI runtime flags, roll out subscriptions or start real student traffic. Funding approval ($1) is retained and no extra budget consent required. This is an **operational control**, not another architecture approval.

References: [QA 3/3](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38913629415), [money-only QA 3/3](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38912625223), [Supabase Edge Function tester](https://supabase.com/docs/guides/functions/quickstart-dashboard), [Supabase Edge Secrets](https://supabase.com/docs/guides/functions/secrets).
