# iClub AI v2.1 — CI-only verification branch

QA-to-QA draft PR, no merge to main, no deployment, no production secrets, no live DB. The only purpose of this branch is to trigger the existing full offline Node/Chromium/Deno/PostgreSQL/Math parity workflow and inspect actual job steps. Deployment permission remains NO-GO.

Re-run requested after fixing the exact two source QA tests observed in workflow #203. No product release or protected app modifications.

CI proof re-run for additional QA-only signed Home-plan bridge, no rollout or production changes.

Another full CI run: bounded cleanup for short-lived Chromium profile subprocesses. QA-only change; retain no-merge/no-production scope.

Final QA-to-QA run for owner-subject-intent commercial access proof, exact source hashes and signed Home authorization. Never merge to main.

QA CI rerun 2026-10-15: verify Home source priority by real enrolment mode, subject-level synthetic authorization, independent academic/editorial rechecks and final owner screen/scan stability. No paid Supabase branch or production changes. NEVER MERGE.

QA CI 2026-10-15: verify frozen existing global-ai-ui.js, commercial-access-ui.js and plans-ui.js against trusted QA baseline without altering original production surfaces. NO MERGE.

2026-10-15 §96: verify localhost HTTP->scratch PostgreSQL->signed Home policy, no live Supabase and no product release; never merge.

2026-10-15 §96–§97: actual HTTP + scratch PG + server HMAC + native Chromium across 3 locales; QA-to-QA only, NO MERGE.

2026-10-15 §97 rerun: PostgreSQL boolean EXISTS::text uses 'true' (not libpq display 't'); check actual local HTTP + Chromium only on disposable PG.

2026-10-15 §98: verify real scratch editorial rights/revocation/source fingerprints through signed Home HTTP and Chromium; QA only, no Supabase, no merge.

2026-10-15 §98 corrected scratch source fixture exact SQL dollar syntax; recheck 12 unique per-locale sources, real DB revoke and rights in HTTP and Chromium. Never merge or deploy.

2026-10-15 §100–101: new strict commercial source adapter + scratch mirror of existing iClub subject guard/capabilities/selection, scanner rejects unselected subjects and falls back to other eligible ones; full CI-only; never merge.

2026-10-15 §101 rerun: share selected-subject PG fixture between scanner and HTTP test; commercial contract under enforced mode requires caps ai_generation_entitled and separately approved QA gate. NO MERGE.

2026-10-15 §103 real commercial pg_proc function fingerprints, read-only contract drift gate, no student SQL, no production/live Supabase CI; QA-to-QA ONLY, NO MERGE.

2026-10-15 §104: final signed Home HTTP delivery authority rechecks commercial/source/academic/screen, transactional race negative tests, UI expires by server TTL in Chromium. QA-only NO MERGE.

2026-10-15 §104 rerun: double-check commercial, academic and editorial rights across last async boundary, then re-read exact owner screen/scan; not an atomic live transaction. NO MERGE.

2026-10-15 §105 final signed Home delivery now presents safe locale-independent subject/action choices only; never exposes internal evidenceId/actionId over HTTP on same-priority ties. Full CI validation, QA ONLY, NO MERGE.

2026-10-15 §106: trilingual subject choices use exact live i18n.js captions in synthetic Home Chromium; must show all same-priority selections, never raw evidence IDs or fake clickable navigation. QA-to-QA only NO MERGE.

2026-10-15 §106 rerun: strictly sorted locale-set QA assertion (en,ru,uz), no product text changed; native Chromium three-language tied subject choices + full offline CI; never merge.

2026-10-15 §107: final one-statement read-only PostgreSQL MVCC commercial/source/screen/academic authority before Home delivery; disposable PG only; NO MERGE.

2026-10-15 §107 exact last-MVCC-moment revocation injected in isolated localhost Home; source rights, ai_generation_entitled and owner screen must fail closed in single SQL SELECT; QA-only no merge.

2026-10-15 §108: local one-use opaque Home handoff; atomic scratch PG claim plus last MVCC permission snapshot, no student progress. QA-only, do NOT merge.

2026-10-15 §108 correction: PostgreSQL INSERT token digest must be returned by SELECT CTE, not psql command-tag output; verify localhost issuer+claim end to end; QA only.

2026-10-15 §108 final: normalize psql text-count assertion, run real concurrent independent worker-thread/psql claims against separate scratch PostgreSQL; strictly QA-only NO MERGE.
