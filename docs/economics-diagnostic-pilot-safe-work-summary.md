# Economics Diagnostic Pilot — Safe Work Summary

Date: 2026-07-03

## Production safety rule

The work was done without breaking the live app or rewriting historical data.

No changes were made to:

- `questions` content;
- old option text;
- `correct_answer`;
- `practice_answers` history;
- `tour_answers` history;
- old practice/tour scores;
- current public app policies.

## Applied work

### 1. Governance decisions

For 7 selected Economics pilot questions, governance decisions were marked as `applied`:

- 1081 — diagnostic mapping only;
- 1071 — diagnostic mapping only;
- 1115 — diagnostic mapping only;
- 1135 — diagnostic mapping only;
- 2548 — diagnostic mapping only, clone for future if stronger version is needed;
- 1018 — historical recalculation candidate, approval required before any retroactive scoring;
- 1022 — future evaluator rule only.

Verified count: 7 applied decisions.

### 2. Diagnostic rows

Published rows in `question_answer_diagnostics` for the pilot questions:

- 5 MCQ questions × 4 option-level rules = 20 rows;
- 2 input questions with exact/pattern/fallback rules = 7 rows;
- total = 27 published rows.

### 3. Input evaluator correction

The new safe RPC `submit_practice_answer_safe` was corrected so matched input diagnostic rules can affect the future `is_correct` result.

This fix applies only to the new safe diagnostic RPC.

The legacy live app submission flow was not changed.

### 4. False-negative protection

For `question_id=1018`, the future evaluator accepts conceptually correct unit answers:

- `3 birlik Y`;
- `3 единицы Y`;
- `3ta Y`.

It rejects unrelated wrong answers such as `48`.

Historical scores were not recalculated.

## Current pilot state

- Economics full-subject audit remains `ready=false`, because only a pilot subset is mapped.
- The selected pilot subset is ready for technical demo logic at the diagnostic-data layer.
- Frontend connection is still pending.

## Next safe step

Connect only a separate pilot UI path to:

1. `get_safe_questions_by_ids(...)` for safe question delivery;
2. `submit_practice_answer_safe(...)` for server-side checking and feedback.

Do not remove the old `questions_public_read` policy until the pilot UI has been tested end-to-end.
