# Economics Diagnostic Pilot — Next Safe Frontend Step

Date: 2026-07-03

## Goal

Add a separate pilot diagnostic UI path without touching the current live tour/practice flow.

## Non-goals

Do not change:

- existing practice loading;
- existing tour loading;
- existing scoring history;
- current active public question policy;
- old answer records.

## Safe pilot path

The pilot should use fixed selected question IDs first:

```text
[1081, 1071, 1115, 1135, 2548, 1018, 1022]
```

Question delivery:

```sql
select * from public.get_safe_questions_by_ids(array[1081,1071,1115,1135,2548,1018,1022]);
```

Answer submission:

```sql
select public.submit_practice_answer_safe(
  p_attempt_id,
  p_question_id,
  p_user_answer,
  p_time_spent,
  p_picked_index
);
```

## UI result block

After each submitted answer, show:

- whether the answer is correct;
- short feedback;
- weak topic/subtopic;
- next recommended action.

Do not show:

- `correct_answer` before submission;
- explanations from `questions` table before submission;
- internal table/function names to students.

## Release rule

This should be hidden behind a pilot/admin/demo entry point until tested.

Only after the pilot path works end-to-end should the old public question read policy be narrowed or removed.
