# iClub AI Tutor — Verified Practice Context (PC1–PC4, release OFF)
**Updated 2026-10-27. Status: DRAFT / NOT DEPLOYED / NOT APPROVED FOR PRODUCTION.**

## Product intent
ONE existing iClub AI Tutor, not another on-screen Practice card. Only finalized, owner-authorized **main Practice V4** attempts qualify; Tour and Exam Prep are excluded. Tutor may explain verified score, offer cautious next steps and compare comparable attempts; a specific academic mistake requires an admitted source card. The limited PC3 model route cannot fabricate Mathematics solutions from 7/10 alone.

### Prepared PC1/PC2
- `supabase/candidates/iclub_ai_practice_context_v1_dormant.sql`: service-only read, fresh owner/finalization/active-assessment checks; independent OFF flag; no progress or score writes.
- `supabase/functions/iclub-ai-practice-prepared/index.ts`: provider-free verified score/next-step and constrained academic source path.
- SQL candidate is NOT a migration; Edge is NOT deployed.

### PC3 freeform restricted scope
- `supabase/candidates/iclub_ai_practice_freeform_pc3_gate_dormant.sql`: independent OFF gate, requires PC1+PC4 switches, existing released beta consent and exact existing money/model controls.
- `supabase/functions/iclub-ai-practice-freeform/index.ts` + `practice_freeform_pc3_core.ts`: verified owner/attempt/locale/source snapshot; only numeric result questions without an academic source. Uses existing **gpt-5.4-mini**, output cap 384, existing lifetime $5, max $0.05/request, max $0.75/user, parallel max 2 and existing beta weight 3. No model upgrade or second spend pool.
- Provider responses, output and costs must be checked. No real provider call has occurred in this feature branch.

### PC4 durable receipt and full-reload recovery
- `supabase/candidates/iclub_ai_practice_receipts_pc4_dormant.sql`: service-only receipt table and OFF switch, 24-hour bounded replay; no device storage.
- `supabase/candidates/iclub_ai_practice_receipt_rpc_pc4_dormant.sql`: one `dispatch_once` after checks of canonical shared budget/quota reservations, request fingerprint matching, stored result, replay, ACK and verified accounting.
- `supabase/candidates/iclub_ai_practice_recover_pc4_dormant.sql`: service-only receipt lookup by current authenticated learner, authorized finalized attempt and locale. Only a pending `ready` receipt with **charged** canonical money can auto-restore. The Edge recomputes current PC1/source fingerprints and matches the returned server-only hashes; raw hash material never goes to browser. Exact-ID retry of ACK can find `acknowledged` even after lost HTTP ACK response.
- On browser reload, the existing Tutor, after server permission, displays one recovered answer and ACKs using the original receipt ID. No `localStorage` or cookies storing attempts, question text or provider content.
- If provider response or charge is uncertain, the same UUID **must never call the model again**. Preserve `money=unknown` and `receipt=unknown`, release reserved learner quota where canonical rules permit, never describe the spend as confirmed or free. Manual/source-authoritative reconciliation is still required before real release.

### Single UI
- `iclub-ai-v21-ui.js` + `iclub-ai-v21-beta-client.js` on the feature branch route authorized main Practice messages through the existing Tutor, including saved-response and resumed ACK; account switch clears chats, active tests hide Tutor, changed attempt with no fresh server grant cannot fall back to paid General Help.
- `index.html` only changes cache keys for existing Tutor assets. The legacy `practice-ai-prepared-qa.js/.css` files and standalone fixture remain **unloaded in app**, available solely for synthetic QA. No second Practice AI card.
- User-facing recovery labels are RU/UZ/EN. No real learner data is ever used in CI.

## Cancellation and emergency shutdown while model is in flight
- Service-only PC4 `void`, `unknown`, `inspect` and `accounted` transitions may complete **without active PC1 consent/entitlement or PC3 release flags**, BUT only for an existing exact owner/UUID/request-context-source fingerprint, service role, and legal receipt state; they never expose text or dispatch new generations. This prevents financial or quota cleanup from being blocked when student consent is withdrawn.
- New requests, dispatch, store, replay and answer delivery still require current access and enabled controls. The Edge checks the **independent PC3 release gate** again before and after any provider dispatch; disabling the feature while model work is in-flight cannot deliver an answer.
- On a provider response delivered after consent revoke or PC3 OFF, the canonical money ledger still records the real provider cost, generated learner quota is released via canonical RPC, and the receipt becomes `unknown` (no answer replay). The same UUID cannot dispatch again even when permission returns.
- Verified by a localhost-only integration test that revokes beta membership and independently switches OFF PC3 inside the fake provider handler; both cases return no answer, preserve `money=charged`, `quota=released`, `receipt=unknown`, and forbid repeat model calls. No live OpenAI request.

## Evidence / scope
- [GitHub Actions 40495018747 — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40495018747): real unified Tutor + beta JS in isolated Chromium; full page reload recovers pending response with the same UUID; one message/ACK; no localStorage, account and attempt isolation, protected quiz, zero external network.
- [GitHub Actions 40495487593 — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40495487593): disposable PostgreSQL 17, actual candidate RPCs, Deno candidate, five read-only snapshots of canonical shared money/quota RPCs, and synthetic OpenAI result; 1 successful provider result, saved reply, lost HTTP, reload recovery and ACK; separate simulated ambiguous provider status preserves `money=unknown`, `quota=released`, `receipt=unknown`, forbids double call.
- Most recent feature branch consolidation is reviewed against `main` before any change. Source is not deployed, no migration applied, no paid model request, no modification to real learner data, scores, localStorage, deployed Edge or existing budget.

## Release blockers (do not silently mark complete)
1. Review crash windows for **in-flight provider dispatch**, unconfirmed settlement, lease expiry, unknown upstream bill and delayed accounting; source-authoritative reconciliation/retention job is not yet operational.
2. Real authenticated **isolated-backend** protected Preview end-to-end and UX acceptance; the browser CI is synthetic, not a real learner session.
3. Source governance and versioned academic cards for specific Mathematics mistakes; never infer explanations from an unsupported source.
4. Separate architect sign-off for any production Supabase migration, Edge deployment, beta entitlement or paid provider call. **Do not merge PR #366 as-is.**
