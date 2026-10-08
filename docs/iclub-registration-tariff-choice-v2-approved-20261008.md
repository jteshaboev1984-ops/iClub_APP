# iClub registration + tariff subject choice v2 — architectural clarification
Date: 2026-10-08
Status: architect-confirmed PRODUCT DIRECTION; DESIGN/PREVIEW ONLY; NO PRODUCTION ACTIVATION

## Source reconciliation
The 2026-10-06 approved target `iClub_Global_AI_Tariffs_Implementation_Working_Doc_v1.0_2026-10-06.docx` includes Exam Prep for all three tariff interfaces: Free introduction plus first diagnostic; Plus and Pro full Exam Prep. A later launch-safe implementation audit excluded Free Exam Prep from *current launch UI* because Free diagnostic/preview capability was not implemented, rather than because the target was abandoned. The architect explicitly reaffirmed **Exam Prep opens on all tariffs** on 2026-10-08. Implement the original tier difference, but NEVER promise an unimplemented Free diagnostic as already usable.

## Registration/transition, approved
- Every new learner registers normally; virtual Free is default. Plus/Pro may be upgraded through a real payment flow once available.
- Existing learners do NOT sign up again. A one-time, prefilled profile-confirmation + subject-selection screen may be required **only after real Plus/Pro checkout is operational**, never simply on a code merge/deployment.
- Keep the same authenticated user ID, Telegram identity, profile, legacy user_subjects, all Tours/rankings/certificates/Exam Prep evidence and local drafts. This is NOT the existing registration submit handler (that handler clears local data).
- Before payment is operational: only a standalone visual mockup/canary shadow test is permitted; do not redirect registered users or enforce Free limits.
- During outages/unresolved identity/grandfather state, never reset a user or close existing legacy learning access.
- Study slot changes cannot rewrite/delete legacy subject rows. Commercial choices live in separate guarded subject slots. Subject history returns if a paid plan is regained.

## Subject selection and Competitive
- FREE: one chosen active study subject. For a learner eligible for Competitive/Tours, that SAME chosen subject is automatically their single Competitive subject. No duplicated subject list, toggle or second confirmation. Do not grant Tours access to ineligible non-school users merely by UI selection.
- PLUS: up to three active study subjects and up to two Competitive subjects; Competitive choice is a subset of study subjects.
- PRO: all currently active study subjects included automatically (no five unnecessary Study toggles), up to two separately chosen Competitive subjects.
- Do not show currently inactive English/SAT/IELTS catalog items as available.
- Validate and enforce per-user Free/Plus/Pro choice atomically on the server; prevent rapid clicks and cross-account writes.

## Exam Prep location, scope and tier capabilities
- Exam Prep lives as an ordinary function in each active subject hub beside Practice and Tours; NOT a separately selectable study subject or commercial subject slot. Do not display an explainer about it being 'inside Mathematics' in registration.
- Mathematics P1/P5 is currently functional. Other active subject hubs may display a clearly non-interactive 'Exam Prep — in development / Tez orada / В разработке' status rather than a broken action. Do NOT promise dates or fabricated content.
- Target tier matrix (only when implemented and independently accepted):
  Free: entry, overview/intro and one first diagnostic; no full exam preparation route. Plus: full deterministic preparation, weekly work/corrections/retest/mixed/timed/readiness. Pro: same full academic Core; value difference is all active subjects and the highest governed iClub AI allowance.
- One deterministic academic authority for every tier: tariff NEVER changes correctness, mastery, placement, marks, readiness or results. AI Assist is additive and optional; Mentor Care is independent, not automatically bundled in Plus/Pro.
- Existing beta/temporary Exam Prep access stays as architect instructed until the *approved payment-ready* access transition. Do not accidentally gate the Mathematics Subject Hub and hide an existing Exam Prep route.

## Copy and display
- RU/UZ/EN must be natural, concise, symmetric and tested at 320x720 and 390x844. Prefer 'Musobaqa va reyting' to literal Tour/Tur translations in Uzbek user guidance; keep established product feature names iClub AI, Practice, Tours, Exam Prep where necessary.
- The visual demonstration has no authentication, writes, payment or real-user data. Its Free selected subject is Competitive automatically; no separately rendered second Free selector. Pro includes all active subjects automatically.
- Free/Plus/Pro detail must not expose internal usage units, model/caching internals or promise unsupported mentor/priority support.

## Implementation HOLD
This text documents an architectural/UX decision, not completed runtime functionality.
The existing #327 release candidate remains DRAFT, all commercial enforcement, payment and Global AI generation flags OFF.
Before activation: build registered-user safe prefilled flow distinct from re-registration; verify server-enforced Free auto-Competitive choice; implement and QA Free introductory diagnostic; QA Plus/Pro full Exam Prep access; preserve current beta; verify real checkout and rollback; get explicit architect approval for one production deployment.
