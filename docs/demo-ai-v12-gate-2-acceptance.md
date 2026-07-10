# iClub APP — demo AI tariffs v1.2

## Gate 2: Subject Hub, one profile and three plan states

**Acceptance date:** 2026-07-10  
**Branch:** `demo-ai-v12`  
**Production baseline:** `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`  
**Gate 1 checkpoint:** `54be4ef49c6dd071cec084564ec5e5be0d6f7e98`  
**Gate 2 runtime checkpoint:** `06acc50a47b9792226a9a6224884d59d1b7dc133`

## 1. Implemented scope

Gate 2 adds the product shell required to compare Free, Plus and Pro on one synthetic learner and one shared history.

Implemented:

- Economics Subject Hub;
- visible synthetic profile `Сардор Каримов`;
- neutral initials avatar and label `Демонстрационный ученик`;
- persistent Free / Plus / Pro switch without page reload;
- compact `Сценарий` menu;
- plan-aware AI card;
- current seven-question diagnosis entry point;
- closed Tour 4 result `6/20`;
- post-tour Practice 4 result `10/10`;
- plan-aware `Что требует внимания` card;
- shared history with plan-specific tabs;
- Free comparison screen for Plus and Pro;
- Plus tutor interface preview with persistent draft;
- Pro trajectory preview;
- active Tour 5 theory-only preview;
- presentation-tools preview;
- hidden technical panel;
- own `iclub-ai-mark.svg` interface mark;
- RU / UZ / EN copy for the new Gate 2 screens.

## 2. One learner and one history

Free, Plus and Pro use the same static profile and the same history object.

Switching plan does not create a new learner, attempt or answer set. The difference is limited to available actions and depth of interpretation:

- **Free:** attempts, scores, ordinary review and topic summary;
- **Plus:** Free layer plus subject tutor and current-attempt explanation;
- **Pro:** Plus layer plus trajectory and question-level progress context.

## 3. Plan transition mapping

Implemented transitions:

| Current screen | Switch to Free | Switch to Plus | Switch to Pro |
|---|---|---|---|
| Subject Hub | Same Hub | Same Hub | Same Hub |
| Practice before answer | Same attempt | Same attempt | Same attempt |
| Result | Basic result / comparison | Current-attempt AI action | Trajectory action |
| Plus tutor | Locked comparison with draft preserved | Same tutor | Same tutor with Pro context |
| Pro trajectory | Subject Hub | Closest Plus equivalent | Same trajectory |

The current diagnosis state is not reset by plan switching. Language switching preserves the current custom screen, plan and scenario.

## 4. Persistent demo controls

The plan switch remains visible below the main iClub topbar.

The compact `Сценарий` menu contains:

- ordinary learning;
- active Tour 5;
- presentation tools;
- scoped demo reset;
- technical panel.

Reset continues to remove only keys beginning with `iclub_demo_v12.`.

## 5. State contract

Gate 2 extends the existing scoped state without creating a new namespace.

Persisted values include:

- language;
- selected plan;
- selected scenario;
- current Gate 2 screen;
- Plus tutor draft;
- shared attempt history.

A small bootstrap script reads the saved plan before the Gate 1 runtime initializes, preventing the base runtime from dropping Gate 2 fields during reload.

## 6. Safety and isolation

No Supabase client, production endpoint or database migration was added.

The route still declares:

```text
connect-src 'none'
```

The technical panel reports the actual isolated state:

- data source: static;
- production calls: 0;
- storage: local/session only;
- current plan and scenario;
- browser network guard.

The production branch remains unchanged at the original baseline. Repository comparison confirms that `demo-ai-v12` is ahead of `main`, while the merge base and main commit remain `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`.

## 7. Functional checks

Completed:

- JavaScript syntax validation for Gate 2 runtime modules;
- plan selection persists across reload;
- plan change does not reload the page;
- language change does not close a Gate 2 screen;
- Plus draft persists when switching plan;
- Free cannot remain on a Plus-only tutor screen;
- non-Pro users cannot remain on the Pro trajectory screen;
- the same current diagnosis and shared history remain available in every plan;
- active Tour 5 is separated from the closed Tour 4 history;
- Vercel deployment check succeeded for runtime checkpoint `06acc50a47b9792226a9a6224884d59d1b7dc133`.

Final 360 / 390 / 430 px visual hardening is intentionally not claimed here; it remains part of Gate 8. Gate 2 provides the mobile-first structure and responsive safeguards required for later visual QA.

## 8. Rollback

Gate 2 can be rolled back without any database operation by returning the demo branch to the accepted Gate 1 checkpoint:

```text
54be4ef49c6dd071cec084564ec5e5be0d6f7e98
```

## 9. Exit criterion

Gate 2 exit criterion is met:

> The same learner and the same history visibly produce different Free, Plus and Pro experiences, while plan transitions preserve state.

Gate 3 may now add presentation answer controls, strict before-answer AI blocking and dynamic skill evidence driven by the actual seven submitted answers.
