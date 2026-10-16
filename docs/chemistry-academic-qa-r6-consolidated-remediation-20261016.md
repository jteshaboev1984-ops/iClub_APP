# iClub Chemistry 9701 — R6 consolidated academic remediation

**16 October 2026 · Editorial/academic handoff · NO PRODUCTION MUTATIONS**

## Decision taken

The 56 previously flagged live Chemistry question IDs are now assigned a concrete **future-only remediation path** without rereading the 630-question bank or invalidating student history. These are **proposals and decisions**, NOT 56 fixes installed or 56 independently proven errors.

| Group | IDs | Current state |
|---|---:|---|
| R5 ready for guarded release | 8 | Previously academically SELF_VERIFIED; explicit Preview E2E and exact-content GO outstanding; source P0 #3373 remains live |
| R6 new offline editorial candidates | 28 | 8 language-only future clones; 6 diagnostic-explanation future clones; 8 upgraded hard application items; 6 additional reasoning/content replacements |
| R6 evaluated KEEP/dependent dispositions | 20 | 7 textbook enrichment Practice items retained with **no Cambridge outcome credit**; 4 acceptable spaced-recall items; 7 paired-source items retained only once the counterpart R5/R6 question is replaced; 1 numeric-precision caveat; 1 prerequisite mapping issue still needs curriculum-context confirmation |
| Total previously flagged | **56** | **All 56 have a recorded path; NONE should be marked production-remediated yet** |

**R6 exact structure:** 28 unique source question IDs: 8 localization overlays, 6 improved explanation overlays and 14 fully authored three-language replacements. Existing IDs/attempts are never overwritten by this package. A future approved release creates brand-new IDs and switches only affected bank membership links, preserving question order and archived originals.

### Meaningful fixes prepared together

- **Language parity (8 locale-only):** #5317, #5333, #5340, #5346, #5355, #5367, #5371, #5373 — provide specific replacement RU/UZ stems, explanations and options where necessary, without changing EN/key/difficulty.
- **Non-diagnostic explanations (6):** #1927, #1939, #1941, #1945, #1984, #2021 — give actual mechanism/causal reasoning in EN/RU/UZ, not the answer restated.
- **Real hard-level application (8):** #5310 polyester repeat from diol + diacid; #5319 chlorine isotope pattern + molecular ion and fragmentation; #5345 aromatic acid chloride + diamine polyamide; #5353 combined 1H NMR integration/splitting; #5378 aldehyde/ketone tests **and** HCN stereochemistry; #4003 bridging AlCl₃ dative bonding; #4717 half-life deduced from three halvings; #4734 E° and ΔG° with correct electron count.
- **Six targeted content/problem upgrades:** #3139 acidic permanganate half-equation, #4744 initial-rate comparisons + k with orders **0 and 2**, #4753 Ksp for M₂X₃ rather than another 4s³ task, #8567 new AS bonding and polarity question instead of book-only latent-heat test; #1946 combustion elemental/molecular formula, #1965 hydrocarbon combustion stoichiometry.
- **Eight already ready R5:** #3106, **#3373**, #4757, #9797, #9801, #9824, #9831, #9835. R5 file and gated SQL are included unchanged as prior evidence.

### Official Cambridge 9701 checks that materially changed the package

- For §26.1.2(a) **rate orders m and n are limited to 0, 1 or 2**. A preliminary fractional-order experiment was **rejected** and replaced by #4744 using 0th-order A, 2nd-order B and a numeric rate-constant calculation. Source: Cambridge International AS & A Level Chemistry 9701 syllabus 2025–2027, p. 43, https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf
- Original #8567 was previously marked BOOK_ONLY_EXTENSION in a Season2 Tour 2 assessing early AS material. Instead of substituting the **A Level** atomisation/Born–Haber definition in an AS-positioned bank, #8567 is proposed as an **AS molecular-shape and bond-dipole** question (OF₂, central atom with 2 bonds and 2 lone pairs; unique D: bent, polar).
- R6 #5310/#5345 use Cambridge §35.1 condensation/polymer structure; #5319 uses AS §22.2 mass spectra, M+2 chlorine pattern and fragment interpretation; #5353 uses §37.4 proton NMR integration/splitting. #5378 links qualitative organic tests and chiral centres.
- **No use of textbook chapter numbers as if they were official syllabus outcome numbers.** R5 retains its individually mapped objectives. For R6, exact objective mapping still needs per-item verification against the official syllabus prior to release.

