# TEMP Chemistry J23–J32 execution tracker — DELETE WHEN COMPLETE
Keep only until the full agreed Chemistry J23–J32 plan is finished, then delete this temporary file. Retain permanent academic/release evidence.
- [x] J23 initial 154 Theory/462 locales/12 LAB and Entry/Recheck/P1 baseline inventory
- [x] J23 version-preserving P1 SO2/SO3 correction created (v5; 7 reviews PENDING)
- [ ] J23 AS Theory release signoff: after the complete AI/editorial 91/91 source review, prepare canonical release source package, reconcile tutors, verify all hashes and obtain independent science/EN-RU-UZ, rights and owner signoff
    - [x] Substantive editorial review **91/91** (Chemistry 9701 AS source §1–22); 78 no confirmed defect, 12 corrected CLOSED candidates, 1 enrichment-only no-defect. **All 91 remain unapproved for learner release.**
    - [x] Immediate corrections are stored in private protected candidate table: **12 revised rows**, original **154 theory library** rows and hashes preserved.
    - [x] Pin 91 AS source references + 12 protected revision fingerprints in `docs/exam-prep-chemistry-j23-as-91-closed-editorial-candidate-manifest-20261029.json`; this is a non-publishing editorial manifest, NOT the canonical source package.
    - [x] Recovered exact source-backed per-locale authoring fields in **PRIVATE CLOSED** `private.iclub_exam_chemistry_j23_as_authoring_recovery_v1` by installed migration `20261029112704` (matching GitHub SQL). Exactly **273 locale rows / 91 skills**, 273/273 original examples, 273/273 common traps, 186 existing questions extracted, **87 question slots missing**, **273 check answers deliberately NULL**, 36 locale rows carry the 12 J23 revisions. Private RLS enabled, no `authenticated` table read, legacy untouched.
    - [ ] Complete remaining 87 original check-question language slots and 273 scientifically verified check answers; produce a NEW immutable authoring version (do not overwrite recovery rows). Existing library stores title + combined explanation, and the canonical packager requires all 6 per locale.
    - [ ] Rebuild full versioned 91-card canonical six-field authoring package and matching Tutor references; never assign JSONB candidate/recovery digests as source-packager hashes. The recovered private rows are AUTHORING INPUT, NOT canonical release material.
    - [ ] At approved-version cutover, change J24 catalogue and authorization from hardcoded `chemistry9701_20261022_stageb_draft` to the independently signed, version-pinned 91-card source and compatible `iclub_exam_core_skills_v1` links; do not alter current J24 grants or open access during staging.
    - [ ] Review corrected 12 lessons and source manifest with independent Chemistry academic owner; approve syllabus scope, EN/RU/UZ, rights and backups.
    - [ ] J23 academic signoff after canonical package generation; never overwrite the immutable historical library source.
- [x] J24 91-card AS-only gated server + isolated reader implemented
- [x] J25 consent-free rollout installed as migration 20261029080305; audience_mode=closed, owner_opened_at=NULL, J24.enabled=false, no learners enrolled
- [ ] Wave A one authorized test account, then existing beta cohort Chemistry Theory
- [ ] J26 Entry 22 approved original questions and safe learning path
- [ ] J27 Recheck 22 independent questions, source-linked mistakes and lifecycle
- [ ] J28 Paper 1 40 independently secure-ready MCQ and timed session
- [ ] J29 six AS P3 practical-learning cards, not practical exam claims
- [ ] J30 static explanations, then independent generative tutor with separate safety
- [ ] J31 authentic Paper 2 and Paper 3 practical-learning completeness
- [ ] J32 63 A Theory, P4/P5, six P5 LAB cards
Permanent rule: no invitations or subject-specific consent in any beta/release. Keep AI provider privacy guard distinct. Never reset users, localStorage or progress.
