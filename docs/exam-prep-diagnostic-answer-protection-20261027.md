# Exam Prep Core — diagnostic answers and lost acknowledgement, 2026-10-27

**Observed risk:** Native Stage 0 diagnostic previously cleared its on-screen inputs on `submitResponse` before the response was acknowledged. A lost or hung network response led to an error screen and ambiguous saved status. The same safe in-memory read-before-retry path recently hardened for Core study is suitable for diagnostic because it already reads authenticated `getSession`, only reuses the original exact payload and idempotency key, never issues an automatic second write, and finalizes normally if the server confirms a saved item.

**Patch:** Extend the existing answer-recovery branch in `exam-prep-live.js` to `session_type === 'diagnostic'`, regardless of dashboard/component return destination. Keep the learning/mixed/retest Core branch unchanged and `timed`/`paper` paths excluded (timer semantics require separate design and QA). No schema, review, score, stage, grading, old session, user access, beta enrollment, AI, Mentor, Economics, Practice, Tours or translations altered.

**Isolated test:** Real native UI, synthetic RPCs, browser network blocked: launch Stage 0 from P1 component card; MCQ and written inputs; server commit followed by lost acknowledgement vs loss before commit, plus hung written call; RU/UZ/EN on mobile and desktop; verify draft kept, no automatic resend, read-only confirmation, explicit same-key/same-payload retry, diagnostic finalization without generating a weekly plan.

**Release:** Separate PR, CI smoke and baseline red-gate comparison. Real authenticated production journey still requires human-governed beta QA. Maintain temporary QA-wide Core/Weekly access per owner decision.
