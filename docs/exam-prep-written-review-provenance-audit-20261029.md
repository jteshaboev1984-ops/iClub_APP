# Mathematics P1/P5 written criteria: evidence-of-review checkpoint

**Date:** 2026-10-29. **Scope:** read-only production audit of Mathematics written criteria governance, NOT editing/translating criteria. **Decision:** technical localization COVERAGE PASS; **independent review provenance NOT VERIFIED**. This is not a new academic approval, mass-release decision, user-access change, or claim of a defect in every translation.

## Current production evidence (Supabase SELECT only)

| Component | Published QA-passed written tasks | English source criteria | RU checksum approved | UZ checksum approved | Identical academic/language review refs |
|---|---:|---:|---:|---:|---:|
| P1 | 167 | 853 | 853 | 853 | 853 RU + 853 UZ |
| P5 | 161 | 851 | 851 | 851 | 851 RU + 851 UZ |
| **Total** | **328** | **1,704** | **1,704** | **1,704** | **3,408 approved locale records** |

Source-vs-locale rule checksums and task/version joins match for all published QA-passed criteria. There are 0 missing/stale RU/UZ locale rows in the covered set. All 3,408 approved locale rows contain both review reference fields and reviewed_at, but all 3,408 use the *same value* in both roles. There are only 2 distinct academic/language reference pairs, each labeled `OWNER_DIRECTED_AI_ASSISTED...`. No independent line-by-line human reviewer identity/attestation is established by this data.

**Corroboration in repository (do not replay):**
- `scripts/ops/20261028_p1p5_written_owner_beta_release.sql` explicitly states: “This does NOT claim a completed independent human line-by-line review.” It bulk-updated 3,194 draft locale rows to `approved` using the same owner-directed AI-assisted QA reference for both fields.
- `scripts/ops/20261028_p1p5_translation_review_timed_publish.sql` uses the same correction-review reference in both fields for 54 additional locale rows (part of the current total).
- `docs/exam-prep-written-criteria-ru-uz-approval-v1.md` requires **independent mathematics and native-language review** against exact task version and criterion.
- Production `private.exam_prep_written_criteria_locale_v1` has RLS on, no direct authenticated SELECT privilege, and an enabled trigger preventing silent edits/deletions of approved locale rows. Technical version/checksum coverage is not equivalent to meaningful human review.

**Interpretation:** Status `approved` and identical provenance fields show an owner-directed bulk acceptance, not proof of independent specialist signoff. This neither proves the mathematics is wrong nor asserts that no subsequent independent review happened. Do not mislabel the current rows as independently human-reviewed without verifiable separate evidence.

## Repeatable non-mutating verification

Run `scripts/fixtures/math-written-review-provenance-readonly.sql` using a private authorized Supabase admin SQL console. It returns **counts only**, grouped by P1/P5 and RU/UZ; it exposes neither protected rubric wording, private reviewer identities nor learner information. Interpretation:
- `missing_or_stale > 0`: technical coverage or version/checksum problem;
- `same_review_ref > 0` or `owner_ai_assisted_ref > 0`: independent-review provenance **unverified**, even when source checksum is valid;
- `METADATA_ONLY_PASS_NOT_HUMAN_SIGNOFF`: still **not** evidence of a substantive human review. It only means this static query found no flagged metadata patterns.

This is an observational audit, **not a release gate that changes flags**. It must never rewrite existing `approved` rows, reset sessions or create synthetic human reviewer signatures.

## Remaining specialist QA (owner / authorized reviewers)

1. The owner identifies real independent mathematics and RU/UZ language reviewers, or retrieves genuine existing records; do not invent people, review dates, or approval IDs.
2. In a **private review environment**, each reviewer receives the exact approved English source, corresponding locale, mathematical notation/marks and immutable `task_id` / `task_version` / `criterion_id` / checksum. Review semantic correctness and language independently; record verifiable scope, decision, timestamp, and reviewer evidence without leaking protected source text to public GitHub.
3. For any confirmed errors, use the existing **new task-version + approval** workflow, preserving immutable published originals and active-session pinning. Do not patch `approved` rows in place.
4. For any authentic retrospective signoffs, store separately traceable evidence under the approved private governance procedure; do **not** retroactively manufacture independence by replacing matching reference strings.
5. Only after authorized real approvals may the owner decide whether the current localization satisfies the academic bar. No automatic public release or entitlement change is licensed by this document.

## Explicit no-change constraints

- No edits to Mathematics rubric text, marks, task/version identifiers, translations, approved statuses, P1/P5 written flags or allowlists.
- No edits to Economics/Chemistry, other subjects, Tours, Practice, ratings, certificates, AI/Mentor or localStorage.
- No edits to student progress, attempts, sessions or history.
- No disabling `qa_open_all_core` or `qa_open_all_weekly`; no automatic mass release.
- The user intentionally deferred **authenticated learner E2E** and **four real weekly beta reviews**. Both are outside this audit and remain requirements before their respective later rollout decisions.

**Verification:** On 2026-10-29 the new SQL was run read-only against production and returned `REVIEW_PROVENANCE_UNVERIFIED` for all four P1/RU, P1/UZ, P5/RU and P5/UZ groups; all source checksum coverage counts matched.
