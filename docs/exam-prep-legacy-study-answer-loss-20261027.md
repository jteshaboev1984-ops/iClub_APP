# Core Exam Prep — preserve legacy study answers on uncertain network acknowledgment (27 October 2026)

Owner intent: **improve active Core without spending effort resuming old synthetic sessions**. Do not delete, auto-close, or fabricate work in those old sessions. Keep QA-wide Core/Weekly access in place. P1/P5 written-paper mode and RU/UZ translation review are independent, unchanged.

## Confirmed code defect and minimal scope
Before this fix, the native `exam-prep-live.js::submitAnswer` used the protected pending-answer read-before-retry route **only when** `iClubExamPrepWeeklyFlowEnabled === true`. For an otherwise valid legacy plan/component study session, it immediately called `renderLoading()` before awaiting `submitResponse`. A lost acknowledgment or failed RPC destroyed the text field or MCQ selection even if the response had committed. Learners could not safely tell whether to retry.

We now reuse the already-reviewed guarded route for both legacy and opt-in weekly study sessions with `session_type` `learning`, `mixed`, or `retest` originating from plan/component. It keeps the exact submitted payload/idempotency key in memory, never automatically resends an uncertain write, reads the authoritative session for reconciliation, and permits only explicit same-key retry if the original item remains unanswered. Original diagnostic, timed and full-paper submission paths are untouched. The server remains the sole authority for correctness, completion, credit, mastery, and due retest.

### Required checks
- **Real-DOM isolated browser:** RU/UZ/EN × 390/1280px × MCQ/written × lost ACK before/after commit × guarded/legacy (=48), plus hung written RPC at 390px × three languages × guarded/legacy (=6).
- The original text input and selected radio survive uncertain outcomes, not replaced by a red error screen; saved results commit exactly once and any explicit resend reuses original payload/key; legacy post-finalization plan-generator behavior is preserved, not invoked by the guarded path.
- Existing Core weekly flow, old-data firewall, P1/P5 separated state, Exam Prep paper-written OFF, and Practice/Tours/Economics remain untouched.
- GitHub source SHA pinned CI is updated to the exact reviewed `exam-prep-live.js` Git blob; cache-bust both API loader and entry HTML. No Supabase migrations/SQL writes, no localStorage mutations, no entitlement/access changes.

### Release caveat
Unrelated existing global Practice/AI gate failures include stale asserted asset cache strings and module order; this PR does not waive them, hide them, or misreport them green. Check Core critical workflows separately, and refrain from deploying if these changes introduce any new failing Core checks.
