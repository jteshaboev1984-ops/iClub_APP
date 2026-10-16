# iClub Chemistry 9701 — R5 Academic Self-Review & Release Gate

**Date:** 2026-10-16  
**Reviewer:** ChatGPT (AI self-review; **not** an external chemist or independent linguist).  
**Scope:** the **same eight** R5 targeted replacement candidates. No re-review of the 630-question bank.  
**Result:** `SELF_VERIFIED` for academic content, three-language meaning, answer keys and distractors. **Production release remains `HOLD`** pending a genuine user-facing smoke/E2E and explicit architect `GO` for the exact content fingerprint.

## Source hierarchy and methods

1. **First pass — scientific reasoning and translation review:** Each of eight English stems and all four response options were evaluated against the Cambridge 9701 2025–2027 syllabus; EN/RU/UZ text and explanations checked for equivalent task, units and key. For q3373 the original Cambridge Chemistry Coursebook 3e (Lawrie) Ch.10 §10.7 was inspected directly (PDF pp.322–323); it explicitly explains Al₂Cl₆ hydrolysis to an acidic solution, and SiCl₄ hydrolysis forming off-white SiO₂ precipitate and HCl. No quotes are reproduced here.
2. **Second pass — separate deterministic checks:** Recomputed the four numerical questions directly from the raw experimental values and compared keyed options in all three languages; verified exact candidate SHA-256 hashes, source manifest, original release SQL embedded payload, unique IDs/options, documented distractors and a fail-closed release gate. Results: **73/73** targeted programmatic assertions passed (`SELF_REVIEW_EVIDENCE.json`). The checks do not independently establish real user-interface behaviour.

Official source: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf

## Item-specific academic decisions

| Old ID | Destination | Official objective | Independent academic finding | EN/RU/UZ parity | Reviewer outcome |
|---:|---|---|---|---|---|
| 3106 | Practice 3 | 7.1.3, 7.1.9 | SO₂/SO₃ forward reaction exothermic: heating shifts toward reactants and lowers Kc; B uniquely right | PASS | SELF_VERIFIED |
| **3373** | **Practice 4** | **9.2.5–6** | **Source P0 removed**. SiCl₄ is tetrahedral molecular chloride; hydrolysis yields off-white SiO₂ and HCl. AlCl₃/Al₂Cl₆ also acidifies water, but is not the described tetrahedral SiCl₄ molecule; A is uniquely defensible | PASS | SELF_VERIFIED, priority |
| 4757 | Practice 6 | 24.1.2–4 | Q = 193 C, n(Cu)=0.00100 mol, n(e⁻)=0.00200 mol, F=96500 C mol⁻¹, L=**6.03 ×10²³ mol⁻¹**; B uniquely right | PASS | SELF_VERIFIED |
| 9797 | S2 Tour 5 | 15.1.3(a), 16.1.2(d), 17.1.1(a) | Aqueous OH⁻ substitutes Br; oxidise primary alcohol under distillation to retain butanal. Excess reflux favours acid. D uniquely right | PASS | SELF_VERIFIED |
| 9801 | S2 Tour 5 | 14.2.2(a)(ii), 14.2.5, 16.1.1(a) | Acid hydration of CH₂=C(CH₃)₂ via more stable tertiary carbocation gives 2-methylpropan-2-ol; C | PASS | SELF_VERIFIED |
| 9824 | S2 Tour 6 | 24.2.9 | E = 0.340 + 0.0592/2 × log10(0.0100)=**+0.281 V**; B | PASS | SELF_VERIFIED |
| 9831 | S2 Tour 6 | 25.2.1–2 | [X]hexane=0.800, [X]water=0.100 mol dm⁻³; Kpc=**8.00**; C | PASS | SELF_VERIFIED |
| 9835 | S2 Tour 6 | 24.2.10 | ΔG° = −nFE° = −2×96500×0.500 = **−96.5 kJ mol⁻¹**; B | PASS | SELF_VERIFIED |

Each wrong option was checked for being false under the stem's assumptions. Existing `wrong_option_diagnostics_en` provides a plausible misconception for all 24 distractors. The `SELF_VERIFIED` designation is a content review statement, not a psychometric validation or official Cambridge endorsement.

## Release safety, provenance and what is NOT done

- Original candidate JSON is **unchanged**: SHA-256 `eef1c85146ee7c24e2858395be0f51c189cf58fa9fc6674f2fd8b3b87e22049d`.
- R5 package ZIP unchanged: SHA-256 `b54f012be68e1baacd3abe2adc6cc5e4c35ac6cb35ea601c53f369b1f2c5bf11`.
- Supabase source old question IDs and target memberships were verified in the preceding preflight. User answer distribution is **NOT_OBSERVED** (prior aggregate attempt was blocked); zero affected learners has **not** been assumed.
- The proposed replacement SQL creates **new question IDs**, stores history links, and atomically replaces only designated bank memberships at original positions; it does not update old question rows or historical attempts, grades, certificates, ratings or local storage.
- The former SQL, which contained fields that would falsely imply independent external signoff, is superseded by `R5_ATOMIC_RELEASE_SELF_VERIFIED_GO_E2E_GATED_NOT_EXECUTED.sql`. The replacement explicitly identifies the AI-only review and leaves **both** `v_architect_exact_hashes_approved = FALSE` and `v_protected_preview_e2e_passed = FALSE`. It will deliberately abort without a **real** approval and **real** UI evidence. Do not flip them merely to bypass a guard.
- A Vercel production deployment and an existing ready Preview deployment were identified, but **no logged-in end-to-end user flow was executed**. Listing or fetching Vercel deployment metadata is not an E2E pass.
- No changes made to Supabase contents, GitHub `main`, Vercel deployments or real learner progress in this work session.

## Next exact release step (not another audit)

1. Run an authorised test-user smoke flow in a protected Preview covering a replacement MCQ in Practice and a Season2 draft Tour in preview/test context. Validate that correct/wrong grading, EN/RU/UZ rendering, timer, progress persistence and return/navigation behave normally. Do not open Season2 in production.
2. Get a **separate architect `GO` for the exact eight-item content fingerprint** shown above and the 8-ID-only membership scope (do not infer `GO` from delegation of the scientific review).
3. On `GO`, run one supervised guarded atomic migration with current source preflight and snapshots; inspect all eight new mappings, Practice 70-per-tour and draft Tour 20-per-tour, Season2 `draft`, and absence of historical changes. No score recalculations.

**Product risk while on HOLD:** legacy ambiguous Practice 4 question #3373 remains active. Fixing this P0 is the first priority once the release gate is satisfied. Other 48/56 original flagged IDs remain a separately prioritised backlog; they have not been silently marked repaired.