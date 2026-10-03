# Exam Prep real-usage weekly audit — 2026-10-03

Scope: production Cambridge AS Mathematics P1 + P5 Exam Prep.  
Audit type: read-only production evidence review.  
PII: no learner identifiers retained in this evidence note.

## Last 7 days

Window observed: approximately 2026-09-26 11:54 to 2026-10-03 11:54 Asia/Tashkent.

Production activity:
- 14 Exam Prep sessions started
- 3 distinct real production users
- 57 response records answered during the window
- all 14 newly started sessions finalized

Controlled-beta activity within that window:
- 1 of the 3 currently active beta learners used Exam Prep
- 2 new sessions started: P5 diagnostic + P5 learning
- one older P1 learning session was resumed and answered during the window
- 10 responses from the active beta learner during the window
- 4 machine-correct responses
- 10 governed evidence events
- 1 weekly plan generated
- 3 weekly goal snapshots generated
- 5 correction actions recorded
- 0 retests created
- 0 retests completed
- current correction state for active beta learners: 25 open + 3 remediating

The other two currently active beta learners had no Exam Prep sessions in the observed seven-day window.

## Completed real-monitoring weeks available for governance review

Real-review epoch: 2026-09-14 09:41:45 Asia/Tashkent.

Week 1:
- period: 2026-09-14 09:41:45 -> 2026-09-21 09:41:45 Asia/Tashkent
- Core sessions: 20
- finalized sessions: 19
- P1 sessions: 17
- P5 sessions: 3
- evidence events: 75
- all weekly_snapshot_v2 hard blockers: 0
- AI active members: 0
- Mentor Care active members: 0

Week 2:
- period: 2026-09-21 09:41:45 -> 2026-09-28 09:41:45 Asia/Tashkent
- Core sessions: 6
- finalized sessions: 6
- P1 sessions: 5
- P5 sessions: 1
- evidence events: 18
- all weekly_snapshot_v2 hard blockers: 0
- AI active members: 0
- Mentor Care active members: 0

These are genuine real-cohort snapshots and are usable as source evidence for a governed weekly review.

They are **not yet P3-01 weekly-review rows**. The weekly snapshot explicitly returns `NOT_DERIVED_BY_SYSTEM`; the production recorder requires an explicit governance reviewer and explicit service decisions.

## Governance blocker discovered

`private.exam_prep_beta_weekly_reviews` currently has zero rows.

`private.exam_prep_staff_roles` currently has zero rows, so no valid `lead_mentor`, `academic_moderator`, `mentor_ops` or `safeguarding_lead` reviewer exists for the governed weekly-review recorder.

Therefore the observed Week 1 / Week 2 data must not be silently converted into GREEN review rows. Doing so would fabricate human governance evidence.

Current P3-01 state correctly remains:
- decision = NO_GO
- reason = active_weeks_1_4_incomplete
- real_weekly_review_count = 0
- automatic rollout = false

Current monitoring Week 3 ends 2026-10-05 09:41:45 Asia/Tashkent.
Week 4 ends 2026-10-12 09:41:45 Asia/Tashkent.

## Temporary QA-open access discovered

Production feature config still has:
- `qa_open_all_core = true`
- `qa_open_all_weekly = true`
- last config update: 2026-09-23

This temporary QA override allows registered authenticated users to use Core without per-user beta entitlement.

Observed effect:
- 2026-09-24: 329 non-cohort sessions from 81 users
- 2026-09-25: 165 non-cohort sessions from 28 users
- 2026-09-29: 11 non-cohort sessions from 1 user
- 2026-10-02: 1 session from a previously removed beta member

These rows are real production activity but are not controlled-beta cohort evidence and must not count toward P3-01.

No automatic access-setting change was made by this audit because disabling the QA override would revoke Exam Prep from users who currently receive access through it and therefore requires an explicit product decision.

## Evidence-use decision

Use:
- Week 1 and Week 2 snapshots as real governance-review source data.
- Current Week 3 active-beta activity as ongoing real-monitoring evidence.
- Non-cohort QA-open activity as product/traffic evidence only.

Do not use:
- non-cohort QA-open activity as controlled-beta evidence;
- removed-member activity as controlled-beta evidence;
- any synthetic data as real beta evidence.

No user/history/Practice/Tour/certificate data was modified by this audit.
