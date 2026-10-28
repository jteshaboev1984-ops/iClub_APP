# iClub Chemistry 9701 — J23 initial academic/source QA evidence
Date: 2026-10-28. **Audit stage 1 completed, not a full 154+12 scientific certification.**
Execution: read-only Supabase metadata and bounded source examination. Production source and learner records NOT modified.
Current version: `chemistry9701_20261022_stageb_draft`; composite source snapshot MD5 `cfd46b6e603abf046a1c5a25be051086`.

## Authority
- Cambridge International Chemistry 9701, [official 2025–2027 syllabus](https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf), especially 10.1 Group 2, 12.1 nitrogen/sulfur and 24.2 Nernst equation; [Cambridge qualification page](https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-chemistry-9701/).
- Project's `Tour Map v1.0 — Chemistry (7 туров)` in the source documents, describing five AS tours and two A Level tours.
- Private versioned iClub Chemistry Core skills, Theory, Tutor, LAB and source-item preflight views. These and their content hashes, not textbook chapter headings alone, identify the current candidate set.
- The supplied *Chemistry for Cambridge International AS & A Level Coursebook*, Ryan & Norris (third edition), used as a cross-check; no book passages transferred into the repository.

## Reproducible audit: 33 metadata controls
Script: `scripts/qa-chemistry-9701-j23-academic-source-inventory-readonly.sql`.
**Result 25 PASS / 7 HOLD / 1 FAIL**. Deliberately includes unresolved release items as HOLD/FAIL instead of disguising them as completed readiness.
- **Theory**: 154 records (91 AS, 63 A). 154/154 mapped to existing canonical Chemistry core skill, source hash, tour number and syllabus point. 0 cross AS/A tour assignments. All 154 EN/RU/UZ titles and explanations meet basic length/integrity thresholds.
- **Tutor source**: 462 records, 462 unique (skill,language) pairs; 0 missing Theory or stale source hashes; all four explanation fields exist and meet minimum lengths. **This is static source validation, not a functional generative AI Tutor verification.**
- **LAB**: 12 records, 6 AS P3 and 6 A P5, 12/12 draft, EN/RU/UZ explanation strings populated. These are **study cards**, not practical examinations.
- **Entry**: 22/22 syllabus units, 22/22 internal QA/independence metadata checks, but approved release manifest **0/22**.
- **Recheck**: 22/22 distinct units and internal QA/independence checks, but release manifest **0/22**.
- **Paper 1**: 45/45 draft rows structurally valid; 44/45 have seven recorded reviews. One current item has one FAIL and six PENDING reviews; **0 secure-issuable**, **0 approved manifest**, whereas 40 are required. No student exam should be issued.
- **Syllabus exceptions**: one card explicitly carries `NO_EXPLICIT_9701_OUTCOME`; two additional source mapping fields are labelled context/enrichment. These are not automatically eligible for scored Cambridge mastery.

## Academic issue ledger (no question stems, answers, or book text in Git)
| ID | Severity | Source key | Finding | Required remedy | Status |
|---|---|---|---|---|---|
| CH-J23-001 | BLOCK | `CHEM9701-P1-SECURE4-20261026-T12-02` | The existing `syllabus_scope` QA gate is FAIL. Its own review notes: this draft discusses sulfur oxides SO2/SO3 but is mapped to `CHEM9701-12-03` (nitrogen oxides) rather than intended `CHEM9701-12-04`. Other six gates are PENDING. | Preserve original draft and its review history. Author a **new, independently audited and versioned candidate** mapped to the correct syllabus skill, check both question and key, run all seven gates, dedupe against existing banks, then decide whether it belongs in the 40-item P1 manifest. Never flip the failed original to PASS. | BLOCKED |
| CH-J23-002 | HOLD | `CHEM9701-10-04` | `Flame colours and ion tests` is intentionally tagged `NO_EXPLICIT_9701_OUTCOME`. Official Chemistry 9701 2025–2027 §10.1 is about Group 2 reaction equations, stability and solubility trends. The Theory text correctly presents flame colours as supporting clues, not a specified stand-alone §10.1 outcome. | Preserve as labelled enrichment / practical observational clue only, **not an independent scored 9701 §10.1 mastery node**. Confirm policy for Theory navigation and student progress before any AS release. | HOLD pending product mapping decision |
| CH-J23-003 | HOLD | `CHEM9701-12-02` | Source mapping explicitly uses `7.1(10); 12.1 context only` for Haber process context. | Verify the actual §7.1 learning outcome and keep the industrial illustration from being misrepresented as a separate core 12.1 learning outcome. | HOLD |
| CH-J23-004 | HOLD | `CHEM9701-36-02` | Source maps protecting-group discussion to `36.1;PROTECTING_GROUPS_ENRICHMENT`. | Keep clear enrichment label and no extra Cambridge assessment/mastery claim unless syllabus review authorizes the specific application. | HOLD |
| CH-J23-005 | BLOCK | Entry/Recheck/P1 | Source banks exist but **0/22 Entry**, **0/22 Recheck**, **0/40 P1** owner-release manifest; no real student Chemistry tests or approved members. | Run original-science + trilingual checks on each candidate, version/approve exact hashes, test live authorized learner end-to-end in a controlled cohort. | BLOCKED |

