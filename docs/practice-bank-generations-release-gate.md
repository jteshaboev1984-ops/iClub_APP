# All-subject Practice bank generations — release gate

## Confirmed source of truth
Mathematics Practice v2 published at **2026-10-08 12:44:31.862792 UTC** according to `private.practice_v2_release_switch_audit` (status `published`, completed_at). This is the generation 1 → 2 boundary, not the date of the Vercel deploy. The 495-question bank is already published; do not republish.

Every other subject starts at generation 1. Each later *full* bank replacement needs its own audited activation. Routine question fixes do not change generation.

## Implemented in staged migrations (not installed)
- Registry per subject and immutable generation on server-created main Practice and drill sessions.
- Existing sessions classified by their server start timestamps; older legacy attempts are classified only when safely before a replacement.
- Historical recommendations classified by verified activation timestamp; future recommendations must link to finalized safe-v4 session and are validated against server-recorded mistakes.
- Authenticated server read returns only current-generation Practice recommendations. Tours continue to use their separate existing read.
- Old client uses existing queries until the new RPC is available. New client fails closed on a server-side provenance rejection and does not revive local recommendations after successful generation-scoped read.

## Required release verification
1. Test staged migrations in an isolated DB; no production migration execution without explicit approval.
2. Check safe-v4 start/finalize and retry flows for every subject, including a session begun before an activation and finished after it.
3. Validate historic recommendations on both sides of the exact Mathematics boundary; ensure other subjects remain generation 1.
4. Confirm RLS and execute privileges; verify direct legacy recommendation writes cannot bypass provenance after cutover. The current staged migration intentionally retains compatibility until this gate is cleared.
5. Run `node scripts/practice-bank-generations-contract.cjs` and existing release QA contracts locally (no Vercel builds).
6. Verify My Recommendations shows Practice and Tours independently, then run mobile/locale QA and only one approved Preview if necessary.
7. Prepare RU/UZ/EN in-app notice; do not broadcast before release approval.

## Safety
No production database writes, deletions, deployment, user notifications or forced localStorage resets in this staged change.
