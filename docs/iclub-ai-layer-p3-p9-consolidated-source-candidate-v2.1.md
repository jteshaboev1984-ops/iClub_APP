# iClub AI Master Plan v2.1 — §43 consolidation / no circles

## Concrete consolidated deliverable
The single `qa/ai-layer-v21-preview-assembly.cjs` takes the **actual** app.js and index.html from GitHub, installs exactly three explicit hooks into temporary copies, and **never changes the source**: Practice navigation, server-finalized Practice result (V4 session), and server-reviewed question rendering. Source anchors must be unique; any drift aborts the build. The temporary assembled copies are destroyed after SHA verification. The browser entry is QA-flagged and contains no direct new network service.

`qa/ai-layer-v21-preview-glue.cjs` joins prior exact EvidencePublisher to the real Practice events; an old Practice attempt ID never masquerades as a V4 session. A failed/empty/changed review denies selection and navigation revokes the ephemeral proof. Student progress remains owned by existing deterministic Core.

**The assembled candidate is not deployed, not connected to v2 /context or /answer, and cannot establish live student authorization.** The existing video screen currently changes a selected lesson ID to a subject's first lesson to open a Telegram group, so true per-lesson AI stays blocked until an actual dedicated lesson UX is approved. The AI symbol is pending owner decision.

## GO / NO-GO
Internal synthetic assembly and SQL/security/browser tests: check CI separately. Protected live-like Preview: **NO-GO until one specifically authorized deploy** of the complete synthetic UI package, verified protected target, safe no-new-AI-write connection and valid QA auth context. Master Plan §10 explicitly allows the existing protected Preview with **synthetic UI only** and does not require a second cloud Supabase.

NEXT: stop accumulating independent bridge stages. Request owner authorization for the specific Preview milestone; then perform one actual protected UI acceptance, not a paid model or student rollout.