## Bounded assistant-led scientific and language spot review
Seven distinct EN Theory worked examples across all seven instructional tours were independently recalculated/checked (sample; **not** 154-card approval):
1. `CHEM9701-02-04`: Mg + 2HCl mole ratios and ideal-gas molar-mass calculation (31.2 g/mol) numerically consistent.
2. `CHEM9701-05-02`: 50.0 g × 4.18 × 4.00 = 836 J; 0.0200 mol gives −41.8 kJ/mol. Second example gives −58.5 kJ/mol and correct heat-sign convention.
3. `CHEM9701-07-04`: ammonia equilibrium Kp expression, partial-pressure calculation, kPa⁻² dimensions and 1.85×10⁻⁶ kPa⁻² result consistent.
4. `CHEM9701-12-04`: balanced simplified SO₂/NO₂ catalytic and Contact-process reactions; distinction between acid mist and industrial oleum route preserved.
5. `CHEM9701-16-02`: primary/secondary/tertiary alcohol oxidation, distillation vs reflux and oxidant colour change consistent.
6. `CHEM9701-24-04`: Nernst equation, correct z=2, log10(0.0100)=-2, copper E≈+0.281 V; §24.2 official A Level scope.
7. `CHEM9701-37-01`: ethyl group ideal first-order triplet 3H/quartet 2H and exchangeable proton caveat consistent.
**Sample finding: 7/7 no obvious scientific/numeric mismatch in the inspected EN explanations.** This is deliberately **not** a result for the remaining 147 explanations and does not certify all third-language translations.
Extra RU/UZ comparison of `CHEM9701-02-04` and `CHEM9701-24-04`: chemical species, ratios, calculations, units, Nernst signs and major caveats semantically consistent in both languages. **2/2 sampled topics, 4 sampled translations**, not an exhaustive multilingual review.

## Product/academic distinction
The attached seven-tour map includes chapter-based teaching examples and per-tour question-volume planning. It is not a replacement for exact syllabus outcome IDs. In particular, the map's paragraph after Tour 3 saying this tour "ends AS theory" is not to be interpreted literally: Tours 4 and 5 are also AS topics. Keep the app's own level assignments 1–5 AS, 6–7 A. The source's "20 questions per tour" and "70 practice" describe Tour/Practice product design, not Cambridge Paper 1/2 assessment obligations.

## Release and safety conclusion
**J23 initial audit complete; academic full review remains IN PROGRESS.** Structural controls (25) passed, but 1 source fail and 7 further release/mapping holds remain. No source, flags, manifests, permissions, attempts, or user localStorage were changed.
- J24 AS Theory candidate content **cannot be marked ready merely from the 154/154 structural result**; needs full per-card semantic science/EN-RU-UZ review and an AS-only reader/security test.
- J26/J27 cannot open exams until 22/22 + 22/22 independently reviewed and release-manifest approved, plus authenticated canary testing.
- J28 P1 is BLOCKED, current 0 secure-ready and 1 failed item; never bypass original-review failure to fit 40 questions.
- Static authored Tutor sources are not generative AI Tutor; separate true model integration and owner permissions required.
- No Chemistry learner publication in this checkpoint. Existing Mathematics/Economics/Practice/Tours and student data untouched.

## Next execution checkpoint
1. Continue J23 per-card science and EN/RU/UZ review, prioritizing all 91 AS Theory and the 44 Entry/Recheck questions (answer-key review restricted to private channels; no keys in Git).
2. Preserve bad P1 original, prepare corrected authoring version for `CH-J23-001` with explicit mapping to `CHEM9701-12-04`, re-run seven independent evaluations; no release approvals until all pass.
3. J24 design AS-only reader/entitlement in a separate code branch; do NOT publish the 166 component package or enable LAB/Tutor in bulk.

