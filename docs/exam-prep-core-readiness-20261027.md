# Core Exam Prep P1/P5 — production readiness audit, 2026-10-27

**Scope:** Mathematics P1/P5 Core independently from RU/UZ written-criteria localization. Evidence: production Supabase aggregate SQL (read-only), current Vercel production, existing Core workflows and canonical P3-01 decision gate.

## Checked production facts
- Live Vercel deployment READY at commit efbfea98996d0e52ba08ac7e2f7637718fd33021; runtime errors: none in the observed 24-hour provider window.
- Cohort math_as_p1_p5_beta_2026_09_01: canary, wave 1, planned 12, **3 active beta members**. No claim that all three have recent activity.
- **Core live:** rollout_state=controlled_beta, core_enabled=true, kill_switch=false. **Temporary QA overrides are BOTH ON:** qa_open_all_core=true, qa_open_all_weekly=true. This extends Core usage outside the consenting controlled-beta cohort. Do not silently disable: real users have historical and potentially still resumable sessions from this route.
- ai_enabled=true globally; this is NOT proof every Core user has AI access. Effective AI requires individual entitlement (verify separately before any product claim). Mentor globally OFF.
- Historic Math usage: 544 P1/P5 sessions; 514 sessions belong to 113 unique accounts outside active beta membership (historic cohort classification; not evidence of present active use). 56 active sessions were not touched within 30 days. **Never delete or auto-finalize** these sessions.
- Week plan/corrections: 73 plans, 219 plan items; 8 scheduled P1 retest events with no completed retests indicated by the snapshot. A product journey may have content, but this alone does not prove successful observed retest completion.
- Human governance: 0 real weekly review records, 0 active staff reviewer roles. Do NOT synthesize reviewer identities or GREEN weekly decisions.
- P3-01 server decision NO_GO, reason four_real_weekly_reviews_incomplete, no Sev0 and no unresolved release-blocking Sev1 in that gate's evidence; product content and Stage 5/6 surfaces present. This is **not** approval for expanded or mass rollout.
- Written external P1/P5 is independently OFF; no student allowlist. Translations are owned by a separate thread; not changed in this audit.

## Safe hardening in this package
The private *read-only mass Core release decision RPC* cannot declare eligibility until both temporary QA-open overrides are closed. The additive function-only migration is versioned. It does **not** change access, session state, beta roster, AI, Mentor, localStorage or learner history. Existing expanded-beta and product-content gates remain mandatory.

## Remaining REAL (non-technical) release blockers
1. Review the 113 historic outside-cohort accounts and user communication policy **without revoking access mid-attempt**. Define a product-authorized closure date and verified allowlist/entitlements first. Do not automatically close either QA override.
2. Have authorized staff actually perform and record 4 real weekly beta reviews with truthful GREEN/AMBER/RED decisions. If there is no staff identity with the required role, appoint an actual responsible reviewer; never fabricate.
3. Run an authenticated production browser path on real consented beta accounts (diagnostic → result → weekly plan → corrective activity → delayed retest → next step) and verify mobile and all EN/RU/UZ. CI synthetic browser tests and a ready Vercel deploy cannot replace that.
4. Independently test P1/P5 written-paper mode only after approved RU/UZ criterion coverage; Core legacy remains operational meanwhile.
5. Record signoff that live Practice/Tours, ratings, certs, local drafts, user progress and historic submissions have not been mutated, and keep reversible flags/incident monitoring.

## Accepted interim outcome
Existing Core technical services can continue for currently authorized learners without any state reset. No **mass Core release** and no **automatic beta expansion** is allowed from this status. Translators may work concurrently on a separate protected table.
