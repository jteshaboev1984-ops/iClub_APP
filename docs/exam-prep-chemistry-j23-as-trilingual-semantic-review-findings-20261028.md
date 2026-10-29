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

## J23 batch: Equilibria and acid/alkali CHEM9701-07-01–07-05 (2026-10-29)
Sources: complete EN/RU/UZ immutable library texts; Lawrie Ryan/Roger Norris Chemistry 3e; official Cambridge 9701 2025–2027 syllabus §7.1–7.2, p. 24 (https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf).

- **J23-SCI-032 | CHEM9701-07-01 | §7.1 | BOUNDED PASS**: closed-system dynamic equilibrium requires equal forward/reverse rates, not equal reagent/product concentrations; catalyst affects the approach but not equilibrium position; H₂+I₂⇌2HI gaseous stoichiometry has Δn=0, no preferential pressure shift. All locales consistent.
- **J23-SCI-033 | CHEM9701-07-02 | §7.1 | BOUNDED PASS**: Le Chatelier Haber exothermic forward direction (high p→NH₃, high T→reactants), Contact catalyst and equilibrium rate-yield tradeoff, pressure change by compression with Δn=0, inert gas at constant V/T and temperature-only K dependency maintained in EN/RU/UZ.
- **J23-SCI-034 | CHEM9701-07-03 | §7.1 | BOUNDED PASS**: Kc for H₂+I₂⇌2HI correctly `0.6²/(0.3×0.2)=6` (no concentration units). Haber Kc `0.4²/(0.5×0.2³)=40 dm⁶ mol⁻²` (net exponent −2) identical in all three languages. Purity/state caveats retained.
- **J23-SCI-035 | CHEM9701-07-04 | §7.1 | BOUNDED PASS**: mole fractions 2:3:1 at total pressure 600 kPa give partial pressures N₂=200, H₂=300, NH₃=100 kPa; `Kp=100²/(200×300³)=1.85185×10⁻⁶ kPa⁻²`, matching EN/RU/UZ. Do not use Kp–Kc conversion (not required in syllabus).
- **J23-SCI-036 | CHEM9701-07-05 | §7.2 | BOUNDED PASS**: strong versus weak acid degree of dissociation, equivalence versus indicator end point, weak acid+strong alkali equivalence >7, strong acid+weak alkali <7, weak acid+weak alkali lacks a sharp indicator transition. The specified **volume of alkali added** graph axis is retained in all locales; no unsupported exact equivalence pH claimed.

**Cumulative: 35/91 read in all three languages; 32 provisional no-defect, 3 translation HOLD.** No approved 91-card manifest, Chemistry AS Theory remains locked.


## J23 correction implementation — CLOSED CANDIDATE, 2026-10-29
Previously found corrections are **implemented in protected Supabase** as full three-locale candidate payload rows in `private.iclub_exam_chemistry_j23_theory_revisions_v1` with `revision_key=chemistry9701_j23_20261029_revision_v1`. Each row retains its exact base source version/hash and receives a new `revision_sha256`. The first four rows were installed by migration `20261029095317`; later 09-01/09-04 by `20261029095542`, and 08-03 by `20261029095654`. The separate revision hash audits the candidate's JSONB payload and **is not interchangeable with the six-field canonical source-packager hash**. Original source and existing `exam_core_skills` references remain unchanged; these candidates are not automatically accessible to users.

- **FIXED IN CANDIDATE, pending academic signoff:** CHEM9701-01-02 RU/UZ mass-spectrum relation; CHEM9701-01-03 UZ p-orbital nodal plane; CHEM9701-06-03 RU acidic-versus-alkaline manganese product; CHEM9701-10-02 RU/UZ Group 2 hydroxide/sulfate titles and matching topic lines.
- **FIXED IN CANDIDATE, pending academic signoff:** CHEM9701-08-03 UZ homogeneous-versus-heterogeneous catalysis definition; CHEM9701-09-01 RU 3p-subshell grammatical case; CHEM9701-09-04 RU title/topic adjusted from exclusively 'hydrolysis' to broader 'chlorides reacting with water' (NaCl also dissolves).
- **Release prerequisite still missing:** full canonical six-field authoring source version and matching tutor/source hashes, exact 91-card manifest, independent academic owner and trilingual signoff, rights and backup release approval. No published content mutation, mastery credit, or gate opening.

