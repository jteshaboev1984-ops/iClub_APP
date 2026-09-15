# P2-80 — Independent A-to-Z Release Audit

Status: **CANDIDATE AUDIT — engineering CI must pass before closure**  
Audit date: 2026-09-15  
Production baseline SHA at audit start: `bf8e0399ccfab1de402b97f404f334c0379d8f7c`

## Scope

This is the final independent engineering re-audit required by the synthetic-validation roadmap. It checks the implemented Mathematics Exam Prep P1+P5 system against the approved project documents and the actual GitHub, Supabase and deployed-browser state.

The audit does **not** convert synthetic evidence into a claim about learner outcomes, UX value or real Mentor Care capacity. Those remain real-world evidence questions.

Normative sources rechecked:

- 09 Cambridge AS Mathematics P1+P5 Master Implementation Plan v1.1;
- 07 Beta & Release Plan v1.1;
- 04 Content Governance Model v1.1;
- 06 AI Layer Safety Architecture v1.1;
- 05 Mentor Care Operating Model v1.1;
- 08 Annual Roadmap Compliance Audit v1.0;
- 03 Integration Architecture Audit v1.0;
- 01 Academic Syllabus Source Map v1.0;
- current synthetic-validation roadmap and prior P2-62..P2-79 evidence.

## Independent production read-only snapshot

At audit start, production remained:

- rollout: `controlled_beta`;
- Core: ON;
- AI learner capability: OFF;
- Mentor learner capability: OFF;
- kill switch: OFF;
- provider generation: OFF;
- AI runtime: `shadow`;
- active synthetic identities: 0;
- terminal unclean synthetic runs: 0;
- active Mentor Care entitlements: 0;
- active mentor assignments: 0.

Canonical registry is exactly P1 = 45 and P5 = 36. All private Exam Prep tables have RLS. There are zero anon/authenticated direct grants on private Exam Prep tables and zero browser-executable private Exam Prep functions.

Legacy preservation baseline remained unchanged during the read-only audit:

- Practice attempts: 906;
- Practice answers: 8,820;
- Tour attempts: 365;
- Tour answers: 6,267;
- certificates: 157;
- users: 1,326.

## Academic/content governance

Production checks found:

- 65 Exam Prep content versions, all published;
- 303 governed question metadata rows;
- governed question QA failures: 0;
- governed diagnostic-rule failures: 0;
- 102 written tasks;
- governed written-task QA failures: 0;
- protected retest non-holdout failures in the audited P5 reserve set: 0;
- 21 canonical mixed mappings, all fail-closed as objective-transfer-only and not written-mastery-ready.

The production runway report at active week 1 is green for both P1 and P5 through active week 24, with the 4-week target and 2-week hard floor green.

## AI boundary

Production contains exactly 12 approved runtime source cards:

- P1 progress context EN/RU/UZ;
- P1 weekly-plan context EN/RU/UZ;
- P5 progress context EN/RU/UZ;
- P5 weekly-plan context EN/RU/UZ.

All use source version `iclub_ai_context_v1_2026_09_07`. No theory/error card has been silently enabled. Production generation remains OFF and runtime remains shadow. P2-80 re-runs the fake-provider P2-74 safety regression and makes zero paid provider calls.

## Mentor boundary

Production has zero active Mentor Care entitlements and zero active mentor assignments. The Mentor Technical result remains an engineering result only. Real staffing, calibration, SLA and capacity are not inferred from synthetic mentor tests.

The 600/10 law was previously proven by P2-78 and is re-covered by the Core dress rehearsal: only active assignment scopes may enter Mentor Care; unassigned learners do not create routine human queue/SLA scope.

## GitHub ↔ production migration provenance

The three P2-77 production migration-ledger entries use deployment-time numeric version prefixes:

- `20260915050035` — `exam_prep_p2_77_mentor_technical_foundation_v1`;
- `20260915050103` — `exam_prep_p2_77_mentor_technical_convergence_v1`;
- `20260915050115` — `exam_prep_p2_77_synthetic_staff_firewall_compat_v1`.

The repository contains the same three logical migrations under source-order prefixes:

- `20260915043000_exam_prep_p2_77_mentor_technical_foundation_v1.sql`;
- `20260915043100_exam_prep_p2_77_mentor_technical_convergence_v1.sql`;
- `20260915043200_exam_prep_p2_77_synthetic_staff_firewall_compat_v1.sql`.

Read-only inspection confirmed matching logical names and matching beginning/end migration content, and the expected production objects/functions are present. The numeric prefix difference is recorded as deployment provenance metadata; production migration history is not rewritten. Final parity is judged by the checked schema/function contracts and full clean migration replay from repository `main`, not by rewriting historical version identifiers.

## Deployed browser parity

Vercel production is deployed from `bf8e0399ccfab1de402b97f404f334c0379d8f7c` at `i-club-app.vercel.app`.

The live Exam Prep host remains Mathematics-only and server-capability gated. The live API adapter uses safe server RPCs for session start/submit/finalize, recovery, weekly planning and later-stage workflows. No browser academic-state authority or legacy localStorage write path was found. P2-80 independently re-runs the browser legacy-storage firewall and the full Core learner journey.

## Recovery / rollback

P2-79 already passed on PR head and again after merge. P2-80 re-runs the rollback/disaster matrix in an isolated database, including kill-switch recovery, failed-migration rollback, interruption recovery, stale content/client handling, AI outage, interrupted synthetic run/cleanup and replay. It also requires final zero synthetic residue.

## Real-world evidence gate

Production currently has:

- active controlled-beta members: 3;
- granted consents: 3;
- real Exam Prep beta sessions: 0;
- weekly beta reviews: 0.

The production expansion gate is therefore **not eligible**. This is correct fail-closed behaviour. Engineering GREEN must not be interpreted as authorization for expanded beta or mass rollout.

## Candidate split verdict

Pending exact-head P2-80 and P2-73 CI plus post-merge rechecks:

- **Core Engineering: GREEN candidate**
- **AI Engineering: GREEN candidate**
- **Mentor Technical: GREEN candidate**
- **Real-world Evidence: UNPROVEN**

Expanded beta: **NO-GO until the real beta evidence gate is satisfied**.  
Mass rollout: **NO-GO**.

P2-80 may be marked COMPLETE only after the exact candidate passes this independent gate, the three-seed Core dress rehearsal remains green, the change is merged, post-merge checks pass, and a fresh production read-only snapshot confirms no safety-boundary or legacy drift.
