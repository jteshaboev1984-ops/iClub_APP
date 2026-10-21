# iClub Global AI v2.1 — free-form model answers for consenting beta students
**21 October 2026 · revised product priority · existing QA branch ONLY**
**Status: QA candidate; live model generation remains disabled.**

## Product behavior explicitly requested by owner
Learner opens iClub AI and writes a **free-form question in their own words**; a provider model creates a NEW explanation specific to that question. An unrelated pre-authored card must NOT be returned merely because it is available or cheaper.

The model remains **source-grounded** and scoped to the actual authenticated learner's authorized screen/subject/source. For questions unsupported by verified local course/source materials it must refuse rather than use arbitrary external knowledge. AI is non-authoritative: student answers, grades, progress, eligibility, tests and user localStorage are unchanged.

### User experience / route
1. The existing chat composer in production UI `global-ai-ui.js` already includes a free-form textarea (max 2000 chars) and a send action. On current production it submits `user_text`, but the active `iclub-ai-v21-prepared` Edge gateway accepts only predefined `prompt_key` and has **no model implementation**. This gap cannot be solved by flipping `generation_enabled` on.
2. The universal **QA** routing core `qa/ai-layer-v21-edge-request.cjs` already distinguishes `promptKey` → prepared (1 unit) from `question` → generated (3 units). Exact locale, subject/context authorization, protected assessment, source release and entitlement are checked by trusted services. English/Russian/Uzbek free-text is not silently replaced by a generic prepared answer.
3. New `qa/ai-layer-v21-freeform-generation.cjs` makes a strict provider adapter for an independently configured **synthetic mock**. It accepts a question plus server-verified source text/source checksum/subject/locale and sends the natural-language question to an injected provider with no tools, no external web access, `store:false`, fixed output cap, and source-limited instructions. A missing trusted source, unsupported language or changed context denies before contacting the mock model.
4. New `qa/ai-layer-v21-freeform-generation.test.cjs` checks new-question generation, exact model request, no-source refusal, source hash drift, assessment lock, wrong subject, unsafe HTML, malformed provider response, provider outage, language routing and zero calls on authorization failure. `qa/ai-layer-v21-edge-request.test.cjs` additionally verifies the whole synthetic sequence user → authenticated scope → admitted source → atomic learner quota (3) → independent money reservation/dispatch → mock provider response → final checks/delivery and that no-source frees learner quota but preserves possible provider liability.
5. The authorized subject/surface/topic now follow the **server** from `ContentHandoffGate`; the last context validation includes those fields. The learner cannot choose the source via prompt.

### What is NOT yet live
- Actual production database `private.iclub_ai_v21_beta_control.generation_enabled=false`, academic policy `provider_enabled=false`.
- Current beta Edge `iclub-ai-v21-prepared` **does not accept free-form prompts as model requests**. Its `status.preparedOnly=true` and `providerEnabled=false` are correct.
- Production `private.iclub_ai_v21_provider_spend_control` and provider leases are **not installed**; QA budget tables explicitly reject application outside disposable scratch PostgreSQL.
- Existing `iclub-ai-paid-canary` Edge is operator-only, uses a fixed app-support question, and must NOT be repurposed into a learner-general model endpoint.
- New 210 academic source locales remain unpublished without valid independent review receipts/owner release records. The existing old 111 have older closed beta admission and only a subset is reachable via current Practice pools.
- Per current Master Plan, Free plan generation is blocked. A beta-only exception for Free learners is a separate explicit **product eligibility** decision and must not covertly change tariff policy. Free-form is not the same as Free tier.
- No real OpenAI/LLM paid requests or model keys were used in this QA step; semantic accuracy of actual model replies cannot be claimed from synthetic outputs.

### Production GO checklist (no shortcuts)
A. Exact consented cohort and beta test generation eligibility approved; do NOT infer this from registration alone.
B. Owner chooses a **maximum real-money lifetime cap** and per-request cap; independently verify deployed model pricing/token ceiling and funded operator credential (server only).
C. Bind a fresh versioned, publishable P4 source with rights/locales/academic signoffs, or separately approved exact guidance; **no fallback** to unreviewed 210.
D. Add provider-spend atomic hold/dispatch/settlement and idempotent recovery with strict fail-closed behavior on ambiguous bills, concurrent calls, revoked access, and app timeout.
E. Deploy a single formally reviewed student Edge route and modify only its UI transport binding to send a validated `question`. Do not edit legacy Math Tutor/Exam Prep, content, grades or learner data.
F. One consenting real beta learner asks a free-form question against published material after completing a permitted learning step; verify received NEW source-grounded answer, EN/RU/UZ route, usage weight 3 (when entitled), provider debit ≤ cap, immutable grade/progress, and no answer on active assessment. Then expand cautiously.

**Owner action still required before funded pilot:** select beta eligibility and total real-model spend cap. Until confirmed, retain generation OFF and all current production settings.


## QA acceptance and live readback
- [Full independent QA run 39559491882 — SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39559491882). Tested code SHA `9d8ace048ca4f52185d0b943a24aaa8715c11a25`. Includes the QA-only freeform provider adapter tests and existing Edge mock end-to-end free-text route alongside protected Chromium/PostgreSQL/Math regressions.
- A production Supabase SELECT **after testing** confirms `generation_enabled=false`, academic `provider_enabled=false`, no live v2 money registry, 111 existing eligible source locales, 0 new qbank releases, 0 real academic deliveries.
- Production Vercel remains `READY` on previous source SHA `482c1b79d2dee10d9da751f5e8f008cf3777087d`.
- **Actual live generated model calls performed during this change: 0.** Synthetic provider responses do not constitute a user-facing real generative AI launch.