## J23 scientific and trilingual source review: kinetics 08-01–08-04
Grounding: complete immutable EN/RU/UZ explanation texts and supplied Cambridge Chemistry 3e textbook chapter 'Reaction rates'; 9701 2025–2027 §8.1–8.3. 
- **J23-SCI-037 | 08-01 | BOUNDED PASS:** Reactant 0.80→0.50 mol dm⁻³ over 60s gives 0.0050 mol dm⁻³ s⁻¹; NO₂ 0.120/20.0=0.00600, O₂ formation half that =0.00300. Tangent/instantaneous and secant/average distinction consistent across EN/RU/UZ.
- **J23-SCI-038 | 08-02 | BOUNDED PASS:** Collision theory, temperature vs concentration, effective Eₐ threshold, Maxwell–Boltzmann curve shape and constant total area for fixed molecule count all agree. Gas compression vs argon at fixed V/T correctly distinguishes reactant partial pressure from total pressure.
- **J23-LANG-007 | 08-03 | CORRECTED CANDIDATE:** All three explain unchanged ΔH and equilibrium constant under catalysis. UZ core omitted the EN/RU distinction between homogeneous and heterogeneous catalysis. Corrected UZ definition: `Gomogen katalizda katalizator va reagentlar bir xil fazada, geterogen katalizda esa turli fazalarda bo‘ladi.` Stored in protected candidate, with original source unchanged.
- **J23-SCI-039 | 08-04 | BOUNDED PASS:** Product concentration 0.10→0.34 over 30s =0.0080 mol dm⁻³ s⁻¹; gas syringe, escaping gas mass loss, colorimetry applicability, quenching sampled aliquots all match.

## J23 scientific and trilingual source review: Period 3 09-01–09-04
Grounding: complete immutable EN/RU/UZ explanations and Cambridge Chemistry 9701 2025–2027 §9.1–9.3 / supplied coursebook Periodicity chapter.
- **J23-LANG-008 | 09-01 | CORRECTED CANDIDATE:** Na⁺ > Mg²⁺ > Al³⁺ (10e each); P³⁻ > S²⁻ > Cl⁻ (18e each) and Mg→Al IE exception consistent. RU sentence `из более высокоэнергетической подуровни 3p` ungrammatical; corrected to `с более высокоэнергетического подуровня 3p`.
- **J23-SCI-040 | 09-02 | BOUNDED PASS:** Na/Mg/Al metallic, Si giant covalent, P₄/S₈/Cl₂ simple molecules, Ar monatomic; sulfur versus phosphorus London forces and Si electrical properties aligned.
- **J23-SCI-041 | 09-03 | BOUNDED PASS:** Na₂O, MgO basic; Al₂O₃ and Al(OH)₃ amphoteric; SiO₂/P/S oxides acidic with relevant water reactions. P₄+5O₂→P₄O₁₀ and Al(OH)₃+OH⁻→[Al(OH)₄]⁻ atom/charge balanced. Appropriate sodium oxide/peroxide caveat retained.
- **J23-LANG-009 | 09-04 | CORRECTED CANDIDATE:** Correct PCl₅+4H₂O→H₃PO₄+5HCl and SiCl₄+2H₂O→SiO₂+4HCl in all languages. RU title/topic incorrectly framed *all* Period 3 chloride water reactions as hydrolysis although NaCl chiefly dissolves. Corrected RU title + intro to `Взаимодействие хлоридов элементов третьего периода с водой` in protected candidate.

**Cumulative reviewed 43/91, 37 provisional no-defect, 6 inspected lessons with corrected source candidates (01-02,01-03,06-03,08-03,09-01,09-04).** One additional correction candidate for 10-02 title was identified earlier and staged pending that card's full substantive review. **No source approved for release.**

