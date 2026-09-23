# P5 original eight assessment compositions — review packet (DRAFT, 21 Sep 2026)

Scope: content version `p5_repr_beta_v1`, production assessment rows 1–8. These are **pre-existing published content**; this packet is neither academic approval nor authority to alter learner-visible records.

## Established technical root cause
The original `20260903143000_exam_prep_p0_08_rules_written_assessments.sql` inserted eight assessments directly with `status='approved'` but omitted `approved_at`. The subsequent `20260903144000_exam_prep_p0_08_qa_publish_gate.sql` checked status, not per-assessment approval evidence, and moved the eight to `published` without recording an approval date. Immutable audit INSERT/UPDATE snapshots support this sequence. Consequently, a null field is not evidence that a review did or did not occur; the exact historical human decision is undocumented in the accessible record. Never infer a sign-off from a content-version or item-level approval, and do not set historical `approved_at` to an inferred migration/audit time.

## Read-only production composition baseline
21 Sep 2026, one REPEATABLE READ / READ ONLY query. Each fingerprint is `md5(string_agg(md5(to_jsonb(assessment_item)::text), '' ORDER BY item_order))` for the corresponding set; generated solely to detect composition drift, **not** to substitute academic review. All eight rows are `published` with `approved_at IS NULL`. All 21 question items and three written items have the existing per-item QA/copyright flags passing; aggregate checks found no cross-set duplicate question IDs, wrong P1/P5 skill owners, unexpected reserve roles, or duplicate positions. There are 12 marked holdout items. Passing item QA does not prove assessment-level blueprint, accuracy of academic interpretation, translation quality, or absence of an undocumented prior review.

| Existing ID | Key | Type | Questions | Written | Composition fingerprint |
|---|---|---|---:|---:|---|
| 1 | `p5_repr_diagnostic` | diagnostic | 3 | 0 | `1ff1e882e0bc03442e16d9a438e08d27` |
| 2 | `p5_dat01_learning` | learning | 3 | 1 | `171152eb351edd8016a228f7e07de999` |
| 3 | `p5_dat04_learning` | learning | 3 | 1 | `12d805e3953109e9bf6d3d9466d962b7` |
| 4 | `p5_dat06_learning` | learning | 3 | 1 | `426c761833cff983e4f10cb30af6a685` |
| 5 | `p5_dat01_retest` | retest | 2 | 0 | `58c354e445a7ab7e71391f48c1f6bf4d` |
| 6 | `p5_dat04_retest` | retest | 2 | 0 | `14c94b5f804a27d5482e4f6aabf173b7` |
| 7 | `p5_dat06_retest` | retest | 2 | 0 | `eadc1e3ecf809b121c138853577eed90` |
| 8 | `p5_repr_mixed` | mixed | 3 | 0 | `7662f9bca29416f5d1bbd9b68967399f` |

## Honest resolution workflow (not performed yet)
1. Search for independently dated, attributable approval of each exact assessment composition, not merely approval of source questions/whole content version. Match the reviewed composition to the current fingerprint or source manifest with item order and version. If a contemporary attestation exists, archive a verifiable pointer without modifying the original historic timestamp.
2. If an original composition-level approval cannot be established, a qualified academic reviewer must conduct a **new review now** of all eight actual sets and sign an actual current date, identity, source references and exact composition fingerprints. Check assessment blueprint/skills and Cambridge 9709 P5 scope, problem and answer mathematical accuracy, written rubrics, RU/UZ/EN equivalence, diagnostic/retest/mixed independence and reserves/copyright. Record findings per ID, including `pass`, `needs_revision`, or `cannot_verify`. A model's automated QA is only preparatory evidence, never a claim of independent human approval.
3. Any required corrections must be versioned and reviewed separately; never silently edit published frozen items or change historic learner attempts. Approval metadata, any new governance table and future publish-time gate require their own additive migration, independent DB/ACL/rollback test, and owner authorization. Preserve the eight original `created_at`, `approved_at`, existing published status and immutable audit trail until a truthful, approved change is ready.
4. For future assessments: separate `source_content_approved_at` from `assessment_composition_reviewed_at` and human reviewer evidence. Require exact current composition fingerprint and recorded review before an `approved` -> `published` transition, with deliberate exception handling for existing legacy published rows. Avoid blindly enforcing `approved_at >= created_at` on earlier inherited source-approval timestamps, which would misclassify historic records.

**Decision status:** technical omission identified; per-assessment historical academic provenance NOT established, no academic sign-off claimed. No production SQL writes, content edits, implicit risk acceptance, retroactive dates, or publishing changes are authorized by this packet.
