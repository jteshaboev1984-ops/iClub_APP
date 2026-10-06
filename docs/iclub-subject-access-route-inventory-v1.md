# iClub commercial subject-access route inventory v1

Date: 2026-10-07  
Phase: shadow observation only  
Production enforcement: OFF

## Purpose

Before any Free/Plus/Pro subject limit can block a learner, every route that starts or opens subject-specific activity must be identified and tested.

This phase does **not** block navigation. For the three beta users it records the commercial decision the future guard would make while the existing app continues exactly as before.

## Access classes

### Study
Future active-learning access. Requires:
- Pro: all active study subjects are included; or
- Free/Plus: the subject is selected in the commercial study slots.

Routes:
- catalog subject → Subject Hub
- global Books shortcut
- Subject Hub video/lessons
- Mathematics Exam Prep open
- Practice open/start/again
- Subject Hub Books
- recommendation → Books
- recommendation → Practice/retry/train/repeat
- Tour review → Practice
- Tour result → Practice

### Competitive
Future competitive participation access. Requires an explicit commercial Competitive selection for the subject.

Routes:
- legacy Profile Competitive slot → Subject Hub
- Subject Hub → Tours
- Tour start

Historical Tour results, archive and certificates are **not** in this class and must remain readable.

### History
Read-only/history-oriented access is preserved even when the subject is no longer selected or later becomes inactive.

Routes:
- global Recommendations
- Profile Recommendations
- Subject Hub Recommendations
- resume an already paused Practice attempt
- recommendation detail → back to Subject Hub

These routes must never be used to delete or hide historical evidence.

## Current route codes

| Route code | Class | App entry |
|---|---|---|
| catalog_subject_hub | study | Courses subject catalog |
| profile_competitive_subject_hub | competitive | Profile active Competitive slot |
| global_books | study | global Resources/Books shortcut |
| global_recommendations | history | global recommendations shortcut |
| profile_recommendations | history | Profile recommendations |
| subject_video | study | Subject Hub video/lessons |
| subject_exam_prep | study | Subject Hub Exam Prep |
| subject_practice | study | Subject Hub Practice |
| practice_start | study | actual new Practice start |
| practice_start_past | study | legacy Practice start fallback |
| practice_resume | history | resume existing paused Practice |
| practice_again | study | start another Practice attempt |
| subject_tours | competitive | Subject Hub Tours |
| tour_start | competitive | actual Tour start boundary |
| tour_review_practice | study | Tour review → Practice |
| subject_books | study | Subject Hub Books |
| subject_recommendations | history | Subject Hub recommendations |
| recommendation_books | study | recommendation → Books |
| recommendation_practice | study | recommendation → Practice |
| recommendation_train | study | recommendation training drill |
| recommendation_retry | study | recommendation mistake retry |
| recommendation_repeat_drill | study | repeat recommendation drill |
| tour_practice | study | Tour result → Practice |
| recommendation_to_subject | history | recommendation detail → Subject Hub |

## Explicitly preserved routes

The commercial subject gate must never remove access to already-earned/recorded evidence:

- completed Practice result/review/history;
- completed Tour result/review/archive;
- ratings already recorded;
- certificates already earned;
- stored recommendations/history;
- Exam Prep evidence/readiness/history already recorded;
- local learner progress/history.

A plan downgrade changes future entitlement, not historical truth.

## Shadow event contract

The shadow event stores only:
- user id;
- subject key;
- route code;
- access class;
- effective test/commercial plan;
- would_allow;
- reason;
- timestamp.

It stores no question text, answers, chat text, assessment content or private reasoning.

## Activation sequence

1. Keep `subject_access_shadow_routing_enabled=false` by default.
2. Activate only with `subject_limits_mode=shadow`.
3. Restrict rollout through the existing server-side Plans canary gate.
4. Collect route decisions only for the three beta users.
5. Verify there are no unobserved subject-entry routes or false blocks.
6. Only after a separate approval may a later phase introduce enforcement.
7. Enforcement must be server-authoritative and must not rely on client-only route checks.
