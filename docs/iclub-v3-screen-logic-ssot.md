# iClub v3 — Final Screen Logic SSOT

Status: APPROVED implementation contract
Scope: UI/UX + navigation logic only; production remains unchanged until security/isolation gates pass.

## 1. Product laws

1. Permanent bottom navigation: Home / Study / Ratings / Profile.
2. Nested screens inherit a route-group owner so the active global tab remains visible.
3. Assessment sessions hide the global bottom navigation.
4. One dominant action per ordinary screen.
5. Home deep-links to the exact next action; it must not add a redundant overview tap.
6. P1 and P5 are independent for placement, coverage, evidence, retest, timed work, papers and readiness.
7. P1 denominator = 45; P5 denominator = 36. Prerequisites and mixed nodes stay outside those denominators.
8. Core is complete without AI or Mentor Care. AI explains; it never changes academic truth. Mentor Care appears only for active assignments and adds human judgement without rewriting raw evidence.
9. Practice teaches. Tours assess competition. There is no duplicate learner-facing “Olympiad Practice” destination beside Practice.
10. Resources is one destination. Book is content inside Resources, not a duplicate route.
11. Certificates live contextually after eligible Tour results and globally in Profile → Achievements; they do not need a permanent Subject Hub row.
12. Tour Archive lives inside Tours, not as a second global/subject destination.
13. Recommendations are contextual after learning/error events; saved recommendations live in Profile.
14. News / Community / About are secondary information under Profile, not Home.
15. No destructive progress reset from changing UI/content language.
16. Exam Prep internal routes never persist EP-* names into legacy `iclub_state_v1`.
17. Live timed-session evidence is server-authoritative. Local time/state cannot manufacture evidence.
18. No answer key or private explanation in protected pre-answer payloads.

## 2. Global map

APP START
- Splash / session restore
  - existing profile → Home
  - no profile → Registration
- Registration
  - Step 1: profile + interface language
  - Step 2: school / region / grade
  - Step 3: subjects + competitive selection
  - complete → Home

GLOBAL SHELL
- Home
  - Today → exact next action
  - Continue learning → exact subject/activity
  - Weekly snapshot → Weekly Plan when relevant
  - Upcoming → Tour / retest / checkpoint / assigned mentor review
  - Notifications → Notifications
- Study
  - Subject Hub
    - Mathematics
      - Exam Prep
      - Lessons
      - Practice
      - Tours
      - Resources
    - Other subject
      - Lessons
      - Practice
      - Tours
      - Resources
- Ratings
  - competition leaderboard only
- Profile
  - Subjects
  - Achievements / Certificates
  - Saved recommendations
  - Services
  - Settings
  - Support
  - Information → News / Community / About

## 3. Mathematics Subject Hub

Header: Mathematics / Cambridge AS Mathematics

Primary module when Exam Prep is enabled:
- Exam preparation
- Paper 1: separate coverage + evidence + next action
- Paper 5: separate coverage + evidence + next action
- one CTA: Continue exam preparation

Secondary grouped lists:
- Learning
  - Lessons
  - Practice
- Competition
  - Tours
- Materials
  - Resources

No permanent rows for Olympiad Practice, Book, Recommendations, Certificates or Tour Archive.

## 4. Exam Prep screen contract

EP-00 Overview
- Separate P1/P5 cards.
- Today / next action.
- Quick access = Weekly Plan / Syllabus Progress / Corrections & Retests / Timed Practice & Papers.
- Placement/Profile are setup/re-entry flows, not daily quick-access clutter.

EP-01 Preparation Setup / Exam Profile
- Exam series/date window.
- Mathematics weekly time budget.
- Previously studied areas/paper experience.
- Learner goal may inform planning pace but never correctness/mastery.
- Changing setup never deletes evidence.

EP-02 Placement Hub
- P1 and P5 separate status/actions.
- One may be complete while the other remains incomplete.

EP-03 Placement Session
- Multi-question protected session.
- No detailed feedback during evidence collection.
- Confirmed answers may be resumed safely.
- Result only after session finalization.

EP-04 Placement Result
- Component starting point, strong evidence, needs attention, recommended first focus, uncertainty/retest need.
- Never infer P5 from P1 or vice versa.

