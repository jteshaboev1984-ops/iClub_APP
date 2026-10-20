# iClub AI v2.1 — CLOSED academic beta go-live (20 October 2026)

**Owner decision:** enable previously staged original-iClub Chemistry and Economics explanations in the existing controlled beta NOW. Independent academic/rights/language editorial approvals are a future product workflow and must NOT be falsely marked as granted.

## Release and scope

- **111 locale cards** representing **37 exact questions**: Chemistry 33 × RU/UZ/EN (99), Economics 4 × RU/UZ/EN (12).
- Already staged in `private.iclub_ai_v21_academic_sources` and still `published=false`, `revoked=true`, all four reviewer flags `false`, `approved_at=NULL`. These fields continue to mean **not independently editorially signed**.
- A **separate reversible owner-beta allowlist** is `private.iclub_ai_v21_owner_beta_source_releases` (111 versioned entries). `private.iclub_ai_v21_source_admitted_v1` now accepts either the strict future fully reviewed publication OR this separately owner-approved closed beta when the original legacy card still matches its `approved/original_iclub` evidence. Exact `source_card_key`, version, text hash, current target question hash, question publication status and RU/UZ/EN must match.
- `private.iclub_ai_v21_academic_policy.enabled=true`, **provider_enabled=false**. The existing verified-JWT Edge v5 routes to the same generic capabilities/delivery functions; no new subjects or hardcoded question IDs, no model calls.
- The **existing three preselected beta candidates** and **their own separate Global AI consent** remain mandatory. No other learner can receive academic content. A beta member without consent cannot retrieve the explanation, even if their Practice attempt was finalized and wrong.
- For Practice, the server derives the subject from the **real finalized V4 session**, validates its legacy attempt, current enrollment, exact wrong and actually answered question, ownership, no active protected assessment, current subscription entitlement where applicable, source integrity, replay ID and the shared prepared-answer quota.
- Tour archive and real per-lesson routes remain part of the generic architecture but receive **no extra owner-beta release** this time. The generic Study video page is a subject Telegram hub, NOT an actual lesson selector. Do not advertise academic lesson-specific answers there.

## What was deployed

1. `qa/live_candidate/iclub_ai_v21_owner_beta_admission_STAGE_OFF_20261020.sql` — created new private allowlist + service-only source admission, replaced only two generic academic functions, **left academic policy OFF** for independent QA.
2. `qa/live_candidate/iclub-ai-v21-owner-beta-release.test.cjs` — contract checks for unchanged rights, owner/finalization, target hashes, model-off, revocation and absence of fabricated editorial approval.
3. Current main + scratch PostgreSQL/Chromium passes at [run 39390564952](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39390564952) and [run 39390565020](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39390565020).
4. `qa/live_candidate/iclub_ai_v21_owner_beta_ACTIVATE_20261020.sql` — separate post-QA guarded change of **academic policy only** to ON. Supabase application succeeded.
5. Found real integration mismatch: the already published and visible Practice quick prompt `practice_after` was missing in the connected browser's local whitelist. Added precisely that key to the beta client, plus a permanent test that all seven visible premium quick prompts exist in both browser and Edge. Main change **only** `iclub-ai-v21-beta-client.js` and its script cache-version in `index.html`. User progress, Exam Prep, visual Option A and the AI panel remain unchanged.
6. **Immediate pause**: `qa/live_candidate/iclub_ai_v21_owner_beta_PAUSE_20261020.sql`. In an emergency the owner-beta sources are independently disabled and academic policy switched OFF; this **does not** delete source rows, learner history, question bank, quota history or Math Tutor.

## Confirmed live post-release facts

| Verification | State |
|---|---|
| Released in owner-specific private allowlist | 111 |
| Actual generic source resolver sees | 111 |
| False independent reviewer approvals | 0 |
| Academic beta server switch | ON |
| Paid academic provider | OFF |
| Existing original general Help | 39 (preserved) |
| Beta candidate count | 3 |
| Separately consenting beta accounts at last check | 1 |
| Successful real learner academic deliveries at last check | 0 |
| Direct academic delivery for `authenticated` SQL role | DENIED |
| Unknown account academic request | DENIED |
| Real finalized wrong-answer user without consent | DENIED |
| Math Tutor, Practice marks and current learner progress | UNCHANGED |

**Honest limitation:** The current consenting beta account has both Chemistry and Economics in its selected subjects but has not yet finalized an *incorrect* answer in the 37-source set. Until the real student does so, the **positive signed student E2E** cannot be claimed as confirmed; backend admission and QA fixture checks passed, however.

## Real beta acceptance flow (student's usual account and domain)

Open the iClub on the regular URL and stay signed in. The user must belong to the original three-person Global AI cohort and independently accept Global AI beta in **Profile** if not already done.

Go to **Study → Chemistry or Economics → regular Practice**, complete the test and open **Result → Mistake Review**. If the finalized attempt includes one of the **37 exact verified question IDs** and it was *answered incorrectly*, that row receives **«Объяснить ошибку» / «Xatoni tushuntirish» / «Explain the mistake»**. Press it: the already approved premium Option A AI panel should show that question's language-matched original iClub explanation. Prepared reply consumes one unit of the existing beta quota, no model call. Other questions **do not** show a misleading academic button.

Verify that correct/unanswered questions do not receive the button; opening an active exam remains protected, navigating accounts or screens never displays an old response, and grade/progress does not change. The previously published general Practice chip **«Как разобрать и исправить ошибки?»** must also work, independent of whether a particular question has an academic source.

If no exact-source mistake occurs in a particular Practice run, no academic button is **expected**; this is content coverage, not a network failure. Do not fabricate a test failure, reset user answers or override actual student results to force a demo.

## Scaling without per-subject releases

For the next question batch, the Content Manager uses the existing generic intake and real `question_id` plus all three localized original explanations. New rows remain unpublished until either independent editorial release OR a distinct explicit owner-controlled beta grant. No new Edge route, subject-specific JavaScript, tariff changes or data resets. The future editorial approvals are developed separately and will not retroactively assert that these owner-beta cards were human-reviewed.
