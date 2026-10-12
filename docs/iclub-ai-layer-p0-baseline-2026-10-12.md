# iClub AI Layer v2.1 — P0 baseline и журнал начала работ
**Дата проверки:** 2026-10-12  
**Статус:** P0 evidence gathered, preliminary. **Production: read-only; не считать релизным разрешением.**  
**QA branch:** `qa/iclub-ai-layer-v21-20261012` from `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf`.

## 1. Evidence observed

| Surface | Read-only observation | Interpretation |
|---|---|---|
| GitHub | `main` production commit `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf`, release #341, 47/47 CI in recorded commit | Baseline for future regression. 47/47 is release commit metadata, **not** validation of this new QA branch. |
| Vercel production | `i-club-app.vercel.app` READY, target production, same SHA | No production promotion performed by this work. |
| Vercel project | SSO protection configured for `all_except_custom_domains`; no password protection | Do **not** infer full protection or safe database isolation for future Preview. Check exact Preview and env bindings before launching. |
| Vercel QA branch | Branch-filtered deployment list count **0** at verification | No Preview deployed in this step. |
| Supabase project | `mmmduffgpvwjdpruzikw`, ACTIVE_HEALTHY | **Production DB**. Read-only inspection only; not for synthetic Preview. |
| Exam Prep flags | Core ON, AI ON, Mentor OFF; controlled_beta; kill_switch=false | Preserve existing Exam Prep. |
| Exam Prep entitlements | Exactly **3** rows with `ai_assist=true` | Don't change/silently move these learners to new billing. |
| Tutor content | `tutor_v3_learner_first` approved runtime: 81 EN + 81 RU + 81 UZ = **243** | P1=45 and P5=36 canonical skills across locales. |
| Theory source | atomic `p3_02_full_theory_pack_v2_atomic_2026_10_06`: 81×3 = **243** | Do not rewrite approved content. |
| Practice AI | `enabled=false`, `generation_enabled=false`, rollout off; entitlements 0 | Any new Practice AI route remains mock/off. |
| Practice approved source | Economics 81×3, Chemistry 38×3 | Existence of cards is not approval for broad subject generation. |
| Global AI | `ui_enabled=false`, `gateway_enabled=false`, `generation_enabled=false`, `plans_ui_enabled=false`, `checkout_enabled=false`, `kill_switch=true` | Global AI dormant. |
| Global usage/subscriptions | `private.iclub_ai_usage_periods` = 0; subscription entitlements = 0 | Do not create a user billing period here. |
| Global readiness | Math exam_prep full/source-governed; Math global and Biology/Chemistry/Economics/Informatics global = basic/no generation | Multi-scope/topic/locale registry still needed. |
| Edge functions | exam-prep-ai and practice-ai active; Global AI Edge not found among deployed active functions | GitHub source for global-ai does not prove deployment. |

## 2. Precise code impact (no production edits)

1. **`supabase/migrations/20261006102000_iclub_global_ai_tariff_foundation_v1.sql`**: `public.reserve_iclub_ai_usage_service_v1` currently computes weight from policy, and on expensive shortfall with active period sets `private.iclub_ai_usage_periods.exhausted=true`. This conflicts with the owner's **new** route-specific shortfall policy.
2. **`private.iclub_ai_usage_policies`**: current generated weight = 5 in earlier approved policy. QA target temporarily = 3; never change live policy until final QA and owner release gate.
3. **`supabase/functions/global-ai/index.ts`**: currently dormant implementation of global AI; exact prepared-cache/source routing, quota checks and output validation must be regression-tested before integration.
4. **`global-ai-ui.js/css`**: protected assessment currently dims/blocks icon; 33B requires complete hide while active.
5. **`supabase/functions/practice-ai/index.ts`**: older post-answer explanation exists; user 10B allows new AI only after completed Practice.
6. **`exam-prep/exam-prep-ai-ui.js`**: working separate Exam Prep Tutor, approved content and followup flow. Protect and compare before connecting to common AI shell.
7. **`private.iclub_ai_subject_readiness`**: table is currently keyed by subject/scope; must be extended additively for subject × screen × feature × topic × locale. No mutation of live registry now.

## 3. Synthetic acceptance started

QA test file: `qa/ai-layer-metering-v21.synthetic.js`, with eight test cases passing in an isolated JavaScript execution environment:

- Remaining 2: generated3 denied; prepared1 + prepared1 accepted without global lockout.
- Mixed Plus/Pro limits with TEST-ONLY weights 1/3.
- Free no generated calls.
- First failed request releases quota and doesn't start period; 5h reset after first success.
- Duplicate request ID and concurrent reservation cannot overspend.
- Protected assessment, in-development and missing exact source block without charge.
- Provider failure releases reserved units, safe prepared response still available.
- No cross-user or cross-route reuse of request ID.

**Boundary:** this is an isolated **behavioural simulator**, NOT proof that live SQL RPC or Vercel app currently satisfies these tests. Follow-up P1/P7 must run an equivalent real implementation suite **only in an isolated testing database**.

## 4. Data-safety and release restrictions

- Do not run UPDATE/INSERT/DELETE/DDL in production Supabase; no real subscriber/school accounts for QA.
- Do not use production Supabase URL/service secrets in the Preview.
- Before Vercel Preview, prove deployment protection AND environment isolation. Automatic branch deployments must not be treated as approved synthetic Preview.
- No production/main changes and no PR merge. The QA branch holds only documentation and sandbox tests at this point.
- AI rollout/public billing/Mentor Care remain unchanged and require separate explicit approval.

## 5. P0 next checkpoints

- Check production aggregate integrity/RLS read-only immediately before any future deployment or branch promotion.
- Map all course and screens, including English A1/A2/B1 and SAT; identify source/topic/locale readiness.
- Implement exact contract checks for existing `reserve_iclub_ai_usage_service_v1` **in isolated QA database only**.
- Establish a protected synthetic-only Preview independent of production network credentials, then UI/readiness work.
- Capture CI test pass/fail for this QA branch (local synthetic test passed; GitHub CI not claimed).

**GO/NO-GO:** P0 preliminary evidence GREEN, but P1 deployed Preview is **NO-GO** until an isolated backend and Preview bindings are proven.
