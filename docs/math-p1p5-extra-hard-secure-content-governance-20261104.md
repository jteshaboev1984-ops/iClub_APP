# Mathematics P1/P5 Extra Hard — secure draft architecture

**RELEASE OFF. Public GitHub is not a vault.** Never commit future protected question prompts, worked solutions, answer keys or bank dumps into JSON, migrations, browser assets, Action logs/artifacts or static hosting.

**Architect decision, 2026-11-04:** RETAIN the original 12 authored P1/P5 examples (6 P1 and 6 P5) and their existing RU/UZ/EN conditions, answers and solutions. Do not replace, regenerate, or renumber them for administrative reasons. Their earlier source file was removed when the public draft branch was rebuilt, and its exact content has not yet been recovered into the current working tree. A public Git history may still contain those texts; this does not prove anyone actually read them, but we must not falsely guarantee their secrecy. Retrieve the exact original payload before any import. This does not authorize changing or inventing answer keys.

## Implemented
- New private tables for task versions, owner-scoped attempts and Math-only release switch, initially disabled with EMPTY protected bank.
- Source SHA-256 and math/translation/technical QA plus published immutable version are required to activate any future task.
- Four authenticated Math-Core-gated RPCs: list, start, submit, resume. Answer key returns only to the owner AFTER durable submission; before that only prompt and optional saved response. All written correctness stays unknown; no score/mastery/diagnostic/Paper mutation.
- Optional trilingual learner view and P1/P5 link. When disabled, it shows a preparation message; normal learning and weekly budgets are untouched.

## Before launch
1. Recover and preserve the SAME original 12 P1/P5 tasks without rewriting them; verify their 8+5 syllabus-area mapping and relevant Pure Mathematics 1 / Probability & Statistics 1 textbook references. No duplicate replacement bank.
2. Perform one full mathematics, translation, technical, intellectual-property and difficulty acceptance; record source version, approvals and SHA without exposing private answers.
3. Stage those 12 existing question texts and answer keys using a restricted admin/database import, never an unreviewed public runtime migration; update only approved private task rows and the separately approved bank release control.
4. Verify real student ownership and answer secrecy until submission, repeat/lost-ACK, ungraded outcome, no cross-user access, and no cross-credit.
5. Update precise Math beta-state cleanup/FK/backup manifest for new attempts before any public release; separate architect GO is mandatory.

**Status: DRAFT, protected content EMPTY, Math Exam Prep public NO_GO.**
