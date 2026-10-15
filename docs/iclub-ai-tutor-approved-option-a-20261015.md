# iClub AI Tutor — approved brand mark Option A

**Approved by product architect:** 15 October 2026, explicit user instruction: “принимаю вариант а”.
**Scope:** iClub AI Tutor mark only. The original iClub app wordmark, icon, logo.png, main navigation and brand identity are unchanged.
**Reference:** original generated Option A, upright lowercase “i” inside a sapphire/cyan layered ribbon, clean white core. This is the approved artwork, **not** an instruction to redesign it as a sparkle, robot, OpenAI logo or other company's mark.

## Asset and current implementation

- Original user-approved Option A raster: `глянцевый_синий_иконный_символ_i.png` (1254×1254). SHA-256 of original source: `a2b8a8abd839fc9c40ab502e61a383966828e226777d2e6510dca3650df793f7`.
- QA-only optimized derivative: `qa/iclub-ai-tutor-a-96.webp` (96×96, alpha transparency), Git blob `8cfd1eb93bdbc782d0c944baf55e574dd6c21a77`. A crop/resize of exactly the accepted Option A, not a substitute drawing.
- `qa/ai-v21-real-preview-ui-snapshot.js` uses the icon as a 40×40 mark in a 48×48 floating button and as 32×32 image in the existing AI sheet header.
- `qa/ai-v21-real-preview-ui-snapshot.css` protects sizing, center alignment, accessibility, focus ring, stable geometry and screen blackout.
- `qa/ai-v21-real-preview-build.cjs` copies this QA-only image to `iclub-ai-tutor-a.webp` in the **disposable Preview output only**, leaving `app.js`, `index.html`, production CSS/JS and `logo.png` unmodified.

## Acceptance and prohibitions

- One iClub AI across Home, Study, Lesson, Practice result/review, Tours rules, Profile and other eligible screens; no artificial Tutor tab or separate fake app.
- Entire AI control, including approved logo, must disappear during active Practice, Tours and protected Exam Prep.
- Image is decorative when adjacent to labelled AI control: image `alt=""`, parent has accessible text name. Do not use image text extraction for meaning.
- Preserve mobile hit target, 320–1280 px responsive checks and panel layout. Do not make the logo itself an extra tappable control.
- State illustrations (locked/unread/theory only) in the earlier concept sheet are **not** automatically approved behaviors or entitlements. Their use requires source-of-truth UI state and separate implementation review.
- Option A is selected as brand direction; this does not activate a paid AI provider, production rollout, change tariff data or grant real student access.

## Preview and release state

- Protected Vercel Preview with A mark: deployment `dpl_EAP6N5RKLnVqw3F7yEDoZ7off2ub`, READY, pinned to `ff0e8c2d5e6551233e0608baa8778c10a6fdd462`.
- URL: https://i-club-ooxnejmos-jasurbeks-projects-c5451f97.vercel.app/
- QA acceptance: GitHub Actions `38751755387` GREEN, including image loading, real Home/Study route, Practice/Tours blackout and 320/390/1280 px visual containment.
- Production Global AI **OFF**; independent Mathematics Tutor and all learner progress preserved.

## Next academic milestone

Keep QA illustration separate from actual tutoring. Approved icon does not imply verified academic source or ready AI answer. Next target: separately authorised, source-versioned RU/UZ/EN `practice_error` after JWT-bound verified V4 completion; synthetic CI remains insufficient to claim production readiness.
