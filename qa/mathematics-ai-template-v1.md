# iClub APP — Stage 08 Mathematics AI reference template (QA only)
Date: 2026-10-09
Scope: Cambridge AS Mathematics P1 + P5; RU / UZ / EN.

## Approved architectural decision
Mathematics P1/P5 is the technical reference for all future subject AI.
Biology, Chemistry, Economics and Informatics academic AI are **not acceptance targets**
while their content is being rewritten. Their ordinary Courses, Practice and Tours stay as-is.
This document does NOT approve public AI activation.

## Automated QA contract
Run the existing build command stage09-preview-build.cjs then stage03-qa-build.cjs.
The QA-only file stage08-mathematics-ai-contract.cjs validates:
- Global generated route accepts only the approved math_exam_prep_v1 adapter,
  Mathematics, exam_prep scope, P1/P5 component, matching approved skill code.
- Other subject, wrong component, wrong scope and malformed skill requests are rejected
  before a provider call can begin.
- Global and Exam Prep Edge handlers retain mandatory server guards.
- Missing approved source, provider budget reserve and output validation remain required.
- P1 / P5 chat histories are isolated; course screen routing and contextual Tutor remain correct.
- Protected assessments block AI, ephemeral chat clears on account change.
- The RU / UZ / EN and P1 / P5 allowlists remain unchanged.
This is a source/build contract, not a real authenticated API/provider test.

## Read-only academic source verification
Approved runtime source AND tutor cards: P1 = 45 skills per locale,
P5 = 36 skills per locale, 0 missing / duplicate active skill versions;
required source/tutor fields populated. Placeholder records without a skill code
are excluded from per-skill counts; no rows modified.
Spot checks in all three languages: P1-CIR-01 radians,
P1-TRI-05 trigonometric equations, P5-BIN-01 binomial prerequisites,
P5-PRO-06 without-replacement probability tree. Examples were internally
consistent and basic calculations checked. This does NOT establish 81/81
answer quality for a live model.

## Actual operating state at this read-only pass
- Exam Prep Core ON; Exam Prep AI controlled beta.
- Global AI OFF, generation OFF, gateway OFF and kill switch ON.
- Practice AI OFF; new Global AI Edge Function not deployed.
- No live provider invocation or learner account impersonation was performed.

## Release gates still open
1. Finish safe subject-topic switch RPC separately without changing old results.
2. Controlled authenticated Mathematics-only test using existing authorized beta students,
   including diagnostic/retest/paper protection and server-side request denial.
3. Test real P1/P5 AI replies against approved reference and verify provider cost.
4. Restore the required final AI-off / public-Free state and verify Core independently.
5. Single architect-approved final merge, production deploy and preservation check.
Do not apply to main or production on the basis of these build checks.
