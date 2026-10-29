# TEMP Chemistry J23–J32 execution tracker — DELETE WHEN COMPLETE
Keep only until the full agreed Chemistry J23–J32 plan is finished, then delete this temporary file. Retain permanent academic/release evidence.
- [x] J23 initial 154 Theory/462 locales/12 LAB and Entry/Recheck/P1 baseline inventory
- [x] J23 version-preserving P1 SO2/SO3 correction created (v5; 7 reviews PENDING)
- [ ] J23 AS Theory release signoff: after the complete AI/editorial 91/91 source review, prepare canonical release source package, reconcile tutors, verify all hashes and obtain independent science/EN-RU-UZ, rights and owner signoff
    - [x] Substantive editorial review **91/91** (Chemistry 9701 AS source §1–22); 78 no confirmed defect, 12 corrected CLOSED candidates, 1 enrichment-only no-defect. **All 91 remain unapproved for learner release.**
    - [x] Immediate corrections are stored in private protected candidate table: **12 revised rows**, original **154 theory library** rows and hashes preserved.
    - [x] Pin 91 AS source references + 12 protected revision fingerprints in `docs/exam-prep-chemistry-j23-as-91-closed-editorial-candidate-manifest-20261029.json`; this is a non-publishing editorial manifest, NOT the canonical source package.
    - [x] Recovered exact source-backed per-locale authoring fields in **PRIVATE CLOSED** `private.iclub_exam_chemistry_j23_as_authoring_recovery_v1` by installed migration `20261029112704` (matching GitHub SQL). Exactly **273 locale rows / 91 skills**, 273/273 original examples, 273/273 common traps, 186 existing questions extracted, **87 question slots missing**, **273 check answers deliberately NULL**, 36 locale rows carry the 12 J23 revisions. Private RLS enabled, no `authenticated` table read, legacy untouched.
    - [x] J23 authoring-recovery whitespace issue fixed immutably via migration `20261029113019` → `chemistry9701_j23_20261029_sixfield_recovery_v2`: boundary whitespace stripped for 273 examples/traps and existing 186 check prompts. v1 preserved; use v2 as recovered authoring input.
    - [x] **91/91 six-field draft source coverage**: 29 newly authored check questions × 3 locales (87); 62 existing source check prompts initially retained, of which 8 ambiguous/instructional prompts replaced across EN/RU/UZ (24); all 273 candidate check answers authored. Two language leaks in RU answers immediately corrected as append-only v2 rows. **NOT independently academically approved.**
    - [x] **Append-only canonical candidate v2 staged PRIVATE in Supabase**: 91 six-field Theory cards and 273 Tutor source links with per-card SHA-256, plus exact UTF-8 Theory/Tutor source bundle and true combined package SHA-256. See `docs/exam-prep-chemistry-j23-as-91-sixfield-private-package-candidate-v2-delta-20261029.json`.
    - [x] Seven stale Tutor RU/UZ titles identified and corrected in candidate v2; source v1 and historical 154 cards unchanged; both migrations are tracked in GitHub.
    - [ ] Independent scientific/trilingual academic review of all NEW 29 × 3 check prompts, eight rewritten self-checks, all 273 answers, and Tutor explanation semantics; resolve any found defect as NEW append-only closed source version before academic owner approval.
    - [x] Build the full **CLOSED** 91-card canonical six-field Theory/Tutor source bytes in `private.iclub_exam_chemistry_j23_as_source_bundle_v1`, with per-card source SHA-256, 273 version-linked Tutor records and package SHA-256 according to `scripts/subject-release-packager.py` formats. Current v2 package SHA-256: `b09996b5f6611221beb8230712926393d6fd8308c825bc0887e9fde1b0715d1d`; Theory SHA-256: `36cb6a088971a1c4b740684153dfe9964cf0ba8068b64f43eed0ce19919e9eac`. This remains an unapproved staging package.
    - [ ] Export the exact private source bytes for independent `scripts/subject-release-packager.py` execution; verify the local Python package hash and Tutor alignment; independent owner rights and academic signoff remain required before release.
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
