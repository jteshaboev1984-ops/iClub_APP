# B00 — Stitch visual fidelity correction after architect feedback

**Date:** 2026-11-11 · **Owner feedback:** Earlier draft looked only cosmetically different; future designs should reproduce accepted Google Stitch compositions much more closely, not just adopt the general colors or add steps. User's requirement: "student notices the app was redesigned". Treat this as binding for B00 and future visual blocks, subject to exact existing source functionality/text and no production/data changes.

## Source material compared
- Actual owner's supplied Step1 screenshot `image(20261111-113456).png`.
- Accepted Stitch v2 ZIP: `stitch_iclub_registration_visual_redesign (1).zip` Step1 `step_1_of_2_personal_details/screen.png` and Step2 `step_2_of_2_school_subjects_default/screen.png`, associated HTML design references and `academic_sapphire/DESIGN.md`.
- First implemented B00 Chromium PNG screenshots at PR #534's earlier baseline `8f546f1f21bd75662fa86025ac9e8e65d1ab7848`.
- Reworked B00 Chromium screenshots in Actions final artifact `b00-registration-visual-qa-screenshots` [run #43015524827](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43015524827).

## Concrete before-vs-after visual differences

| Stitch characteristic | Earlier PR #534 | Corrected in final draft |
|---|---|---|
| Step 1 form card | Button placed inside smaller outlined card | Source fields re-grouped inside elevated white card; CTA separate below |
| Visual rhythm | Compact 15px field spacing, 16px internal padding | 25px internal field rhythm, 20–24px card padding |
| Text hierarchy | 22–27px title, 12px labels, 13px subtitle | 26–31px title, 14–15px labels, 15px subtitle |
| Inputs | Prominent outlines, square-ish platform look | Rounded 12px, subtle light shadow, focus halo, 50px height |
| Language notes | Second note in blue filled callout box, no icon | Both notes as aligned concise icon-text rows, preserving real i18n text |
| District | Pale disabled select, no glyph | Light lavender disabled field with lock icon and correct original placeholder |
| Next button | Inside card, no arrow | Large separate primary button with arrow, distinct elevation |
| Topbar registration | Boxed back button | Minimal unboxed back arrow; exact real iClub logo and brand retained |
| School toggle/School+Grade | Two disconnected cards | Unified soft-elevated school card like Stitch |
| Subject chips | Small bold text squares; active solid blue | 50px flexible wrapped tiles with five inline decorative category SVG masks; selected pale blue with blue outline/check |
| Selected summary | Smaller detached label box | Styled read-only X/2 counter plus original primary/secondary summary within one pale tinted module |
| Consent and second-step actions | Thin outlines, boxed Previous | Separate white consent card, prominent CTA+arrow, minimalist local Previous |
| Surface colors | Cool grey blue | Stitch-inspired near-white lavender `#FAF8FF` scoped ONLY to active registration; real brand `#2F6FD6` unchanged |
| State change | No animation | Subtle reduced-motion-respecting visual reveal |

**Intentionally NOT copied** from Stitch: fake Cambridge partner/accreditation/security claims, changed consent, Step 3/percentage, new name-document requirement, fictitious district instructional paragraphs, demo profile identity, any new sign-in, or replacement Tailwind/runtime. Existing exact app copy, existing real `logo.png`, original school/class/subject rules, native form and unchanged save remain authoritative.

## Implementation proof
- Same isolated code [Draft PR #534](https://github.com/jteshaboev1984-ops/iClub_APP/pull/534), branch `draft/b00-registration-two-step-visual-20261111`, **verified latest HEAD `6ec05e6a7e8258ad207356163aa6c9c26248a38e`**. `main` remains `85297150a347e98deb8f1e1c58cfbfa2236aea03`.
- Strictly B00-scoped additions/changes in existing `registration-b00-ui.js` and `visual/iclub-registration-b00.css`, plus asset cache bust in `index.html`, isolated QA adaptations. Real `app.js`, `i18n.js`, original registration markup, Supabase and database not touched.
- Existing DOM field instances (not clones) are moved to visual Step1 field card, Step2 school card. Selection count is **read-only derived display**; no changes to actual choices.
- UI mock tests and real `app.js` / `i18n.js` with LOCAL fake database/Telegram tested at 320/375/390/1440px, school and non-school, RU/UZ/EN, source subject max 2, final save error and conflict recovery modal.
- Final latest [GitHub Actions run #43015524827](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43015524827) **SUCCESS**; real source runtime fixture never makes external requests. 10 screenshot artifact including clean Step2 after third-chip toast closes. Exact run head equals PR head above.
- No merge, deployment, real Supabase writes or real-user progress changes.

## Acceptance and next blockers
Owner has NOT yet explicitly accepted this corrected Stitch-fidelity appearance; present full Step1 and Step2 screenshots and side-by-side comparisons. Treat as **visual revision ready for architect review**, not released/merged.
Full real staging Supabase/Telegram/JWT/RLS remains untested and must be authorized separately. Important UX fact: **B00 is only a registration/splash surface**. Returning existing users go directly to Home, not registration. Achieving the architect's "wow, app updated" goal requires separate faithful visual redesign of **B01 shared shell and B02 Home**, with source parity and full three-language/responsive QA. Do not infer that a B00-only change provides a redesigned home experience.
