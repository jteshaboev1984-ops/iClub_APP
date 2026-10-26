# iClub Chemistry 9701 — J-02 Authenticated P1 + shared host (26.10.2026)

**Status: IMPLEMENTED BEHIND OFF GATES; NOT RELEASED.**  
**Isolated branch:** `work/chemistry-9701-j02-auth-host-20261026`, based on an actual `main` snapshot.  
**Existing production:** Mathematics P1/P5, Economics P1/P3, Tours, Practice and user history must remain unchanged. No branch merge, PR, Vercel deployment, account enrollment or beta release in J-02.

## Verified architecture

1. **Beta ownership / consent:** `private.iclub_exam_chemistry_p1_beta_control_v1` (singleton `enabled=false` and `owner_go_at=NULL`), plus `private.iclub_exam_chemistry_p1_beta_members_v1` (zero rows). All future learners require explicit owner approval, consent, active Chemistry subject selection, non-anonymous login, program published, Paper 1 published and owner-approved release manifest. This is distinct from Mathematics and Economics cohorts.
2. **Gated shell:** `public.get_my_exam_prep_chemistry_shell_v1(language)`, authenticated-only; returns `{}` when any access gate is closed. The default end-user remains **«В разработке»**.
3. **Confidential P1 content:** 45 original private drafts, 44 internal GPT-6-reviewed (no independent human examiners, by owner decision), 40 editorial selection + four reserves, 22 AS topic units. **No owner-approved release items yet** in `private.iclub_exam_chemistry_p1_owner_release_items_v1`. `private.iclub_exam_chemistry_p1_live_attempts_v1` contains **zero** real-user attempts and is `FORCE RLS`, no direct client privileges.
4. **Server-only answers:** five authenticated and separately authorized public RPCs:
   - `iclub_exam_chemistry_p1_start_v1` — account-bound, idempotent, per-user advisory lock, 75-min timer, 40 exact approved source hashes, seven internal AI QA gates, 22 topics, **owner-approved manifest must match**.
   - `iclub_exam_chemistry_p1_get_v1` — EN/RU/UZ and resumed selections. No correct option or explanation before finalization. Verifies `auth.uid()` ownership.
   - `iclub_exam_chemistry_p1_answer_v1` — atomic saved choice, revisions before deadline, first answer timestamp.
   - `iclub_exam_chemistry_p1_finish_v1` — server grades 0–40; retry idempotent; unattempted questions zero; **no mastery or verified skills granted**.
   - `iclub_exam_chemistry_p1_history_v1` — own 30 latest attempts only; the saved answer count uses supported PostgreSQL `jsonb_object_keys`.
5. **UI:** `exam-prep/exam-prep-chemistry-native.js` uses **the existing shared** `#exam-prep-host-root` and existing Economics-native styling rather than a new app. `exam-prep/exam-prep-host.js` conditionally mounts Chemistry on **server-side shell.enabled=true**. `index.html` loads the gated adapter. RU/UZ/EN text, back, full P1 attempt, timers, per-item choice, server save, history, results and answer explanations after finishing. Active Chemistry language switches preserve the open session. Core needs neither AI Tutor nor Mentor Care.

## Testing and evidence

- Synthetic signed-in SQL identity (not an actual student; transaction rolled back) tried shell RU/UZ/EN, start/get/answer/finish/history with **all denied while beta OFF** (8/8).
- Native Chemistry UI JavaScript and shared Host compile, mock DOM mount refuses `enabled=false` and loads only Chemistry history RPC when synthetic `enabled=true`. No credentials or secret keys in browser source.
- Existing service-only Chemistry shadow engine previously demonstrated server-side 40/40 and replay/expiry handling inside rollback transactions. **This is not a positive authenticated end-to-end learner test.** The new authenticated API remains fully OFF, so a positive test with an eligible learner has intentionally not been performed.
- `scripts/qa-chemistry-9701-j02-gated-auth-host-readonly.sql`: **28/28 pass**; no real or shadow Chemistry attempts remain, no beta members, no approved content, no changes to Math/Econ/Practice or old Chemistry Tours/Practice materials; original 26 variants preserved. A later run must repeat this check after any changes.
- Supabase security advisor: only expected INFO `rls_enabled_no_policy` for five intentionally closed private tables and WARN `authenticated_security_definer_function_executable` for six intentionally callable authenticated RPCs. These have explicit `auth.uid()`, user membership, owner/content/program gates and exact session ownership checks. No `anon` RPC execution. Re-review at actual release; see [Supabase security advisor](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

## Applied DB migration versions

- `20261026182943` — default-off beta/consent authorization and shell.
- `20261026183106` — empty owner version release manifest and isolated future learner attempts.
- `20261026183240` — authenticated start/get, server-owned question keys, exact source/version/QA gates.
- `20261026183346` — answer, finish, history; no mastery.
- `20261026184024` — correct JSONB answer count in history.

Each is committed in this isolated Git branch with matching migration version. Earlier Chemistry private material and prior service-only shadow harness remain separately tracked in the older work branch; none were promoted to `main`.

## Remaining release blockers — not implied completed

1. **Positive end-to-end account test** on isolated staging data: real authenticated user with explicit beta consent, approved version snapshot, start/resume/re-answer/expires/finish, cross-account denial, no keys before finish. Do not fake real user's consent or write a synthetic user into live history.
2. **Full browser QA** on actual desktop/tablet/mobile, keyboard/focus/back, offline/reconnection and RU/UZ/EN. Mock DOM and static checks do not replace visual verification.
3. Approve content release, topic distribution, academic review results and release manifest with exact hashes; reconcile Chemistry Paper 1 to the complete AS learning journey. Internal AI QA is not a human Cambridge examiner's approval.
4. Confirm Core journey: diagnostics, skill plan, errors, delayed checks, mixed practice, timed paper, readiness. J-02 installs P1 exam UI and server persistence, **not** the complete Chemistry learning workflow. P2/P4/P5 written and P3 laboratory teaching/assessment still require separate honest handling.
5. Owner release GO, separate feature flag, QA and rollback protocol. **No automatic launch.**

**Never turn on Chemistry via broad flag update**, repurpose synthetic shadow sessions for live learners, grant browser access to service_role or alter past users' localStorage/history.
