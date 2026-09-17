# Exam Prep Progress UX v1 — final visual handoff for Stitch

Status: DESIGN HANDOFF ONLY. Approved functional product contract: `docs/exam-prep-progress-ux-v1-contract.md`. This handoff does not authorize any production SQL, deployment, feature enablement or alterations to the academic engine.

## Source of truth
Use actual iClub Mathematics → Exam Prep screenshots from the current app/feature branch as style reference. Preserve existing header, back navigation, single saved exam plan and its Edit action, typography, color system and screen stack. Do not redesign Practice, Tours, ratings, certificates or other subjects. New Progress UX is additive and controlled by a default-OFF flag.

## Four mobile-first views
1. **Overview:** one coherent P1 card and one P5 card, clearly separated, no repeated plans or cards. Within each card show the academically determined stage (if returned), confirmed syllabus coverage, a confirmed-coverage skill count labelled as coverage rather than mastery, total *finalized* study sessions, open corrections, and one next available action. The active week out of 36 is a planning reference, not stage promotion or readiness.
2. **Weekly plan:** a single heading; stable original goals (one to three per component), e.g. `1 из 3`, with each goal's title and human status. Distinguish goal completion from a current action that may change on replanning. Up to three actionable items may be fewer than original goals: retain all original goals. Explain displaced work and keep the next action unmistakable. If there are zero actionable rows, show preserved goal history and a neutral unavailable-step message; never create a dead Start button.
3. **Session complete:** enhance the existing completion screen rather than replacing its verified saved-answer count or navigation. Show authoritative before/after counts only when same active week and verified server states are comparable; label potential multi-device changes. Preserve current result, open correction and the one next action. An answered item is *not* an automatically correct or mentor-verified answer.
4. **Waiting for delayed check:** clearly distinguish `weekly work complete` from `correction still open`; use server-provided retest date or `Дата уточняется` and no premature active retest button. Keep the next eligible action accessible.

## Layout and copy constraints
- Mobile target 390px, stress-test 320px; desktop 1440px. No horizontal overflow, clipped Uzbek text, doubled progress panels, uneven card edges, or competing primary buttons.
- RU, UZ (Latin), EN. Exact academic skill descriptions are source material: do not invent or paraphrase a skill translation. When a translation is unavailable, use a correctly localized syllabus *area* label rather than a fake detail. Keep dates readable in all three languages.
- No combined P1+P5 readiness percentage, invented mastery, fake student stats, gamified badges, progress loss messaging or technical implementation terminology (`ledger`, `evidence`, `L1`, `state machine`, `лестница`).
- No dependencies on AI or mentors. Display states must work with AI OFF and Mentor OFF.
- Work with illustrative learner values in design only; label mockups as examples. Never suggest displayed mock values are actual learner records.

## Verified source-title decision, 2026-09-17
- Read-only canonical registry matches **eight P1 sections / 45 skills** and **five P5 sections / 36 skills**. All 13 exact official section keys have corresponding localized area labels in the feature UI. P1 and P5 must not share a denominator.
- For Russian, the existing authorized academic tracker returns `canonical_description` and the UI displays it without silently rewriting the learner's skill. Several canonical Russian descriptions contain mixed English mathematics terminology; a fully rewritten per-skill RU/UZ/EN catalogue needs an explicit content-governance review. Do not treat Stitch's attractive English placeholder as the true academic title.
- For Uzbek and English the approved fallback is the actual section/topic label; it is **not a per-skill translation**. When the tracker response is missing, show a generic localized action label. Do not invent a topic, exact skill, mastery or score.
- Keep goal titles distinct from their server-authenticated states and the existing current task card. A waiting-correction goal can be complete as assigned work while the correction stays open; do not claim the entire week is finished unless the server confirms all goals.

## Acceptance and rollout separation
Deliver four consistent annotated mobile views plus overview/plan desktop adaptations and explicit spacing/typography/button states. First verify design against current implementation, then make any CSS/markup changes only inside the isolated Progress UX feature branch with the flag OFF by default. Functional CI, SQL rollback evidence and a separate release authorization remain required before production use.
