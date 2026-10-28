# Chemistry 9701 J23 — source-text trilingual semantic review, continuation
Date: 2026-10-28. Status: **ACADEMIC REVIEW OPEN; no approved source change, no release**.

## Method and controlling scope
Read actual `private.iclub_subject_library_theory` EN/RU/UZ texts and syllabus links from protected Supabase metadata; compare to Cambridge Chemistry 9701 2025–2027 syllabus and iClub academic QA. Source version `chemistry9701_20261022_stageb_draft` is **historical and must not be silently modified**. The earlier 91-card token comparison is not scientific signoff.

## Finding J23-LANG-001 — confirmed cross-language title specificity mismatch
- Skill `CHEM9701-10-02`, official assessed point `10.1`.
- Existing English title: `Group 2 hydroxide and sulfate solubility`.
- Existing Russian title: `Растворимость солей второй группы`.
- Existing Uzbek title: `Ikkinchi guruh tuzlarining eruvchanligi`.
- The RU/UZ titles generalize to all Group 2 salts, but the English title and official syllabus expressly distinguish **hydroxides** (solubility generally increases down the group) from **sulfates** (decreases down the group). The actual three long explanations inspected do correctly distinguish both, so **scientific body verdict in this bounded inspection is PASS, title/intro equivalence is HOLD**.
- Recommended next candidate source version (not yet deployed):
  - RU title: `Растворимость гидроксидов и сульфатов элементов группы 2`.
  - UZ title: `2-guruh gidroksidlari va sulfatlarining eruvchanligi`.
  - Update the matching `Тема:` and `Mavzu:` opening lines only within **a new versioned Theory source candidate** with recomputed exact content hash and skill mapping, then repeat all three scientific/linguistic checks. Do not mutate current hash-bearing source in place.
- Scope: not a new official syllabus skill; no mastery credit is authorized by this correction.

## Finding J23-SCOPE-002 — contextual marking, not proven scientific error
- Skill `CHEM9701-12-04`, syllabus point `12.1`.
- Inspected all three actual EN/RU/UZ explanations. Balanced `2SO₂+O₂⇌2SO₃`, `SO₃+H₂SO₄→H₂S₂O₇` and `H₂S₂O₇+H₂O→2H₂SO₄` chemistry is internally consistent and consistent across languages, and separation of industrial oleum from direct water hydration is accurate.
- Cambridge 9701 section 12.1 focuses on atmospheric nitrogen/sulfur oxide pollutants, including catalytic oxidation to acid-rain products; industrial Contact-process detail in this card should be labelled as **additional application/context** rather than implied as a separately assessed §12.1 learning objective. **Scope wording pending**, no material content-change approval from this finding.

## Finding J23-SCI-003 — bilingual reaction checks
- Skill `CHEM9701-11-03`, `11.3` Halide precipitate tests.
- Inspected EN/RU/UZ full actual source. AgCl (white, dissolves dilute NH₃), AgBr (cream, concentrated NH₃), AgI (yellow, insoluble NH₃), nitric acid acidification, balanced bromide/sulfate redox, and iodide-to-H₂S examples are consistent in all three texts. Bounded **PASS for this source item only**; cannot authorize full 91-card release.

## Operational rule
The affected cards stay unpublished. Any future semantic change is versioned and hash-tracked with original retained; the current J24 manifest is unchanged. No statements such as `all 91 academic-reviewed`, `Cambridge certified`, or `production fixed` follow from this partial review.

Source: Cambridge International AS & A Level Chemistry 9701 syllabus 2025–2027, official §10.1, §11.3 and §12.1; iClub protected Theory records; Ryan & Norris Chemistry coursebook as secondary teaching cross-check. No copyrighted excerpts or question keys reproduced.
