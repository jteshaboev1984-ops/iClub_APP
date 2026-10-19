# iClub AI v2.1 — Knowledge First prepared Practice QA handoff (2026-10-19)

Status: **QA ONLY / SYNTHETIC CI / UNDEPLOYED / PRODUCTION NO-GO**.

This handoff reuses the existing \`createKnowledgeFirstReadOnlyGate\` and \`CandidateEdgeRequest\` rather than inventing a second answer evaluator or metering engine. Its sole tested route is an exact, finalized, owner-bound Practice question with \`intent=practice_card\`, \`promptKey=explain_error\` and the identical source key independently confirmed by the governed publication gate and the shared Edge admission gate. Other routes—including the functioning Mathematics Exam Prep Tutor, arbitrary academic questions, Home, Tour and generic topic fallbacks—are refused.

The bridge is importable only in explicit synthetic CI with \`ICLUB_AI_QA_BOUND_PREPARED=synthetic-only\`, mock-only dependencies, and no real Supabase or model environment. The existing v21 request core independently enforces auth, protected assessment, rollout, release/source integrity, temporary prepared-route quota, single-use delivery claim, and pre-delivery revalidation. This test has **no deployed HTTP route**, authentic hosted Supabase Auth, live PG migration, editorial publication, real student session, or production billing entitlement.

This is **not** owner approval to issue source content to live learners. No source content is created or published, no app/core/math files are changed, and the original offline QA remains the compatibility gate. Tests require successful exact prepared delivery with one *temporary QA quota unit* and **zero paid-provider calls**, and no content/usage when source rights are absent, an assessment is protected, the subject is unavailable, source ID differs, or the request is replayed. A genuinely atomic production authorization of exact source version/hash and publication revision is still a separate release gate before a real learner delivery. Prepared means no paid-model invocation, **not** unlimited quota or an approved tariff.

Next: validated independent rights publication, real Auth→Edge→RLS owner proof, exact version-pinned source binding in a single authoritative delivery transaction, and a separately authorized protected Preview; only then consider owner/cohort release.

## QA hardening — verified incorrect answer and exact publication pin

- The server-only, exact finalized Practice explanation now demands
  `confirmedIncorrectAnswer:true` from verified scoped context. The underlying
  UNAPPLIED SQL already demands `is_correct IS FALSE` and non-null
  `answered_at` at both mint and read time. Correct, unanswered and unknown
  items are modeled as hard denial, never as errors.
- The read-only metadata proof includes verified source **key, version, SHA-256
  hash and independent positive publication revision**. All four are pinned
  across Edge release/source proof/approved prepared bundle and revalidated
  after quota claim and before delivery. Changing answer correctness or
  source metadata after reservation returns no answer and refunds synthetic
  learner quota, without any paid model call.
- This remains mock-only CI with separate asynchronous read checks. It is NOT
  genuine production atomic authorisation, independent editorial publication
  or Supabase Auth/RLS testing. Running Mathematics Tutor is untouched.
- Further stage: authenticated live server and rights-publication approval,
  atomic final-read/delivery claim, protected original-app Preview, and
  separate owner GO. No new production deployment, migration or student data.

Test evidence: GitHub Actions for the corresponding existing QA branch commit.
