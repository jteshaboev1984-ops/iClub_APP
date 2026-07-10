# iClub APP — Demo AI v1.2 — Gate 5 acceptance

Date: 2026-07-10
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Rollback checkpoint before Gate 5: `aff2496defdd8760c6c8d7e97c88ea0f9e740038`

## Scope completed

- Added 30 expert-written Economics knowledge cards.
- Every card contains RU / UZ / EN versions of:
  - short answer;
  - simple explanation;
  - example;
  - micro-check;
  - micro-check answer;
  - iClub source label.
- Added manually approved aliases in RU / UZ / EN.
- Added a plan-aware AI card inside the copied Subject Hub:
  - Free opens the Plus / Pro comparison;
  - Plus opens the Economics tutor;
  - Pro opens the same tutor with a Progress entry point.
- Added a persistent local tutor chat and draft in `iclub_demo_v12.chat`.
- Added actual conversation history generated from the local chat. No decorative fake dialogue is inserted.
- Added `Fill question`; it inserts the approved question but never sends it automatically.
- Added verified answer actions:
  - explain more simply;
  - show an example;
  - check understanding;
  - reinforce in practice.
- Added contextual AI review from:
  - the current attempt result;
  - a submitted question in question review.
- Added a no-source response when no approved alias matches.
- Added Plus chat tabs and Pro Chat / Progress tabs.
- Added a safe renderer based on DOM nodes and `textContent` for user questions and answer content.
- Added technical fields for verified / no-source mode, model call, source IDs, latency, quota and renderer.

## Verified route acceptance

Approved question:

`Чем allocative efficiency отличается от productive efficiency?`

Expected behavior:

- the question is inserted by the demo autofill button but not sent;
- after manual send, the card `allocative_vs_productive` is returned;
- the answer is marked `Проверенный ответ iClub`;
- source is shown as an iClub Economics card;
- `model_call=false`;
- quota is not charged;
- no network request is required.

## Plan boundaries

- Free cannot open the tutor and sees a clear Plus / Pro comparison.
- Plus explains the current question and current attempt but does not calculate a long-term trajectory.
- Pro uses the same chat history and can open the deterministic Progress trajectory from Gate 4.
- Switching plans does not create a second learner or a second attempt history.

## Safety

- Production Supabase is not loaded.
- Production user, attempt and answer requests remain 0.
- CSP remains `connect-src 'none'` for Gate 5.
- Chat, draft and technical state stay under `iclub_demo_v12.*`.
- Reset remains limited to that namespace.
- Verified answers do not call an external model and do not spend tokens.
- User text and answer text are not inserted through unsafe `innerHTML`.
- `main` remains unchanged.

## Files

- `diagnostic-demo-gate5-cards-a.js`
- `diagnostic-demo-gate5-cards-b.js`
- `diagnostic-demo-gate5-ui-v2.js`
- `diagnostic-demo-gate5.css`
- `diagnostic-demo.html`

## Checks completed

- Knowledge-card count: 30.
- Languages per card: RU / UZ / EN.
- Approved autofill question resolves to a verified card.
- Unknown question resolves to `no_source` without a model call.
- Chat draft and message history use `iclub_demo_v12.chat`.
- Superseded Gate 5 controller was removed and is not loaded.
- Vercel preview deployment succeeded.
