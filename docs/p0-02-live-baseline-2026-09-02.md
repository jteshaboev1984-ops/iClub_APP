# P0-02 live baseline — 2026-09-02

Purpose: read-only snapshot taken immediately before any production P0-02 write. The live app continues to receive real user activity, so this snapshot supersedes older operational counts for the security migration gate; older counts are historical references, not invariants.

## Production data counts at snapshot

- questions total: **4567**
- Mathematics questions total: **951**
- Mathematics active: **881**
- Mathematics active + published: **790**
- Practice attempts: **908**
- Practice answers: **8840**
- Tour attempts: **365**
- Tour answers: **6267**
- Certificates: **157**
- ratings_cache rows: **0**

## Mathematics history / memberships

- active Practice memberships across active Mathematics pools: **490** (= 7 × 70)
- active `tour_questions` memberships attached to Mathematics Tours: **280**
- Mathematics Practice answers: **4134**
- Mathematics Tour answers: **2477**

## Important interpretation

Older project snapshots recorded lower total Tour-answer / certificate counts. The app is live, so new legitimate activity can change totals between audits. P0 regression therefore compares a fresh pre-write snapshot to a post-write snapshot while separately accounting for controlled smoke-test rows; it must not blindly compare September totals to an August snapshot.

The canonical Mathematics question counts and active Practice 7 × 70 invariant remain unchanged at this snapshot.

## Security state at snapshot

- `questions_public_read` still exists and exposes active `questions` rows to browser roles.
- `safe_questions_public` exists and is selectable by anon/authenticated.
- `get_safe_questions_by_ids(bigint[])` is intentionally callable for the legacy safe diagnostic flow and currently does not protect Tour membership by itself.
- `tour_questions_public_read` still exists.
- direct Tour attempt/answer browser write policies still exist.
- existing hardened Practice RPCs exist: `submit_practice_attempt`, `submit_practice_answer_safe`, `get_safe_questions_by_ids`.
- no P0-02 v3 runtime tables/RPCs have been applied to production at the time of this snapshot.

## Production-change status

**NO P0-02 production write performed yet.**

The corrected P0-02 v3 migration, Tour parity patch, frontend RPC client, P0-03 cutover draft, and regression plan exist only on `iclub-v3-implementation` pending the explicit production gate.
