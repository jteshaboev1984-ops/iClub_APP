# Mathematics P1/P5 — change-control addendum v2.0 (Issue #450)

**Date:** 2026-11-02 · **Status:** architect-approved product decisions, proposed versioned implementation/governance change; **NOT release GO**.  
**Full current plan:** [Mathematics P1/P5 workplan v2.0](math-p1p5-release-workplan-v2-20261102.md).  
**Previous E2E evidence ledger:** [Integrated digital E2E roadmap v1](math-p1p5-integrated-e2e-release-roadmap-v1.md); do **not** discard evidence from PRs #451–#467.  
**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450).

## Precedence and scope

The latest explicit product decisions (D01–D13) in **v2.0** supersede conflicting *product expectations* in older mathematics release documents, but do not retroactively make obsolete CI or production release gates pass. Engineering verification remains evidence-based. Older test claims must be relabeled or re-executed when they assume written self-marks, four human weekly reviews or a 72-hour wave.

1. **Only Mathematics Core (P1+P5)** for public launch, both study and competitive registrations. Economics, Chemistry, Biology and Informatics Exam Prep display "In development" in RU/UZ/EN and remain inaccessible for new public use; preserve historic subject-specific records. Tours, certificates, other subjects, and current Mathematics Practice v3 must remain untouched.
2. **Written solutions receive no marks from the learner, app, or AI.** Remove learner self-mark UI and reject/retire self-mark RPC write paths. Do not add self-awarded marks to timed/full-paper scoring, comparable-paper readiness thresholds, stage unlocking or exam claims. Preserve task text, student's solution where intended, rubric for voluntary self-review, and legitimate auto-checkable objective answers separately; label partial objective outcomes honestly. Current production contains self-mark code; this is a release blocker. Updating live rules requires contract/regression tests and independent treatment of no-written-score comparability.
3. **AI Assist** stays limited to the existing three explicitly authorized beta accounts under existing consent; future tariff-based AI is an entirely separate release. Mentor Care stays OFF. No new public AI entitlement is implied by opening Core.
4. **Old beta and prelaunch Mathematics Exam Prep learner-state is test-only** and must be cleaned once at the final launch boundary after explicit architect GO, exact allowlist, dry-run, verified backup and restore test. Never indiscriminately delete all exam_prep_* tables: many are program/content/governance catalogs or belong to preserved beta/AI entitlements and other subjects. NEVER delete public.users, Tours, certificates or other real-app progress; NEVER repeat old Practice v2 cleanup or erase Practice v3.
5. **Individual preparation horizon = completed diagnostic date → confirmed P1/P5 exam date** (per component, not fixed 36 weeks). "Exam series" is not an exact paper date; unverified dates cannot yield a precise countdown. Weekly/periodic (7-day) forecast recalculates from the remaining time, remaining syllabus gaps, and observed work quality without changing academic evidence merely because time passed.
6. **Time recommendation = iClub calculation**, derived from authoritative Cambridge 9709 structure, verified source-appropriate Cambridge *general* guided learning benchmark (not personal minutes), approved skill-level study-time intervals, explicit unknown-skill uncertainty, corrections and full-paper duration. Do not claim Cambridge recommends an individual's exact daily minutes or guarantees an A. Never silently change a user's hours. Exactly three recommendation actions: "Оставить моё время", "Принять рекомендуемое", "Указать другое время". Each saved action is idempotent, server-owned and changes only future planning, never erases existing responses.
7. **Extra Hard** is optional, original syllabus-bound P1/P5 challenge content for strong learners or by choice. Do not add a fourth value to shared public.questions.difficulty (restricted to easy/medium/hard). Use versioned Exam Prep challenge metadata, source provenance, protected reserve separation, QA of objective equivalence, three locales and independent mathematical solutions. No academic credit for unverified written work or inflated mastery solely for challenge participation.
8. **Accelerated release gate**: automated isolated actual UI/JWT/PostgREST/PG17 and academic QA, shortest acceptable hosted/Telegram device smoke with consenting participants, no long-term four human weekly reviews/72h wave required as new conditions. **Crucial:** the currently installed private.exam_prep_p3_01_mass_core_rollout_gate_v1 still returns NO_GO; revise it transparently in its own versioned governed migration/test and obtain explicit architect approval. Never create fake real-user evidence or simply flip the NO_GO bit.
9. **Release gate integrity:** existing Stage-D same-SHA engineering aggregator remains valuable; adapt its academic assumptions and acceptance inventory for the new no-self-mark, deadline, workload and Extra Hard contracts rather than proclaim old GREEN evidence proves untested new features. Existing 15 canonical +18 adversarial test definitions do not automatically mean 33 full longitudinal browser journeys.
10. **Release switch:** test controlled_beta→public in all UI bootstraps and RPCs; QA-open flags currently broadly permit Core. Uncontrolled flag flip can strand legacy sessions; prelaunch cleanup is explicitly authorized only at final GO and changes that decision. No production writes, DDL, cleanup, deploy or feature-flag change in this documentation PR.

## Superseded/conflicting old requirements

| Older requirement | v2.0 disposition |
|---|---|
| Four real mentor weekly reviews as mass prerequisite | Replace through versioned, approved *accelerated* gate; real reviews cannot be fabricated. |
| 72-hour observed real wave prerequisite | Replace through versioned shortened smoke, automated fail-closed checks and accountable residual-risk acceptance. |
| Student written self-mark contributes provisional 75/50 full-paper score | Remove both self-mark and misleading full-score readiness arithmetic. |
| All beta Mathematics Exam Prep progress remains permanent | One-time precise clean of prelaunch **only** at GO; no indiscriminate purge. |
| One fixed 36-week plan and original September cohort dates | Personal dated horizon; academic stage transitions stay evidence-gated. |
| "Hard" is adequate for every learner | Approved optional Extra Hard challenge layer; shared enum unchanged. |
| General AI access with Core | Not authorized; separate tariff AI launch later. |
| All subjects open together | Only Mathematics now; all other Exam Prep subjects in development. |

## Governance and acceptance

- Change scope includes release plan, beta-policy, content governance and assessment-score semantics. Record one versioned approval in main **before public launch**; linked draft PR alone does not authorize migration.
- Keep the existing issue #450 as persistent engineering test tracker and link this addendum and new canonical workplan at the top. Do not rewrite its historical stage ledger or erase former failed/green records.
- Package 0 requires exhaustive dependency inventory and reversible targeted cleanup plan. The test-only beta progress reset is **one-time release operation**; verified unaffected counts are a hard gate.
- Package 1 begins after Package 0 baseline: syllabus/exam-date registry, per-paper diagnostic completion anchors, additive profile fields and validated exam calendar, no unverified "days remaining".
- With no confirmed date or no supported workload norm, return "insufficient evidence", not invented numeric weekly advice.
- Final GO belongs to the architect, not to a successful CI run or an assistant.

**Next-chat continuation message:**  
> Продолжай цифровой E2E-полигон Mathematics P1/P5 по GitHub Issue #450. Прочитай сохранённый roadmap, проверь текущий прогресс и работай с первого незавершённого этапа.

Read issue #450, this addendum, the complete v2.0 plan, the v2.0 execution ledger and the older E2E v1 record. Then choose the *first unfinished v2.0 package*; reuse prior E2E evidence and do not mistake old stage B–D labels for v2.0 completion.
