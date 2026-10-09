# iClub unified release — historical v2 publication checklist (SUPERSEDED)

> **HISTORICAL DOCUMENT — DO NOT EXECUTE.**
> Superseded 2026-10-09 by [current Stage 12 release gates](iclub-stage12-current-release-gates-v3.md).
> PR #327 is already merged. Mathematics Practice v2 was already published on
> 2026-10-08 (490 old -> 495 new). Repeating the bank switch, reset or cleanup
> would endanger real learner progress. The steps below are archived for provenance,
> **not an executable checklist**.
>

Status: prepared; NOT authorized automatically. The single shared release stays on PR #327.

## Sequence (one GitHub merge, one production Vercel deployment)

0. Before any mutation, recheck main/head SHAs, current Vercel production source SHA, live users/Tours/certificates/fingerprints and live Math Practice 490 legacy + 495 staged. No automated merge based on a stale SHA.
1. Validate the combined PR's GitHub Actions (including registration preview browser matrix and Practice v2 rehearsal). No preview deployment is a condition of GitHub Actions; do not spend Vercel preview capacity simply for visual checks.
2. Confirm all commercial/Global AI/subject enforcement switches remain OFF in Supabase; do not activate payments, AI or legacy-user transition.
3. Release **once**: squash merge PR #327 into main only when all tests are GREEN and current SHA still matches, and wait for one production Vercel deployment to become READY with that exact commit. If this fails, STOP: do not publish the bank.
4. Add/verify the **read-only authenticated publish proof** RPC from `20261008110000_math_practice_v2_post_publish_local_reset_gate_v1.sql`; no user-data DML. Before the bank switch, proof is false for a registered user. Ensure the new gated JS is serving and eager local clear was replaced.
5. Run `supabase/preflight/math_practice_v2_release_preflight.sql` READ-ONLY at the actual cutover. Verify 490 live old memberships, 495 staged, 201 diagnostics, 868 mappings, 0 Tour overlap; save the protected Tours fingerprint, including certificates.
6. Only then perform `private.publish_math_practice_v2_release_v1('math_p1_practice_v2_2026_10_07')` once, in its atomic transaction. This intentionally resets legacy **Mathematics Practice only**, as architect approved. It must preserve Tours, certificates, user accounts, other subjects, and all current Exam Prep academic evidence except explicitly Practice-derived legacy evidence.
7. Immediately run `supabase/preflight/math_practice_v2_post_publish_audit.sql`, prove the authenticated local reset RPC becomes true, then execute verified real learner smoke QA (new Math v2 session, question, answer, feedback, results, refresh, Tour history). If these fail, STOP and use the approved **pre-cleanup rollback**, accepting that legacy Practice progress cannot be restored. Do NOT perform question cleanup merely because SQL audits pass.
8. Only after real smoke QA is GREEN, run `private.cleanup_math_practice_v1_questions_v1(...)` and `math_practice_v2_post_cleanup_audit.sql`. Expect four Tour-linked old questions retained. Physical deletion ends the SQL rollback window; do not trigger automatically.
9. Recheck real-user and Tour/certificate counts and fingerprints; report before/after and end release. Do not turn on commercial enforcement or AI.

## STOP conditions

- Any preview/browser regression, Practice release rehearsal, code quality check or migration compatibility check fails or was not actually executed on the exact candidate.
- No documented, authorized test session available for real learner smoke QA after publish. Do not conflate synthetic test green with real production smoke.
- The first boot JS still contains unconditional `localStorage` cleanup, or the post-publish RPC is absent.
- The deployed Vercel commit SHA does not exactly match the approved merged main SHA.
- Any live Practice release preflight invariant drifts, any protected Tours fingerprint changes or an unexpected active v2 membership appears.
- Commercial/AI/checkout features activate unintentionally.

No Vercel preview deployment and no bank switch is ever necessary to conduct these read-only preparatory checks.