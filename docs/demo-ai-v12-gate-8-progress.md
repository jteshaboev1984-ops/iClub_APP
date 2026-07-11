# iClub APP — Demo AI v1.2 — Gate 8 progress

Date: 2026-07-11
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Stable checkpoint before this fix: `d23dcb222acd0bf59eb5b550a26d28c06cbda796`

## Active Tour 5 routing fix

The previous UI allowed some Active Tour 5 prompts to fall through to the older verified-answer route when the question matched an approved Gate 5 alias.

The send pipeline now enforces this order:

1. When Active Tour 5 is enabled, every non-empty send is routed through the Gate 7 guard.
2. Exact and paraphrased tour tasks are blocked.
3. General theory is sent in `demo_active_tour5` / `theory_only` context.
4. The older verified-answer route can run only outside Active Tour 5.

This applies to both the Send button and Enter-key submission.

## Gate 8 work completed in this checkpoint

- Added dedicated responsive hardening for 360, 390 and 430 px widths.
- Added wrapping protection for long answer, source and warning text.
- Hardened fixed composer width and safe-area behavior.
- Added localized presentation labels that avoid visible `cache` / `fallback` engineering wording.
- Added `Presentation readiness` inside Scenario menu.
- Added checks for:
  - iClub shell and AI mark;
  - mobile container width;
  - RU / UZ / EN core cards;
  - client guard test matrix;
  - absence of Supabase assets;
  - server endpoint and production DB isolation.
- Added an explicit 0–10 presentation-run counter. Runs are counted manually only after a real full presentation pass.

## Remaining Gate 8 acceptance work

- Confirm blocked exact task in deployed UI.
- Confirm blocked paraphrase in deployed UI.
- Confirm allowed general theory in deployed UI.
- Complete 10 real full presentation runs.
- Record the reserve presentation video.
- Freeze the final SHA only after those checks.

## Safety

- Main branch is unchanged.
- Production Supabase is not loaded.
- Demo state stays under `iclub_demo_v12.*`.
- Existing learner progress is not reset by this update.
