# iClub Exam Prep — one subject access policy, no extra invitations/consents
Date: 2026-10-29 · Architecture decision by product owner · DRAFT implementation
Applies to Mathematics, Economics, Chemistry and all future subject Exam Prep modules.

## Product contract
A learner's normal iClub sign-in, selected active subject and enabled server entitlement determine which released component is usable. There are **no extra subject-by-subject invitations, checkbox confirmations, acceptance dialogs or opt-in participant lists**. Beta participants are owner-managed test accounts. A learner's first normal **Start practice** action may create an owned study plan (idempotently) but must never be stored as a separate legal consent or automatically start an exam.

**Do not assert that using an app is legally equivalent to informed data-processing consent.** Terms, privacy, children's data and third-party model privacy may require separate policy and legal review, outside subject-specific UX. This implementation does not erase legal notices and does not fabricate or delete historical consent records.

## Existing state verified on production (read-only)
- Math Beta active members = 3 with active core entitlements = 3; cohort is `canary`. Historical consent records exist.
- Global Math `qa_open_all_core=true` and independently `exam_prep_beta_open_recruitment_v1.enabled=true`. Thus **the current effective Maths eligibility must not be claimed exclusive to 3 accounts** without a separate rollout controls audit. These settings are not changed by this PR. The owner must choose the appropriate closure/release target before actual rollout.
- Economics written beta control enabled, ceiling 3. One historical opt-in and one written plan/access exist. These records must be preserved.
- Chemistry J24 remains gated OFF; Chemistry J25 opt-in was withdrawn in PR #397 and replaced by owner-controlled `closed/beta/released` staging.

## Per-subject behavior
- **Mathematics:** if the existing `get_exam_prep_capabilities_v1` returns Core access, open the existing P1/P5 flow; otherwise show the restricted/in-development state. Do not call invite, grant, claim-seat or revoke-consent RPCs. Do not grant a seat when merely opening the subject.
- **Economics:** retain P1 diagnostic prerequisite, P1/P3 native session security and actual written task readiness. P2/P4 remain informative until an owned written plan exists. The **Start written practice** control calls `iclub_econ_written_start_v2()` (no confirmation input), creates the same twelve-task ordered plan only if the user passes all existing academic/release/cohort/capacity gates, and does not insert an opt-in/consent row. Reopening is idempotent; historical withdrawn/archived records remain closed. Remove the withdrawal-consent affordance from the learner UI; navigation Back remains available.
- **Chemistry:** follow the independent, fail-closed J24/J25 owner rollout in PR #397. Do not merge Chemistry consent logic from main back into PR #397.
- **Future subjects:** reuse the same subject registration, authenticated server eligibility, owner-configured component release and content source integrity. Do not duplicate Mathematics beta consent tables or create new subject-level opt-in steps. Release can be beta-allowlisted or general by owner decision; never infer release from frontend state alone.

## Database implementation notes
**One staged backend migration plus one manually executed post-client operation:** Phase 1 `20261029094000_exam_prep_math_economics_no_extra_consent_v1.sql` installs consent-free checks / written start but **keeps legacy RPC grants temporarily** for already-open clients; Phase 2 `scripts/ops/20261029_exam_prep_legacy_self_enrollment_revoke_after_client_qa.sql` disables old learner self-enrollment/consent-grant privileges **only after the updated frontend is deployed and verified**. Neither has been applied. The second operation is deliberately outside `supabase/migrations`, so automated migration replay cannot revoke the old RPCs prematurely. It keeps existing Math membership, entitlements, capacity guard, synthetic-identity firewall and public consent history immutable; removes only historical consent as an additional server admission prerequisite. Economics P1 authorization still requires active beta cohort, activated membership, live Core entitlement, subject and feature config. Economics written practice requires prior finalized diagnostic and its own enabled maximum-3 cohort gate. No data migration of existing attempts, grades, questions or progress.

## Release / rollback
- Versioned frontend asset caches (API, host and Economics native); no localStorage writes.
- Run regression with the legacy P0-14 host Playwright matrix, Economics P1/P2/P3/P4 navigation tests, negative authorizations, mobile/RU-UZ-EN, ongoing-sessions preservation, and idempotent start. Run SQL on disposable PostgreSQL/test Supabase first, not on live user tables.
- Rollback by keeping existing migration off and reverting the frontend preview; do not DELETE historical plans, opt-in/consent records, beta memberships, entitlements or exam history.
- **No merge/main deploy until backend migration is verified and deployed in safe sequence relative to client code**. New Economics client uses `iclub_econ_written_start_v2`, so applying client first would fail for an otherwise eligible learner.

## Holds
No backend migration applied or production configuration changed; no live learner simulation. Existing Math `qa_open_all_core` and open recruitment governance need a separate owner rollout audit. AI Tutor provider-specific safety/privacy is not silently disabled by this subject-level UX change.

## 2026-10-29 extra production impact evidence
Read-only query: 880 current Mathematics subject subscribers, only 3 active individual Exam Prep Core entitlements, 7 distinct Exam Prep session accounts within 30 days, and 6 of those session accounts lack individual Core entitlements. Current `qa_open_all_core=true` means simply turning it off would remove live access for some existing sessions. Do **not** change Math QA-open state or delete existing attempts in this opt-in removal PR. Separate governed migration/entitlement reconciliation is required before any beta-to-release tightening.

## Safe deployment ordering
1. Validate isolated SQL, permissions and lifecycle, check current live user baseline without exposing user IDs, and confirm a no-session-loss fallback.
2. Apply **Phase 1** backend migration; verify old and new RPCs coexist, and new RPC does not write a consent row.
3. Deploy matching version-pinned frontend and smoke test signed-in Mathematics, Economics P1 / P2 and cross-subject Back on protected Preview then production.
4. Run manual **Phase 2** script only after new frontend operates and legacy tabs are no longer relied upon; verify deprecated self-enrollment is denied and all 3 existing entitlements/6 recent session accounts retain intended access.
5. At any failed step, stop. Never delete consent history or rollback by erasing learner data; use reviewed code/config rollback.
