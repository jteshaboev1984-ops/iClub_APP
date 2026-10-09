# iClub APP — Practice topic switch release gate
Date: 2026-10-09. QA only. Do not deploy to production without release approval.

## Accepted learner behavior
- If a previous topic attempt is unfinished, offer **Resume attempt** or **Discard attempt and change topic**.
- Closing the modal does nothing; resume restores the earlier attempt.
- Switching to a different topic uses one server-side atomic transaction.
- The discarded unfinished attempt becomes `abandoned` (not included in learner results or re-submittable), not a destructive delete of historical rows.
- Previously finalized attempts and their results remain unchanged.
- RU: попытка; UZ: urinish; EN: attempt. Practice is a section, not "тренировка".
- If the server has not confirmed successful replacement, preserve and offer recovery of the saved draft.

## Current code
- QA-only source: `supabase/migrations/20261008150000_practice_topic_switch_atomic_v1.sql`
- QA dialog: `stage03-topic-choice-decision.cjs`
- QA contract: `stage03-topic-switch-contract.cjs`
- Build gate executes contract after stage03 composition; source checks 36.
- Synthetic, no-write PostgreSQL tests: 10/10 status/ownership/retry classifications passed.
- Live Supabase already accepts `abandoned` status and has unique (user_id,client_session_id).
- A real authenticated SQL/UX test has NOT happened. The new replacement RPC is NOT installed.

## Required release order
1. Run candidate Preview build and compare existing users, progress, records read-only before any change.
2. Obtain architect approval for migration and controlled safe installation with a rollback plan.
3. Deploy function without changing existing tables or learner rows, verify grants/contract.
4. Run explicitly authorized, isolated test-account topic switch and network-retry test.
5. Verify completed Practice results and Tour/certificates unaffected, check RU/UZ/EN.
6. Only after other Master Plan v3 gates, merge once into main and ship production.

Do not substitute schema/static checks for a real authenticated test; do not activate new Global AI.