EP-05 Syllabus Tracker
- P1: 8 areas / 45 skills.
- P5: 5 areas / 36 skills, including geometric distribution inside the DRV/BIN/GEO area.
- Foundation skills shown separately and never add denominator credit.

Area subview
- Dynamic `component_code + area_id`.
- Skill rows show natural title + state + one relevant action.

EP-06 Skill Detail
- Dynamic `component_code + skill_id`.
- One primary action.
- Evidence journey.
- Latest issue/correction.
- Resource.
- AI/Mentor contextual additions only.

EP-07 Weekly Plan
- Exactly one state at a time: NORMAL / RECOVERY / LATE_JOINER.
- Maximum three visible top priorities before secondary work.
- Calendar does not auto-promote stage.

EP-08 Corrections & Retests
- Needs correction → correction detail → similar work → delayed retest → confirmed.
- A failed retest reopens the cycle as “More practice needed”; no shaming language.

EP-09 Timed Practice & Papers
- One hub, not duplicate Timed/Papers destinations.
- Separate P1/P5 selector.
- Timed section / mixed timed set / full paper.

EP-10 Paper Attempt / Result
- Full paper route: instructions → session → submit/time end → result.
- Component-specific record only.
- Track raw/max, actual time, in-time marks, after-time work where allowed, unattempted marks and main loss causes.
- App readiness is separate by component and is not a predicted Cambridge grade.

EP-11 Mentor Review
- Only active Mentor Care assignment.
- Written/method/graph/multi-part human judgement.
- Human decision cannot alter the learner’s raw response.
- Mentor Verified readiness remains distinct from App Readiness Estimate.

## 5. Unified Question Runner

One UI shell with mode-specific controllers:
- learning
- practice
- placement
- retest
- mixed
- timed
- paper
- tour

Submission behavior:
- learning: server confirms → correct = brief feedback/next; incorrect = explanation + correction link
- retest: server confirms → pass = new evidence state; not pass = correction loop reopens
- placement: continue until session finalization; never result after one question
- timed: continue until set finalization/timer end
- paper: full attempt finalization before result
- tour: existing one-attempt/anti-cheat rules; no answer reveal until allowed

Exit behavior differs by mode:
- Practice: pause/resume allowed
- Placement: confirmed answers resume-safe
- Learning: safe exit
- Retest: incomplete session grants no confirmation
- Timed: interruption is recorded
- Comparable full paper: exit may invalidate comparability
- Tour: no pause; legacy rules preserved

## 6. Navigation law

Every route owns one global tab group:
- HOME: home
- STUDY: study, subject-hub, lessons, practice*, tours*, resources, exam-prep*
- RATINGS: ratings*
- PROFILE: profile, certificates, recommendations, settings, support, information*

Exam Prep maintains an internal transient stack. `entry_origin` is remembered only inside the module session.
Examples:
- Home → Retest → Skill → Close = Home
- Study → Math Hub → Exam Prep → Skill → Back = Exam Prep previous route; Close EP-00 = Math Hub

Switching bottom tab or subject closes/unmounts Exam Prep and stops timers/listeners.

## 7. Home next-action priority

Deterministic priority order:
1. active critical session/deadline
2. open Tour close to deadline if learner still eligible
3. required delayed retest/latest-safe task
4. Weekly Plan priority #1
5. Practice needed before upcoming Tour
6. resume last meaningful learning activity

If an item is already the Today action, do not duplicate it in Upcoming.
AI may explain “why this is next” but may not select a different academic priority.

## 8. Acceptance tests

Must pass before production integration:
- No P1 screen can silently open a P5 skill/result and vice versa.
- Every area/skill/question/paper route carries component context.
- P1 coverage denominator always 45; P5 always 36.
- No combined Mathematics mastery/readiness percentage.
- No duplicate Practice/Olympiad Practice destination.
- No duplicate Book/Resources destination.
- Full paper never jumps directly to result.
- Placement never jumps to result after one question.
- Weekly Plan never shows Recovery and Late Joiner simultaneously.
- Protected assessment never exposes correct answer/private explanation pre-finalization.
- Core path remains usable with AI OFF and no mentor assignment.
- Unassigned learner creates zero Mentor Care queue UI/tasks.
- Global active bottom tab remains correct on nested screens.
- Deep-link Back/Close returns to actual entry origin, not a hard-coded parent.
- Language changes are non-destructive.
- Feature OFF leaves legacy app behavior and state untouched.
