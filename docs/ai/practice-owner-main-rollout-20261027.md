# iClub AI Tutor — owner-only main rollout (2026-10-27)

This is a direct-main production release plan, not a hosted Preview. Never publish to all learners or use real users' accounts for test setup.

## Staged checks

1. Merge only after the isolated SQL+GoTrue+Chromium+canonical quota/budget jobs are green, and qualify existing unrelated legacy CI failures against current main. Do not discard Economics/Exam Prep updates.
2. Apply the reviewed additive production migration only with all new flags OFF. It creates service-only PC1/PC3/PC4 storage and grants. No scores, user data, attempts, source content, localStorage, AI usage or existing budget changes.
3. Deploy two unique Edge slugs, `iclub-ai-practice-prepared` and `iclub-ai-practice-freeform`, separately, with JWT verification and server-only provider credentials. Existing AI, Tour and Exam Prep Edge slugs are never replaced.
4. Require explicit owner confirmation of the actual signed-in iClub Auth account. `private.iclub_ai_practice_context_v1_control.owner_user_id` defaults NULL: no guessing or beta-wide activation.
5. Owner can inspect real finalized main Practice V4 attempts only. `error_enabled` must remain FALSE: no subject question-specific diagnosis. Other learners, in-progress assessment, stale/foreign attempts must be denied.
6. Full stack owner activation requires approved `owner_user_id`, separate PC1, PC4, PC3 flags, current consent, unchanged canonical $5 lifetime/50,000 micro-USD request/750,000 learner caps, 2 parallel max, original quota. No extra spend pool or model.
7. Run one owner-authorized funded response on real finalized scores only; verify exact Auth/attempt, receipt ACK and canonical billing. Do not claim funded success from synthetic CI.
8. Emergency shutdown PC3=false first, then PC1 to block new learner access; keep server accounting cleanup available for unknown costs. Do not delete receipts or reset budgets/learners.

## Independent kill switches (defaults)

- `private.iclub_ai_practice_context_v1_control`: `enabled=false`, `owner_user_id=NULL`, `error_enabled=false`.
- `private.iclub_ai_practice_receipt_v1_control`: `enabled=false`.
- `private.iclub_ai_practice_freeform_pc3_control`: `enabled=false`.

### Non-negotiable release limitations

The browser's `status` and `practice_visibility` preflights were partially stubbed in isolated CI; verify authentic access before funded production test. Existing Exam Prep 243 topic cards are not approved Practice per-question diagnosis cards. PR #366 stays a development reference; this main-lineage branch cherry-picks only its reviewed files, preserving all current main changes.
