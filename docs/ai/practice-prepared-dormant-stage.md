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

## Real isolated Supabase Auth verification (no hosted Supabase)
- GitHub Actions starts the **official pinned** `supabase/gotrue:v2.197.0` in a disposable container, using a **separate disposable database** `iclub_ai_auth_ci` with an `auth` schema and schema search path. It never uses iClub production credentials, accounts or PostgreSQL; the container is destroyed at end of the job.
- Two synthetic email/password accounts sign in through genuine GoTrue `/token?grant_type=password`; `/user` verifies both signed JWTs. The actual unreleased PC3 Edge forwards user verification to this local real Auth service.
- A newly finalized, isolated Practice V4 attempt 701 is assigned only to the first real GoTrue user. The second user's signed token and a deliberately tampered token are denied. The first user can ask a numeric-result question, recover the saved answer without regenerating and ACK it; canonical local ledgers confirm `charged`, `completed` and `acknowledged`.
- [GitHub Actions 40506514262 — SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40506514262): local Auth/password/JWT, PC1/PC3/PC4 PostgreSQL and Edge integration, synthetic provider, plus original isolated Chromium UI.
- [GitHub Actions 40511989615 — SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40511989615): **genuine Supabase JS client in Chromium** signs in with a password against official disposable GoTrue; signed JWT reaches the candidate PC3 Edge and canonical local PostgreSQL. The SAME existing Tutor restores a saved PC4 reply and ACKs it, then sends a new typed question with one synthetic provider dispatch and verified `charged/completed/acknowledged` ledger. Real browser logout invalidates the old JWT; a fresh login can idempotently ACK. The other account cannot see the old response. No real host, account, app DB or paid provider is touched.
- **Scope honesty:** the Chromium fixture is not the full production login shell. Its `status` and `practice_visibility` UI preflights are explicitly stubbed (and owner-gated by the local GoTrue `/user`); the provider-generating PC3/PC4 path is NOT stubbed. An end-to-end deployed release with genuine feature-status/visibility checks still requires separate acceptance.

## Evidence / scope
- [GitHub Actions 40495018747 — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40495018747): real unified Tutor + beta JS in isolated Chromium; full page reload recovers pending response with the same UUID; one message/ACK; no localStorage, account and attempt isolation, protected quiz, zero external network.
- [GitHub Actions 40495487593 — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40495487593): disposable PostgreSQL 17, actual candidate RPCs, Deno candidate, five read-only snapshots of canonical shared money/quota RPCs, and synthetic OpenAI result; 1 successful provider result, saved reply, lost HTTP, reload recovery and ACK; separate simulated ambiguous provider status preserves `money=unknown`, `quota=released`, `receipt=unknown`, forbids double call.
- All isolated PC3/PC4 regression steps and browser paths passed on commit `62784e19b41aa02a6e2b8945e64055d79ce77553`. The browser signs in using the actual pinned `@supabase/supabase-js@2.57.0`, pinned GoTrue v2.197.0, and disposable PostgreSQL; real money is never touched.
- **Branch preservation checkpoint:** `main` has gained parallel Economics/Exam Prep changes (including `index.html`) since the last branch synchronization. Reconcile and rerun full release gates before any eventual merge. Do not replace `main` or discard those commits.
- Source is not deployed, no migration applied, no paid model request, no modification to real learner data, scores, localStorage, deployed Edge or existing budget.

## Cross-workflow regression reconciliation (not a release PASS)
- The dedicated isolated Practice AI pipeline is **SUCCESS** at [run 40511989615](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/40511989615). This is **not** a claim that every PR check is green.
- Seven other PR checks failed in the same code round: `iClub clean Core release gate`, `P0-02 release regression`, `Practice Topic Choice Premium QA`, `Mathematics Practice v2 Global QA`, `AI-2 Practice AI Foundation`, `Global AI Learner Shell v1`, `Global AI Contextual Conversations v1`.
- At least five legacy checks assert stale HTML asset-version tokens, e.g. `ptopic1-reviewback1`, `reviewback1-postpublish1`, `global-ai-ui.css?v=globalaichat1`, `global-ai-ui.js?v=globalaichat1`; these tokens are **also absent in current `main`**. `practice-ai-ui.js?v=ai2review1` remains present in both. The cross-branch `app.js` blob SHA is identical: `97b4a4868d32367397f8b21b5bf9869b71ccef9c`. The PR changes only two existing Tutor script cache tags in `index.html`; it did not edit the legacy Practice router or legacy Global AI.
- These failures therefore do **not** prove a new failure of the candidate Tutor; equally, they cannot be dismissed as harmless without independent baseline qualification. Review/reconcile outdated CI contracts in their own scope; **do not change main's cache pins or disable gates solely to turn this PR green**.
- Meanwhile, `main` has newer Economics, Exam Prep and `index.html` commits: before any merge, resolve the actual branch divergence and rerun release-wide checks. This was deliberately **not** attempted as part of the isolated Auth work.

## Release blockers (do not silently mark complete)
1. Review crash windows for **in-flight provider dispatch**, unconfirmed settlement, lease expiry, unknown upstream bill and delayed accounting; source-authoritative reconciliation/retention job is not yet operational.
2. **Passed in isolation:** real GoTrue JWT, real Supabase JS browser sign-in, unified Tutor reply recovery and newly typed question through the actual candidate Edge / local canonical RPCs. **Still pending:** full production-shell/real feature-status and `practice_visibility` integration; isolated browser preflights are not proof of the deployed product. No Preview or hosted Supabase tests are currently required for these isolated checks.
3. Source governance and versioned academic cards for specific Mathematics mistakes; never infer explanations from an unsupported source.
4. Separate architect sign-off for any production Supabase migration, Edge deployment, beta entitlement or paid provider call. **Do not merge PR #366 as-is.**
