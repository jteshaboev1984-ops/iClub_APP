# iClub Global AI + tariffs — controlled canary readiness v1

Status: engineering readiness gate only. **No production activation.**

## What this gate proves

The stacked Free / Plus / Pro + Global AI + subject-access implementation is tested as one system before any real beta promotion.

The gate covers:

- every normal authenticated learner resolves to Free without a mass entitlement write;
- only three service-managed canaries may receive Free / Plus / Pro test overrides;
- non-canary learners remain outside Plans / Global AI / tariff subject enforcement;
- Global AI can be completely OFF without breaking the app contract;
- Free generated AI remains unavailable;
- Free permits exactly three successful prepared replies per five-hour period;
- the five-hour period starts only after a successful delivered response;
- a released/failed first response does not start the period;
- duplicate request IDs cannot double-charge usage;
- Plus generated accounting uses five hidden units;
- if a requested paid route cannot fit the remaining allowance, the whole period is exhausted — there is no learner-facing limited mode;
- protected assessment blocks before usage reservation;
- Free / Plus / Pro subject-selection boundaries work only for canaries;
- Pro study access covers all active subjects while Competitive remains separately selected;
- downgrade changes capability without deleting subject-slot state or learner evidence;
- all test state rolls back without residue.

## Current HOLD before real Global AI generation canary

Prepared/contextual Global iClub AI is structurally ready for controlled canary testing.

**Live Global AI generation is intentionally NOT ready yet.**

`supabase/functions/global-ai/index.ts` still contains the explicit boundary:

`generation_adapter_not_promoted`

That is correct at this stage. Plus/Pro free-form requests must not be promoted merely because tariff accounting exists.

Before real generated-answer canary, a separate provider phase must prove:

1. approved Mathematics source/context handoff into the Global AI gateway;
2. provider spend reservation and finalization;
3. no provider call for Free;
4. no provider call during protected assessment;
5. timeout / 429 / 5xx / invalid-output failures release hidden usage rather than charging the learner;
6. output validation and source/fact safety equivalent to the governed Exam Prep path;
7. maximum request/output cost stays inside the approved ceiling;
8. model/provider telemetry contains no raw learner chat beyond the approved minimal operational contract;
9. provider kill switch can disable generation while prepared iClub AI continues safely.

## Activation state

Do not activate production from this document.

Current required production state remains:

- Global AI UI OFF;
- Global AI gateway OFF;
- Global generation OFF;
- Plans UI OFF;
- checkout OFF;
- public subject enforcement OFF;
- canary subject enforcement OFF.

The next engineering phase is the Global AI generated-response adapter, reusing the already governed Mathematics provider boundary rather than inventing a second weaker provider path.