## J23 batch: Group 2 CHEM9701-10-01–10-04 (2026-10-29)
- **10-01 | bounded science and tri-locale check:** Mg/Ca/Sr/Ba oxygen/water/dilute HCl equations, steam forming MgO and H₂, decreasing ease of losing electrons down the group, sulfate coating exception consistent in EN/RU/UZ.
- **10-02 | CORRECTED CANDIDATE, content reviewed:** hydroxide solubility increases and sulfate solubility decreases down Group 2; Ba(OH)₂ vs Mg(OH)₂ and BaSO₄ examples sound. RU/UZ original titles were too general, previously corrected in the **closed** protected J23 revision record; no mismatch in the explanations. Await canonical packaging/signoff.
- **10-03 | bounded science and tri-locale check:** Group 2 carbonates to oxides+CO₂, nitrates to oxide+NO₂+O₂, correctly balanced `2M(NO₃)₂→2MO+4NO₂+O₂`, increasing thermal stability and aqueous CaCO₃/HCl reaction condition consistent.
- **10-04 | bounded enrichment-only check:** Ca/Sr/Ba flame colours and barium sulfate precipitate distinction technically plausible; **syllabus_point=NO_EXPLICIT_9701_OUTCOME**, so this card is supplementary learning ONLY, not an exam outcome or grade/mastery input. Do not misrepresent formation of BaSO₄ using added BaCl₂ as proof that the unknown solution initially contained barium.
**Cumulative substantive AS review 47/91: 40 provisional no-defect, 7 inspected lesson correction candidates (including 10-02). 44 remain.** No learner opening or source overwrite.


## J23 batch: Halogens CHEM9701-11-01–11-04 (2026-10-29)
Reference: supplied Cambridge Chemistry 3e coursebook Group 17 chapter; original protected three-locale explanation text; official Cambridge 9701 2025–2027 §11.

- **11-01 | CORRECTED CLOSED CANDIDATE:** halogen colour/boiling trend and F–F/Cl–Cl/Br–Br/I–I mean bond energy comparison scientifically consistent; boiling relates to London forces, not X–X bond strength. EN explicitly states hydrogen–iodine formation is **reversible** and Group 17 colour generally darkens; RU/UZ omitted the reversibility, and UZ omitted the colour trend. Both translations corrected immediately in private closed revision `20261029095956`. Source still immutable.
- **11-02 | BOUNDED PASS:** Cl₂+2Br⁻→2Cl⁻+Br₂; Br₂+2I⁻→2Br⁻+I₂, halogen oxidising power and halide reducing power opposite trends, orange Br₂/violet I₂ organic-layer distinctions consistent in EN/RU/UZ.
- **11-03 | BOUNDED PASS:** AgCl white/dilute NH₃ soluble, AgBr cream/concentrated NH₃ soluble, AgI yellow/NH₃ insoluble; nitric-acid pre-treatment (not HCl), 2HBr+H₂SO₄→Br₂+SO₂+2H₂O, 8HI+H₂SO₄→4I₂+H₂S+4H₂O all atom/charge consistent across languages. No misleading claim that all hydrogen halides merely protonate.
- **11-04 | BOUNDED PASS:** Cl₂+2OH⁻→Cl⁻+ClO⁻+H₂O in cold dilute alkali; 3Cl₂+6OH⁻→5Cl⁻+ClO₃⁻+3H₂O in hot concentrated alkali, chlorine 0→−1/+1 or −1/+5, HOCl/ClO⁻ aqueous disinfection and pH dependence present in EN/RU/UZ.

**Cumulative reviewed 51/91; 43 provisional no-defect, 8 corrected CLOSED candidate lessons among the 51. 40 remain unreviewed, zero approved for learner release.**


## J23 substantive chapter batch 12–16 — 2026-10-29
Full EN/RU/UZ source explanations for all **20** lessons CHEM9701-12-01 through 16-04 inspected against Cambridge 9701 subject scope. Scientific review remains *bounded editorial* and requires owner science approval before release. No learner access or source data changed.

