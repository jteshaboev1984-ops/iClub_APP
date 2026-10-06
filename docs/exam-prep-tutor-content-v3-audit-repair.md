# Exam Prep Tutor Content v3 — Audit Repair

Status: production-safe versioned correction package  
Date: 2026-10-06  
Scope: Cambridge AS Mathematics P1 + P5 curated Tutor Cards

## Why this package exists

A full read-only academic/content audit of the current `tutor_v2_learner_first` corpus found:

- one mathematical BLOCKER: P5-NOR-06 omitted the explicit normal-approximation conditions `np>5` and `nq>5`;
- one MAJOR RU pedagogy/translation defect in P1-CIR-03;
- one MAJOR originality defect in the P1-QUA-06 worked example;
- one MINOR originality risk in the P5-BIN-02 numerical example;
- several localized RU/UZ terminology/grammar defects;
- a systemic source-card architecture issue: family-generic source bodies rather than atomic skill-specific grounding.

## Safety decision

Do **not** edit the approved/runtime v2 rows in place.

This package creates:

- Tutor content version: `tutor_v3_learner_first`
- source version: `p3_02_full_theory_pack_v2_atomic_2026_10_06`
- Tutor keys ending in `:v3`
- source keys ending in `:v2`

The current v2 Tutor corpus and its bound source-v1 rows are preserved as historical rows and only retired at the atomic promotion step.

No learner answers, attempts, evidence, mastery, stage, readiness, corrections, retests, cohort/entitlement data, Practice/Tour history, ratings, certificates or localStorage are changed.

## Repair set

Exactly 21 skill-locale Tutor rows change learner-facing copy:

- P1-QUA-06: EN/RU/UZ
- P1-CIR-03: RU
- P1-TRI-05: RU/UZ
- P5-DAT-01: RU
- P5-DAT-03: RU/UZ
- P5-DAT-07: UZ
- P5-DAT-09: RU/UZ
- P5-BIN-02: EN/RU/UZ
- P5-GEO-03: UZ
- P5-NOR-04: RU/UZ
- P5-NOR-06: EN/RU/UZ

The other 222 Tutor rows are copied byte-for-byte at the learner-text level.

## BLOCKER repair

P5-NOR-06 now states in source + main + simple + alternative + focus:

- `q=1-p`
- `np>5`
- `nq>5`

Only after both inequalities hold does the card proceed to `mean=np`, `variance=npq=np(1-p)` and continuity correction.

## Originality repairs

P1-QUA-06 replaces the textbook-matching example `x⁴-5x²+4=0` with the independently authored:

`x⁴-13x²+36=0`

which reduces to `(u-4)(u-9)=0` and gives `x=±2,±3`.

P5-BIN-02 replaces the matched numerical example `n=5, p=0.4` with:

- `n=6, p=0.3`
- `P(X=2)=0.324135`
- `P(X≤1)=0.420175`

## Atomic source v2

All 243 source-v2 cards are rebuilt from the corresponding final Tutor-v3 skill-specific main explanation and focus check. Therefore each source card is atomic to one skill+locale instead of inheriting a family-generic body.

The source layer remains `original_iclub`, draft/runtime-OFF until promotion, and is hash-checked before activation.

## Promotion order

The promotion migration runs in one transaction:

1. retire Tutor v2 runtime rows;
2. retire exactly the source-v1 rows bound by Tutor v2;
3. approve/enable all 243 atomic source-v2 rows;
4. approve/enable all 243 Tutor-v3 rows;
5. verify runtime service coverage = 243, P1 = 135, P5 = 108, missing = 0.

The partial unique runtime index guarantees no two Tutor versions can be runtime-active for the same skill+locale.

## Rollback

The reversion file atomically:

1. retires Tutor v3;
2. retires atomic source v2;
3. reactivates the historical bound source-v1 rows;
4. reactivates Tutor v2;
5. confirms all 243 service lookups resolve to v2.

No history rows are deleted.

## Validation

`supabase/tests/p3_18_tutor_content_v3_repair.sql` verifies:

- exact 243/81/3-locale coverage;
- exactly the expected 21 changed Tutor rows;
- current hashes;
- source binding;
- 243 distinct atomic source bodies;
- P5-NOR-06 threshold coverage in all four variants and source;
- originality replacements;
- audited RU/UZ terminology/grammar repairs;
- variant uniqueness and minimum content thickness;
- runtime service coverage;
- unchanged browser/private-storage privilege boundary.

