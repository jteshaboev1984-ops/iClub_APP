# Economics 9708 Exam Prep — P0 controlled release checklist (28 Oct 2026)

**Current state: HOLD.** Branch `fix/economics-exam-prep-answer-parity-p0-20261028`, PR #401 remains draft. Do not merge, change flags, apply migration or deploy to production until real authenticated acceptance is completed and explicitly approved.

## What has been verified

- Production baseline `main`: `a11599609d3e3f8fa153efd267e16110e186b4d6` at the preview creation time. Always re-check immediately before release.
- All 25 GitHub Actions workflows passed at `03b9245b3982ea5db5704c7fac40e866a72f443e`. The branch has since gained a *rollback-only* SQL file (not applied).
- Browser suite: 78/78 Chromium simulated-RPC cases, RU/UZ/EN, 390/1280, P1 diagnostic and P3 full paper, lost ACK, precommit failure, revoked read, concurrent answer, unsent answer, resumed draft, expired pending.
- Existing written-beta, Chemistry, Core and legacy preservation regression gates succeeded on that same commit.
- Vercel PREVIEW deployment `dpl_CWTCDtBVW1N6rsiNEbzWfw86r7Cc`, source SHA `03b9245b3982ea5db5704c7fac40e866a72f443e`, READY. Its preview URL is `https://i-club-khyi5dvma-jasurbeks-projects-c5451f97.vercel.app`. The project has Vercel SSO protection enabled for preview.
- Read-only production DB baseline: Economics MCQ attempts **3** (active **0**); existing written plans **1**, written plan items **12**, released written tasks **12**, held written tasks **32**. The five authorization changes are **not applied**.
- Candidate SQL migration compiled and passed transaction-rolled-back owner and cross-owner tests, but **this is not a real logged-in browser test**.

## Mandatory release blockers (do NOT skip)

1. Have a dedicated **authorized test learner** with permitted Economics 9708 access and Vercel Preview/SSO access. No real learner identity, tokens, account or stored learning data may be repurposed for QA.
2. Confirm whether preview uses production or isolated Supabase. Prefer isolated test backend; if a test account is deliberately used on production backend, get explicit permission for that specific account and scope beforehand.
3. In an authenticated browser, verify `login → Economics setup → P1 12-item check → choose and explicitly submit → refresh → previous/next → finish → results → study plan → mark studied → recheck`. Also test P3 30-item paper and an internet-interruption scenario, RU/UZ/EN with mobile and desktop views.
4. Verify a second account **cannot** see, modify or finish the first account's attempt, and losing Economics eligibility blocks active access while keeping owned finalized history readable.
5. Confirm the written P2/P4 limited beta, enrollment consent, written plan and completed records remain unchanged. Test the Math flow and the app entry route.
6. Check exact source SHA, the production branch, feature flags and complete GitHub Actions status again just before release.

## Changes to apply only after sign-off

1. Record a fresh DB row-count and feature-flag baseline without copying private student details. Preserve current production Vercel deployment ID and `main` SHA.
2. Apply ONLY `supabase/migrations/20261028194500_iclub_economics_native_mcq_active_access_parity_v1.sql` through the approved migration process. It alters five RPC bodies; no data/table mutation and no release flags.
3. Confirm the five RPCs now contain the current Economics beta guard and that authorized learner/session tests succeed; check ownership, deadline, duplicate submission and finalized-history access.
4. Merge approved PR into `main` and verify intended Vercel production build and source SHA. Do not deploy a separate feature branch to production, and do not modify Supabase beta cohorts or written releases as part of this P0.
5. Perform small controlled post-release smoke checks and inspect errors; check total MCQ/written counts to ensure nothing disappeared.

## Rollback if a problem occurs

- Stop broader rollout and preserve evidence of the error; do not reset a learner or clear localStorage.
- Restore the previous verified Vercel production deployment through the approved release rollback.
- If the new five RPC guards are the cause, use **manual review** of `supabase/rollback/20261028194500_iclub_economics_native_mcq_active_access_parity_v1_rollback.sql`. This file is a precise `pg_get_functiondef()` snapshot of all five production functions from **before** PR #401, captured 28 Oct 2026. Only restore if no newer migration has modified these functions. Avoid blindly rolling back unrelated changes.
- Verify again: authorized session, owner-only history, prior completed attempts, written plan records and unaffected Mathematics.
- Never DELETE/TRUNCATE attempts, users, progress, written plans, cohorts or study records. No localStorage reset.

## What is NOT yet verified

- Authenticated preview browser smoke end to end, actual eligibility switching across accounts, and the real on-server MCQ mutation after deployment.
- Preview response HTML and protected routes were not fetched by the current automation client due to Vercel SSO protection; READY plus build logs establishes successful build, not full rendered UI functionality.
- Production release is **not** approved or performed.
