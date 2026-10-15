# Chemistry 9701 Tour 2 — offline QA checkpoint (2026-10-15)

**HOLD. Read-only study and local tests only. Not a release migration.**

## Existing infrastructure used
- Repository: `jteshaboev1984-ops/iClub_APP`; branch `chemistry-academic-audit` (existing, no new branch created).
- Branch is 2702 commits behind `main` (main SHA `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf`). Do not merge this historical branch into main as code.
- Supabase `iClub_APP` currently reports **zero development branches**. Vercel Preview is not an isolated database. No authenticated test writes were attempted.

## Read-only production metadata, 2026-10-15
- Chemistry subject_id=4; 867 total questions; 154 legacy inputs, 151 active.
- Ordered old input-ID checksum: `979f55f0e3d95b712a2313e3f8124745`.
- Unchanged scorer source MD5s: Practice `9183e7230bda1321df05138a472325cd`, Tour `6fda83af7c7c38415475b82fdee99a40`.
- New strict policy and frozen legacy table are not installed.
- Eleven keepers: active Chemistry MCQ, each already in one Practice pool, zero Tour references, existing timers unchanged (total 840 seconds).

## Re-executed locally (not PostgreSQL RPC)
- Existing fail-closed route simulation: **1811/1811 PASS**.
- Existing archive content/timer preflight: **674/674 PASS**.
- Independent archive preflight: **311/311 PASS**, archive manifest, 79 draft candidates, 28 numeric contracts, 59 Practice timer *proposals*, 20 frozen Tour limits, and unchanged legacy metadata.
- Verifiable appended package: `Chemistry_9701_Tour2_EXISTING_BRANCH_QA_2026-10-15.zip` in iClub Library. Its 64 original files are byte-for-byte unchanged; 4 QA-only files appended, including executable standard-library Python checker with SHA256 `41ed03f13e47ee93f531f120809d53921dd7d03cc09b4bdc384d9b201e0569f8`.

## Release gates not met
1. No isolated Supabase branch is available; production write-path E2E must **not** be attempted via existing previews.
2. SQL transaction rollback, session ownership, idempotency, and no-leaked-answer E2E remain **NOT EXECUTED**.
3. 59 proposed Practice timers need product-owner approval; strict scorer staging, expert Chemistry QA and RU/UZ/EN native reader review remain pending.
4. Eight book-only extension classifications require separate academic review.
5. No production/main change, no question publication, no score/progress rewrite, no notifications, no installation until an affirmative separate GO.

**Scope:** This file is only QA evidence in an already-existing historical branch. Never cherry-pick old app/runtime code from it.