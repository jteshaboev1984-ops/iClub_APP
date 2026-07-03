# iClub — President Tech Award Readiness

Date: 2026-07-03
Status: working document for competition preparation

## 1. Positioning

iClub is not a generic quiz platform and not an AI chatbot. The competition narrative should be:

> iClub is a secure, source-aligned diagnostic learning infrastructure for STEM, Cambridge A-Level and olympiad preparation in Uzbekistan and Central Asia.

## 2. Current verified foundation

The project already has a working MVP foundation:

- real users;
- subjects;
- questions bank;
- practice attempts;
- practice answers;
- tour attempts;
- tour answers;
- recommendations;
- lessons;
- tours;
- certificates infrastructure;
- telemetry/events;
- Telegram WebApp frontend.

This should be shown as traction + working MVP, not as an idea-stage project.

## 3. Main technical risk

The main risk before presenting the project is answer-key exposure:

- active questions have `correct_answer` stored in `questions`;
- active questions have explanations stored in `questions`;
- the old `questions_public_read` policy still allows active questions to be read directly;
- the legacy `submit_practice_attempt` trusts client-provided `is_correct`.

Therefore, the first technical proof is not AI Mentor. The first proof is safe question delivery + server-side answer checking.

## 4. Competition-ready core proof

Minimum strong version before submission/demo:

1. Questions are delivered to frontend without `correct_answer` and explanations.
2. Practice pilot flow checks answers server-side.
3. Client sends only `user_answer` / selected option, not `is_correct`.
4. One subject has diagnostic pilot mapping.
5. MCQ option-level diagnosis is visible.
6. Input exact/tolerance/fallback checking is visible.
7. Result screen shows mistake reason and next action.
8. Basic roadmap is generated.
9. Minimal teacher dashboard shows weak topics and mistake types.
10. GitHub contains migration/function/docs proof.
11. Unfinished items are clearly separated as investment roadmap.

## 5. Category strategy

Use the actual President Tech Award form at the moment of submission.

Priority:

1. If EdTech exists — choose EdTech.
2. If EdTech does not exist and Social Tech exists — choose Social Tech.
3. If Social Tech is not available — position as MicroSaaS with teacher dashboard and school package emphasis.
4. AI category should be chosen only if AI Mentor + diagnostic proof is strong enough.

Current public competition page lists Edtech among startup categories, so EdTech is the first-choice category unless the application form changes.

## 6. What was started on 2026-07-03

Added a safe diagnostic foundation in Supabase:

- `safe_questions_public` view;
- `get_safe_questions_by_ids(...)` RPC;
- `question_answer_diagnostics` table;
- `user_answer_diagnosis` table;
- `learning_roadmaps` table;
- `submit_practice_answer_safe(...)` RPC;
- `get_diagnostic_pilot_audit(...)` RPC.

Important: this was added without deleting old policies and without breaking the current app flow. The old public question policy must be closed only after frontend pilot flow has moved to the safe source.

## 7. Next work order

### Step 1 — Safe frontend pilot

Move one pilot practice flow from direct `questions` reads to `get_safe_questions_by_ids(...)`.

### Step 2 — Server-side submit

Move pilot practice answer saving to `submit_practice_answer_safe(...)`.

### Step 3 — Diagnostic mapping

Select one subject, preferably Economics or Mathematics, and map 20–30 pilot questions:

- each MCQ question: 4 option-level diagnostic rows;
- each input question: exact/tolerance/pattern/fallback rule;
- RU/UZ/EN feedback;
- RU/UZ/EN next action.

### Step 4 — Result UI

Show:

- selected answer;
- correct/incorrect status;
- mistake type;
- weak skill;
- short explanation;
- next action;
- recommended topic/subtopic/lesson.

### Step 5 — Teacher mini-dashboard

Show:

- weak topics;
- mistake-type distribution;
- student progress;
- targeted assignment suggestion.

## 8. Investment roadmap

Do not claim these as already finished:

- all-subject diagnostic mapping;
- full AI Mentor;
- Teacher Pro dashboard;
- school packages;
- parent/admin reports;
- payment system;
- full leaderboard privacy refactor;
- app.js modular refactor;
- Central Asia scaling.

## 9. Pitch formula

What exists now:

> working MVP + users + questions + attempts + recommendations.

What is being built before competition demo:

> secure 1-subject diagnostic proof.

What investment scales:

> all-subject mapping + full AI Mentor + Teacher Pro + school packages + regional expansion.
