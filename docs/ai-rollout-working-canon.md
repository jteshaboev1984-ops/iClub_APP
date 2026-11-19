# TEMPORARY — iClub AI Rollout Working Canon

Status: temporary implementation canon.  
Created: 2026-09-25.  
Delete this file after AI-1 through AI-8 are completed and the final permanent AI architecture/release documentation supersedes it.

## Non-negotiable rules

- Existing live user data, localStorage, Practice/Tour history, ratings, certificates and Exam Prep evidence must not be reset, rewritten or silently recalculated.
- Deterministic/server logic remains the academic source of truth. AI explains and personalizes; it does not award mastery, placement, readiness, marks, progression, grades or mentor decisions.
- AI failure must never break Core learning flows.
- AI provider credentials remain server-side only.
- All learner-facing AI is feature/capability gated, auditable and kill-switchable.
- RU/UZ/EN must preserve the same academic facts.
- Video content is not treated as known unless a future governed transcript/content map exists.

## Eight implementation stages

### AI-1 — Exam Prep: progress + weekly plan
Connect real model generation to the existing Exam Prep AI safety boundary, but keep production learner generation disabled until release gates are satisfied.

Initial provider-enabled interactions only:
- progress_summary
- weekly_plan_narration

Use existing approved P1/P5 progress and weekly-plan source cards plus server-built deterministic context. No academic writes.

### AI-2 — Practice: post-answer and post-result explanation
Add optional AI only after server-side Practice checking. AI may explain the completed answer, approved principle/topic and server-approved next action.

Practice is a learning mode, so post-submit explanation may be richer than Tour review. Core Practice must work identically with AI OFF.

### AI-3 — Deterministic diagnostic AI
Where question/answer diagnostic mapping exists, AI may explain the mapped misconception and repeated-error pattern.

Where deterministic mapping does not exist, AI must not invent a misconception. It may give a bounded topic/principle explanation only.

### AI-4 — Approved source + diagnostic coverage expansion
Expand governed source cards and deterministic diagnostic mappings subject by subject.

Priority order:
1. Economics
2. Chemistry
3. Biology
4. Mathematics
5. Computer Science
6. Additional subjects after their own source/content audit

### AI-5 — Tour archive AI only
AI is never available for an active Tour and is not available merely because a learner submitted.

AI may use a Tour only after the server says the archive/review is open. The AI input is restricted to the learner-safe archived review payload already authorized for that user.

Allowed after archive opens:
- explain an archived wrong answer;
- explain the governing principle;
- group weaknesses across already-open archived Tours;
- explain repeated errors only when supported by deterministic mappings;
- recommend an existing Practice/topic action.

Forbidden:
- any active/future/closed-review Tour question access;
- hints, option elimination or solution help during an active/locked Tour;
- changing score, percent, rating, certificate, violations or attempt history;
- recalculating historical results;
- reading the full private question bank or answer-key store.

### AI-6 — Subject-source assistant
Provide subject-level Q&A only from approved subject sources.

This can coexist beside Lessons, but the assistant must not claim it knows what a specific video contains. If the needed approved source is missing, use no_source/fallback or offer the mentor route.

### AI-7 — Video AI (deferred)
Do not connect contextual AI to video yet.

A future release requires a governed mapping such as lesson -> transcript/content -> section/timestamp -> approved source references. Until then, no "explain minute 03:42", video summary or claims about what the teacher said.

Allowed interim UX:
- ask a question about the subject using approved subject sources;
- suggest contacting the subject mentor.

### AI-8 — Home/Profile study coach
Only after a common server-owned cross-subject next-actions contract exists.

The server decides priorities/actions from canonical learning data. AI only explains those priorities and progress in learner-friendly language; AI does not invent the study program.

## Runtime checkpoint — 2026-11-19 (supersedes historical execution point below)

Verified against GitHub `main` `74e291b0fba989084387a6fe137871db07f10fbd` and SELECT-only Supabase state. This is a **state snapshot**, not a product-rule change or release authorization. Check [Issue #412](https://github.com/jteshaboev1984-ops/iClub_APP/issues/412) for later actual SHA, approval and implementation progress.

- Existing `iclub-ai-v21-ui.js` and `iclub-ai-v21-beta-client.js` are loaded by `index.html`; existing Mathematics Exam Prep also has separate contextual `exam-prep-ai-ui.js`. Do not add a competing new Tutor window. Preserve already-released Exam Prep AI.
- Global AI runtime: `ui_enabled=true`, `gateway_enabled=true`, `generation_enabled=false`; rollout `consented_beta_v21`. v2.1 prepared + beta routes ON, freeform generation OFF; academic provider OFF. One consent-enabled v2.1 beta account in current record (not a public rollout).
- Existing Exam Prep `generation_enabled=true` with three active feature entitlements and **243** runtime-allowed approved P1/P5 Tutor Cards. The old statement below that *all* production AI is OFF is **outdated**.
- General Practice AI policy `enabled=false` and `generation_enabled=false`; existing independent Practice-context gate ON but question-specific error explanations OFF. No silent general availability.
- Global all-route spend ceiling implementation exists but `enabled=false`. Do not increase paid route use or activate it before specific owner-approved ceilings/reconciliation. Existing Exam Prep generation remains as-is.
- Before broadening learner access, honor the open protected-content access hold in Issue #412 without publishing private reproduction steps. Existing Practice/Tour/Exam Prep history remains immutable.
- The next execution is **four small packages**, detailed in `docs/ai/ai-tutor-screen-actions-hybrid-v1.md`: (A) provider-free learner-context handoff, (B) targeted reliability/trace/privacy/cost readiness, (C) separately approved limited paid clarification beta, (D) quality-based subject expansion. This is an **implementation order**, not an order to enable features.
- Reuse reviewed prepared help, source-version binding, existing Edge/RPC contracts, and existing targeted CI. No mandatory vector DB/RAG, extra server, multi-agent layer, always-on streaming, paid judge or backup model until a concrete need is demonstrated.

## Historical execution point — originally written 2026-09-25; NOT current state

AI-1 engineering is complete: the Exam Prep provider adapter, server-side spend/concurrency admission, production-safe Edge deployment and funded provider quality acceptance are GREEN. The funded quality run passed 18/18 cases across P1/P5 and RU/UZ/EN. Real-learner activation remains intentionally on HOLD: production stays AI-off/shadow with zero AI entitlements until the Core real-beta evidence gate and a separate activation decision.

AI-2 is now in implementation. The first substep is a default-off Practice AI safety foundation with server-owned post-answer/result context, approved-source allowlisting, protected-assessment blackout and no model call or UI exposure yet.
