# Diagnostic Learning Engine — Live Practice Integration Plan

Date: 2026-07-03

## Current state

The diagnostic demo exists as a separate hidden page:

```text
/diagnostic-demo.html
```

It is not connected to the live practice/tour flow.

This is intentional because the live app has real users and real history.

## Product goal

The final diagnostic experience should feel like a natural part of the main iClub app, not like a separate technical demo.

The demo should eventually become visually and logically close to the real practice flow:

1. subject selection;
2. practice start screen;
3. question screen;
4. per-answer diagnostic feedback;
5. final diagnostic summary;
6. recommended next practice / lesson.

## What should be shown in real practice

### 1. Before practice

Show a normal practice card:

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

### Phase 1 — Hidden demo polish

Status: in progress.

Scope:

- keep `/diagnostic-demo.html` hidden;
- make it visually close to app design;
- support EN/RU/UZ;
- hide technical labels;
- show final diagnostic summary;
- no database writes from the demo session.

### Phase 2 — Real app visual clone

Create a second hidden route that mirrors the main app flow more closely.

Suggested route:

```text
/diagnostic-practice-pilot.html
```

This route should include:

- app-like header;
- subject card for Economics;
- start diagnostic practice button;
- question flow;
- feedback block;
- final summary.

Still hidden. Still no effect on live practice/tour history.

### Phase 3 — Safe pilot in real practice

Add diagnostics behind a feature flag.

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

### Phase 4 — Live practice integration

Only after Phase 3 testing:

- load questions through safe payload;
- check answers server-side;
- write diagnostic records safely;
- update practice result screen with diagnostic summary;
- keep old scores/history stable.

### Phase 5 — Tour review integration

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
