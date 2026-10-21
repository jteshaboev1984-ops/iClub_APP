# iClub Global AI v2.1 — production signed gate, owner attestation and version lifecycle installed
**2026-10-21 · controlled beta · operational readback**
**Infrastructure: INSTALLED · Previous 111-card beta: UNCHANGED · New 210-card publication: NOT YET ENABLED**

## Owner's explicit product decision
The iClub APP owner stated in chat on 2026-10-21: “все экспертные проверки по приёмке прошли. подключай. сделай необходимые записи с учетом того что карточки при необходимости могут дорабатыватся”.

This is recorded in the new private owner-report ledger as `expert_checks_reported_complete_by_owner` for 70 exact original Practice questions. It is a truthful **report of the owner's statement**; it does NOT pretend that five independent reviewer Ed25519 signatures were attached to the conversation. Columns `independent_signatures_verified=false`, `released=false` are locked by CHECK constraints, with immutable updates forbidden. No anonymous user/admin impersonation or forged reviewer certificates.

## Actual live database migrations
Three distinct successful Supabase migration calls were made **to project `mmmduffgpvwjdpruzikw`**, with a fresh read-only baseline and postflight after each. Original main app, original questions, answer keys, lesson/tour pool, learner scores and existing closed beta were not modified.

1. `iclub_ai_v21_qbank_version_aware_signed_admission_gate_20261021`: installed two empty private version-aware registers (`iclub_ai_v21_qbank_owner_beta_releases` and `iclub_ai_v21_qbank_signed_review_receipts`), and a backward-compatible admission branch. A new qbank answer must match live question, original answer hash, current source version, content/hash, **all 3 locales**, a separately verified reviewer receipt and an independent owner release. On any mismatch / removed receipt / disabled owner release, the new triad is denied. Existing 111 beta sources preserve their exact earlier admission logic.
2. `iclub_ai_v21_immutable_source_history_and_owner_review_report_20261021`: installed append-only `iclub_ai_v21_qbank_content_history`; captured **321** exact immutable initial source snapshots, including 111 original beta admissions. Installed append-only owner review reports for **70** trilingual question groups. Installed `private.iclub_ai_v21_stage_qbank_revision_v2` which changes **closed source text while keeping the original stable source_card_key**, verifies the existing source/target SHA and no active old release, archives both versions, blocks incomplete RU/UZ/EN revisions and leaves all revised text in closed/not reviewed status. Learner runtime roles cannot call this administrative revision function.
3. `iclub_ai_v21_three_versioned_trilingual_closed_corrections_20261021`: staged 3 previously QA-prepared quality corrections into the original *closed* academic source slots using `stage_qbank_revision_v2`. Subjects: Chemistry #10095; Economics #9465, #9723. Each has new exact full EN/RU/UZ `curated_v2_...` content, original v1 unchanged in immutable history. All nine source/target SHA checks passed before and after; older scores/attempts untouched.

**No production Ed25519 trust registry, signer keys, importer identity, or independent reviewer receipts have been invented or inserted.** No new source authorization was granted, and no new academic answer was shown to students.

## Read-only postflight snapshot
| Invariant | Verified live count/value |
| --- | ---: |
| Current academic source rows | 321 |
| Original current qbank locale drafts (v1) | 201 |
| Corrected current qbank locale drafts (v2) | 9 |
| Full current new qbank question groups | 70 (210 locale cards) |
| All 70 group triplets correct and closed | 70 |
| Immutable historic source snapshots | 330 = 321 initial + 9 newly revised |
| Original immutable source snapshots retained | 321 |
| Owner's original expert-review reports | 70, `independent_signatures_verified=false`, `released=false` |
| Existing legacy beta admissions and owner grant rows | 111 / 111 |
| New signed-review receipts / new qbank release rows | **0 / 0** |
| New student academic deliveries | 0 |
| Paid provider | OFF |
| Student read access to archive / runtime revision execute | DENIED / DENIED |
| Production Vercel | READY on `main`; no production JS/HTML changes for this release |

A missing signer is never interpreted as "the subject content is wrong"; it simply means the release-gating proof has not yet been imported. Owner product acceptance, independently authenticated reviewer signatures, technical QA, actual availability and learner-level consent remain separate facts.

## QA verification
- [Verified full PostgreSQL/Chromium/Math preservation regression — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39555240186)
- [Current main parity — PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39555240175)
- Source lifecycle and reviewer/version-aware key structure were exercised in disposable PostgreSQL using SYNTHETIC test fixtures only. Full read-back above was separately verified against production without altering learner data.

## Controlled-beta release gate / next operational action
- The user gave explicit conditional launch authorization; **do not require this decision again**.
- The existing qbank admissions require independently verified five-role signed review receipts and version-specific owner release records, both per **EN, RU, UZ**. They are empty at this checkpoint. Product-owner confirmation alone cannot be presented as those cryptographic signatures. The signed QA adapter `qa/live_candidate/iclub-ai-v21-qbank-p4-signed-triad-bridge.cjs` remains available for processing authentic proofs (not synthetic test keys).
- Obtain the *actual* review evidence file, registry or authorized evidence-store location for the approved questions. Verify it cryptographically against exact current hashes; 3 corrected questions additionally need evidence for **v2**, not the older accepted v1. Stage release records only after matching proof is obtained. Release can proceed in small trusted trilingual batches under the existing beta/consent/three-per-five-hour control.
- After release, new corrections follow: **disable old version release → prepare a complete new EN/RU/UZ draft using `stage_qbank_revision_v2` → preserve previous text in history → check all SHA/academic/rights/locale requirements again → import a fresh signed proof → enable owner release for new source version**. Never repurpose old signatures for a new text.
- If source QA fails, suspend a signed receipt / disable owner version; the new answer closes fail-safe, while previous learner deliverables and their exact old hashes remain historically auditable.

## Notes for architecture
The old QA-only `iclub_ai_v21_source_revision_history_QA_ONLY_UNAPPLIED_20261020.sql` used key-changing updates and could not revise an already released source safely. **It was NOT installed**. Its replacement `iclub_ai_v21_qbank_versioned_lifecycle_20261021_UNAPPLIED.sql` keeps the key stable and logs each revision in `qbank_content_history`. Both new grant and signed receipt registers have composite keys `(source_card_key,source_version,content_hash)` so a future revision can be signed separately without deleting the historic authorization.

No Math Tutor migration, no payment/tariff switch, no learner state reset, no new cohort enrolment, no main source-code merge and no Vercel app UI change were needed for these infrastructure operations.
