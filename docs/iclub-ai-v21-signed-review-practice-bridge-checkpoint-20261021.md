# iClub Global AI v2.1 — signed Practice source bridge checkpoint
**2026-10-21 · existing QA branch · technical PASS / new-content RELEASE HOLD**

## Goal aligned with Master Plan
Reuse the **existing** P4 Ed25519 editorial verifier and a single Global AI response surface without changing Mathematics Exam Prep Tutor, production learner progress, original question keys, grading, billing or AI brand. Do not treat an owner closed-beta flag as an academic/content/rights signature.

## Completed in QA (not installed in production)

1. `qa/live_candidate/iclub-ai-v21-qbank-p4-signed-triad-bridge.cjs` validates exact fresh, trusted server snapshots of one live Practice question and the three corresponding EN/RU/UZ academic source cards. It verifies source and original content hashes, live target fingerprint, question publication, active Practice pool, matching subject, exact source key/version/revision and all three languages. It maps `practice_error` to P4's **canonical editorial** `practice / answer_explanation` identity without ever aliasing a live source permission. A reviewer signing a different locale, text, topic, source version or subject cannot authorize the candidate.
2. It reuses `qa/ai-layer-v21-editorial-evidence.cjs` (existing Ed25519 canonical message format) for distinct content/rights/technical signers, and additionally verifies independently trusted academic/language signers on those SAME exact signed bytes. All **five roles per locale** must be distinct. It returns a verified proof only; `releaseAllowed=false` always. It has no DB update, publisher, runtime rollout, owner grant or provider call.
3. P4 source-envelope digest `SHA256(UTF8(body_text || LF || '{}'::jsonb::text))` is independently verified in the real disposable PostgreSQL suite with Unicode/multiline content. This is explicitly NOT equal to the beta's existing `SHA256(UTF8(body_text))`; copying the old content hash into a P4 ticket must fail.
4. `qa/live_candidate/iclub_ai_v21_qbank_owner_provenance_GATE_ONLY_UNAPPLIED_20261020.sql` now also creates a **separate, initially EMPTY** private `iclub_ai_v21_qbank_signed_review_receipts` register. The proposed new beta source-admission branch requires **both** a matching independently verified review receipt and a separate owner-authorized release record, for each exact source and all three locales, alongside current content/version/target hashes and active Practice membership. Absent receipt = DENY even when all owner allowlist entries are enabled. A suspended receipt for RU alone closes the whole question triad. The original old 111-card admission predicate is retained unchanged.
5. The receipt importer is an independent **NOLOGIN** role. RLS is explicit; learner service_role, anon and authenticated cannot import or read reviews. A separate NOLOGIN safety role can suspend a receipt but cannot unsuspend under its RLS policy. PostgreSQL does NOT perform Ed25519 verification: only an independently authenticated, credentialed intake using the existing QA verifier may import the receipt. These credentials/reviewer keys **have not been provisioned**, and no real attestation exists.
6. `qa/live_candidate/iclub-ai-v21-qbank-p4-signed-triad-bridge.test.cjs` uses temporary TEST-ONLY Ed25519 keys and negative cases for partial locale, missing keys, changed text, version drift, mismatched original/target hash, forged identity, duplicate roles, expired/revoked signer, disallowed question and ticket replay. The scratch PostgreSQL test additionally uses explicitly synthetic receipts and negative checks for owner-only release, reviewer suspension, curated version revision, legacy release compatibility and irreversible archive history.

### Exact QA acceptance
- [Full isolated GitHub QA run #39552582617 — SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39552582617)
- [Integration parity with current main #39552582677 — SUCCESS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39552582677)
- Tested source commit `30e35567403f745e00c563fd1d8b12e5b84441c6`. This is NOT a production deployment or an academic reviewer approval.

### Production safety / correction log
During QA work, a scratch test-only file was inadvertently committed to default `main` as `ad5b4ff9c76be711a07d094d452b0eb653fe701a`; the Vercel platform built it automatically. It was promptly removed in commit `482c1b79d2dee10d9da751f5e8f008cf3777087d` (single-file deletion, no app code changed). Verified Git tree SHA of the corrected main is **identical** to the prior main `7ea6c2960e6be1b1c46bf7b8506ee3106ad974e7`: `c6501eda1c7302952da5c1f1e6564865ce3cd369`. The latest production Vercel deployment is READY at `482c1b79...`. No Supabase production writes took place in this stage.

**Production Supabase read-only checkpoint**: 321 total academic source rows; 111 admitted and previously authorized; 210 fully closed new locale drafts; 111 original owner release entries; 0 student academic deliveries; provider OFF. The new signed receipt table, qbank beta release table and archival table are **absent** in production. No live SQL migration, paid generation, academic source publication, learner score/answer edit or new rollout.

## Product release decision
**Technical bridge: PASS. New 210-card learner rollout: HOLD.**

Before an actual release:
1. Verify **independent, auditable iClub ownership / legal rights** for every source, rather than assuming a stored explanation or Cambridge book reference is a license.
2. Complete academic scientific/key + RU/UZ/EN translation review for 70 source questions; resolve the 8 known hold items (3 proposed trilingual corrections and 5 metadata/taxonomy fixes). Never edit prior question grades to fix an AI reply.
3. Provision genuine out-of-band Ed25519 reviewer public-key registry and signer identity/authorization; store independently verified five-role receipts via a secured importer. Synthetic test keys and synthetic receipts are NEVER real approvals.
4. Validate the schema release in a separately rehearsed, controlled, reversible production migration with RLS, read-back and rollback plan; no copying scratch guard to Supabase by itself. Keep existing beta sources functioning unchanged.
5. Under the owner's previously given **conditional release authorization**, admit only individually verified source triads for the current consented small cohort; verify one genuine finalized incorrect Practice scenario end to end, monitor non-debit on DENY and maintain instant safety suspension.

No reauthorization is needed to continue technical QA. But conditional owner release permission alone does not replace independently verified reviewers, content provenance or a clean production deployment gate.
