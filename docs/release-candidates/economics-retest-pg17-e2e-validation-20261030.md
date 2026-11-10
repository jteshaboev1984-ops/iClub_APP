# Economics P1/P3 — isolated retest runtime validation (30 October 2026)

## Executed on a disposable PostgreSQL 17 instance

**Evidence:** GitHub Actions `Economics Retest Isolated PostgreSQL Runtime Gate`, run **41014591935**, status **PASS** on branch commit `a94e39d14ce1c921b28447c7a0345f23e06ecc56`. The accompanying `Economics Retest Semantic Revision Gate (Synthetic)` and `Exam Prep Unified Subject Access (no extra consent)` also passed (runs 41014591864 and 41014591923).

The actual SQL candidate in `docs/release-candidates/economics-private-retest-gated-v1.sql` was executed in a **fresh, unrelated PostgreSQL 17 service** with synthetic stand-ins for Supabase Auth and the minimum existing legacy tables. Runtime cases covered:

- New issuance is **OFF by default**, and draft/unapproved sources remain unavailable even if the global switch is temporarily ON.
- An authenticated, non-anonymous learner needs an **owned finalized wrong answer**, not an unrelated session, already-correct answer or unanswered item.
- A candidate is limited to the same approved direct skill and component. Session identity/answer keys remain server-side; the active get response does not disclose correct_index, is_correct, answer key or explanation.
- GET/SUBMIT by another user are refused; anonymous users and server-expired sessions are refused.
- Repeated start with the same request key returns the same session; alternate keys for the same active error also resume it. Concurrent requests in separate PG connections produced **two results pointing to one issued session**.
- One-time scoring, duplicate submit idempotence, explanation/answer reveal **only after finalization**; changed submit is rejected.
- After finalization, attempting a new retest for the same original error returns `already_retested`; expired attempts return `prior_retest_expired` and cannot be restarted with a fresh key.
- The kill switch blocks **new issuance**, without hiding existing finalized results from the valid owner.
- `pg_dump -Fc` followed by `pg_restore` into a new disposable database preserved the synthetic original attempts, retest sessions, protected sources and source table privilege boundary.
- All original fictional exam attempts and responses remained unchanged. No protected question bank was committed.

## Safety / interpretation

- These were PostgreSQL **synthetic** tests, not an authenticated production Supabase Auth/JWT/REST/browser test; the Auth schema and entitlement checks were **mocks**. A fresh Supabase environment with the real role/permission and REST contracts is a separate release gate.
- A fictional database dump/restore proves the test workflow only; it **does not** prove production Supabase backups, PITR availability, or a recovery plan.
- The 71 original Economics same-skill alternative candidates (35 P1 + 36 P3) are still private and **NOT approved for student release**. The second private revision contains 6 amended items; 65 unaffected items were preserved. Academic/translation/source-rights sign-off and later repeated-retake reserve remain outstanding.
- Real production SQL/DB, Vercel deployment, published question bank, Math, Chemistry, Practice, Tours, certificates, localStorage, historical attempts and user progress: **no changes from this PR**.
- Feature status **HOLD**, no source import, no migration applied, no feature enable, PR remains **Draft**. Do not merge as a signal that learner release is ready.

## Next release blockers

1. Independent expert review of 71 questions and trilingual equivalence, rights and original-item semantic independence. Until approval, no imported/released learner bank.
2. Safe Supabase-specific staging environment / verifiable restore plan; then real authenticated API and role negative/positive E2E with no production learner state.
3. Decide subsequent alternative bank size (one candidate per skill cannot support indefinitely many independent retests); verify no previously shown item can be reissued.
4. Prepare controlled owner-authorised rollout only when remaining gates are green.

**Other subject-bank requirement:** [issue #432](https://github.com/jteshaboev1984-ops/iClub_APP/issues/432) and `docs/exam-prep-independent-retest-all-subjects-v1.md`: implement the same evidence principles when updating Mathematics, Chemistry, Biology and Computer Science banks, using subject-specific skills, papers, methods and checks.
