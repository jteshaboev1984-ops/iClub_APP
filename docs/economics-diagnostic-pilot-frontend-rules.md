# Economics Diagnostic Pilot — Frontend Safety Rules

Date: 2026-07-03

## Rule 1 — separate pilot path only

The first frontend connection must be separate from the live practice/tour flow.

It can be:

- hidden admin/demo route;
- temporary internal button;
- feature-flagged screen.

It must not replace the current working practice/tour screens immediately.

## Rule 2 — safe delivery only

Pilot questions must come from:

```text
get_safe_questions_by_ids(...)
```

They must not be read directly from `questions` for the pilot.

The frontend must not receive:

- `correct_answer`;
- `explanation_ru`;
- `explanation_uz`;
- `explanation_en`.

## Rule 3 — server decides correctness

Frontend sends only:

- attempt id;
- question id;
- selected option or input text;
- time spent.

Frontend must not send trusted `is_correct`.

Correctness must come from:

```text
submit_practice_answer_safe(...)
```

## Rule 4 — result wording for students

Do not show internal terms such as table names, RPC, diagnostic_id, answer_key or rule_json.

Student-facing result should show:

- answer result;
- short feedback;
- weak topic/subtopic;
- next action.

## Rule 5 — old policy stays until tested

Do not remove or narrow `questions_public_read` until the pilot path is tested end-to-end.

The live app already has real users, so migration must be gradual.
