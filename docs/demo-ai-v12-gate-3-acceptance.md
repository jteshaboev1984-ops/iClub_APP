# iClub APP — Demo AI v1.2 — Gate 3 acceptance

Date: 2026-07-10
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Rollback checkpoint before Gate 3: `fb592313ea550d657120d92bcff4cf6894478c26`

## Scope completed

- The diagnostic route uses seven fixed Economics MCQ items.
- Difficulty distribution is exactly 2 easy / 3 medium / 2 hard.
- The item sequence follows the approved Gate 3 demonstration scenario:
  1. utility meaning;
  2. diminishing marginal utility;
  3. indifference-curve definition;
  4. budget-line change after an income rise;
  5. allocative efficiency;
  6. productive efficiency;
  7. internal versus external growth.
- A collapsible presentation-only control is available on each question.
- `Demo answer` selects the approved scenario option but never submits it.
- The selected option remains editable before the learner presses the normal answer button.
- `Fill remaining` is available only from the demo scenario menu. It selects future approved options but does not submit them.
- The ordinary local checking path still calculates the score.
- AI help is visibly locked before the answer for Free, Plus and Pro.
- Each submitted or timed-out answer is written only to `iclub_demo_v12.cache` as a local answer event.
- Pro evidence is computed from the actual selected answers, not from the approved presentation scenario.
- Free shows the ordinary result layer.
- Plus summarizes only the current seven-question attempt.
- Pro shows question-level skill evidence and a dynamic conclusion.

## Dynamic acceptance case

Approved presentation answer for question 5 is `B` (`TR = TC`). The Pro conclusion identifies confusion between break-even and allocative efficiency.

When question 5 is manually changed to `A` (`P = MC`) before submission, the Pro conclusion changes to a positive signal for allocative efficiency. The score and evidence are recalculated through the same answer-checking path.

## Safety

- Production Supabase is not loaded.
- Production user, attempt and answer calls: 0.
- Content Security Policy keeps `connect-src 'none'`.
- Demo writes only to keys beginning with `iclub_demo_v12.`.
- Reset deletes only that namespace.
- `main` is unchanged.

## Checks run

- JavaScript syntax check passed for the Gate 3 data and controller.
- Static data check passed: 7 questions, 2 easy, 3 medium, 2 hard.
- Deterministic evidence test passed for both question-5 paths: scenario answer `B` and manual answer `A`.
- Visual acceptance remains a preview-deployment check on the direct demo URL.
