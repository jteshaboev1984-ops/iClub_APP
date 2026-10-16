# iClub Chemistry 9701 — R5 release readiness (read-only), 16 October 2026

**Status:** eight verified offline candidates and one guarded migration draft. **NOT installed in production.** The R4 package remains as prior history; the R5 candidate for question 3373 supersedes its earlier R4 text/hash.

## Actual progress, without redoing 630 questions

The eight issues come from the R1–R4 academic ledger. During R5, I independently checked the exact eight candidates against Cambridge 9701 (2025–2027) and re-read only the eight current live source question IDs and target links.

| Existing ID | Live location / existing position | Decision | R5 candidate SHA256 |
|---:|---|---|---|
| 3106 | Practice3, #59 | P1 equilibrium wording | `2ac241357349a6a0…` |
| 3373 | Practice4, #37 | P0 ambiguous old item | `98beef39842e157d…` |
| 4757 | Practice6, #65 | P1 buffer duplicate | `429fc6e93b5213cc…` |
| 9797 | Season2 Tour5, #4 | P1 repeated route | `c78df094c180e9d0…` |
| 9801 | Season2 Tour5, #8 | P1 repeated addition | `6f3ab6e6912d61f8…` |
| 9824 | Season2 Tour6, #7 | P1 potential duplicate | `e7a446a81222d230…` |
| 9831 | Season2 Tour6, #14 | P1 rate-law duplicate | `6468ef38d18ea0cf…` |
| 9835 | Season2 Tour6, #18 | P1 out-of-required-scope entropy | `3312dbb729cd8043…` |

## Academic findings

- **P0 / q3373:** R4 wording directly supplied the product formula SiO₂, making the answer trivial. R5 now requires the joint evidence of a *discrete tetrahedral molecular chloride* and hydrolysis; no second response among NaCl, MgCl₂, AlCl₃ is supported by those combined conditions. Original q3373 is unchanged. The school-level hydrolysis equation is a simplified representation.
- **3106:** exothermic forward SO₂ + O₂ → SO₃ equilibrium; temperature rises at constant total pressure, so Kc decreases and equilibrium SO₃ proportion declines. Candidate B retained.
- **4757:** Cu²⁺ electrodeposition and Q/amount/e measurements give L = 6.03125 × 10²³ mol⁻¹; requirement 24.1.2–4.
- **9797:** correct two-step substitution and controlled oxidation to butanal; prolonging reflux yields butanoic acid.
- **9801:** acid hydration of 2-methylpropene proceeds to the tertiary alcohol under the taught electrophilic addition pathway.
- **9824:** Cu²⁺/Cu Nernst calculation at [Cu²⁺] = 0.0100 gives +0.2808 V → +0.281 V.
- **9831:** partition coefficient is the concentration ratio: (0.0400 / 0.0500)/(0.0100 / 0.1000) = 8.00. The solute is present dissolved in both liquids.
- **9835:** −nFE° yields −96.5 kJ mol⁻¹. Correct replacement for additional/not-required total-surroundings entropy example.

Cambridge source: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf (not coursebook chapter numbering). In particular, syllabus §§9.2.5, 17.1, 24.1.2–4, 24.2.9–10, and 25.2.1–3 apply.

## Production preflight factual result

- All eight original `public.questions` rows present, published, active, Chemistry subject 4.
- Each exactly linked in the expected target bank/slot. No overlapping active Practice/Tour membership of those source IDs and no already recorded `question_version_links`.
- Current Season2 is `draft`; 210 active items across Practice3/4/6 and 40 current Season2 Tour5/6 links remain unchanged.
- Recorded source-content MD5 fingerprints in the release manifest for change detection immediately before future write.
- Did **not** access or mutate students’ attempt contents. An earlier attempt to retrieve aggregated affected-user history was blocked; exact user-impact counts remain unknown and must not be reported as zero.

## Why NOT released in this pass

The academic operating standard and R4 contract require independent chemistry review, independent EN/RU/UZ science-language review, protected Preview E2E, and architect approval for the **exact content hashes**. None has been evidenced as complete. I did an independent self-check, not an external specialist signoff. The SQL intentionally declares all four authorisation booleans `FALSE` and raises before any write. Do not switch these flags without approval evidence.

## Prepared release design (single atomic migration; NOT EXECUTED)

1. Refuse execution without all four signoffs; confirm original item fingerprints/locations and version absence, Season2 draft and existing bank-size/slot uniqueness.
2. Create private snapshots of original links and eight source question records (no learner data included).
3. Insert eight **new** question IDs, full EN/RU/UZ content, canonical answers/explanations, and audit records in `question_version_links` / `question_content_change_decisions`.
4. Verify both safe server graders for every new item; deactivate only the eight old *membership links* and add eight new links at the same positions. No existing question row is rewritten.
5. Assert 70 per Practice, 20 per Season2 Tour, closed Season2, stable old source texts. A failure rolls back the entire transaction.

**Excluded:** recalculation of historical attempts, ratings or certificates; changes to localStorage; GitHub main / Vercel / UI / other subjects; opening Season2.

## Files in this package

- `R5_8_TARGETED_REFINED_CANDIDATES_EN_RU_UZ.json` — complete eight EN/RU/UZ drafts and individual SHA256.
- `R5_CANDIDATE_8_SOURCE_FINGERPRINT_MANIFEST.json` — expected current source ID, bank and content MD5.
- `R5_EIGHT_ITEM_ATOMIC_MIGRATION_SIGNOFF_GATED_NOT_EXECUTED.sql` — preflight, backups, atomic insert/switch, rollback conditions, deliberately OFF.
- `630_Question_QA_Traceability_Ledger_v5.csv` — all 630 rows retained; only R5 candidate information layered on top.
- `R5_STATIC_QA_RESULT.json` and `R5_INDEPENDENT_NUMERIC_RECHECK.json` — narrowly scoped checks.

**Next real gate:** external scientific and EN/RU/UZ specialist approval and protected-preview run, then a separate exact-hash architectural release approval. In the meantime the current live P0 q3373 is still present in Practice 4, so prioritise its resolution rather than claiming safety is restored.