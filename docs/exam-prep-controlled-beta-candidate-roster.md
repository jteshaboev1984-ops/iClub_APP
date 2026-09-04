# Exam Prep Controlled Beta Candidate Roster

**Program:** `math_as_p1_p5`  
**Cohort:** `math_as_p1_p5_beta_2026_09_01`  
**Cohort capacity:** up to 12 learners  
**Recorded:** 2026-09-04  
**Current status:** DRAFT / NOT ACTIVATED

## Candidates currently staged

| Learner | Service mode | Planned wave | Status | Learner consent |
|---|---|---:|---|---|
| Azizbek Erkinov | Core | 1 | candidate | missing |
| Sarvarbek Erkinov | Core | 1 | candidate | missing |
| Жасурбек Тешабоев | Core | 1 | candidate | missing |

Current roster: **3 / capacity 12**. The capacity is an upper bound, not a requirement to fill every seat before the controlled beta can start.

These candidates were resolved against production `public.users` using exact name matching plus account-activity/auth evidence where duplicate names existed. Database UUIDs are intentionally not copied into this human-facing document.

## Safety state at staging

- cohort status: `draft`;
- global rollout state: `off`;
- `core_enabled=false`;
- `ai_enabled=false`;
- `mentor_enabled=false`;
- `kill_switch=true`;
- active Exam Prep entitlements for these three candidates: `0`;
- learner consent grants: `0 / 3`;
- no learner access was granted by staging these rows.

## Current release gate

The older exact-12 / mixed-service start requirement is superseded for the initial canary by the Core-first amendment. The initial controlled beta may start with the three current Core learners once all three explicitly consent and the production Core-first/self-consent migrations are verified fail-closed.

AI Assist and Mentor Care candidates are **not** required as placeholders for the first Core canary. Those service modes may be added later, within the remaining capacity, and activated only after their independent readiness gates pass.

The next live sequence is therefore: deploy the already-tested governance/self-consent overlays without enabling access → verify this roster and fail-closed state are unchanged → collect **3 / 3 explicit learner consents** → approve the cohort → activate **wave 1 Core only** → begin first-72h P1-01 monitoring.
