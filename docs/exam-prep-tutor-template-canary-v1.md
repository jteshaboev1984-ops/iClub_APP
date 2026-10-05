# Exam Prep AI Tutor — Provider-Free Tutor Template Canary v1

Status: IMPLEMENTATION — CANARY DEFAULT OFF
Date: 2026-10-05
Scope: existing three real beta learners only

## Product behavior

For an eligible controlled-beta learner on a topic screen:

1. **Explain this topic** first returns the reviewed iClub Tutor Card for the exact component + skill + locale.
2. No external provider call is made for that first explanation.
3. The preset follow-ups are also provider-free:
   - Explain more simply → simple_explanation
   - Explain it differently → alternative_explanation
   - What should I focus on? → focus_explanation
4. A learner-written follow-up question remains provider-backed, bounded and source/context locked.
5. If the Tutor Template canary is OFF or an exact runtime card cannot be read, the existing provider-backed theory path continues unchanged.

## Safety boundary

The existing guard still runs before any Tutor Template is returned.

Therefore the canary preserves:
- AI entitlement gating;
- controlled-beta scope;
- active-assessment blackout;
- component validation;
- locale validation;
- skill mapping requirement;
- approved grounding source requirement;
- deterministic context binding;
- audit logging;
- academic_state_changed=false.

## Separate kill switch

The canary adds private.exam_prep_ai_tutor_template_policy.

Default:
- template_canary_enabled=false;
- preset_followups_enabled=true;
- cohort_key=math_as_p1_p5_beta_2026_09_01.

The Edge Function checks the service-only canary RPC for the current user.

The RPC returns enabled=true only when all are true:
- template canary flag ON;
- feature rollout controlled_beta;
- Core ON;
- AI ON;
- Mentor OFF;
- global kill switch OFF;
- user is an active ai_assist member of the exact beta cohort;
- valid beta consent exists;
- active Core + AI entitlement exists;
- Mentor entitlement is false;
- user is not synthetic.

## Tutor Template response contract

Mode:
verified_template

Main response:
- generated=false
- academic_state_changed=false
- provider tokens/cost absent
- thread_eligible may be true when bounded follow-up is available

Preset template follow-up:
- mode=verified_template
- generated=false
- same component/skill/locale
- same deterministic snapshot hash
- same approved source-card binding
- no provider reservation/call

Learner-written follow-up:
- interaction=context_followup
- followup_mode=question
- existing provider budget/concurrency/timeout/safety validation applies
- maximum follow-up turns remains 2

## Thread compatibility

A verified_template audit row is a valid thread parent.

This is required so:
- a learner can open a curated explanation;
- choose a provider-free preset clarification;
- then ask one bounded free-text question if still unclear.

The existing output-hash and context-hash binding remains mandatory between turns.

## UI

The topic action becomes learner-accurate:
- RU: Объяснить эту тему
- UZ: Bu mavzuni tushuntirish
- EN: Explain this topic

The iClub AI Tutor mark and contextual placement remain.

The curated root explanation uses a source note that refers only to iClub learning material, while generated/personalized explanations keep the existing note that can refer to learner work.

## Activation sequence

1. Merge code with canary default OFF.
2. Apply policy migration with flag OFF.
3. Deploy Edge Function.
4. Confirm frontend can consume verified_template root/follow-up responses.
5. Run production read-only preflight.
6. Execute the separate activation release package.
7. Smoke the existing 3 beta learners only.
8. Compare provider-call/audit behavior before considering any wider rollout.

## Immediate fallback

Running the reversion release package sets template_canary_enabled=false.

No Edge redeploy is required to return immediately to the existing provider-backed theory path.
