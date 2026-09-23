# P5 broad MCQ QA dependency — security-sensitive summary

A September 21 read-only assessment-bank inspection identified a broader correct-choice-position imbalance in P1 and P5. Detailed distribution and vulnerable assessment identifiers are deliberately excluded from this public repo. The private owner-only audit preserves exact counts, scopes and inspected implementation paths.

The fix is not simply translating the 17 localized candidates or rotating the labels on the screen: stored correct_answer, diagnostic distractor mapping, server scoring, three locales, offline replay, frozen attempts and recovery must agree on a single immutable per-session mapping. Do not reshuffle already-started sessions or rewrite answer evidence. If content versions are rebuilt, they require independent academic QA and a versioned assessment release. If per-session permutation is used, it requires audited backend selection and evaluation, deterministic resume, and protected-answer no-leak tests.

This dependency must be scoped and approved as a separate product/security task. PR #138 does not implement the solution. Do not claim P5 assessment-validity completion from localization-only tests.
