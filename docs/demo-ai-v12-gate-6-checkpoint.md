# iClub APP — Demo AI v1.2 — Gate 6 implementation checkpoint

Date: 2026-07-10
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Endpoint: `/api/diagnostic-ai`
Rollback checkpoint before Gate 6: `31be0c8244313458fe4c08894a0d34c33f461679`

## Typography and mobile readability

Before starting Gate 6, the AI and trajectory screens received a dedicated mobile typography pass:

- primary reading text increased to 15 px;
- secondary text increased to 13 px;
- captions increased to 12 px;
- chat input increased to 16 px;
- reading line height increased to approximately 1.5;
- principal buttons and actions increased to at least 44 px high;
- quick prompts increased to 48 px high;
- badges, source labels, skill rows and plan rows enlarged;
- a reduced but still readable scale is applied below 370 px.

The changes are isolated in `diagnostic-demo-typography.css` and do not modify production styles.

## Gate 6 implementation

### Endpoint contract

`POST /api/diagnostic-ai`

Accepted fields:

- `session_token`;
- `question`;
- `language` (`ru`, `uz`, `en`);
- `context_type`;
- allowlisted `context_id`.

The endpoint does not accept client-supplied source text, correct answers, plan decisions or guard results as trusted values.

### Implemented protections

- signed short-lived demo session token;
- same-origin and JSON-only requests;
- maximum question length;
- URL and file-request rejection;
- allowlisted contexts;
- maximum one active model request per session;
- per-IP request throttling;
- signed per-session generation allowance;
- daily process budget guard;
- timeout and bounded output;
- no file upload, URL fetch, browsing or external tools;
- server-selected knowledge cards;
- strict structured JSON output;
- source reference validation;
- `store: false` on the provider request;
- no production database access.

### Response modes

The client and endpoint support:

- `generated` — a model answer grounded only in selected cards;
- `cached` — repeated question served without a second model call;
- `fallback` — clearly labelled saved verified answer;
- `no_source` — insufficient verified context;
- existing Gate 5 `verified` route — exact approved answer without a model call.

### Demo controls

Inside the Plus / Pro tutor, presentation-only controls were added:

- `Live AI example`;
- `Repeat for cache`;
- `Fallback answer`.

Each control only fills the composer. The presenter must press Send manually.

### Cache

- client session cache uses `iclub_demo_v12.cache`;
- server cache key excludes the plan;
- repeated generated question returns `cached`;
- cached response reports `model_called=false` and `charged=false`.

### Fallback

Fallback is never presented as a generated answer. The UI labels it as a saved verified answer, and the technical panel records `mode=fallback`.

### Technical panel

The panel records:

- answer mode;
- model call yes/no;
- source IDs and version;
- latency;
- quota charged and remaining;
- cache hit;
- endpoint;
- guard decision;
- safe renderer.

## Provider configuration status

The endpoint is designed to work in two safe states:

1. With `OPENAI_API_KEY` and `DEMO_AI_GENERATED_ENABLED=true`, the live route can return `generated`.
2. Without the key, with the flag disabled, on timeout, or on provider error, the route returns an honest `fallback` and the verified Gate 5 route remains fully operational.

The repository connector cannot read or change Vercel environment variables. Final acceptance of the `generated` case therefore requires checking the deployed endpoint health and one live response in the Vercel environment.

## Known infrastructure boundary

The signed per-session quota is enforced by the endpoint. IP and daily counters are currently process-memory guards suitable for the isolated preview demonstration. A multi-instance production deployment would require a durable counter store before this could be described as a globally hard daily limit.

## Safety

- `main` remains unchanged;
- production Supabase is not imported;
- production user, attempt and answer calls remain 0;
- generated chat state stays under `iclub_demo_v12.*`;
- client output is rendered through DOM nodes and `textContent`;
- reset remains limited to the demo namespace.

## Files

- `diagnostic-demo-typography.css`
- `api/diagnostic-ai.js`
- `diagnostic-demo-gate6.js`
- `diagnostic-demo-gate6.css`
- `diagnostic-demo.html`

## Deployment

Vercel build passed for commit:

`2449af1eca54a404319e740f4c58b8e74c7f9402`

Gate 7 must not start until the deployed `generated`, `cached` and `fallback` cases have been observed and recorded.
