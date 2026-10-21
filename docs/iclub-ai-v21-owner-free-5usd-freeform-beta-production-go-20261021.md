# iClub Global AI v2.1 — owner-approved $5 consent-only freeform pilot GO
**Production release: 2026-10-21 · controlled owner beta · no expansion of old cohort**

## Scope authorized in chat
Owner explicitly approved Free participation for every consented beta member and a hard **$5 total pilot** spend cap. This is NOT a paid subscription or tariff change. Free-form is supported **initially only for verified General Help facts about using the iClub app**. Academic free-form requests remain source-gated; new Chemistry/Economics drafts are not silently released.

## Actual production rollout — completed
- GitHub production `main` fast-forwarded atomically from `482c1b79d2dee10d9da751f5e8f008cf3777087d` to `59815b31316dd2fe4b5c9bd5c0a73477e5a1cd9b`, **exactly 3 files**: `iclub-ai-v21-beta-client.js`, `iclub-ai-v21-ui.js`, and cache-busting versions of those 2 scripts in `index.html`. Everything else is identical. Vercel latest production SHA `59815...` status **READY**.
- Created independent Supabase Edge `iclub-ai-v21-freeform-beta`, version **3**, status **ACTIVE**, `verify_jwt=true`, including browser `x-client-info` CORS support. The old `iclub-ai-v21-prepared` v5 and Math Tutor remain unchanged.
- Added `consented_beta_v21` to the existing read-only rollout authority and the **single** Global AI rollout CHECK constraint. No broadened `all` or product canary membership.
- Installed stronger `finish_iclub_ai_v21_freeform_quota_v1`: before consuming 3 student usage units and approving a response it rechecks valid consent, latest global money kill switch, payment settlement and protected/active exams. A revoked/deauthorized response returns the student units and never publishes grades or answers.
- Installed owner-approved `private.iclub_ai_v21_freeform_budget_control` earlier with one aggregate lifetime $5 cap (5,000,000 microUSD), 50,000 microUSD per-request exposure ($0.05), 750,000 microUSD per student, maximum 2 concurrent reservations; full unknown liability retained. Model `gpt-5.4-mini`; source bundle 13/locale from 39 reviewed General Help texts.
- Owner-approved activation `iclub_ai_v21_freeform_beta_owner_5usd_GO_ACTIVATION_20261021.sql` was applied after full QA PASS and latest production READY with strict zero-spend and original-111 baseline preflight. Production state now `global_ai_rollout_mode='consented_beta_v21'`, UI + gateway enabled, global kill switch OFF; **old** `generation_enabled=false` throughout. Separate new money pilot `enabled=true`.

## Recorded independent acceptance
- [Full isolated PostgreSQL + Deno + Chromium + protected Math regression PASS, source SHA 6adb6e63c3febb696f18f974901a688571844a22](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39580609934)
- [Current-main compatibility / identical original prepared+Math route PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39580246424)
- Strict atomic activation + kill switch both PASS in separate disposable PostgreSQL, including no-charge refund and preservation of synthetic old user data.
- Actual immediate Supabase SELECT after production GO: 3 registered beta users; exactly **1** consented, roll-out allowed and eligible; **2** without consent excluded; **0** false admissions; 3 approved General Help language bundles (EN/RU/UZ) valid.
- Existing admission: **111** original locale sources unchanged; new 210 locale drafts not released, new qbank release table still **empty**, academic delivery count **0**. Earlier single prepared-help delivery remains intact.
- New model pilot money ledger **0 rows**, quota holds **0 rows**, actual pilot spend **$0 at activation**.

## Hard boundaries maintained
Only the server can authorize a paid invocation. Student sessions cannot read the raw source bundle, alter budget ledger, bypass review, change exam grades, write to Core or increase spend. A free-form question in non-General academic context is **not** routed to this app Help model. No OpenAI key is embedded in a client file. OpenAI provider results are strictly checked for model/status/usage/allowed output, and an ambiguous provider bill keeps the full reserved liability. The server sends `store:false` and allows no model tools/browsing.

## Instant production stop
Approved kill-only SQL, preserving all budget receipts and student history:
`qa/live_candidate/iclub_ai_v21_freeform_beta_owner_5usd_KILL_SWITCH_20261021.sql`.
It atomically disables the new budget, returns UI to `off`, reenables global UI kill switch and hides the panel. Running this kill does not reset practice scores, personal data, historical prepared answers or paid provider charges.

## Remaining positive beta E2E evidence
**Not yet verified**: no real consenting learner has submitted a General Help free-form model question since GO. A green synthetic test is not a claim of a real, source-grounded answer; OpenAI credential readiness at this exact time was not introspected. A prior unrelated paid canary had one settled charge, but that does not replace the live learner test.

**Valid real learner test (without changing grades):** the already-consented beta student opens the newly visible iClub AI icon from Home/Profile and asks in their natural language, e.g. «Как найти поддержку в приложении iClub?» (at least 8 chars). The route must return a NEW model-generated General Help response, never a ready-made navigation string; one generated reply consumes 3 units in the existing 5-hour beta window, and the budget should record a bounded provider charge. If unsupported, it must refuse and return the student units while preserving paid liability. Then recheck real ledger/allowed cohorts, exam blackout and no Core writes.

**No further beta enrollment, academic source publication, tariff change or full subject Tutor enablement authorized by this implementation.**
