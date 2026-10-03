# Exam Prep P3-02 Held-Ready Closure Evidence

Date: 2026-10-03  
Scope: Cambridge AS Mathematics P1 + P5  
State: technically held-ready; real learner AI activation remains OFF and requires a separate explicit decision.

## Closure result

P3-02 engineering work packages A–J are complete for the held-ready state.

This closure does **not** enable AI or Mentor Care for real learners, does **not** perform mass Core rollout, and does **not** alter the real beta evidence gate.

## Production state after P3-02

Repository production merge:
- main SHA: `877c087c1aa9b1f08944eac3304b6a97b9950f76`
- merge: PR #282 — capability-aware AI learner UX and fail-soft transitions

Vercel:
- production deployment: `dpl_GTKuS9A4RxqdzcBXebfDH3FCc2BV`
- state: READY
- deployed SHA: `877c087c1aa9b1f08944eac3304b6a97b9950f76`

Supabase:
- `exam-prep-ai` Edge Function version 7
- status: ACTIVE
- JWT verification: enabled
- approved runtime AI source cards: 267
- approved theory cards: 243
- P1 theory cards: 135
- P5 theory cards: 108

Feature state remains:
- rollout_state = controlled_beta
- Core = ON
- AI = OFF
- Mentor Care = OFF
- kill switch = OFF
- AI runtime = shadow
- provider generation = OFF

## Production preservation

Post-deployment invariant counts:
- public.users = 1442
- practice_answers = 8770
- tour_answers = 6267
- certificates = 157

No localStorage reset was introduced.
No Practice/Tour/certificate/history rewrite was introduced.
P1 and P5 remain academically independent.

## AI quality and safety acceptance

The governed theory layer covers all 81 internal canonical iClub skills:
- P1: 45
- P5: 36
- RU / UZ / EN coverage

The 81 count is an internal iClub decomposition, not an official Cambridge skill count.

The final funded provider quality acceptance passed:
- 49 / 49 cases GREEN
- critical failures = 0
- provider calls = 49
- estimated actual cost = $0.006553
- P1 GREEN
- P5 GREEN
- RU / UZ / EN GREEN
- theory explanation GREEN
- repeated-error explanation GREEN
- multilingual explanation GREEN

Learner-facing provider output is constrained to approved deterministic context and approved source cards. Raw LaTeX markup is rejected from learner-facing provider output. AI cannot change academic state.

## Learner UX and service transitions

PR #282 final candidate completed 27 / 27 workflows GREEN.

The browser transition regression proves:
- Core-only -> AI available -> Core-only -> AI available
- AI kill switch ON/OFF without Core loss
- provider unavailable fallback
- no_source fallback
- provider timeout fallback
- late provider response stays hidden after AI capability removal
- payloads claiming academic-state change are not rendered
- no AI action is exposed during an active assessment
- live RU / UZ / EN learner copy
- 360 / 390 / 430 mobile widths plus desktop
- transitions themselves do not create provider calls
- Core learner actions remain present through AI failures

Existing P2-75, P2-77, P2-78 and P2-73 gates continue to prove academic-state parity, Mentor Care assignment isolation, 600/10 service isolation and Core independence.

## Synthetic cleanup

Production synthetic residue:
- active synthetic identities = 0
- synthetic identity rows = 0
- synthetic validation run rows = 0
- dirty completed/failed/aborted synthetic runs = 0
- auth users matching synthetic `@invalid.example` fixtures = 0

Synthetic CI evidence is never counted as real beta evidence.

## Real beta gate

The production P3-01 gate remains correctly closed:

- decision = NO_GO
- reason_code = active_weeks_1_4_incomplete
- automatic_rollout_permitted = false

No real weekly-review evidence was fabricated, inserted or backfilled. No threshold was weakened.

## Separate Biology staging decision

The old Biology Season 2 staging table was reviewed separately and was **not deleted**.

Current safe facts:
- table retains 21 rows
- RLS is enabled
- anon SELECT = false
- authenticated SELECT = false
- no database view references it
- no database function references it
- no trigger references it
- dependency entries found are structural table/index/constraint/default dependencies
- repository search found no live application reference

The safe decision is to preserve these rows rather than perform destructive cleanup without provenance. This is outside the Mathematics P3-02 release state.

Old one-off/temp Biology loader Edge Functions also have no repository references and showed no calls in the reviewed 24-hour log window. They are left unchanged in this closure to avoid breaking an unrelated legacy content-loading path without a separate governed security change.

## Held-ready rule

P3-02 is technically held-ready, but real learner activation remains an independent future decision.

Until that decision:
- AI remains OFF for real learners
- generation remains OFF
- Mentor Care remains independently OFF/capacity-gated
- Core continues under controlled beta
- P3-01 remains governed only by real weekly evidence