- **12-01**: NH₃ lone-pair Brønsted basicity, NH₄⁺+OH⁻→NH₃+H₂O and damp red litmus, weak-base equilibrium: consistent.
- **12-02**: Haber N₂+3H₂⇌2NH₃, Δn=−2, pressure/temperature compromise, Fe catalyst and recycle correct in three languages. Explicit metadata **7.1(10); 12.1 context only**: do not imply an independent 12.1 tested outcome.
- **12-03**: N₂+O₂→2NO, 2NO+O₂→2NO₂ and 4NO₂+O₂+2H₂O→4HNO₃ balanced; the PAN/smog process is explicitly multistep, and catalytic NO reduction 2NO+2CO→N₂+2CO₂ valid.
- **12-04**: NO₂/NO oxidation of SO₂, Contact process 2SO₂+O₂⇌2SO₃, V₂O₅, oleum H₂S₂O₇ and dilution equations all balanced; **industrial context** must be differentiated from the syllabus's assessed nitrogen/sulfur oxides and pollution outcomes, not a new separate tested module.
- **13-01**: 2-methylbutane and butan-2-ol locants and structure reading align across EN/RU/UZ.
- **13-02**: –OH versus –COOH distinction, aldehyde, ester, amide identification and HOCH₂COOH dual groups correct; amide example is illustrative, not automatic AS examinable extension.
- **13-03**: but-2-ene E/Z versus propene, chiral 2-bromobutane versus achiral 2-bromopropane, carbon σ/π bonds, 109.5°/120°/180° examples correct in all languages.
- **13-04**: curly full arrow from lone pair/bond versus one-electron fishhook, OH⁻ substitution and C–Br electron movement correct.
- **14-01**: UV Cl₂ homolysis and methane substitution chain, cracked C₁₀H₂₂→C₈H₁₈+C₂H₄ conservation, catalytic 2NO+2CO→N₂+2CO₂ balanced.
- **14-02**: electrophilic HBr addition to propene, stable secondary carbocation, bromine addition to ethene without UV; three translations agree.
- **14-03**: bromine-water unsaturation, dilute/cold manganate diol versus hot/concentrated cleavage and but-2-ene→2 CH₃COOH under oxidative conditions consistent; conditions are mandatory.
- **14-04**: poly(propene) and PVC repeat units correctly show saturated backbone and substituents. **Verified against the official Cambridge 9701 2025–27 syllabus (p. 37): section 20.1 addition polymerisation is explicitly AS content.** The prior assertion that it was an A Level-only topic was incorrect and is superseded. Syllabus also requires disposal/non-biodegradability awareness, to be checked for content coverage separately.
- **15-01**: C–X bond strength and comparable substrate hydrolysis, AgNO₃ precipitation after X⁻ release (not detection of covalent C–X) align.
- **15-02**: aqueous nucleophilic substitution, SN1 carbocation vs SN2 concerted step and rate laws `k[RX]`, `k[RX][Nu⁻]` scientifically coherent across locales.
- **15-03**: hot ethanolic versus aqueous OH⁻ elimination/substitution; β-H counting, bromoethane→ethene balance correct.
- **15-04**: cyanide substitution adds one carbon and nitrile hydrolysis yields acid/carboxylate with work-up; educational source warns cyanide laboratory-only. No in-app experimental instructions beyond syllabus theory.
- **16-01**: primary/secondary/tertiary alcohol classification, alkene hydration and aldehyde/ketone NaBH₄ reduction vs carboxylic acid LiAlH₄ correct; stronger-reductant example may be enrichment and needs syllabus scope signoff.
- **16-02**: primary alcohol distillation vs reflux oxidation to aldehyde/acid, secondary to ketone, dichromate orange→green and tertiary resistance consistent.
- **16-03**: concentrated H₂SO₄/Al₂O₃ dehydration vs SOCl₂ or HX substitution, ethanol+Na producing sodium ethoxide and H₂ balanced in all three.
- **16-04**: iodoform CHI₃ positive for ethanol or CH₃CH(OH)– and negative for propan-1-ol; distinction of original alcohol vs oxidised carbonyl correct.

**Cumulative inspected: 71/91 AS Theory.** The eight previously corrected closed candidate records still await owner academic signoff. **20** remaining (chapters 17–22); source hashes remain unchanged and the AS release stays closed.


## J23 final bounded editorial review: 91/91 AS Theory cards (2026-10-29)
All 91 source-linked Theory entries in the current Chemistry AS mapping have had their complete EN/RU/UZ explanation texts read for scientific meaning, equations, numeric checks, syllabus alignment and obvious translation defects. **This is an AI editorial evidence pass, not independent science teacher certification, rights clearance, or a release-ready version.** External primary reference: official Cambridge International Chemistry 9701 2025–2027 syllabus, pp. 10, 37–38 (https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf).

