# iClub Global AI v2.1 — delegated final acceptance / conditional controlled-beta release
**Decision date: 2026-10-20**  
**Scope: 70 additional Chemistry/Economics active Practice questions (210 EN/RU/UZ source drafts)**  
**Decision: NO-GO for the 210 new learner-facing academic cards. Existing closed beta remains as is.**

## Authorization and interpretation
The iClub owner delegated technical and content acceptance to the assistant, allowing release **only if acceptance is actually satisfactory**. This is conditional authorization, not instruction to fabricate rights provenance, sign for several independent human reviewers, enable unreviewed records, waive the Master Plan or alter real user progress.

Source materials were checked against `docs/iclub-ai-layer-master-plan-v2.1.md`, `04_Content_Governance_Model_P1_P5_v1.1(1).docx` (strict original-content copyright/provenance firewall), `06_AI_Layer_Safety_Architecture_P1_P5_v1.1(1).docx` (non-authoritative AI), `07_Beta_Release_Plan_P1_P5_v1.1(1).docx` (P0 blocking gates), previously tested QA, exact production source state and supplied Cambridge chemistry/economics coursebooks. Exact textbook chapter matching was used as *background*, not proof of iClub ownership.

## Acceptance evidence already obtained
| Test | Result / correct interpretation |
| --- | --- |
| Live source baseline | 321 academic rows, 111 existing admitted (unchanged), 210 new fully closed draft rows |
| Existing cohort and model | Existing owner release rows 111; provider OFF; zero confirmed actual academic deliveries |
| Structural new-question QA | 70/70 have EN/RU/UZ questions; 63 MCQ (A–D keys) + 7 input (nonblank keys); all 63 MCQ options translated; no blank EN/RU/UZ question |
| New source version SHA and live question fingerprint | 70/70 passed previous read-only technical preflight; copied snapshots pinned in 70-row reviewer queue |
| Localized content screen | All 70 tri-locale explanatory texts screened for numeric omissions/shortening; two material omissions independently flagged (#9465 UZ and #9723 RU/UZ). Numeric scans are **not** equivalent to 70 full academic + translation signoffs |
| Eight editorial holds | 5 Chemistry topic/subtopic classifications and 3 explanation/translation correction cases; all tracked by IDs |
| Correction proposals | 3 full EN/RU/UZ AI-only explanation revisions and 5 taxonomy-only proposals; all remain PENDING / NOT_APPROVED |
| General frozen regressions | [Full isolated PostgreSQL/Chromium QA PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39438170426); [main compatibility PASS](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39437772429) |
| Production release readiness | Executed `qa/live_candidate/iclub_ai_v21_new_batch_owner_acceptance_READ_ONLY_20261020.sql` in real Supabase; decision `NO_GO__NEW_APPROVAL_AND_IMMUTABLE_HISTORY_NOT_DEPLOYED` |

## Hard blockers (independent, not solved by a green test)
1. **Authenticity/rights:** existing `public.questions.explanation_*` fields and a `book_ref` do **not** certify that iClub owns original explanations or holds the redistribution/republication rights needed for Global AI. No supported ownership/provenance record exists for 210 new source rows in the new release path. The Cambridge books are commercially copyrighted third-party reference texts and cannot substitute for iClub originality evidence.
2. **Academic/language decision:** every new row still has `content_reviewed=false,rights_reviewed=false,locale_reviewed=false,academic_qa_passed=false,published=false,revoked=true`; the 70-question reviewer matrix still has eight named gates PENDING. Automatic correctness/key/translation checks do not equal independent academic review. AI may provide technical/editorial suggestions but must not assert several independent human Ed25519 signoffs.
3. **Governance interface mismatch:** the existing QA-only P4 signed editor operates on `practice/answer_explanation` and hashes its **source text + newline + canonical prepared variants**; the actual beta works on `practice_error` with `SHA256(body_text)`. Automatically reusing a signature or source_hash would authorize a different object and fail the original contract.
4. **Missing safe release infrastructure:** new source provenance release table and append-only revision archive were tested on disposable PostgreSQL but do **not** exist in production. Installing scratch SQL directly into production is not authorized or independently rehearsed as a migration.
5. **No positive real beta academic delivery:** observed zero real successful academic deliveries; a production launch cannot be described as student-E2E-validated based on synthetic tests.

No release because these are failed **product** acceptance gates. The original, previously authorized 111 cards remain admitted; do not pause those solely because new batch is held.

## Safe operational continuation, no bypass
1. Keep 210 new drafts closed. Retain old 111 and the existing three-person beta boundaries, untouched Math Tutor, provider OFF and old production Vercel/main SHA.
2. Collect genuine question-by-question iClub origin/rights proof, review entire EN/RU/UZ question + answer + options + explanations, resolve the 8 identified holds and produce immutable revised versions as needed. Academic + language reviews can be AI-assisted, but legal source permissions and independent official reviewer signatures cannot be invented.
3. Adapt the **existing** editorial signature protocol to the exact live source and trilingual release group (no separate weak evidence chain); run real scratch release tests and a planned reversible production migration, preserving no-edit learner history.
4. Only after these gates, use conditional owner authorization for one narrow controlled release; confirm read-only baseline, no protected active assessments, all 3 languages and one consenting learner's natural finalized wrong Practice question. Reject without billing if any gate fails.
5. Keep a post-release kill switch/independent source revocation with exact version/hash and no changes to old scores.

## Artifacts in the existing QA branch
- `docs/iclub-ai-v21-qbank-70-editorial-review-queue-20261020.csv` — 70 hash-pinned trilingual editorial review records, all eight gates PENDING.
- `docs/iclub-ai-v21-70-draft-acceptance-tri-locale-screen-20261020.csv` — per-question EN/RU/UZ numerical/text-length screen; automatic heuristics only.
- `docs/iclub-ai-v21-3-trilingual-curated-content-proposals-20261020.json` — 3 proposed updated explanations.
- `docs/iclub-ai-v21-5-taxonomy-correction-proposals-20261020.json` — 5 proposed label corrections with original question fingerprint.
- `docs/iclub-ai-v21-p4-editorial-evidence-bridge-gap-and-70-source-handoff-20261020.md` — verifiable difference between editorial and live source routes.
- `qa/live_candidate/iclub_ai_v21_new_batch_owner_acceptance_READ_ONLY_20261020.sql` — rerunnable production read-only gate.

**Production actions in this acceptance turn:** zero migrations, zero publication, zero new permission records, zero Vercel deployment, zero original question/student writes. The user instruction to release *if all okay* is respected: the conditions were checked, some failed, and release was therefore withheld.
