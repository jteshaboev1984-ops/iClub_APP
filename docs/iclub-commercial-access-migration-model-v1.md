# iClub commercial access migration model v1

## Why legacy user_subjects is not the tariff authority

The current app uses public.user_subjects as a learner preference / Competitive-mode contract, not as a complete access-entitlement table.

Important current behavior:
- school learners can have Competitive and Study rows;
- non-school learners can still study/practice active subjects even when no user_subjects row exists;
- user_subjects is also used by Profile, Home pins and Competitive/Tours behavior.

Therefore Free/Plus/Pro subject limits must **not** be implemented by deleting, rewriting or reinterpreting legacy user_subjects rows.

## New commercial access layer

Commercial access is kept separately in private tables:
- subscription lifecycle events;
- current entitlement period/scheduled change fields;
- commercial migration state;
- legacy subject snapshot for audit only;
- commercial subject-slot selections;
- subject-slot event history.

Legacy academic/product state remains untouched.

## Default plan and canary rule

All authenticated learners resolve to **Free by default** unless they have an explicit active paid entitlement.

This is a virtual/server-side default. It does **not** mass-insert Free entitlement rows for all existing users, which keeps rollout reversible and avoids rewriting production account state.

Before public rollout, the new Global AI + Plans experience is limited to a hard maximum of **3 service-managed canary users**. Those test accounts may receive temporary Free/Plus/Pro overrides for QA. Canary membership is private/service-only and is enforced on the server gateway as well as the UI bootstrap.

Important distinction:
- commercial plan identity defaults to Free;
- legacy subject access is preserved separately until the learner completes the approved subject-selection cutover.

Therefore default Free must never be interpreted as permission to immediately delete or hide an existing learner's subjects/history.

## Grandfather rule

Approved technical default:

**preserve_legacy_until_choice**

At cutover:
1. subject limits first enter shadow mode;
2. a versioned snapshot records which users existed before cutover and their current legacy subject rows;
3. those users receive migration_state=legacy_preserved;
4. legacy_preserved users continue opening any currently active subject;
5. no subject is auto-removed and no learning history is deleted;
6. once a learner explicitly confirms their tariff subject choices, migration_state becomes migrated;
7. only after that does the commercial slot selection become the access authority for finite-subject plans.

Pro has no study-subject count cap, so it does not require explicit study slots to preserve all-subject access.

## Runtime modes

subject_limits_mode:
- off — exact current app behavior; commercial guard is pass-through;
- shadow — calculate/store proposed selections and limit outcomes, but do not block because of numeric tariff limits;
- enforced — block new/open access according to plan slots, but only after the grandfather snapshot is complete.

If enforced is ever misconfigured before the grandfather snapshot exists, the guard intentionally fails open to legacy access rather than locking real learners.

## Subscription lifecycle

The lifecycle contract is event-driven and provider-neutral.

Supported events:
- activate
- renew
- upgrade
- downgrade
- schedule_downgrade
- schedule_cancel
- cancel
- pause
- resume
- revoke
- expire

Every event has an idempotent event_id. Repeated provider callbacks therefore cannot double-apply a transition.

Future downgrade uses schedule_downgrade and keeps the current plan active until the effective event arrives. schedule_cancel similarly keeps current access active until the later cancel/expire event.

## Data preservation law

Plan change, downgrade, cancel or subject-limit enforcement must never delete:
- Practice attempts/answers/history;
- Tours attempts/answers/history;
- ratings evidence;
- certificates;
- recommendations;
- Exam Prep evidence, readiness or progress;
- legacy user_subjects rows;
- learner localStorage progress.

A lower tariff may later limit *access*, but historical evidence remains intact and must reappear when access is restored.

## Current release status

This phase is backend-only and dormant:
- lifecycle_enabled=false;
- subject_limits_mode=off;
- Global AI rollout mode=off;
- Plans rollout mode=off;
- every authenticated learner resolves to Free by default without a stored entitlement row;
- at most 3 service-managed canaries may receive temporary Free/Plus/Pro test overrides once canary rollout is explicitly activated;
- no browser can mutate subscription, canary membership or subject authority;
- no payment provider is connected;
- no frontend subject enforcement is wired yet.

Next phase after GREEN:
1. authenticated subject-selection/read model;
2. learner subject-choice UX;
3. shadow-mode integration into Study/Profile;
4. migration impact report for existing users;
5. only then consider enforcement and payment integration.