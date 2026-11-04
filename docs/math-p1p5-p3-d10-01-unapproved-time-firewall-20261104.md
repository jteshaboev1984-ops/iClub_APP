# Issue #450 — D10-01: enforce academic approval before personal study-hour suggestions

**2026-11-04 · DRAFT / NO_GO · based on D09-05 PR #483**. This is a corrective code change, **not** independent academic validation of the 81 skills.

## Verified contradiction

The D09-05 7-day progress report correctly returned `recommended_weekly_hours=null`, while the older public `get_exam_prep_simple_learning_timeline_with_hours_safe_v2` could still convert **historical 2020 Cambridge guided teaching hours** into a *personal-hours* heuristic. The underlying P2-14 SQL used equal division of chapter hours by skills and unverified 1.0/0.8/0.6/0.0 progress factors, and then the P2-17/D11 explicit Accept or Keep endpoints consumed that approximation.

The actual P2-07 academic review protocol still requires independently reviewed per-skill learning/revision intervals, distinct primary/independent reviewers, and a source-backed planning engine. **All 81 original independent-study intervals remain unapproved.** An opt-in click does not turn an unreliable time estimate into academically established advice.

## Narrow remediation

- New **additive draft** migration `20261104134000_exam_prep_p1p5_unapproved_workload_time_firewall_v1.sql` overrides the last public timeline RPC with an owner-scoped **progress-only** timeline: both paper skill counts, exam dates, student's already chosen hours and plan revisions remain readable, but **all estimated remaining hours, weekly target, and difference are NULL**. It never calls the old historical teaching-time proxy or writes learner data.
- Both previously implemented owner-authenticated Accept and Keep functions compute their target through this RPC; a NULL target now **fails closed** for both. Any future numerical engine requires a separate, independently reviewed, versioned release and its own full real server acceptance. There is no automatic off-switch bypass just by changing a text/approval flag.
- Optional learner timeline JS accepts the explicit pending-review contract, renders existing P1/P5 progress and date controls with clear RU/UZ/EN explanatory text, and offers **no numeric recommendation or Keep/Accept choice**. An old heuristic response without `numeric_recommendation_enabled=true` is rejected by the new client. The learner can still edit an existing study schedule deliberately through its normal controls.
- Unchanged: same P1/P5 component ownership, ONE non-additive Mathematics hours budget, original prior plan identities and marks, allowed learning beyond planned time, no daily reminders, exactly-once weekly/monthly reports, protected content and source hashes, no AI authority. The requested exact original 12 Extra Hard (6 P1/6 P5) remain neither restored nor replaced.

## Verification and release boundary

The existing seven-phase real signed JWT→PostgREST→disposable PG17 P2-17 acceptance test is converted from **successfully accepting unreviewed heuristics** to asserting **direct API refusals**, wrong/anon/stale rejection, no profile revision and no Keep receipt. Academic source/proxy helper checks remain as historical-reference tests, not user recommendations. Unit UI now checks both a future explicitly approved *synthetic mock* and the actual unapproved progress-only contract across RU/UZ/EN.

No production migrations, Vercel deployment, `main` merge, user progress reset, cleanup, live feature flags, legacy Practice/Tours/certificates, or other-subject changes. **Public release remains NO_GO.** The full exact-HEAD CI and controlled device smoke must still be verified on this candidate.
