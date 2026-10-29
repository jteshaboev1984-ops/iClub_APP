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


## J23 first 3/91 AS lessons — substantive three-locale audit (2026-10-29)
Live source: `private.iclub_subject_library_theory`, immutable `chemistry9701_20261022_stageb_draft`. Checked full EN, RU and UZ explanation text against official syllabus 9701 2025–2027 §§1.1–1.3 and the supplied Chemistry coursebook. This is a bounded assistant editorial review, NOT independent human certification.

### J23-SCI-004 — CHEM9701-01-01, §1.1 — bounded PASS, release remains HOLD
- Full three-language text reviewed: proton / neutron / electron charge, Al-27 notation, Al³⁺ electron count, electric-field deflection, O²⁻/F⁻/Na⁺/Mg²⁺ isoelectronic ion radii and periodic/group radius trends.
- Independent checks: Al has 13p / 14n / 13e and Al³⁺ has 10e; O²⁻, F⁻, Na⁺, Mg²⁺ have 10e and decreasing radius with increasing proton number; electron direction opposite proton in an electric field. These are consistent.
- No identified substantive EN/RU/UZ mismatch in inspected text. Still not released: global source version and owner approval absent.

### J23-LANG-004 — CHEM9701-01-02, §§1.2;2.1 — HOLD translation completeness
- English source explicitly explains that mass spectra provide isotopic masses and relative abundances; Russian and Uzbek full explanations omit this mass-spectrum link. Other quantitative example and relative mass definitions are consistent.
- 75%×35 + 25%×37 gives Aᵣ=35.5 in all three. NaCl relative formula mass 23.0+35.5=58.5; relative masses dimensionless. No numerical issue.
- Add to new *versioned* RU source after the first explanation: `Масс-спектр позволяет определить массы изотопов и их относительные содержания; по этим данным вычисляют относительную атомную массу.`
- Add to new *versioned* UZ source: `Mass-spektr izotoplarning massalari va nisbiy ulushlarini aniqlash imkonini beradi; bu ma’lumotlardan nisbiy atom massa hisoblanadi.`
- Do not update existing hash-bearing source in place. Cross-check exact syllabus requirement and science/language review before signing off.

### J23-LANG-005 — CHEM9701-01-03, §1.3 — HOLD Uzbek shape equivalence
- Electron filling, sulfur 3p⁴, nitrogen Hund boxes, s/p/d capacities, Fe²⁺/Fe³⁺ loss from 4s then 3d, and stated increasing subshell filling sequence appear scientifically consistent across all three texts.
- EN describes a p-orbital nodal plane through the nucleus; RU describes the nodal plane between lobes, but UZ omits the plane entirely, giving a reduced conceptual explanation.
- Proposed UZ correction for a newly versioned source: `p-orbital yadro orqali o‘tuvchi tugun tekisligi bilan ajralgan, yadrodan qarama-qarshi tomonga yo‘nalgan ikki bo‘lakdan iborat; pₓ, pᵧ va p_z o‘zaro perpendikulyar o‘qlar bo‘ylab joylashadi.`
- Retain the statement that electron orbitals indicate probability distributions, not literal trajectories.
- Do not overwrite existing source digest; no learner mastery or exams enabled by this finding.

**Batch status: 3/91 inspected substantively; 1 provisional no-defect item and 2 translation HOLDs. No general 91/91 approval.**

### J23-SCI-006 — CHEM9701-01-04, §1.4 — bounded PASS
- All EN/RU/UZ source texts reviewed. First-ionisation gaseous-atom equation and energy definition, general Period 3 trend, Mg→Al 3p-vs-3s exception, P→S spin-pair repulsion exception and electron configuration are chemically consistent.
- No substantive source or translation error found. Minor English copyediting in a future version: after full stops capitalise `The electron...` and `One sulfur...`. This does not justify publication or modification of the current source hash.

### J23-SCI-007 — CHEM9701-01-05, §1.4 — bounded PASS
- All three locales checked. Sharp IE₂→IE₃ boundary signals two outer electrons for a main-group atom; by itself it does not fix the period. Mg(g)→Mg⁺(g)→Mg²⁺(g)→Mg³⁺(g) equations each release one electron, and third ionisation accesses an inner shell. Gaseous states and charges remain correct in EN/RU/UZ.
- No substantive discrepancy found. No release approval until full source/version review and owner-controlled manifest signoff.

**Updated bounded batch status: 5/91 full three-locale explanations read, 3 provisional no-defect outcomes, 2 translation HOLDs. All 91 remain unreleased.**

