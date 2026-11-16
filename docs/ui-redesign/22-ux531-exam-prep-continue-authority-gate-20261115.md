# UX #531 — Home «Продолжить» / Exam Prep P1–P5 authority gate

**Scope:** preparation for a *separate* Draft PR. This document does not activate Exam Prep from Home, does not authorize a paper, does not create a session, and does not change assessment scores or mentoring rules. Current integrated Home Continue is owner-bound paused Practice **only**.

## Source of truth verified in current source
- `exam-prep/exam-prep-api.js` exposes `capabilities()` (calls `get_exam_prep_capabilities_v1`), `diagnosticProgress(component)` (calls `get_exam_prep_diagnostic_progress_safe_v1`) and `activePlanSession(component)` (calls `get_exam_prep_active_plan_session_safe_v1`).
- `exam-prep/exam-prep-weekly-flow-adapter.js` `recover(component)` calls the same server-authoritative active-session RPC; unlike a local cache, its `allowed(component)` checks controlled-beta capability/kill-switch/feature state and exact P1/P5 component.
- `exam-prep/exam-prep-live.js` `primaryAction()`: while `stage0_complete !== true`, unfinished Stage 0 is identified through `progress.active_session` or `screening.answered_items` (these are **different** states); after Stage 0, a unique server-confirmed plan session may be `resume` or `ready_to_finalize`. `multiple_active` is deliberately **not** a normal resume. In legacy mode the host fails closed when `contract_version !== active_plan_session_v1` or `component_code` mismatches.
- `exam-prep/exam-prep-host.js` global `iClubExamPrep.open(context)` independently checks access and binds the correct visible hub; it is the sole allowed entry. The live shell wraps it and chooses its own routes. No caller should directly restore session IDs, timers, or responses.

## Required conditions before displaying an Exam Prep «Продолжить» card
1. A fresh, authenticated user identity (same before/after async reads) and active Mathematics subject. No guessed enrollment based on a local profile.
2. Confirmed mathematical core access, no kill switch or restriction; verify `capabilities` fresh. Not every user/subject has Math P1/P5.
3. Determine P1 and P5 **independently**; never combine marks, goal evidence or active session identities.
4. For Stage 0: accept a *server-proven active diagnostic* only; `answered_items > 0` without a provably active session does **not** authorize a direct resume CTA.
5. For Stage 1+: `activePlanSession` must return `status in {resume,ready_to_finalize}`, `contract_version=active_plan_session_v1`, exact `component_code`, `active_session_count=1`, valid owner-bound session identity. `multiple_active` and invalid/missing contract fail closed.
6. Any failed/revoked/ambiguous RPC -> hide Resume (or show a safe generic entry to Exam Prep) without changing state.
7. On click, repeat auth/subject/capability checks; navigate to Mathematics hub and call the *existing* Exam Prep host. The host decides the actual session, revalidation, and screens. Never start a new attempt by clicking the Home card.
8. Invalidate display on sign-out, account switch, language/content reset, subject switch, capability revoke, or completion. All read-only calls must be bounded and race-safe.
9. Strict display text: `P1 · ...` and `P5 · ...`; no fabricated scores, written self-assessments, mentor requirements, or claim that Tours resume.
10. Production rollout only after isolated PostgreSQL 17 signed JWT/PostgREST checks, cross-account RLS, browser reload / two-tab / offline / server rejection, and confirmation that there are zero draft writes or extra session creation.

## Acceptance matrix
| State | Home CTA | Action |
|---|---|---|
| unauthenticated / logged out / wrong user | none | fail closed |
| access disabled / kill-switch on | none | fail closed |
| P1 Stage 0 active diagnostic, P5 none | P1 only after confirmed active session | existing host controls recovery |
| P5 Stage 0 answered but no active session | no direct Resume | generic Exam Prep entry only |
| P1 active plan session `resume` count=1 | P1 Resume eligible | existing host handles |
| P5 `ready_to_finalize` count=1 | P5 eligible with truthful wording | existing host handles |
| `multiple_active`, count>1, invalid component/contract | no Resume | no new attempts |
| RPC stale response after user switch | none | discard old result |
| completed / no active session | none | no fabricated progress |
| P1 and P5 both independently active | two separate entries | never merge academic state |

**Implementation gate:** This matrix is source-grounded, but not evidence that all server-returned shapes have been tested. First prove the exact JSON contracts through signed JWT/PostgREST in isolated PostgreSQL and browser fixtures. Then a separate Draft PR may add read-only aggregation. Keep merged/production off until explicit release approval.
