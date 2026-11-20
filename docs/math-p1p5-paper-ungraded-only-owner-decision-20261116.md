# Mathematics P1/P5 — full Paper is permanently ungraded practice (owner decision)

**Binding owner instruction: 2026-11-16**, [Issue #450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450). This **supersedes** earlier mentions of future human-, mentor-, tariff- or AI-awarded written/full-Paper marks for the P1/P5 hybrid Paper journey. Product decision, not approval to merge, deploy, alter production, edit old student results or execute a database migration.

## Decision — no Paper marking, now or planned

1. **P1 and P5 full handwritten Papers are voluntary practice only.** iClub **does not assign any marks** for the written solution or the full Paper, nor a 0/75, 0/50, grade, percentage, simulated Cambridge mark or verified academic score. Completion means the user finished a timed practice session; not proof of correct working.
2. **Review is advice, not assessment.** Offer academically source-approved marking requirements or method checkpoints only as **review criteria** for the learner's own handwritten attempt, clear topic/revision guidance and brief hints where sourced. Do not invent complete worked solutions. Optionally match narrow **final answers only** where already approved; explicitly label match/no-match as an answer-check, never a mark, completion proof or method check. If no checked key exists, skip the optional checker.
3. **Mentor discussion is optional.** The UI may recommend that a learner **ask a mentor for explanation or guidance if available**, but no compulsory meeting/review/upload, no guaranteed response, no registration/paywall prerequisite, and no mentor-awarded Paper scores. There is **no future mandatory or paid AI marking workstream** for these Papers.
4. **Keep Paper history separate from genuine graded objective Core assessments.** Preserve identity, paper version, elapsed time, early/normal/expired status, review visibility and per-component P1/P5 ownership. Unmarked Paper must never produce L2/L3, comparable full-Paper marks, Stage gate credit, grade readiness, AI/mentor-review credit or a scored leaderboard. Revisit/reveal remains read-only/noncredit. Do not re-enable student self-grade RPC or rewrite historic attempts.

## Existing Stage3–6 dependency must be reconciled

Current 2026-09 Stage3 server evaluator requires an **academically comparable full-Paper score baseline** to leave Stage3; certain Stage4–6 readiness displays require comparable full Paper counts/score trends. D03 correctly rejects self-marking and unverified written work. **The owner has now categorically removed written Paper grading from the product**, so waiting for independent verified written marks is **not an appropriate future task** and cannot serve as a permanent stage exit dependency.

The previous [2026-11-09 approved hybrid rule](math-p1p5-v22-s4-current-paper-source-audit-stage-gate-proposal-20261109.md) already approved treating first/second/third Paper rehearsals and unverifiable Paper timing/score trends as **recommended rather than compulsory** for Stage3–6, preserving existing objective skill/mastery/correction/retest evidence. Implement that decision in a **separate Mathematics academic/server draft**, with explicit before/after evaluation matrix and signed isolated PG17/PostgREST/JWT + Chromium verification. Never turn a completed rehearsal, final-answer match, absence of marks or mentor advice into an academic substitute, and never invent new thresholds or mandatory study quotas. Historical graded objective data and all past learner work remain immutable.

**Current technical limitation until source remediation:** Stage3 may remain blocked under the old score comparator even when the Paper is correctly ungraded. This is an **implementation mismatch to fix**, not a reason to start scoring Paper or to declare the learner incapable of progression. Do not silently change production stage rules. The source fix requires its own scoped approval and eventual release gate.

## Learner-facing wording

- RU: «Paper — тренировка без баллов. Сверьте ход решения с критериями и рекомендациями. При желании обсудите вопросы с ментором. Это необязательно».
- UZ: «Paper — ball qo‘yilmaydigan mashq. Yechimni mezon va tavsiyalar bilan solishtiring. Xohlasangiz, mentor bilan maslahat qiling; bu majburiy emas».
- EN: “Paper is ungraded practice. Review your working against the criteria and tips. You may ask a mentor for help, but it is never required.”

**Scope:** Mathematics P1/P5 hybrid Paper only. This decision does not prohibit already approved legitimate grading of separate objective Core/diagnostic/timed items, nor does it change Chemistry/Economics rules.

## Concrete next step

1. Mathematics academic workstream audits **current active** Stage3–6 SQL/RPC dependencies and read-only student-state compatibility; removes only obsolete **Paper-mark-derived** gates in a separate isolated Draft PR.
2. Builds positive/nonnegative regression for objective academic progression with **no Paper score**, plus adversarial negative checks for auto-credit, self-marks, cross-P1/P5, old JWT, existing scores and prior attempts.
3. UX #531 may separately finish fonts/profile layout and optional Paper guidance text; source-only UI review is not Stage progression authority.
4. No merge to main, production SQL, feature flags, learner-data migration or mass rollout without later **specific owner approval**.
