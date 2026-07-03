# Economics Diagnostic Pilot — Test Plan

Date: 2026-07-03

## Scope

Test only the hidden/demo diagnostic path.

Do not test by changing the live tour/practice screens first.

## Test 1 — Safe question payload

Call safe question delivery for the selected IDs.

Expected:

- question text is returned;
- options are returned;
- time limit/topic/subtopic are returned;
- `correct_answer` is not returned;
- explanations are not returned.

## Test 2 — MCQ correct answer

Submit correct MCQ option through the safe/checking path.

Expected:

- `is_correct=true`;
- diagnostic feedback returns;
- no practice/tour score is changed in the live app.

## Test 3 — MCQ wrong answer

Submit wrong MCQ option through the safe/checking path.

Expected:

- `is_correct=false`;
- specific weak skill / feedback returns;
- no answer key is exposed before submission.

## Test 4 — Input exact answer

For question `1018`, submit:

```text
3
```

Expected:

- `is_correct=true`;
- PPC opportunity cost feedback returns.

## Test 5 — Input unit answer

For question `1018`, submit:

```text
3 birlik Y
3 единицы Y
3ta Y
```

Expected:

- each is accepted as correct;
- feedback explains that units were accepted.

## Test 6 — Input wrong answer

For question `1018`, submit:

```text
48
```

Expected:

- `is_correct=false`;
- calculation feedback returns.

## Test 7 — History safety

After demo submissions, verify:

- old tour answers unchanged;
- old practice answers unchanged;
- no historical scores recalculated;
- no certificates or ratings changed.

## Test 8 — Summary screen

Complete all 7 demo questions.

Expected:

- final percent is shown;
- correct count is shown;
- main weak areas are shown;
- mistake pattern is shown;
- next study plan is shown;
- restart button resets only the browser demo state.

## Test 9 — Student-facing language

Switch EN / RU / UZ in the demo.

Expected:

- static UI copy changes language;
- question text and options use the selected language when the database has that language;
- feedback and next action use the selected language when diagnostic text exists;
- internal values such as `mcq`, `input`, `medium`, function names and table names are not shown to students.

## Test 10 — Hidden release rule

Open the normal live app screens.

Expected:

- the diagnostic demo is not linked from the live UI;
- live practice and live tour flows continue to work as before;
- the old public question read policy is not changed until the pilot path is tested end-to-end.

## Pass condition

The hidden/demo path passes if it gives diagnostic feedback and a mini study plan while preserving historical data and not exposing answer keys before submission.