## J23 continuation: AS locale numeric triage (91/91, no source changes)
Second read-only script: `scripts/qa-chemistry-9701-j23-as-locale-numeric-triage-readonly.sql`.
- Scans all **91 AS Theory records** in EN/RU/UZ, normalizes decimal comma vs point and Unicode super-/subscript digits, compares the *sets* of numeric tokens. No actual explanation text or answer keys are returned by the reproducible SQL; only skill keys and differences.
- **84/91** cards showed exactly equal unique numeric-token sets.
- **7/91** cards were flagged for human-style semantic triage: `CHEM9701-01-02`, `05-01`, `07-03`, `07-04`, `08-04`, `11-01`, `13-01`.
- Assistant reviewed EN/RU/UZ of **all seven flagged cards**. The discrepancies reflect harmless notation/wording, e.g. Uzbek `1/12` instead of spelling out one-twelfth, an English "one-step" explanation, explicit algebraic `0.60²` in one locale, and differently formatted chemical group labels. There is no identified **numeric value or equation inconsistency** in this flagged sample.
- Method limitation: token parity ignores sentence meaning, reagents, translation omissions without numbers, and false positives from chemical formulas. **Do not equate 84 matching token sets with 84 fully academically approved lessons**; 91-card scientific semantic review remains pending.
- Numeric triage does **not** change the 33-point release QA verdict (**25 PASS / 7 HOLD / 1 FAIL**), or the unreleased status of every Chemistry learner component.

## J23 targeted correction — prepared but NOT applied to Supabase
- The P1 question `CHEM9701-P1-SECURE4-20261026-T12-02` has a scientifically valid redox answer, but the current item is mapped to `CHEM9701-12-03` (nitrogen oxides), although its stem addresses the SO₂/O₂ → SO₃ step. The existing internal FAIL must remain permanent audit evidence.
- A **fail-closed, version-preserving corrective script** is staged at `scripts/chemistry-9701-j23-private-p1-syllabus-map-correction.sql`. It clones the protected source **inside private Supabase** (no stem/key in Git), maps the new authoring version to `CHEM9701-12-04`, regenerates its built-in source digest, inserts seven **PENDING** new internal review slots, requires the old failed source and source hash to match, and leaves all learner release/mastery flags false. The original draft and its failed review remain unchanged. This corrects the planned content→skill association without pretending the new review is already complete.
- **Execution status: NOT APPLIED.** A live Supabase write attempt hit a connector security block, and an earlier attempt revealed `item_md5` is generated; the prepared script correctly does **not** set that generated column. A subsequent live read-only check confirmed the original failed version = 1, corrected version = 0, P1 issuable = 0 and Chemistry publishing = OFF. Do not mark the issue resolved in the database or claim a new private candidate exists.
- A separate read-only scope check is staged at `scripts/qa-chemistry-9701-j23-as-scope-firewall-readonly.sql`; it must verify 90 core AS items, one unscored enrichment item, A Level separation, and the retained failure. Its whole-query live execution was blocked by the connector safety system in this run, so its status is **PREPARED / NOT EXECUTED**. The underlying counts were previously confirmed in smaller read-only queries.
- Neither script is auto-deployed or run as a GitHub migration. No protected item text, answer key, user identity, scoring state, public permissions or localStorage record was exposed or changed.


## J23 correction execution update — 2026-10-28 (supersedes earlier NOT APPLIED status)
The previous sections above preserve the **historical** initial audit and preparation checkpoint. The operator subsequently executed the guarded private SQL `scripts/chemistry-9701-j23-private-p1-syllabus-map-correction.sql` in Supabase project `mmmduffgpvwjdpruzikw` and independently verified its postconditions with live read-only queries.

- **APPLIED**: new private P1 draft `CHEM9701-P1-SECURE4-20261026-T12-02`, authoring version `iclub_original_private_j23_20261028_v5`, primary skill `CHEM9701-12-04`.
- Original `iclub_original_private_20261026_v4` remains immutable with `CHEM9701-12-03` and permanent `syllabus_scope=fail` review; its original seven QA records remain intact and source-hash-valid.
- New v5 has **exactly seven PENDING reviews**, including syllabus scope, correct answer and distractors, three languages, exam format and content rights. All seven source snapshots are hash-valid. No approval, student issuance, assessment eligibility or mastery credit.
- `private.iclub_exam_core_chemistry_p1_item_preflight_v1` returned `checked=1, all_preflight_pass=true` including direct skill, language structure, deduplication, seven pending slots and draft-only issuance denial.
- Separate live verification: J24 AS Theory gate `enabled=false`, zero active Chemistry beta members, and J12 `can_publish=false`.

**Status:** technical source→skill mapping mismatch corrected in an unpublished new version; the seven academic reviews have **not** passed. Therefore this does not change the initial aggregate 25 PASS / 7 HOLD / 1 FAIL historical audit or unblock Paper 1 release. Do not re-run this non-idempotent clone script; it correctly refuses duplicate v5.
