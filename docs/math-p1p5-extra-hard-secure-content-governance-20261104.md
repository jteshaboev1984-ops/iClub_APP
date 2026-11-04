# Mathematics P1/P5 Extra Hard — secure draft architecture

**RELEASE OFF. Public GitHub is not a vault.** Never commit future protected question prompts, worked solutions, answer keys or bank dumps into JSON, migrations, browser assets, Action logs/artifacts or static hosting.

The 12 exploratory 2026-11-04 example problems were visible in a public unmerged draft branch. **Those exact examples, IDs and solutions are retired from protected use** regardless of Git branch cleanup. Future protected content must be newly authored and reviewed through a private channel.

## Implemented
- New private tables for task versions, owner-scoped attempts and Math-only release switch, initially disabled with EMPTY protected bank.
- Source SHA-256 and math/translation/technical QA plus published immutable version are required to activate any future task.
- Four authenticated Math-Core-gated RPCs: list, start, submit, resume. Answer key returns only to the owner AFTER durable submission; before that only prompt and optional saved response. All written correctness stays unknown; no score/mastery/diagnostic/Paper mutation.
- Optional trilingual learner view and P1/P5 link. When disabled, it shows a preparation message; normal learning and weekly budgets are untouched.

## Before launch
1. Author NEW original P1/P5 tasks privately, map to the 8+5 syllabus areas and separate Pure Math 1 / Probability & Statistics 1 textbook chapters.
2. Perform one full mathematics, translation, technical, intellectual-property and difficulty acceptance; record source version, approvals and SHA without exposing private answers.
3. Stage keys using a restricted authenticated admin/database import, never a public migration; update only approved private task rows and the separately approved bank release control.
4. Verify real student ownership and answer secrecy until submission, repeat/lost-ACK, ungraded outcome, no cross-user access, and no cross-credit.
5. Update precise Math beta-state cleanup/FK/backup manifest for new attempts before any public release; separate architect GO is mandatory.

**Status: DRAFT, protected content EMPTY, Math Exam Prep public NO_GO.**