## J23 batch: AS stoichiometry 02-01 through 02-05 — 2026-10-29
Sources checked: live immutable Chemistry `chemistry9701_20261022_stageb_draft` EN/RU/UZ full explanation texts; user-provided Lawrie Ryan & Roger Norris, *Chemistry for Cambridge International AS & A Level* (3e), Chapter 3 learning intentions, amounts and reaction calculations; Cambridge International Chemistry 9701 official **2025–2027 syllabus, pp. 18–19**, §§2.2–2.4: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf . Source lesson hashes remain untouched. Editorial review is bounded and is NOT independent human academic approval.

- **J23-SCI-008 | CHEM9701-02-01 | §2.2 | BOUNDED PASS.** All EN/RU/UZ definitions of the mole and exact Avogadro constant agree; `0.500 mol × 6.02×10²³ = 3.01×10²³`, `0.250 mol CO₂ = 0.750 mol atoms`, `0.100 mol CaCl₂ = 0.100 mol Ca²⁺ + 0.200 mol Cl⁻` are consistent. Exact SI constant and rounded exam value are correctly distinguished.
- **J23-SCI-009 | CHEM9701-02-02 | §2.3 | BOUNDED PASS.** Percent-to-mole ratios `40.0/12 ≈3.333`, `6.7/1=6.7`, `53.3/16≈3.331` yield CH₂O, then Mᵣ 180 gives C₆H₁₂O₆; hydrate loss `2.46−1.20=1.26 g`, mole ratio `(1.26/18)/(1.20/120.4)≈7.02`, giving MgSO₄·7H₂O. All three translations retain the heating/no-decomposition caveat.
- **J23-SCI-010 | CHEM9701-02-03 | §2.3 | BOUNDED PASS.** Al₂(SO₄)₃ charge balance, MgCl₂(aq)+2NaOH(aq) net ionic precipitation equation, Mg²⁺+2OH⁻→Mg(OH)₂(s), spectator Na⁺ and Cl⁻ and state symbols agree in all languages. Matches syllabus outcomes for ionic formulas and equations.
- **J23-SCI-011 | CHEM9701-02-04 | §2.4 | BOUNDED PASS.** Mg+2HCl example has correct 1:2:1 mole ratio; `M=1.25×8.31×300/100=31.1625≈31.2 g mol⁻¹` at specified kPa/dm³/K units, consistent EN/RU/UZ; conditions caveat for 24.0 dm³ mol⁻¹ present. Topic is broader than the explicit syllabus's reacting masses/volumes focus but explanation is valid application, not independent outcome.
- **J23-SCI-012 | CHEM9701-02-05 | §2.4 | BOUNDED PASS.** Mg/O₂ limiting reagent: maximum 0.200 mol MgO, realised 0.150 mol → 75%; Al/Cl₂ limiting reagent: reaction extents 0.200 vs 0.150, theoretical AlCl₃ 0.300 mol, obtained 0.255 → 85%. All numbers, species, coefficient logic and language meanings align.

**Cumulative substantive review: 10/91 AS lessons; 8 provisional no-defect findings, 2 translation HOLDs (01-02, 01-03).** Remaining 81 unreviewed; all 91 held from release. No public write, no source-hash change, no launch approval.

## J23 batch: Chemistry bonding CHEM9701-03-01 to 03-06 — 2026-10-29
References: exact original live `chemistry9701_20261022_stageb_draft` lesson EN/RU/UZ full text; Lawrie Ryan & Roger Norris, *Chemistry for Cambridge International AS & A Level* (3e), Chemical Bonding chapter; official Cambridge 9701 **2025–2027** syllabus pp. 19–21, §§3.1–3.6 (https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf). No publication or science-signoff record issued.

