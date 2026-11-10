# Economics 9708 — private v9 retest admission and native-exposure safety checkpoint

**Date:** 31 October 2026  
**PR:** #430, DRAFT; no merge, no production migration, no browser entry  
**Status:** **HOLD / NOT RELEASE-AUTHORIZED**

## Protected bank integrity (metadata only; NO question content)

- Source v8: `Economics_9708_P1_P3_71_Same_Skill_Retest_Combined_CAUSAL_ANALYSIS_CORRECTED_PRIVATE_v8_20261030.json`, SHA-256 `d5534d23bbc5a849ee550912f03dfb552db0de8713ac48de65f747e3e99907c5`.
- Candidate v9: `Economics_9708_P1_P3_71_Same_Skill_Retest_INTERNAL_MULTI_PASS_QA_PRIVATE_HOLD_v9_20261030.json`, SHA-256 `8774a2616ff76ca68c12aad93bdcca40541c4c7848426e6fa578c3c2401fb200`.
- Private supporting files: `Economics_9708_71_Internal_Academic_Corrections_and_Integrity_v9_PRIVATE_20261030.json` and `Economics_9708_71_Internal_Multi_Pass_Item_QA_Ledger_v9_PRIVATE_20261030.json`.
- 71 distinct current skill candidates: P1 35, P3 36. Compared with v8: nine semantic retest redesigns, nine reference/wording corrections, 53 item records unchanged.
- Review method **internal multi-pass academic QA** (not human external-expert sign-off). Structural integrity passing is not proof of semantic independence, Cambridge endorsement, readiness, or authorization for learner delivery.

## New additive offline check (no protected source in repo or CI)

`scripts/qa-economics-private-retest-v9-integrity.cjs` validates the actual four private local files, including pinned byte SHA-256, full canonical item hashes, ordered item keys, unmodified skill/paper/syllabus/AO, the 18-entry revision manifest, per-language answer consistency and immutable release flags. It refuses unexpected edits and does not print stems, keys or answers.

`scripts/qa-economics-private-retest-v9-integrity.test.cjs` is deliberately **fictional data only**, executed in the existing `Economics Retest Semantic Revision Gate (Synthetic)` workflow. These tests do not get any private Library file or user data. The real private files were also checked outside GitHub for byte hashes, 71 item identities, full 18-key diff and linked ledger answers; that check alone is not a full browser/backend acceptance test.

Run the full private gate **only in an authorized offline environment**, passing these four paths in order:

```bash
node scripts/qa-economics-private-retest-v9-integrity.cjs PRIVATE_V8.json PRIVATE_V9.json PRIVATE_V9_CORRECTIONS.json PRIVATE_V9_LEDGER.json
```

All inputs remain in the owner's private Library, not in public repository assets.

## Native exposure guard: discrepancy found and corrected in DRAFT SQL

Read-only metadata inspection of actual Economics native MCQ attempts shows snapshots have `source_id` (number) and `snapshot_md5` (string), **not** `item_key`. Their `items` are arrays and `responses` keyed objects. Therefore the earlier `shown->>'item_key'=r.item_key` condition alone did not exclude known legacy source exposures.

The staged, **unapplied** SQL now supports optional `known_legacy_source_id` and `known_legacy_snapshot_md5` for sources that have a known legacy origin, checks both fields against the student's entire native MCQ show history, and still checks `item_key` for future formats. The immutable-source trigger protects these fields once a retest has been issued. The isolated fictional PostgreSQL fixture now uses the actual snapshot field names and includes a refusal case for a user who previously saw the known legacy source.

**Important limitation:** V9 is a bank of newly authored, never-published original candidates. Their legacy provenance fields may correctly be NULL. A null ID/hash proves nothing about semantic originality or prior exposure outside native MCQ sessions. The independent academic comparison, future cross-bank content fingerprints and explicit approval remain separate gates. No candidate has been imported or approved by this patch.

## Live project and release boundary

- A read-only check found no `private/public.iclub_econ_retest_%` tables in the current production Supabase.
- No production schema or data was written, no original attempts or feedback were rescored, and no user progress/localStorage was touched.
- This PR is not the deployed app; it changes only a candidate SQL document, synthetic fixtures, verification scripts, and CI workflow.
- Existing Mathematics Exam Prep, Economics exams, Tours, Practice, P2/P4 self-review and certificates must remain unaffected.
- **Still required:** tested Supabase-specific staging with rollback/backup assurance; authenticated JWT/REST/RLS positive and negative E2E; full source provenance/independence review, exposure and multi-alternative policy; browser/mobile resume and idempotency; explicit architect approval before a narrow controlled release.

A green isolated PostgreSQL or synthetic JS workflow alone is **not** a GO decision.
