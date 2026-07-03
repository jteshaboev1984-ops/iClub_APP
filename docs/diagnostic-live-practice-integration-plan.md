# Diagnostic Learning Engine — Live Practice Integration Plan

Date: 2026-07-03

## Current state

The diagnostic demo exists as one temporary hidden page:

```text
/diagnostic-demo.html
```

It is not connected to the live practice/tour flow.

This is intentional because the live app has real users and real history.

Do not create additional demo routes unless there is a strong product reason. The next step should move toward the existing app flow, not create a demo for the demo.

## Product goal

The final diagnostic experience should feel like a natural part of the main iClub app, not like a separate technical demo.

The diagnostic flow should become part of the real practice experience:

1. existing subject/practice entry point;
2. existing practice start logic;
3. existing question screen style;
4. per-answer diagnostic feedback in practice;
5. final diagnostic summary on practice result screen;
6. recommended next practice / lesson.

## What should be shown in real practice

### 1. Before practice

Show diagnostics as a normal practice feature:

- subject;
- current tour/topic block;
- number of questions;
- estimated time;
- short explanation: practice will show feedback after answers.

Do not use technical terms such as function names, RPC names, table names or internal data labels.

### 2. During practice

After each answer, show:

- correct / needs revision;
- short explanation;
- weak area;
- next action.

For active competitive tours, do not show feedback during the tour.

### 3. After practice

Show a diagnostic summary:

- score / percent;
- strongest topics;
- main weak areas;
- repeated mistake patterns;
- next study plan;
- button to start recommended practice;
- button to review mistakes.

### 4. After active tour

Tour diagnostics should be shown only after the tour is completed/closed according to product rules.

Do not reveal answer keys during active tour participation.

## Safe technical path

### Phase 1 — Keep one hidden demo only

Status: current.

Scope:

- keep only `/diagnostic-demo.html` as a temporary hidden proof-of-concept;
- use it to validate diagnostic copy, EN/RU/UZ, input checking and summary logic;
- do not add another standalone demo page;
- no database writes from the demo session;
- no live practice/tour changes yet.

### Phase 2 — Inspect existing app practice flow

Before writing integration code, inspect the real frontend practice implementation.

Find exactly:

- where practice questions are loaded;
- where answer checking happens;
- where practice result screen is rendered;
- where language selection is applied;
- where user mode/subject/tour context is stored.

Output should be a precise integration map, not new demo code.

### Phase 3 — Add hidden feature flag inside existing flow

Add diagnostics behind a feature flag in the existing practice flow.

Suggested feature flag:

```text
diagnostic_practice_enabled
```

Enable only for:

- admin/test users first;
- selected subject: Economics;
- selected diagnostic question set;
- selected practice mode only.

Do not enable for all users immediately.

### Phase 4 — Safe pilot inside real practice

Only after Phase 2 mapping and Phase 3 flag:

- load selected diagnostic questions through safe payload;
- check answers server-side;
- show diagnostic feedback after practice answers;
- update practice result screen with diagnostic summary;
- keep old scores/history stable;
- keep the ability to switch the flag off quickly.

### Phase 5 — Wider practice integration

Only after the pilot is stable:

- expand diagnostic mapping to more Economics questions;
- then expand to other subjects;
- keep old public question read policy unchanged until the safe flow covers live needs.

### Phase 6 — Tour review integration

Only after live practice integration is stable:

- add diagnostics to post-tour review;
- never show feedback during active competitive tour;
- do not recalculate old tour scores without explicit governance decision.

## Where diagnostics should appear in real app

Recommended placement:

1. Practice question screen: small feedback block after answer.
2. Practice result screen: full diagnostic summary.
3. Subject progress screen: weak topics and next recommended practice.
4. Teacher/admin dashboard later: class weak areas and common mistakes.

## What must not be changed yet

Do not change yet:

- current live practice loading;
- current live tour loading;
- existing scores;
- certificates;
- ratings;
- old practice_answers;
- old tour_answers;
- public question read policy.

## Acceptance criteria before real release

The diagnostic integration can move into real practice only when:

- safe question payload does not expose `correct_answer`;
- answer checking is server-side;
- feedback exists for the selected questions;
- no historical data is changed;
- EN/RU/UZ UI works;
- result summary is clear for students;
- hidden pilot is tested on mobile;
- admin can disable the feature quickly.

## Product principle

The user should feel:

> “iClub understands my mistake and tells me exactly what to do next.”

The user should never see:

> database terms, RPC names, internal labels, answer keys before submission or unfinished technical wording.