- **J23-SCI-013 | CHEM9701-03-01 | §§3.1–3.2 | BOUNDED PASS**: NaCl ionic lattice versus isolated molecules; immobile solid ions and mobile molten charge carriers; Cl/Br electronegativity trend and nonabsolute Pauling character distinction retained in EN/RU/UZ.
- **J23-SCI-014 | CHEM9701-03-02 | §§3.3;4.2 | BOUNDED PASS**: metallic delocalised-electron model, directional giant covalent diamond/SiO₂, graphite exception, molecular C₆₀ and I₂, ionic NaCl/MgO melt conduction consistent across languages; no false claim that C₆₀ molecules form a continuous covalent lattice.
- **J23-SCI-015 | CHEM9701-03-03 | §§3.4;3.7 | BOUNDED PASS**: NH₄⁺ coordinate bond origin but equivalent final N–H bonds; Al₂Cl₆ bridging chlorine donation; propadiene CH₂=C=CH₂ has **6 σ + 2 π**, ethene one σ + one π and ethyne one σ + two π C–C bonds; NO has 11 valence electrons and one unpaired electron; PCl₅ formal ten-electron diagram. All retained semantically in RU/UZ.
- **J23-SCI-016 | CHEM9701-03-04 | §3.5 | BOUNDED PASS**: VSEPR reference angles agree in all three versions: BF₃ 120°, CO₂ 180°, CH₄ 109.5°, NH₃ ~107°, H₂O ~104.5°, PF₅ 90°/120°, SF₆ 90°. Lone-pair versus molecule geometry correctly distinguished.
- **J23-SCI-017 | CHEM9701-03-05 | §3.6 | BOUNDED PASS**: CO₂ versus H₂O dipole cancellation, London dispersion and hydrogen-bond interactions, high boiling point and ice density; no incorrect implication that boiling breaks covalent O–H bonds. Restriction to N–H/O–H examples matches Cambridge 3.6.
- **J23-SCI-018 | CHEM9701-03-06 | §§3.4;3.6 | BOUNDED PASS**: BF₃/NH₃, linear CO₂/bent SO₂, and CCl₄/CHCl₃ vector dipoles chemically consistent; shape-determined polarity present in all languages.

**Cumulative editorial substantive reading: 16/91; 14 provisional no-defect findings, 2 translation HOLDs.** The general source version, 91-card exact hash manifest, rights attestations, and owner academic signoff remain incomplete. No release or backend source mutation.

## J23 batch: States of matter CHEM9701-04-01–04-05 (2026-10-29)
Cross-checked complete immutable EN/RU/UZ texts against Cambridge Chemistry 9701 2025–2027 syllabus p. 22, §§4.1–4.2 (https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf) and user-provided Cambridge Chemistry coursebook (States of matter). No live contents or hash mutated.

- **J23-SCI-019 | CHEM9701-04-01 | §4.1 | BOUNDED PASS**: Gas particle randomness, collisions and pressure; conserved H₂O during boiling; constant pure-substance boiling temperature at fixed pressure and no inappropriate claim that O–H covalent bonds break. The three explanation texts align.
- **J23-SCI-020 | CHEM9701-04-02 | §4.1 | BOUNDED PASS**: pV=nRT, consistent kPa/dm³ mol⁻¹ K⁻¹ units and temperature in kelvins; `V=(0.100×8.31×300)/100=2.493≈2.49 dm³` verified in EN/RU/UZ. New comprehension question at 0.200 mol, 200 kPa, 300 K also gives 2.493 dm³.
- **J23-SCI-021 | CHEM9701-04-03 | §4.1 | BOUNDED PASS**: Ideal gas assumptions about zero particle volume and absent attractions, non-ideal deviations at high p/low T, and competing effects expressed consistently in three languages.
- **J23-SCI-022 | CHEM9701-04-04 | §§3.6;4.2 | BOUNDED PASS**: Water hydrogen bonding and boiling point, liquid surface tension, lower density of ordinary ice, and London/permanent-dipole interactions match across three languages. Chemistry explanation stays within syllabus examples.
- **J23-SCI-023 | CHEM9701-04-05 | §4.2 | BOUNDED PASS, scope note**: C₆₀ correctly classified simple molecular rather than giant covalent; carbon cage `60 vertices × 3 / 2 = 90 edges`; `12 pentagons + 20 hexagons` independently checks `(12×5+20×6)/2=90`. All RU/UZ match EN. Numbered cage-face geometry is **explanatory enrichment**, not a separate mandatory §4.2 learning outcome or a justification for standalone mastery score; the C₆₀ example itself IS explicitly in Cambridge 4.2.
  
**Cumulative substantive EN/RU/UZ review: 21/91 cards; 19 provisional no-defect, 2 translation HOLD.** No academic approval of complete AS Theory or learner release.

## J23 batch: Chemical energetics CHEM9701-05-01–05-05 — 2026-10-29
Evidence: complete immutable EN/RU/UZ library explanations; original Cambridge AS & A Level Chemistry coursebook section on chemical energetics; Cambridge Chemistry 9701 2025–2027 syllabus, §5.1–5.2, p. 23, https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf . No source write, no academic signoff inferred.