### QA evidence and its limits

- `R6_QA_RESULTS.json`: **110/110 offline assertions PASS** for IDs, all required fields, bilingual parity fields, MCQ alternatives, unchanged source format from previously gathered source snapshots, disjointness from R5, math checks and all 56 disposition classifications.
- Independently recomputed numerical outcomes for #1946 (C₄H₈O₂), #1965 (C₄H₁₀), #3139 (8), #4744 (k=0.400), #4753 (1.08×10⁻¹³), #4717 (2.31×10⁻²), #4734 (−88.8 kJ/mol) and mass/isotopic/NMR constraints. This is content self-review, **not** third-party accreditation.
- **Not** a full native-speaker RU/UZ review, real student A/B pilot or psychometric validation. Labels must remain `EDITORIAL_SELF_REVIEWED_OFFLINE_HOLD` until user-path testing.
- A read-only batch of 28 source current-state fingerprints was **blocked by platform safety** in this run. No bypass was attempted. Therefore **R6 live source PRE-FLIGHT NOT PASSED**: source MD5, question version absence and membership slot checks are mandatory again immediately before any future installation. Last earlier source read is not substituted for fresh preflight.
- A logged-in protected Preview E2E is still **not completed**, and no test-user login was supplied. Deployment metadata does not establish functioning grading, language rendering, navigation or progress persistence.

### Production-safe release contract — ONE bundled controlled cutover, not micro releases

1. **Before any mutation:** Validate the immutable R5 file sha256, R6 JSON sha256, newest DB 36 old-source content fingerprints and active bank/slot memberships, protected Preview student flow, then explicitly approve the exact combined content and switch scope. The blocked preflight must be resolved normally; do not retry a blocked access via a workaround.
2. Prepare **one atomic transaction** with 36 new question rows, version links and change-decision records, isolated private snapshots of original question records/memberships, strict MCQ/input grading acceptance and rejection cases, and one-for-one link switching. Preserve 70 Practice per tour, 20 S2 Tour per tour, original order numbers, Season2 `draft`, and all original attempt/answer rows. Generic typed-answer evaluators must be checked for new molecular-formula inputs.
3. Ensure users' active-session semantics and client/localStorage compatibility before change. **Do not alter old question rows, past scores, ratings, certificates, seasons or subjects other than Chemistry.** A failed assertion must roll back **all** new rows and active link changes.
4. After deployment: check targeted 36 links, 7×70 and 7×20 membership invariant, preserved Season1 question IDs and student history, core grading and EN/RU/UZ in protected Preview. Mark complete **only after actual execution evidence**.

**Decision:** No production release is recorded in R6. The critical old q3373 remains active until a supervised, verified cutover. Existing R5 guarded SQL remains `GO/E2E=FALSE`; do not flip booleans to bypass missing evidence.

## File manifest

- `R6_EDITORIAL_CANDIDATES.json` — 28 human-readable, grouped, future-only candidate overrides / fully authored items.
- `630_Question_QA_Traceability_Ledger_v6.csv` — all 630 active question IDs and all previous R1–R5 statuses retained; new R6 decision columns appended.
- `20_KEEP_AND_DEPENDENCY_DECISIONS.csv` — explicit decision and still-unmet dependency for the 20 not needing new content yet.
- `R6_QA_RESULTS.json` — audited 110 assertions.
- `create_R6.py`, `verify_build.py` — reproducible authoring and QA source.
- `R5_8_TARGETED_REFINED_CANDIDATES_EN_RU_UZ.json`, `R5_ATOMIC_RELEASE_SELF_VERIFIED_GO_E2E_GATED_NOT_EXECUTED.sql`, `R5_ACADEMIC_SELF_VERIFIED_RELEASE_GATE_2026-10-16.md` — previous eight candidates and unreleased fail-closed deployment evidence.
- `SOURCE_SHA256_MANIFEST.csv` — SHA256 of each shipped artifact; no package contents were executed against production.