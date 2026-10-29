# Chemistry J23 v7 — exact-source technical, recovery and rights QA

**Date:** 2026-10-29  
**State:** CLOSED, unapproved, no learner availability.  
**Latest source version:** `chemistry9701_j23_20261029_as_91_sixfield_candidate_v7`.

## 1. Python packager contract — actually executed locally

A temporary copy of the current GitHub `scripts/subject-release-packager.py` and its companion synthetic test `scripts/test-subject-release-packager.py` was executed on Python 3.13.5. Results: **6 tests, all PASS** (successful staging-only package; invalid card SHA; missing locale; blank answer; mismatched Tutor/card SHA; wrong parent Theory byte SHA). None used actual learner data, real Chemistry answers or production credentials. The script was run from a local working copy, **not** a GitHub Actions runner. No workflow run was reported by GitHub for the PR head when checked. **This does not yet constitute Python execution against the full private v7 source export.**

## 2. Actual v7 bytes — independent runtime SHA and source contract

Both actual protected UTF-8 source strings were read transiently via the authorised Supabase connector **inside a private tool session**, not printed in chat and not written into public GitHub:

- Theory: **681,779 UTF-8 bytes** / 91 records.
- Tutor: **716,882 UTF-8 bytes** / 273 records.
- Combined material: **1,398,661 UTF-8 bytes** before one zero separator byte.
- Verified a separate pure JavaScript SHA-256 implementation first against Python-known `abc` and mixed-Unicode test vectors.
- **Every** source-derived SHA matched the database's recorded digest:
  - Theory: `0fcba21ee2f6c6d1c25dcde29c11b6d7afc837033d422927d663615e52b7b2f3`
  - Tutor: `5014e71ed1d99ef0131c6d17092d7caf8ec9204fb2926220dd987176672fbf29`
  - Combined `Theory UTF8 + 0x00 + Tutor UTF8`: `197400f1701b424d541bb55c001bfe62eb27a45a1204b3730512a618e7179e27`
- Separately parsed the actual source JSON and recalculated **all 91 per-card SHA-256** using recursively sorted compact `{"locales":...,"skill_key":...}` format required by the real Python packager.
- **0** invalid card SHA, **0** missing six-field locale sets, **0** duplicate Theory keys, **0** duplicate Tutor `skill_key/locale` keys, **0** mismatched Tutor source pointers, **0** blank Tutor required fields, correct package-parent Theory digest.
- These steps independently validate the **real package content**, but are not described as a full end-to-end Python packager run.

## 3. Restoration drill — within the existing Supabase database

Added and **ran** `supabase/tests/chemistry_j23_v7_private_bundle_reconstruction_readonly.sql`. The query reconstructs 91 Theory and 273 Tutor entries from the raw private UTF-8 JSON bundle, independently compares each field against the protected candidate tables and checks all SHA values. Results: **91/91 Theory, 273/273 Tutor, 273 complete locale sets; 0 field/content/source-link mismatches and 0 orphan Tutor; one non-crediting enrichment item.**

**Very important:** This is a **logical reconstruction drill inside the existing database**. It is **not** a tested offsite backup, a separate disaster-recovery environment, or confirmation that private J23 authoring seeds are restorable from public GitHub. The repository is public and does not contain those protected drafts. A separately secured external seed export + actual restore test still blocks merging and launch.

## 4. Closed application access verified

Executed the current `public.iclub_exam_chemistry_j24_theory_catalog_v1` and `...lesson_v1` for **en, ru, uz** in a read-only test. All **six** calls returned `{"ok":false,"code":"not_available"}`. J24 control remained `enabled=false`, J25 `audience_mode='closed'`. Regression test stored as `supabase/tests/chemistry_j24_closed_trilingual_access_readonly.sql`. No learner, practice, tour, score, ranking, local storage, Economics or Mathematics data were edited.

## 5. Book and third-party rights screening — NOT cleared for reuse

The Lawrie Ryan/Roger Norris Cambridge International AS/A Level Chemistry Coursebook third edition is a **copyrighted Cambridge University Press work**. Cambridge's current rights and permissions guidance distinguishes reproducing an *entire* work (rights licence) from reproducing *excerpts, translations, text and figures* (permissions). It does not establish that attaching a PDF to a private session grants redistribution or electronic-publication rights.

Official references:
- [Cambridge University Press & Assessment Rights and Permissions](https://www.cambridge.org/ae/rights-and-permissions)
- [Cambridge International guidance on permissions for copyrighted exam material](https://help.cambridgeinternational.org/hc/en-gb/articles/115004418469-How-do-I-apply-for-permission-to-use-Cambridge-copyrighted-material)
- [Chemistry 9701 endorsed resources — Cambridge University Press publisher](https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-chemistry-9701/endorsed-resources/)

**Release constraint:** Keep published lessons, self-checks and Tutor explanations as original project-authored explanations/questions grounded in chemistry facts and syllabus outcomes. Do not reuse or translate textbook prose, diagrams or proprietary examination questions/mark schemes without the applicable permission. Document the actual originality assessment and any granted licence prior to learner publication. We cannot infer a licence from a user-uploaded copy of the book, and an AI QA result cannot grant one.

## 6. Still outstanding before J24/learner access

1. Proven **private external backup/seed export and tested restoration** in a separately protected environment.
2. End-to-end Python packager execution over exported **exact v7** `theory_source_text` and `tutor_source_text` files; compare both file SHA and generated manifest to the values above.
3. Finish remaining substantive Tutor explanation/translation semantics and originality/rights check (not merely regex/structural checks).
4. Explicit architect approval for a controlled test-account gate, then the planned version-aware J24 catalogue/reader integration with historical sources preserved.

**Do not:** merge PR #397, open Chemistry to students, enable J24/J25, or treat test-packaging, same-database reconstruction or in-session rights research as a complete production release.
