# Exam Prep option-position integrity: confidential release gate (21 Sep 2026)

**Do not publish answer-letter frequencies, per-question keys, vulnerable bank identifiers or possible guessing strategies in this public repository.** The detailed read-only statistical evidence is held in a private owner-only review packet, not here.

During broad P5 localization QA, an independent read-only inspection of published P1/P5 MCQ authoring and delivery revealed a systematic imbalance in stored answer positions. Current `get_exam_prep_session_safe_v1` returns the stored option array; the current native UI renders it in stored order, and `exam_prep_eval_session_question_v1` maps the picked index directly to its original A/B/C/D letter. There is no verified equivalent per-session option permutation in that path.

This is a **separate assessment-validity release concern**, not evidence that students exploited it and not a reason to delete existing users or silently change current questions. Do not publish the detailed statistics in a public issue or PR comment.

Remediation decisions require: per-session stable choice identity; exactly aligned EN/RU/UZ display permutations; server-side evaluation using the original correct option after mapping; diagnostic distractor mapping, protected retest/diagnostic confidentiality; idempotent recovery and multi-device consistency; previous finalized and active attempts unchanged; offline replay consistency; rollback and real beta acceptance. Alternatively, create reviewed immutable question/assessment versions with deliberately varied correct-choice positions, but never permute a history-bearing question in place. Neither remedy is authorized or implemented in this PR.

**Gate:** independent academic/security design and owner decision before claiming full P1/P5 assessment validity. PR #138 remains localization-detector-only, not this security remediation.
