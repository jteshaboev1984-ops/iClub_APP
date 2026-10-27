# Chemistry 9701 — J-14 Protected Preview and Production Safety Hold
Date: 2026-10-27

## Outcome
**PREVIEW READY; AUTHENTICATED DEVICE ACCEPTANCE PENDING; Chemistry release NO GO.**

Vercel project: `i-club-app`, project ID `prj_c1U3yBXrdYtg6uEU5m9AWaja9ie4`.
GitHub repo: `jteshaboev1984-ops/iClub_APP`.
Existing isolated branch: `work/chemistry-9701-j02-auth-host-20261026`.
Pinned preview commit: `69368fa1e747e88ed18c014c650c28e967445cab`.
Protected preview deployment: `dpl_HUZfupDQfGVhvSNqWg7pxSMSbR3t`.
Protected preview URL: https://i-club-hy70l9ula-jasurbeks-projects-c5451f97.vercel.app
Alias: https://i-club-app-git-work-chemistr-3dd911-jasurbeks-projects-c5451f97.vercel.app

The deployment was made through Vercel Git integration without a production target; Vercel reported `target:null` and `READY`, and returned no alias error. The build log confirms checkout of the exact Chemistry branch+commit, build completion and deployment completion, with no build errors. This is a distinct Vercel deployment and does not update `main` or any production alias. Project has Vercel Authentication/SSO protection enabled for all except custom domains. **Do not disable this protection for testing.**

At preview creation, production was READY at deployment `dpl_CVLjwVdpZ2zVb9GZR9hQJmg7prpe`, Git SHA `2f4f37c5fbc88fe1d76afadacd06c57e574ff524`. Branch was 126 commits ahead, 37 behind `main`. Do **not** fast-forward, merge or redeploy production without main compatibility and backup review.

## Preflight validation and regression
- Live Chemistry J12 release gate: `currently_hidden=true`, `core_disabled=true`, `entry_disabled=true`, `recheck_disabled=true`, `p1_disabled=true`, `can_publish=false`. All three J13 P3/P5/Tutor feature switches OFF.
- Zero separately approved A Level users and zero Tutor entitlement users.
- Baseline Mathematics answers 1,979 and Practice answers 4,816 unchanged at preflight.
- Independent J13 read-only SQL regression re-run after preview deployment: **44/44 PASS**.
- Preview commit contains the LAB UI script reference in `index.html`; standalone LAB JS and Entry JS parse as valid JavaScript; host explicitly unmounts the LAB screen on close.
- J13 prior full read-only suite: **310/310**, J08–J13 synthetic UI: **63/63**. These numbers are **not browser acceptance**.

## Strict preview limits
The preview is *protected*, but if an authorized owner signs in, frontend app code may still point to the active Supabase project. Therefore **do not conduct any mutating quiz / consent / attempt flows on a real student account during J14**. Preview READY does not prove the app was navigated or visually inspected in Chrome, Firefox, Safari, desktop/mobile or a screen reader.

No authorized graphical browser session or Vercel authenticated browser tool was available in this run. `get_deployment_file_contents` did not fetch `index.html` (Git deployment file retrieval returned 404); source verification therefore used the pinned GitHub commit and build metadata, **not** an independent HTTP DOM fetch. Do not claim full end-to-end QA.

## Required J14 browser acceptance, when an authorized session is available
1. Open the **protected preview only**, sign in with an independently approved QA account (never a real student, and never use hidden content to create a fake release). Confirm domain + SHA, main production not visited for mutation.
2. Confirm Chemistry displays coming-soon/locked state while global release OFF. P3/P5 and Tutor cannot be reached through UI, direct RPC, or unapproved user session.
3. Verify EN, RU, UZ labels and responsive layout at 375/768/1280px; keyboard tab order, touch targets, screen reader headings/alerts, high text zoom.
4. In non-production test fixtures only, verify P3 six AS titles, P5 six distinct A Level titles with additional per-user A consent. Check paper and locale switching, empty/denied cards, Network OFF/ON, deep-link/reload/back transitions.
5. Verify Mathematics, Economics, Practice, Tours open normally and previously stored user history remains intact. Never reset localStorage, clear databases, create test marks inside production student data, or copy private question content into the repository.
6. Verify off-switch behavior and emergency stop in a transactional isolated test, plus academic/copyright and backup restore signoff before release. Owner's explicit composite GO and separate P3/P5/Tutor GOs are still missing.

## Next checkpoint
Real authenticated browser/device QA with safe non-mutating account, preview origin protection and review of rollback/backup evidence. NO Chemistry publication, no production merge, no beta invitations until separate owner decisions.
