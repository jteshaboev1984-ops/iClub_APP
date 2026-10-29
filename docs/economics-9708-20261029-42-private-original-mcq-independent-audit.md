# iClub APP — Economics 9708 P1/P3: direct audit of 42 private original MCQ candidates
**Date:** 2026-10-29. **Status:** INTERNAL REVIEW / PRIVATE DRAFT; **NO content approval or production publication**. Repository branch: `audit/economics-9708-master-coverage-20261029` (PR #419, draft). Cambridge primary: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf (Version 2, Dec 2025). Live program `economics_9708 / economics_2026_2028_v1`.

## 1. Source truth — verified actual bytes, not earlier working-plan text
User-owned private Library path `/iClub APP/Exam Prep/`:
- `iClub_Economics_P1_30_original_CLOSED_CANDIDATE_20261029.json`: **30 items**, raw-file SHA-256 **`78e624bb8a6c45f5dc79f14d527ae3903a2fd8981fec64a247c6a859023e1a91`** (same hash recorded in working plan).
- `iclub_Economics_P3_12_Independent_Diagnostic_Candidate_PRIVATE_20261029.json`: **12 items**, raw-file SHA-256 **`dee0362c4aeca36f6f1907968498a693cba217f4726b6dc3ed2003c3e7eda70f`**. Not a full 30-MCQ paper.
- The private question texts, choices, explanations, correct answers and individual key fingerprints were *read for this review* but are **not reproduced** in public GitHub.
- Raw JSON verified: total **42 unique item keys**, 42/42 independently recomputed per-item SHA-256 integrity, 42/42 EN/RU/UZ question, four-option arrays and explanation fields structurally present. P1 answer-letter distribution A7/B9/C8/D6; P3 A3/B3/C3/D3. Distribution is *not* evidence of correct economics or AO.
- Cross-check against **1,644 active published legacy Economics MCQs**: **0 exact lowercased-trimmed English question-stem matches** (MD5 compare). A 42×1,644 lexical 3-word-gram Jaccard screen found no score >=0.4 (highest observed 0.294 for one shared XED concept); **semantic equivalent rewordings, past learner exposure beyond legacy membership and copyright provenance still require independent checking**.
- Sampled numeric-value and RU/UZ-language parity. Text token comparison differences were chiefly alternative decimal punctuation, order and omission of redundant context; no basis to declare a final certified translation pass. Full independent linguistic second review remains OPEN.
- Existing authored item keys, content, private original file hashes and historical learner data are preserved.

## 2. Critical P1 canonical skill-key defect and version-safe repair

**12/30 P1 items** (the `EC9708-P1-U24-ORIG-001..012` sub-batch) used noncanonical `ECON-9708-[official-point]-ORIG-U24-xxx` skill IDs that **do not exist** in the live 498-skill taxonomy. Attempting to approve/import them as currently keyed would fail a legitimate canonical FK/join or create a parallel learning-map. This is a PRIVATE DRAFT defect, not a defect in the currently approved 36 P1 questions.

Fix chosen: map each item to the *already-existing* canonical skill ID, **without adding any new skills or changing existing session/plan tables**. Full 42-row, source-free metadata inventory:
`exam-prep/academic/economics-9708-coverage/20261029_42_original_private_candidate_academic_mapping_inventory_v1.csv`.
Special case `EC9708-P1-U24-ORIG-008`: the authored question tests **equality of circular-flow injections/withdrawals**, which directly matches syllabus **4.2.3**, not only identification under **4.2.2**. Its proposed primary official point is changed to 4.2.3, using existing `ECON-9708-4.2.3-BASE`. This is an academic attribution correction, not a content rewrite.

All 18 earlier P1 original skill IDs and all 12 P3 original skill IDs existed in the live 498-skill map. Following the 12 source-only repair mappings, **42/42 proposed canonical IDs correspond to live skills with exact official code agreement**. No corresponding DB row has yet been added/approved.

A separate **P1 30-item private-only versioned copy** was generated in the working container:
`iClub_Economics_P1_30_CLOSED_MAPPINGFIX_v2_20261029.json`
- Parent raw SHA: `78e624bb8a6c45f5dc79f14d527ae3903a2fd8981fec64a247c6a859023e1a91`.
- New raw SHA: **`153250faf127ca3248b316c102a2e884b94763a69534ffc78a9692369aec0099`**.
- New canonical ordered-item content SHA: **`122737c207b5aa55d1acf96283fe892178eeedbf0c4f0ecc2dbf99c95ff45b49`**.
- Exactly 12 `skill_key` metadata changed and **one** `syllabus_point` changed; 30/30 EN/RU/UZ texts, answer keys, distractors, correct answer and explanations **byte-wise content-equivalent** to the original source. Modified per-item canonical hashes recalculated and validated. Old 18 unchanged legacy review hashes preserved; new all-30 canonical hash map recomputed. New file remains `PRIVATE_DRAFT`, with release and server issuance explicitly false.
- **Persistence limitation:** automatic upload of this new private version to personal Library was attempted but the Files backend returned `container_session_expired` three times. Consequently **it is NOT in Library or GitHub**, and should be downloaded or re-imported into personal Library before a later session relies on it. Never assume it was published. The original Library source remains available and untouched.

## 3. Significant exam-blueprint vs private authored mix mismatch

Official approximate component AO weights (Cambridge syllabus printed p14): **P1/P3 AO1 47%, AO2 40%, AO3 13%**.

Private draft tags (not official mark allocation):
- **P1 30 items: AO1 2, AO2 28, AO3 0.** This is heavily AO2-weighted and has **no explicitly labelled AO3**. One 30-item authored learning set is not an exam-faithful blueprint or a separate unseen retest reserve. Do not solve this by simply relabelling items; inspect the reasoning and write new evaluation items where genuinely missing. Also balance calculation, interpretation, diagram and application capability rather than only aggregate AO counts.
- **P3 12 diagnostic items: AO1 0, AO2 9, AO3 3.** This is a provisional diagnostic, **not** a full official Paper 3. AO3 tags on `EC9708-A2-ORIG-003` (Phillips curve) and `EC9708-A2-ORIG-005` (trade diversion) may be AO2 classification/causal analysis rather than actual evaluative judgement. `EC9708-A2-ORIG-004` (supply-shock policy trade-off) is the strongest provisional AO3 among those three; specialist adjudication required. More complex distractors alone do not create AO3.
- Despite three-language structure and first-pass answer plausibility, academic QA requires independent distractor-by-distractor challenge, realistic unfamiliar context, graph interpretation, economic classification and genuine AO3 balance.

## 4. What these 42 private items could actually add after approval

Exact proposed direct canonical skills are unique *within each private paper batch*: P1 30 unique, P3 12 unique. However, **5 P1 and 1 P3 already have an approved MCQ on the same direct primary skill**. These are valuable alternative contexts, but they do NOT add new canonical-skill presence.

| Metric | Live approved now | Private existing direct-skill overlaps | Maximum additional first-skill evidence if all pass | Hypothetical total, NOT live |
|---|---:|---:|---:|---:|
| P1 | 35/200 | 5 of 30 | +25 | **60/200 (30.0%)** |
| P3 | 36/298 | 1 of 12 | +11 | **47/298 (15.8%)** |

**No live approval or coverage changed.** This is a *mathematical ceiling conditional on future validation*, not an approved content expansion. Existing 165 P1 + 262 P3 direct skill deficits therefore remain LIVE unchanged.

Private P1 original unit mix **1:6, 2:6, 3:6, 4:6, 5:3, 6:3**, P3 diagnostic **7:3, 8:3, 9:2, 10:2, 11:2**, chosen for authoring; Cambridge does not prescribe these exact unit allocations. P1 six Unit 4 originals include only four new primary skill slots beyond current approved unit-4 questions (two already map to approved MCQ skills). This alone does not satisfy the full 46-skill breadth or create extra separate retest sets.

## 5. Targeted content and language risk observations

- `EC9708-AS2-ORIG-006`: progressive income tax arithmetic is correct under the stipulated model but tests a narrow application. Official AS 3.3.4 requires understanding redistributive policies including transfers, minimum wages and progressive/inheritance/capital taxation. This single item does not certify the entire point.
- `EC9708-P1-U24-ORIG-008`: proper direct requirement is 4.2.3 circular-flow equilibrium (corrected in private versioned candidate), while 4.2.2 injections/leakages is a prerequisite.
- `EC9708-A2-ORIG-005`: numerical customs-union trade diversion is plausible, but identifying trade diversion alone should not automatically count toward AO3; Cambridge direct point 11.6.3 is valid.
- `EC9708-A2-ORIG-003`: long-run Phillips curve and adaptive expectations logic plausible; AO classification uncertain until rubric-style challenge.
- Several English and RU/UZ items were spot checked for calculations. Numerical checks included tax-incidence arithmetic, CAB balance, growth rate/deflator, monetary multiplier, Giffen/monopsony concepts, circular-flow leakages, customs-union switching and Marshall–Lerner elasticity. No identified reason to reject an item solely for a wrong English numerical key during this bounded review. **Full independent response validation for every distractor and every locale remains OPEN**.
- Content files lack individually verified textbook edition/chapter/printed page at source-task granularity; existing canonical chapters/PDF navigation indices in master matrix cannot be claimed as source-level `book_ref` audit.
- The immediate blocker for *import* was canonical mapping, now corrected only in a **new private copy**. Future publication must use existing protected authorization, immutable snapshot/version governance, protected answer keys, independent separate diagnostic/retest sets and two-level academic QA.

## 6. Operational status and next step

1. Save the new P1 private mappingfixed copy to **personal Library**, not GitHub/public repo, so it can be audited from another chat. Verify new raw SHA after upload. Original is immutable.
2. Final specialist/second-pass evaluate 42 items, especially P1 AO3 absence, P3 AO3 labels, all four distractors, economic and EN/RU/UZ equivalence; preserve versioned corrections. No bulk PASS from presence.
3. Vet whether the new original stems are truly unseen/unequivalent to the legacy pool (token 3-gram screening alone is insufficient), and separate independent mock/diagnostic/retest reserves.
4. Prepare a **separate** versioned private Supabase candidate migration only after academic status is signed, with strict fail-closed service access and zero changes to existing Practice/Tours. No policy/feature toggles until explicit release decision.
5. Re-check current `main` and production SHA before any code work because other project streams evolve concurrently.
6. Re-run read-only counts and compare current progress whenever rolling forward: original verified live numbers P1=36 approved MCQ, P3=36, P2=14 and P4=8 released written tasks, written plan 3 advanced + 19 pending.

**Safety:** this report/CSV contains only private item keys, syllabus link metadata, hash references, status and findings. **No original private question text, answer key, or explanation is published in GitHub.** No production or user data changed.
