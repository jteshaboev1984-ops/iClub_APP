# iClub Diagnostic Engine v1

Date: 2026-07-03
Status: implementation contract for President Tech Award pilot

## 1. Goal

Create a safe diagnostic layer on top of the existing iClub MVP without breaking current users or deleting historical progress.

The engine must prove that iClub can move from simple practice/tour scoring to diagnostic learning:

- safe question delivery;
- server-side answer checking;
- option-level MCQ diagnosis;
- input answer rules;
- mistake reason;
- next action;
- basic roadmap;
- teacher weak-topic analytics.

## 2. Non-goals for v1

The v1 pilot does not include:

- full all-subject mapping;
- full AI Mentor;
- payment system;
- full teacher SaaS dashboard;
- full app.js architecture refactor;
- removing legacy functions before frontend migration.

## 3. Safe question delivery

Frontend must not receive:

- `correct_answer`;
- `explanation`;
- `explanation_ru`;
- `explanation_uz`;
- `explanation_en`.

New safe sources:

- `public.safe_questions_public`;
- `public.get_safe_questions_by_ids(bigint[])`.

The RPC keeps the original question order using `request_order`.

## 4. Server-side checking

Legacy risk:

- `submit_practice_attempt(...)` receives `is_correct` from client.

Pilot-safe replacement:

- `submit_practice_answer_safe(...)`.

Client sends:

- `attempt_id`;
- `question_id`;
- selected answer / typed answer;
- time spent;
- optional picked index.

Server does:

- validates authenticated user;
- validates attempt ownership;
- validates question subject;
- reads `correct_answer` privately;
- computes `is_correct`;
- writes `practice_answers`;
- writes `user_answer_diagnosis`;
- returns safe diagnostic result without exposing the answer key.

## 5. Diagnostic mapping table

`question_answer_diagnostics` stores private mapping rules:

- `mcq_option`;
- `input_exact`;
- `input_tolerance`;
- `input_pattern`;
- `fallback`.

Each row may include:

- mistake type;
- weak skill;
- RU/UZ/EN feedback;
- RU/UZ/EN next action;
- recommended topic/subtopic;
- optional recommended lesson;
- JSON rule.

This table has RLS enabled and no public select policy.

## 6. User diagnosis table

`user_answer_diagnosis` stores the actual diagnosis generated for each answer.

Users may read only their own diagnosis rows.

## 7. Learning roadmap table

`learning_roadmaps` stores attempt-based learning plans.

Users may read only their own roadmaps.

## 8. Pilot audit metrics

Use:

```sql
select * from public.get_diagnostic_pilot_audit(null);
```

A subject is ready only when:

1. every pilot question has at least one diagnostic rule;
2. every MCQ question has four option-level diagnostic mappings;
3. every input question has at least one exact/tolerance/pattern/fallback rule.

## 9. Safe rollout order

1. Keep old app flow untouched.
2. Add safe source and safe submit RPC.
3. Build pilot UI on safe source.
4. Test pilot flow with one subject.
5. Only after frontend is migrated, close old direct `questions` public read policy.

## 10. Demo wording

Use this wording:

> In the current MVP, iClub already has real users, attempts and answer history. The diagnostic engine adds a secure layer: questions are delivered without answer keys, answers are checked server-side, misconceptions are mapped at answer-option level, and the student receives a personal next step.

Do not say:

> The full AI Mentor is already finished for all subjects.

Correct wording:

> The architecture is universal; the pilot proves it on one subject, and investment scales mapping, expert review, AI Mentor and teacher dashboard across all subjects.
