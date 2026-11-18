# Mathematics P1/P5 D3-HOURS · optional study time and realistic learner scenarios

Status: **DRAFT ONLY, owner-approved development; NO MERGE, NO LIVE SUPABASE, NO RELEASE.**
Canonical: [Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) · [PR #569](https://github.com/jteshaboev1984-ops/iClub_APP/pull/569).
Distinct from the completed **D03 written-Paper grading integrity** stage.

## Binding product decision

1. Students who selected Mathematics may begin Exam Prep P1/P5 after giving an exam session and target grade; they **never have to declare available hours**.
2. First visit explains that the entry diagnostic identifies which skills need work. It does **not** promise verified personalized hours before methodology is approved. No questions about tutors, school, or outside-study time.
3. The one existing **My plan** surface owns all voluntary schedule choices. Blank hours = unknown, not zero. A returning learner's hours persist if the newer profile client omits them. Numerical time is not a learning limit.
4. After the learner voluntarily sets daily minutes/days/week, the existing P1/P5 shared budget and S3 three-choice contracts work. An optional sample 30 minutes × 3 days, P1/P5 45+45 minutes is **illustration / edit suggestion only**; nothing is saved until the learner explicitly clicks Save. This is **not** personalized advice or a Cambridge recommendation.
5. Older exam plans, revisions, weekly plans, unfinished diagnostics and sessions, Paper histories, verified outcomes, Practice, Tours, certificates, and subject authorization are preserved. Changing time may update future planning revisions, but must not reset academic evidence or paper comparability epochs.
6. Personal time estimation is a **separate follow-on**: existing 81 source-mapped skills, 486 action norm rows and 13 historical guided-teaching topic references cannot yield learner study-time arithmetic before independent academic acceptance. Historical Cambridge teaching hours (P1 90; P5 50) are not a student's required hours, nor required hours inside iClub. Exam date is useful only when sourced/confirmed; P1/P5 share time without double count.

## Implementation and safe boundaries

- **Server candidate** `supabase/candidates/math_p1p5_d3_optional_hours_v1_dormant.sql` guards five currently installed function definitions with exact historical hashes, and relaxes only the NOT NULL constraint on the two already-existing numeric history columns. It does not wipe or modify any learner row. The live profile table was already nullable.
- The owner-scoped profile writer retains old time values when client omits them; validates positive optional inputs and Math<=declared total if present; maintains versioned immutable revisions.
- Placement eligibility depends on genuine exam profile, not a weekly time value. Academic skill evidence gates remain unchanged.
- S3 `change` first allows an explicit minutes/day and days/week selection without a pre-declared total; `keep` and `redistribute` still require a prior saved choice. It preserves revision checks and idempotency. The existing total-hours cap is enforced when a returning learner has declared that total, but remains absent when total availability is unknown.
- Read-only shared-capacity projection returns `null` chosen hours if none have been supplied; never invents zero or an academic recommendation.
- Initial UI requires only exam session and grade; optional budget editors and saved facts appear in the existing single My plan. Existing 3-language presentation and mobile layout remain.

## User journeys to verify before ANY GO

| Scenario | Expected |
| --- | --- |
| New Math-selected, zero hours | save profile with NULL/NULL, revision 1, Stage0 diagnostic P1 AND P5 starts by real signed HTTP |
| Direct API without Math chosen | denied regardless of hours; existing #526 subject guard retained |
| Learner has not chosen a time | actual chosen budget is null; does not become 0, 90min, or 150min |
| User voluntarily chooses 30min × 3days | first S3 Change succeeds, records 90min P1+P5 as **user's selection**, not system estimate |
| New user revisits without hours | chosen time is preserved; no phantom history revision |
| Existing 12h/6h profile | old values intact when newer client omits hours; update Math to 4h produces one revision |
| Invalid 0, negative, >168, Math > total | server rejects without destructive side effects |
| Old interrupted diagnostics/Paper | sessions, marks firewall, dates, correction, Paper epoch and week history not reset by time change |
| Foreign session | wrong user is denied; original owner remains authorized |
| Stale S3 concurrency or repeated idempotency key | cannot silently overwrite choice |
| RU 390px, UZ 375px, EN 1280px new | exactly exam/grade on first entry, proceed to P1/P5 without hours |
| Same viewports existing | prefills saved hours, survives transient failed save; only explicit successful save persists |
| Unrelated state | Practice/Tours/certificates and norms unchanged |

## Release requirements

Candidate-only, source drift must be reconciled on exact Git HEAD before migration packaging. Test using **disposable PG17 + signed JWT/PostgREST** and **real Chromium** with synthetic accounts; browser mock alone is not signed API E2E. Preserve baseline source gates and current beta; no second Math permission system, no mass enablement or paid marking. Migration source needs a new versioned receipt on explicit owner GO; never replay existing released functions/migrations.

If exact-head CI is queued or failed to initialize, report NO ACCEPTANCE, rather than citing earlier runs as proof. This Draft is not production-ready until all targeted results and owner review are complete.
