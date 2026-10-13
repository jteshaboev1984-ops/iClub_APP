# P9 — Single protected synthetic Vercel Preview candidate

**Architect approved ONE protected Preview.** Prepare a static file-only deployment of synthetic HTML, real checked-in Global AI shell CSS/JS, and exact QA V2 transport/screen binder/evidence publisher/glue. The static app must not import the original app.js, Supabase SDK, actual user sessions, service credentials, external fonts, iframe, analytics or network APIs.

Vercel project `i-club-app` has `ssoProtection.enabled=true`, deployment type `all_except_custom_domains`. A generated `*.vercel.app` preview URL is protected by Vercel team SSO. Never attach custom domains, change production, change account-wide protection or mint shareable bypass URLs.

UI acceptance uses Home -> Practice quiz (AI completely hidden) -> result -> review -> one verified question -> shared iClub AI shell -> prepared synthetic short explanation. Real V2 QA client posts to a deterministic **in-memory function** pretending to be `/context` and `/answer`, with a fake bearer string. No HTTP requests. Both marks and state should disappear on navigation and protected assessment; no student data or real billing. Global AI v1 shell is used for actual visual geometry and receives adapted QA results; this is NOT the final v2 production cutover.

Education-facing RU, UZ and EN copy has synthetic fixture disclaimer. Lesson-specific video tutoring remains disabled because current iClub subject-wide Telegram video cannot establish a unique lesson identity. The AI icon uses a temporary text `i` in this preview, not a final approved firm logo.

Before ONE Vercel deployment: full offline Node/Deno/PostgreSQL/Chromium CI success on this exact candidate commit. During deployment: set `target=preview`, specify project ID, include only static files listed above, never `gitSource` of app, never `production`. Verify resulting deployment target=preview, state READY, URL, SSO and no production alias; no UI use of live services.

**No automatic release to beta or students**. Preview validates synthetic UX only and does not prove real Supabase integration. Owner must approve any later release separately.