- **J23-SCI-024 | CHEM9701-05-01 | §5.1 | BOUNDED PASS**: Exothermic ΔH negative/endothermic positive, reverse reaction sign and forward/reverse activation-energy conventions agree in all three languages. For energy profile R=40, P=10, barrier=150 kJ/mol: forward Eₐ=110, reverse Eₐ=140, ΔH=−30, all verified. Distinguishes reaction rate from heat effect.
- **J23-SCI-025 | CHEM9701-05-02 | §5.1 | BOUNDED PASS**: `q=50.0×4.18×4.00=836 J; ΔH=−0.836/0.0200=−41.8 kJ mol⁻¹`; `q=100.0×4.18×3.50=1463 J; ΔH≈−1.463/0.0250≈−58.5 kJ mol⁻¹`. Unit conversion, limiting reagent, heat-loss direction and sign present in EN/RU/UZ.
- **J23-SCI-026 | CHEM9701-05-03 | §5.1 | BOUNDED PASS**: Formation of 1 mol CaO, gaseous oxygen half coefficient, methane combustion water (l), standard conditions 298 K and 101 kPa, neutralisation per mole H₂O; 2 mol H₂O gives approximately −114 kJ when ΔHneut≈−57 per mole, as stated in all locales.
- **J23-SCI-027 | CHEM9701-05-04 | §5.2 | BOUNDED PASS**: Hess law state function and reversing/scaling equations retained in all locales: `−394+283=−111 kJ mol⁻¹` for C(s)+½O₂(g)→CO(g), consistent states and signs.
- **J23-SCI-028 | CHEM9701-05-05 | §5.1 | BOUNDED PASS**: `H₂(g)+Br₂(g)→2HBr(g)` mean gas-phase bond-energy estimate `436+193−2×366=−103 kJ mol⁻¹`; analogous HCl estimate `436+243−2×431=−183 kJ mol⁻¹`. EN/RU/UZ distinguish liquid standard Br₂ requiring its vaporisation enthalpy, not falsely claiming the gaseous reaction estimate is the standard value.

**Cumulative full text editorial review: 26/91; 24 provisional no-defect, 2 locale HOLD. Remaining 65 require independent full three-language review.** Source versions, content hashes, and closed J24/J25 gates preserved.

## J23 batch: Electrochemistry/redox CHEM9701-06-01–06-04 (2026-10-29)
Grounding: original live EN/RU/UZ descriptions, immutable source version `chemistry9701_20261022_stageb_draft`, supplied Chemistry coursebook, Cambridge Chemistry 9701 2025–2027 syllabus §6.1, p. 23, https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf . No writes to learner records or library source.

- **J23-SCI-029 | CHEM9701-06-01 | §6.1 | BOUNDED PASS**: Mn in MnO₄⁻ = +7; Cr in Cr₂O₇²⁻ = +6; S in SO₄²⁻ = +6; N in NH₄⁺ = −3; peroxide O = −1 and OF₂ oxygen = +2. Fe(II)/Fe(III) Roman numeral means oxidation state. EN/RU/UZ meanings equivalent.
- **J23-SCI-030 | CHEM9701-06-02 | §6.1 | BOUNDED PASS**: Zn loses 2e⁻, Cu²⁺ gains 2e⁻; reducing agent Zn, oxidising agent Cu²⁺; correct consistent half-equations in all languages.
- **J23-LANG-006 | CHEM9701-06-03 | §6.1 | HOLD FOR PRECISE RU TRANSLATION**: Acidic MnO₄⁻+8H⁺+5Fe²⁺→Mn²⁺+4H₂O+5Fe³⁺ has charge +17 on both sides; alkaline MnO₄⁻+2H₂O+3e⁻→MnO₂(s)+4OH⁻ balances O=6, H=4 and charge −4. EN and UZ explicitly warn *not to transplant the Mn²⁺ product from acidic conditions into the alkaline equation*. RU wording `Не используйте продукт Mn²⁺ для кислой среды без проверки условий.` is ambiguous and may incorrectly imply Mn²⁺ is inappropriate **for acidic conditions**. Repair in a new version to: `Не переносите продукт Mn²⁺, характерный для кислой среды, в уравнение для щелочной среды без учёта условий реакции.` No underlying chemistry equation error identified; release HOLD for clarity.
- **J23-SCI-031 | CHEM9701-06-04 | §6.1 | BOUNDED PASS**: Cold dilute base gives Cl⁻ + ClO⁻ (Cl 0 → −1,+1), hot concentrated base gives 5Cl⁻ + ClO₃⁻ (0 → −1,+5); equations atom- and charge-balanced, EN/RU/UZ consistent.

**Cumulative reviewed 30/91; 27 provisional no-defect, 3 locale HOLDs (01-02, 01-03, 06-03).** Existing hashes unchanged; approval of all 91 and release remain blocked.
