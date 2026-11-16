# UX #531 / Math #450 — Mathematics Exam Prep Academy OS v5.8 learner-flow lock

**Decision:** Architect approved focused learner-screen reorganization on 2026-11-16; implementation in sole Academy OS Draft PR #540. **NO production release, DB change, auth/feature flag change or beta data reset authorized by this document.**

## Product shape — one learner route, no parallel Exam Prep

**Entry:** Subjects → Mathematics → Preparation → existing guarded Exam Prep host. No new iClub bottom tab, extra subject permission, feature flag, AI/Mentor requirement or independent Paper score.

**Screen A: Exam Prep landing**
1. Profile exists: title/real saved series, **P1 and P5 learning cards FIRST**. Never combine P1's 45 skills with P5's 36. While Stage0 unfinished, show actual diagnostic counts, not a fake mastery percentage. Cards ALWAYS open their component overview, **never start or consume an assessment**.
2. Under cards: compact **My plan** summary (series/goal, Math weekly time, own P1/P5 dates or honest "Not entered"), one clear Manage action. No permanent schedule/date/week input grids or Paper promo above components.
3. First-time no profile: preserve existing exam plan form and validation before these cards, no fabricated defaults.

**Screen B: My plan** (shared planning capacity for P1/P5)
- Saved exam profile, explicit edit with pre-filled values; schedule, date confirmations, voluntary S3 weekly choice/reports in labelled native disclosures, closed by default. Edit saves reuse existing server API, preserve all completed evidence, restore Plan context. No new weekly minimum, study quota or obligation to enter exam date.
- Three existing voluntary choices remain Keep / Redistribute / Change; no synthetic minutes or unapproved academic norms.

**Screen C: each P1 and P5 component** — uniform three tabs
- **Learning**: server-authoritative Next action (explicit Start/Continue; unique active session only), verified syllabus coverage, real topics and skill detail, correction/retest workflow, materials, readiness when stage allows. Never infer completed written method marks or next step from client-only history.
- **Practice**: original stage-gated timed assessments; independent voluntary S4 full handwritten Paper; independent Extra Hard original tasks. S4 can be opened at Stage0 if current signed Core catalog grants it. No Paper completion gate to study or Cambridge grade claim.
- **History**: retain #544 unified owner-only Paper sessions separate from earlier Core learning/diagnostic results and graded objective marks. Paper rows say actual closure and `written not assessed`; no fake 0/75/0/50 or verified method credits. Reopen existing session/revealed review without creating a new attempt.
- Tabs change view only. P1/P5 history, stages, learning work and rights never merge.

**Screen D: focused task/review** retains existing real server timer, incomplete/recovery/error behaviour, optional approved final-answer check before reveal, notebook solutions, source-approved hints and criteria. Written method and final Paper score remain **unknown** unless legitimately evaluated. History→review→Back returns to SAME component History, catalog→Paper→review→Back returns to catalog. Paper catalog offers new Paper keys and **resume only unfinished** existing sessions; finished sessions are in History, not duplicated under misleading empty "History."

## Academy OS v5.8 styling / safety

- Use accepted sapphire blue/white tokens, text-first cards, consistent margins and type, 3 equally sized accessible tabs, touch targets >=44px, no horizontal overflow at 320/375/390/430 and desktop 1440, RU/UZ/EN labels, no internal engineering vocabulary on learner screens.
- Narrow styling scoped to `#exam-prep-host-root` under Academy OS B07. **Do not modify** Economics P1/P3, Chemistry or Home/Subject Hub navigation contracts.
- Preserve `main` source fix #544 (Paper history), #533 (server-signed S4 availability), #529 (weekly time and idempotent S3), #537/#541/#543 (rights and migration receipt), #542 (unfinished Stage0 coexistence), 42 protected Extra Hard V4.3 tasks, all old history.
- Existing PR #540 branch initially missed the merged #544 client UI; it was synchronized **byte-identically** to current main blob `9f27a28ed19f804e0a5d8abfd75eb2756487c3ec` BEFORE this UX package. Do not replace it with stale PR #540 origin or old archived #492/#519/#520/#523.
- Current PR #540 base is historic; **reconcile exact latest main before merging**, preserving all concurrent changes. Work in one candidate branch; no indiscriminate rebase or bulk old PR integration.

## Acceptance before any release

1. Source syntax and diff-boundary audit; all new RU/UZ/EN text and style checks.
2. Isolated browser 320/375/390/430/1440: first profile form, saved plan landing, My plan edit/disclosures, P1/P5 overview no auto-start, tabs and correct empty/error/status, back navigation.
3. Disposable PG17 signed JWT/PostgREST + Chromium S4 ON/OFF: open P1/P5, start voluntary Paper, early finish, reveal, history reopen same owner session, return from review to originating screen, preserve legacy Core history and separate score semantics.
4. Existing Stage0 diagnostic recovery, weekly plan, timed/written answer ACK, extra hard, P0 security, no unintended other-subject/UI regressions. Report broad CI unrelated infra/mock failures separately; do not call overall CI green unless proven exact-head.
5. Real user/Work authenticated visual acceptance ONLY after safe staging proof. If a Vercel Preview uses production Supabase, NEVER simulate signup/test attempts there. Before main/production merge obtain separate Architect release approval.
6. No mass rollout, QA shutdown, Stage gates, individual entitlement or production user data change as part of this navigation work.

**Issue ownership:** #531 owns Academy OS visual integration and release; #450 owns Math academic/signed Paper outcomes. #526 broader API and P0-16B security separate.