### 17 Carbonyl compounds (17-01–17-05)
- 17-01 **CLOSED CANDIDATE FIX**: the Russian self-check began with Uzbek `Nega`; rewritten into grammatical Russian, exact source anchored, migration **20261029104853**. The 2,4-DNPH / Tollens comparison and propanal vs propanone examples remain scientifically correct.
- 17-02 carbonyl CN⁻ attack, HCN/KCN/heat, eth-anal hydroxynitrile chirality vs propanone non-chirality consistent in EN/RU/UZ. The HCN example is academic only.
- 17-03 NaBH₄ reduction to primary/secondary alcohols, aldehyde oxidation and ketone mild-oxidation distinction sound.
- 17-04 2,4-DNPH, Tollens and Fehling identification together with IR and exceptions consistent.
- 17-05 iodoform from methyl ketones and ethanal, negative propanal example; `CH₃COCH₃+3I₂+4OH⁻→CH₃COO⁻+CHI₃+3I⁻+3H₂O` balances charge and atoms across EN/RU/UZ.

### 18 Carboxylic acids and derivatives (18-01–18-03)
- 18-01 carboxylates, carbonates, primary-alcohol/aldehyde oxidation and nitrile-to-acid conversion; LiAlH₄ vs NaBH₄ distinguished.
- 18-02 reversible acid-catalysed esterification and acid/alkali hydrolysis (carboxylate is the immediate base-hydrolysis product) consistent.
- 18-03 **CLOSED CANDIDATE FIX**: RU and UZ titles and opening topic lines said only "esterification and hydrolysis" whereas EN lesson is a **multi-step synthesis and transformation** source. Updated RU/UZ headings in protected migration **20261029105108**. The full texts describe `21.1 Organic synthesis`, which is indeed an **AS** syllabus outcome.

### 19 Nitrogen compounds (19-01–19-03)
- 19-01 `C₂H₅Br + 2NH₃ → C₂H₅NH₂ + NH₄Br`, NH₃ in ethanol under pressure, subsequent alkylation caution, correctly translated. Official AS §19.1 expressly says **amine classification will not be tested**; this lesson teaches preparation rather than graded amine taxonomy.
- 19-02 CN⁻ substitution adds a carbon, nitrate/nitrile nomenclature, acidic vs alkaline hydrolysis with acidification correct, safe academic framing.
- 19-03 cyanohydrin formation from aldehyde/ketone, carbon chain extension, HCN/KCN and chiral centre discussion correct; do not operationalise toxic HCN instruction in learner labs.

### 20 Polymerisation (20-01–20-03)
- 20-01 `nCH₂=CH₂→[–CH₂–CH₂–]ₙ`, PVC `[–CH₂–CHCl–]ₙ`, conservation and no small-molecule by-product correct.
- 20-02 reverse repeat-unit to monomer and preserve substituents; condensed polyester example is optional enrichment. **§20.1 is definitively AS-level**, correcting the earlier erroneous scope flag.
- 20-03 **CLOSED CANDIDATE FIX**: RU/UZ title and topic line previously translated English *disposal* as merely recycling; corrected to broader **RU "Свойства и утилизация полимеров"** and **UZ "Polimer xossalari va chiqindilarini boshqarish"** in protected migration **20261029105239**. Text covers non-biodegradability and hazardous uncontrolled combustion, required under §20.1.4; PET ester hydrolysis is an illustrative comparison, not standalone mastery.

### 21 Organic synthesis (21-01–21-03)
- 21-01 haloalkane→alcohol→acid, dual –OH and –COOH groups, correct choice of reagent and conditions.
- 21-02 2→3-carbon bromoethane→propanenitrile→propanoic acid multistep route, competing elimination, correct in three locales.
- 21-03 C=O versus O–H interpretation from IR and 2,4-DNPH/Tollens/carbonate evidence, no false unique identification. **§21.1 is AS**, not A-only.

### 22 Analytical techniques (22-01–22-03)
- 22-01 IR C=O ~1700 cm⁻¹, alcohol O–H ~3200–3600 cm⁻¹, acid broad ~2500–3300 cm⁻¹ correctly differentiated across languages.
- 22-02 **CLOSED CANDIDATE FIX**: UZ source previously said molecular-ion peak can be *weak*, omitting English/Russian statement that it can sometimes be **absent**; corrected in protected migration **20261029105239**. `²⁴Mg²⁺` at m/z 12 and `²⁴Mg⁺` at m/z 24 are coherent cross-topic illustrations.
- 22-03 bromine bromoethane `C₂H₅Br` molecular ions m/z 108/110 with ~1:1 intensities, chlorine ~3:1, isotope-dependent M+2 and carbon count by M+1 formula verified. Difference between formula clues and unique structural proof retained.

