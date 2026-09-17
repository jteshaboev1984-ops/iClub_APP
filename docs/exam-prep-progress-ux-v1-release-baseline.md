# Exam Prep Progress UX v1 — release baseline and rollback record

Status: PRE-PRODUCTION / READ-ONLY BASELINE ONLY  
Captured: 2026-09-17, approximately 13:39 Asia/Tashkent  
Production project: current iClub Supabase project  
Feature branch: `feature/exam-prep-progress-ux-v1`

## Purpose

This record exists to prevent a release of Progress UX v1 from being mistaken for an academic-state migration. Progress UX is additive presentation infrastructure. It must not rewrite or delete existing learner history, Practice, Tours, certificates, ratings or Exam Prep evidence.

Counts below are a point-in-time production baseline. Real users may legitimately change activity counts after capture. A later pre-release comparison must distinguish normal new user activity from destructive or unexpected mutations.

## Read-only production baseline

- public users: 1326
- tours: 70
- tour questions: 1523
- tour attempts: 365
- tour answers: 6267
- practice pools: 35
- practice pool questions: 2635
- practice attempts: 906
- practice answers: 8820
- certificates: 157
- ratings cache rows: 0
- Exam Prep profiles: 1
- Exam Prep sessions: 14
- finalized Exam Prep sessions: 14
- Exam Prep responses: 55
- Exam Prep evidence events: 55
- Exam Prep correction cases: 28
- open/remediating/retest-due/reopened correction cases: 28
- Exam Prep retest events: 0
- Exam Prep weekly plans: 6
- Exam Prep weekly plan items: 18
- `private.exam_prep_weekly_goal_snapshots`: NOT PRESENT in production

Additional component observation at capture: production has six P1 weekly-plan versions and no P5 weekly plan. This is an observation, not a frozen expectation; user activity can create new plans later.

## Follow-up production read-only verification — 2026-09-17, 16:16 Asia/Tashkent

Used SELECT-only aggregate queries and PostgreSQL metadata introspection. All 21 numerical baseline counts above matched exactly at the follow-up time. No personal records or user identifiers were retrieved. `private.exam_prep_weekly_goal_snapshots`, `public.ensure_exam_prep_weekly_goals_safe_v1(text)` and `public.get_exam_prep_weekly_progress_safe_v1(text)` are all absent from production, as expected before approval. The active engine version is `objective_state_v1`. This is a second observation, not authorization to migrate.

Source-title audit: production's canonical syllabus registry has **45 P1 skills across eight official sections** and **36 P5 skills across five official sections**. All 13 exact `official_syllabus_section` keys match the opt-in UI's localized area dictionary. The current UI uses the canonical Russian skill description verbatim when available and a syllabus-area name for Uzbek/English instead of inventing per-skill translations. Some source Russian descriptions themselves mix English mathematical terms; their editorial rewrite is a distinct content-governance decision, not a safe unreviewed UI patch. No source content or learner skill records were edited. Fallbacks without a confirmed tracker do not claim an invented exact skill title.

At this comparison the feature branch was 70 commits ahead of `main`, zero behind; `main` remained `95c39e48aa1266f03247e5502e86b3e9e4a6830c`. Recompare on the actual release day rather than assuming this stays true.

## Release invariants

Before any production SQL or feature enablement:

1. Re-run a read-only baseline immediately before release.
2. Confirm the new Progress UX table/functions are the only intended schema additions/replacements.
3. Confirm existing Practice/Tour/certificate/rating tables are not targeted by Progress UX migrations.
4. Confirm existing Exam Prep sessions, responses, evidence, correction cases and weekly-plan history are not deleted, rewritten or backfilled as mastered/completed.
5. Confirm P1 and P5 remain independently scoped.
6. Confirm default feature state produces no Progress UX UI or dependent requests.

## Non-destructive rollback

If Progress UX must be disabled after release, rollback is presentation-first:

1. Set/keep the Progress UX client flag OFF so the optional bootstrap is not loaded.
2. Do not delete learner snapshots merely to hide the feature. They are presentation history and may be retained safely while the UI is disabled.
3. Do not roll back by deleting or rewriting Exam Prep sessions, evidence, corrections, retests, weekly plans, Practice, Tours, ratings or certificates.
4. If a later schema cleanup is ever approved, perform it as a separate migration only after proving that no active code references the Progress UX RPCs/table and after taking a fresh backup/baseline.
5. Academic truth remains owned by the existing Exam Prep engine. Disabling Progress UX must not change mastery, coverage, stages, corrections or readiness.

## Current production authorization

No production DDL/DML, main merge, production deploy or feature enablement is authorized by this document. The feature remains in draft PR until explicit release approval.
