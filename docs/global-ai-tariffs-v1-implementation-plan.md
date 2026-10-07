# iClub Global AI + Free/Plus/Pro — implementation plan v1

Status: implementation branch foundation only.  
Source of product truth: `iClub_Global_AI_Tariffs_Implementation_Working_Doc_v1.0_2026-10-06.docx`.

## Production baseline before implementation

Verified before branch creation:

- GitHub `main`: `823ef7df6dabf08c1a5e616ffbdd33379d8cf14d`.
- Production users: 1,443.
- `public.user_subjects`: 2,044.
- Practice attempts: 901.
- Tour attempts: 365.
- Certificates: 157.
- Recommendations: 3,741.
- Ratings cache: 0.
- Mathematics Exam Prep rollout: `controlled_beta`.
- Exam Prep Core: ON.
- Exam Prep AI: ON for the governed beta path.
- Mentor Care: OFF.
- Active Exam Prep entitlements: 3 Core / 3 AI / 0 Mentor Care.
- Existing Exam Prep AI policy: `max_daily_requests=30`.
- Existing provider safety ceiling: `max_provider_request_cost_usd=0.0100`.

These values are a baseline only. Re-check before every production promotion.

## Non-negotiable invariants

1. No existing learner progress/history row is deleted, rewritten or recalculated by tariff work.
2. Academic correctness, mastery, progression, readiness, ranking and certificate rules never branch on plan name.
3. Global AI is text-only in v1. No navigation, submission, plan mutation or other agent action.
4. Protected assessment blocks prepared/cache/model routes before an answer can be produced.
5. Unsupported academic subjects do not fall back to generic model knowledge.
6. Browser state never grants plan/AI authority.
7. Free/Plus/Pro limits use the same five-hour period model; the period starts on the first successful AI response.
8. Learner UI never exposes internal usage units, route type, cache/provider/source IDs or model cost.
9. If a requested route cannot be funded by the remaining allowance, the whole AI period is exhausted until reset. There is no learner-facing limited mode.
10. Downgrade pauses access only; it never destroys history.

## Implementation sequence

### Phase 0 — baseline and isolation
- Read-only production counts and flags.
- Dedicated implementation branch.
- No production mutations.

### Phase 1 — dormant server foundation
Create additive private server-owned primitives:
- Free / Plus / Pro plan policy.
- Monthly prices: Plus 35,000 UZS; Pro 50,000 UZS.
- Study slots: Free 1; Plus 3; Pro all available.
- Competitive slots: Free 1; Plus/Pro 2.
- AI usage policies:
  - Free: 3 prepared successful replies / 5h; generation disabled.
  - Plus: 9 hidden units / 5h.
  - Pro: 14 hidden units / 5h.
  - Prepared/contextual/deterministic/cache success: 1 hidden unit.
  - New live generation: 5 hidden units.
- Five-hour usage periods and idempotent reservations.
- Global AI runtime config defaults OFF with kill switch ON.
- Subject-readiness registry.
- Subscription entitlement table with **zero assignments** at foundation deployment.
- Safe public plan-catalog read API only; hidden usage economics remain service-only.
- Pre-activation rollback refuses to run once real subscription/usage data exists.

No UI and no current-user access change in this phase.

### Phase 2 — Global AI gateway, still dormant
Build a new server gateway that composes existing safe domain services rather than weakening them.

Required order:
1. authenticate;
2. resolve subscription capability;
3. resolve authoritative subject/surface;
4. protected-assessment guard;
5. subject readiness;
6. determine exact response route;
7. reserve hidden usage for that route;
8. prepared/deterministic/exact-cache response, or source-backed model generation;
9. structured/fact/source validation;
10. finalize usage only after a response is successfully deliverable;
11. operational audit.

The existing Mathematics Exam Prep AI path remains intact until the gateway is proven equivalent for that domain.

### Phase 3 — root-level AI shell behind UI flag
- One root overlay, lazy-loaded.
- Mobile bottom sheet / desktop side panel.
- No overlay on auth, legal/consent or payment confirmation.
- No overlap with bottom navigation, CTA, keyboard or exam controls.
- EN/RU/UZ layout tests at 320px and 390px.
- No plan counter in the chat header.

### Phase 4 — contextual quick prompts and subject threads
- Quick prompt tap sends immediately.
- Prepared and generated responses render identically.
- Separate visible thread per subject plus General iClub.
- Subject switch collapses the current chat.
- P1/P5 remain separate academic authority internally.
- Conversation storage is NOT promoted until bounded raw-chat retention is approved.

### Phase 5 — tariff/profile UX
- Profile gets `Тариф` entry before Performance Overview.
- Separate plan screen for Free / Plus / Pro.
- Pro labelled `Лучший выбор`.
- Natural upgrade surfaces only:
  - Profile → plan;
  - Free asks a generation-only question;
  - Free reaches 3 responses;
  - Plus exhausts and may see Pro.
- No checkout integration until payment provider is approved.

### Phase 6 — subject-access enforcement
BLOCKED until architect approves:
- subject-slot swap frequency/cooldown;
- exact existing-user grandfather/cutover rule.

When implemented:
- excess subjects become paused, never deleted;
- history returns on reactivation;
- no third Competitive slot is sold.

### Phase 7 — controlled canary
Before real learner promotion:
- Free / Plus / Pro synthetic matrix.
- five-hour reset tests;
- duplicate request tests;
- failure does not consume usage;
- no limited mode;
- exam block before prepared/cache/model;
- subject separation;
- AI OFF full app path;
- downgrade preservation;
- payment/cutover rollback;
- cost telemetry and worst-case model-cost check.

### Phase 8 — staged production rollout
Independent switches for:
- AI UI;
- gateway;
- generation;
- subject/interaction readiness;
- provider path.

Existing beta learners are not automatically downgraded or remapped without explicit architect approval.

## Open decisions that intentionally block later phases

- Subject slot swap/cooldown policy.
- Raw AI chat retention period and deletion policy.
- Existing-user grandfather/cutover.
- Payment provider and checkout.
- Exact Plus vs Pro model-context sizes.
- Annual billing.
- Whether/when Mentor Care becomes a separate commercial add-on.

None of these should be guessed during implementation.

## Phase 1 acceptance

Phase 1 may merge only if CI proves:

- defaults are dormant (`ui=false`, `gateway=false`, `generation=false`, `kill_switch=true`);
- no subscription row is assigned to existing users;
- Free generation cannot reserve usage;
- Free allows exactly 3 prepared successes per five-hour period;
- Plus accounting is 9 units with generation weight 5;
- Pro accounting is 14 units with generation weight 5;
- a route that does not fit remaining allowance exhausts the period and blocks even cheaper routes;
- failed first response does not start the five-hour clock;
- request IDs are idempotent and cannot double-charge;
- reset opens exactly one new period;
- internal usage weights are not exposed by the public plan catalog;
- authenticated/anon clients cannot read private ledgers or call accounting RPCs;
- rollback leaves no synthetic residue;
- migration contains no write to existing public learner-history tables.