### Authoring and safety totals after editorial pass
- **91/91 AS lesson texts inspected** (including one enrichment-only 10-04; assessment should exclude its independent mastery flag).
- **12/91 corrected locale/wording candidates** preserved in `private.iclub_exam_chemistry_j23_theory_revisions_v1`: original source hashes remain intact and candidate revisions are private and unapproved.
- **79/91 no confirmed defect requiring a candidate revision** within this editorial pass. This is NOT a claim of teacher-verifiable release quality.
- **154 original Chemistry library cards** remain unchanged; Chemistry J25 `closed`, J24 `enabled=false`.
- **Outstanding gate:** build consistent versioned 91-card source package with canonical authoring-schema 6-field per-card hashes; reconcile tutor locale source hashes and core-skills mapping; re-evaluate official scope against source mapping; obtain independent academic/rights/backup approval; then release AS Theory to a controlled test account. No substitute manual consent or invitation.

## Post-review release-package checkpoint — 2026-10-29

Read-only database check confirms **91 unique AS mapping records, 91 matching immutable source hashes, 12 protected revision candidates with matching base hashes, and exactly one enrichment-only 10-04**. J23 carbonyl RU fix is registered as Supabase migration `20261029104853` and its GitHub filename is `20261029104853_chemistry_j23_carbonyl_ru_language_fix_v1.sql`; later migrations `20261029105108` and `20261029105239` are also registered. No repeat execution.

The permanent **closed editorial candidate manifest** `docs/exam-prep-chemistry-j23-as-91-closed-editorial-candidate-manifest-20261029.json` now pins all 91 base source IDs/hashes and the 12 changed JSONB revision digests without including learner data or exposing protected lesson bodies. This is versioned editorial evidence, **not** a released six-field source package or content approval.

A blocking source-format difference was verified against the actual `scripts/subject-release-packager.py`: the authoring contract requires six nonempty fields (`title`, `explanation`, `original_example`, `common_trap`, `check_question`, `check_answer`) in each of EN/RU/UZ, whereas **0/91** live AS theory records currently contain all six; their `locales` carry `title` and a combined `explanation`. The original source hashes are historical and must not be overwritten or treated as new packager hashes. Before release, retrieve or reconstruct independently reviewed six-field source, run the unchanged canonical packager, reconcile all 273 Tutor source links, then verify academic/rights/backup signoffs. J24/J25 remain CLOSED and no Chemistry learner access is enabled.

## J23 protected authoring recovery — 2026-10-29 migration `20261029112704`

To advance six-field packaging without inventing academic answers, new additive private staging table `private.iclub_exam_chemistry_j23_as_authoring_recovery_v1` was installed from `20261029112704_chemistry_j23_as_sixfield_authoring_recovery_closed_v1.sql`. The SQL recovers per-language `title`, **lossless full** `explanation`, `original_example`, `common_trap`, and existing `check_question` from immutable source text plus the 12 exact protected J23 revisions. It retains source version/hashes and revision fingerprints. Staging contents remain **private, RLS enabled, anonymous/authenticated SELECT denied**; the migration makes **no** changes to learner data, existing original sources, Tutor, J24/J25 switches, or release manifests.

Read-only post-install: **91 skills / 273 EN-RU-UZ rows**, 273 original-example passages present, 273 critical-check passages present, 186 existing check questions recoverable, **87 new question locale slots require expert authoring**, and **273 check answers require expert authoring**. All `check_answer` values deliberately remain `NULL` and staging recovery status is `PENDING_QUESTION_ANSWER_AUTHORING_AND_SIGNOFF`; 36 localized rows incorporate the 12 corrected closed candidates. The authoring recovery is NOT a complete six-field source, a content hash release, or a science teacher approval. Chemistry remains J24 OFF/J25 CLOSED.

A source-preserving normalization was applied immediately after inspecting recovered fields: migration **`20261029113019_chemistry_j23_as_authoring_recovery_trim_v2.sql`** appends `chemistry9701_j23_20261029_sixfield_recovery_v2` (273 rows) with only leading/trailing whitespace removed from recovered examples, traps, and present check prompts. v1 remains immutable. This fixes raw extraction whitespace while maintaining the full explanations, base hashes and academic HOLD.
