# iClub APP — Demo AI v1.2 — Gate 7 acceptance

Date: 2026-07-11
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Endpoint: `/api/diagnostic-ai`
Stable checkpoint before Gate 7: `8223098ca7b755a775f367888fb9f294d027a537`

## Chat reading behavior fixed

The tutor now brings the newest answer into the readable viewport automatically.

- The first line of the new answer is positioned below the fixed top area.
- The fixed composer and mobile safe area are included in the calculation.
- The behavior applies to verified, generated, cached, fallback, theory-only and blocked responses.
- The user can continue scrolling normally after the automatic focus.
- A child-list-only observer is used; text and class changes do not retrigger it.

## Active Tour 5 dataset

A separate synthetic Economics Tour 5 dataset was added for guard testing.

- Five active-tour questions cover labour-market policy, market-failure policy and redistribution.
- RU, UZ and EN stems are included.
- Client payload contains stems, options and guard fingerprints only.
- No correct answer or answer key is present in the client dataset.
- The dataset is isolated from historical closed Tour 4 and the current diagnostic practice.

## Client UX guard

The Scenario menu now includes `Active Tour 5`.

When active:

- the Subject Hub AI card is marked `Theory only`;
- the tutor displays a permanent protection notice;
- presentation controls can fill a tour task, a paraphrase or a general-theory question;
- exact tasks, paraphrases, preserved-number variants, answer confirmation, option elimination and prompt-injection attempts are blocked before a model request;
- general theory remains available;
- blocked responses do not expose the task answer or option logic;
- the guard decision is written to the hidden technical state.

## Server final guard

The server endpoint independently runs the active-tour guard before retrieval, cache or model invocation.

It checks:

- exact and normalized stems in RU, UZ and EN;
- distinctive numeric fingerprints;
- topic terms and option patterns;
- paraphrased task wording;
- requests to confirm an answer or check reasoning;
- requests to remove options or provide a letter;
- prompt-injection attempts that claim the tour has ended.

A blocked request returns:

- `mode=blocked`;
- `guard_decision=blocked_active_tour`;
- no answer content;
- `model_called=false`;
- `charged=false`.

General theory in the active-tour context returns `mode=theory_only` from a neutral verified iClub card, without a model call or quota charge.

The same server guard is applied even when a caller tries to use a normal subject-chat context, so a direct endpoint call cannot bypass protection by changing a client flag.

## Test coverage

Automated guard cases were added for:

- exact RU / UZ / EN stems;
- stem without options;
- paraphrase;
- replacement of wording while retaining distinctive numbers;
- “do not tell me the answer, only confirm my reasoning”;
- option elimination;
- prompt injection;
- allowed general theory;
- direct endpoint-context bypass attempt.

The browser also records a compact client test matrix in `iclub_demo_v12.technical`.

## Safety and isolation

- `main` remains unchanged.
- Production Supabase is not imported.
- Production users, attempts and answers are not read or written.
- Tour 5 answer keys are absent from browser payloads.
- All demo state stays under `iclub_demo_v12.*`.
- User text and AI output continue to use safe DOM rendering.

## Files

- `api/_active-tour-guard.js`
- `api/diagnostic-ai.js`
- `diagnostic-demo-gate7-data.js`
- `diagnostic-demo-gate7.js`
- `diagnostic-demo-gate7.css`
- `diagnostic-demo-chat-focus.js`
- `diagnostic-demo-gate6.js`
- `tests/demo-ai-gate7-guard.test.js`

## Deployment

Vercel preview deployment succeeded for commit:

`5472d38aa4c0b02fd20c44d4402e1e897a5165ef`

Gate 8 starts only after the presenter confirms the automatic answer focus and the active-tour blocked / theory-only routes in the deployed UI.
