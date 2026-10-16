# iClub AI v2.1 — three-stage REAL provider launch finance checkpoint

**Date:** 16 October 2026
**Architect direction:** authorizes preparations for a real paid model; avoid uncontrolled costs and think three steps ahead. **No monetary cap amount specified yet**, therefore no paid request is authorized to cross the money gate. Production and learner data are unchanged.

## Step 1 — before the first charge (hard admission gates)

1. Explicit owner-confirmed absolute USD amount for the first funded canary.
2. Separately verified allowed cohort (prefer a synthetic controlled user without academic writes; no public rollout), independent existing Mathematics Exam Prep untouched.
3. Global AI candidate backend still requires **24 core RPCs + exact 25th Practice resolver** and a separately reviewed Edge deployment; the live database does not have this P9 release. DO NOT run unreviewed drafts on production.
4. Authenticated, user-bound, finalized current screen; deny active Practice/Tour/exams, foreign account or unfinished Practice.
5. For educational answers, exact original topic source + locale + version/hash + copyright/editorial approval. Unknown source says **«В разработке»**, no model fallback. For initial real-cost canary a narrowly approved **public app-help** question can be used without disclosing any learner history, provided its source/route is independently reviewed.
6. Real provider secret remains server-only and never appears in Preview/frontend or project documentation.
7. **Atomic provider monetary hold** plus learner quota/first delivery claim occurs before any HTTP call; all money caps default **zero/disabled**.

## Step 2 — during provider generation (maximum exposure, no replay)

- Separate lifetime (absolute), UTC daily, per-user UTC daily, per-request and max two in-flight caps; all live/synthetic reserved, dispatched and unknown invoices count at their **full worst-case ceiling**.
- No client model selection, never send raw profiles, scores, session IDs, answer keys, unpublished Tours or chat-history archives.
- Pin provider, price revision, response size, input/source size, timeout, `store:false`; deny tool use and unsafe escalation. No automatic HTTP retry after uncertain dispatch. Kill switch should stop new calls instantly.
- Preserve independent existing `exam-prep-ai` / `practice-ai` provider leases and original Mathematics Tutor.
- Reject failures/unsupported language or output before learner delivery; retain real monetary cost if a provider was called, and release learner quota if no validated answer was delivered.

## Step 3 — after generation and before broadening

- Verify provider-reported usage, calculate bill using pinned input/output token rates and reconcile to the reserve; unknown invoice keeps full ceiling (NEVER automatically refund).
- Verify privacy and math/source grounding; no academic-state writes.
- Watch per-day/user/provider usage, failures and abuse, then inspect the first funded answers before any expansion from a tiny canary to more users.
- Independent stop/rollback: disable new Global AI without disabling Core, old Practice AI, or the existing Mathematics Exam Prep Tutor.
- A beta expansion or commercial plan activation remains a separate owner decision.

## Exact cost reference and suggested *unapproved* envelope

The current repository's existing Global AI candidate pins **`gpt-5.6-luna`** at **$0.20 / 1 million input tokens** and **$1.20 / 1 million output tokens**, max output 220 tokens. This is existing source code metadata, not a confirmed available provider account or funded test.

Illustrative normal text request: 2,000 input + 220 output tokens costs approximately **$0.000664** before rounding and other billable features. This example **is not** a maximum nor a provider invoice. A conservative **$0.01 hard reserved ceiling per call** affords a substantial buffer, but the actual final input token bound and selected model pricing must be checked before activation.

**Recommended first real-money acceptance cap for owner confirmation** (no activation until confirmation):
- **Total lifetime for the funded pilot: US$1.00** (absolute global backstop, never auto-reset).
- **Global UTC day: US$0.50**, per learner **US$0.05/day**.
- **US$0.01/request reserved**, max **2 concurrent**, with approval required for any higher amount.
- Student beta release still OFF; first paid provider request ideally performed as one authorized tiny canary, not through a public endpoint.

Current OpenAI sources: https://developers.openai.com/api/docs/pricing and https://help.openai.com/en/articles/9186755-managing-projects-in-the-api-platform . A project dashboard budget/alert may be **soft** rather than a hard kill limit; the app must enforce its own atomic limits. Provider quotes/pricing and the account-level hard cap require re-verification immediately before spending.

## Implemented in protected QA branch only

- `qa/sql_drafts/iclub_ai_v21_provider_spend_UNAPPLIED.sql`: added disabled-by-default UTC global daily + per-user daily + max-two-concurrent financial constraints alongside prior lifetime and per-request controls. SQL remains local-scratch-only and unapplied.
- `qa/sql_drafts/iclub_ai_v21_provider_spend_local_pg.psql`: negative check for each new daily cap, old unknown-bill and no-double-spend cases, all executed with rollback.
- `qa/ai-layer-v21-provider-spend-sql.test.cjs`: explicit zero-default and limit contract.
- `.github/workflows/iclub-ai-real-preview-qa.yml`: finance SQL test runs against a brand-new disposable localhost PostgreSQL, not Supabase.

**Test evidence:** GitHub Actions [38907746572](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38907746572) — 3/3 GREEN. No paid provider request, real user permission change, Supabase SQL execution, deployment or money spent.

**State:** `COST_GATE_PENDING_OWNER_LIMIT`. This is significant progress toward the funded canary, not evidence of release readiness. Owner must confirm actual money ceiling before real provider calls, and exact runtime/rights/canary deployment remain separately gated.
