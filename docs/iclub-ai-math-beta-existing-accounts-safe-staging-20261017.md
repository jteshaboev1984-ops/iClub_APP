# Global iClub AI: existing Mathematics Exam Prep beta users — staging checkpoint

Date: 2026-10-17. Scope: three existing accounts in `math_as_p1_p5_beta_2026_09_01` only.

## Verified live facts (Supabase SELECT / metadata)

- Exactly **three** `private.exam_prep_beta_members` are active in `ai_assist` service mode and have active, unexpired `private.exam_prep_feature_entitlements` for Core+AI Assist.
- Three matching `exam_prep_controlled_beta_v1` consents are granted. **These are not Global AI opt-in consent**.
- All three `auth.users` accounts are anonymous and have no email. This means a distinct Vercel Preview origin cannot silently sign them in again.
- Other removed candidate rows are **excluded**. Matching uses authorized cohort/membership/entitlement/consent, never unverified display names.
- The new operator-only Global QA registry `private.iclub_ai_qa_global_operator_v1` now contains exactly three staged rows with **enabled=false for all**. The only live change in this checkpoint was insertion of these three disabled candidate records into the isolated private registry. No Exam Prep membership, grade, progress, question, Practice, Tour, localStorage, or authorization row was updated.
- Financial control `private.iclub_ai_paid_canary_control_v1.enabled=false`, ledger has **zero rows**, the main Global AI UI/gateway/generation remain OFF and kill_switch ON.
- The paid canary's current ledger has a single fixed `pilot_operator` actor; its daily actor limit is **not** independently metered per learner. Therefore it cannot be used to claim three separate $0.05 daily learner budgets. Keep money OFF pending audited per-user accounting.
- Existing Mathematics Exam Prep Tutor is untouched; its service access must not be equated to Global AI authorization.

## QA code already fixed (no production deployment)

The QA-only `qa/ai-v21-connected-chat-bridge.js` no longer calls `/auth/v1/signup` or creates any anonymous accounts. It attempts only to reuse an already available signed-in account session upon an explicit tap, and it rejects the QA fixture's synthetic identity/session. It never copies/persists access tokens into localStorage or asks for passwords.

Commits: `3b7d2578` (remove signup) and `162af43f` (regression). GitHub run `39057565369` concluded **success**, with all three QA jobs passed.

## Real-use blockers and safe next step

1. An anonymous-authenticated learner session exists only on that learner's actual iClub browser origin/device. The existing QA Preview uses a synthetic auth stub and cannot impersonate or import the learner's token. A meaningful real-user trial needs an **origin-safe, production-shell opt-in adapter** that uses the app's existing authenticated session, without token transfer, new Auth signups or silently touching academic records.
2. Add an explicit, separately worded Global AI first-use opt-in before any user interaction is forwarded. Screen blackout remains mandatory in live Practice/Tour/Exam Prep assessments.
3. The backend must re-check active Math beta membership, entitlement, current consent, exact screen and source for every request, not merely assume membership from the newly staged QA table. If any of these fails, deny the route.
4. Fix per-user financial attribution in a separately tested additive migration before offering paid pilot responses to all three. Retain the total $1/$0.50-day/$0.05-user-day/$0.01-hold/2-concurrent ceilings and both independent OFF switches until verified.
5. Only after the preceding gates pass, allow a tightly limited paid call, confirm accounting and output, and disable both switches again. No public, tariff, Mentor Care or mass cohort enablement.

Status: **three candidates staged, none admitted or billed, no real model response claimed, production Global AI OFF**.
