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

Submit correct MCQ option through the safe RPC.

Expected:

- `is_correct=true`;
- diagnostic feedback returns;
- score/percent update only for the test practice attempt.

## Test 3 — MCQ wrong answer

Submit wrong MCQ option through the safe RPC.

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

After test submissions, verify:

- old tour answers unchanged;
- old practice answers unrelated to test attempt unchanged;
- no historical scores recalculated.

## Pass condition

The hidden/demo path passes if it gives diagnostic feedback while preserving historical data and not exposing answer keys before submission.
