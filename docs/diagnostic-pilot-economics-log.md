# Economics Diagnostic Pilot Log

Date: 2026-07-03
Scope: President Tech Award diagnostic pilot
Subject: Economics (`subject_id=7`)
Safety mode: additive only, no legacy app flow changed

## 1. What was changed safely

The pilot work added a diagnostic layer only.

No historical data was changed:

- no old `questions` rows were rewritten;
- no old options were rewritten;
- no old `correct_answer` values were changed;
- no `practice_answers` rows were rewritten;
- no `tour_answers` rows were rewritten;
- no tour/practice scores were recalculated;
- no current public app policy was removed.

## 2. Questions selected for the first pilot batch

Selected Economics questions with real user history:

| question_id | qtype | topic | subtopic | history policy |
|---:|---|---|---|---|
| 1081 | mcq | Market | Allocative efficiency | diagnostic mapping only |
| 1071 | mcq | Demand | Complementary goods | diagnostic mapping only |
| 1115 | mcq | Market | Consumer surplus | diagnostic mapping only |
| 1135 | mcq | Basics | Income from factors of production | diagnostic mapping only |
| 2548 | mcq | Government macroeconomic intervention | Fiscal policy | diagnostic mapping only / clone if reused in future high-stakes tour |
| 1018 | input | PPC | Opportunity cost on the PPC | future evaluator rule; historical recalculation requires approval |
| 1022 | input | Elasticity | Calculating PED | future evaluator rule only |

## 3. Diagnostic rows added

Published diagnostic rows added:

- 5 MCQ questions with full A/B/C/D mapping = 20 rows;
- 2 input questions with exact/pattern/fallback mapping = 7 rows;
- total = 27 published diagnostic rows.

Current Economics diagnostic audit after this batch:

- `questions_with_any_rule`: 7;
- `mcq_questions_with_4_option_rules`: 5;
- `input_questions_with_rule`: 2;
- `published_diagnostic_rows`: 27;
- full subject `ready`: false.

The full subject remains not ready because this is a pilot proof layer, not a complete Economics diagnostic map.

## 4. Important input false-negative case

Question `1018` has correct answer `3`.

Historical tour users wrote answers such as:

- `3 birlik Y`;
- `3 единицы Y`;
- `3ta Y`.

These are conceptually equivalent to `3 units of Y`, but the old exact checker marked them incorrect.

Decision:

- do not rewrite historical answers;
- do not recalculate old tour scores automatically;
- add future input pattern rule so the new safe evaluator accepts these forms;
- keep the item as a historical recalculation candidate only if the architect explicitly approves a separate impact report.

Pattern safety check:

- accepts `3 birlik Y`;
- accepts `3 единицы Y`;
- accepts `3ta Y`;
- rejects `48`.

## 5. Safe RPC correction

The new safe submit RPC `submit_practice_answer_safe` was corrected so that when a published input diagnostic rule matches and that rule is marked `is_correct=true`, the returned/stored result is also correct.

This affects only the new President Tech Award diagnostic RPC.

It does not change the legacy app submission flow.

## 6. Product principle

For the President Tech Award demo, the diagnostic layer proves intelligent feedback while preserving trust in historical scores.

The safe architecture remains:

> keep old history stable; improve future diagnostic quality through mapping, evaluator rules and cloned versions.
