# iClub AI v2.1 — §34 Cross-worker Budget and Encrypted Reply Recovery

**2026-10-13. UNAPPLIED QA ONLY.** No new commercial policy, source content, production writes or deployments.

## Cross-worker money race
The new QA-only script creates two synthetic generated requests and runs two independent PostgreSQL transactions against ONE total cap. A transaction-level global advisory lock in the existing §33 money SQL must allow exactly one money lease, deny the second, and preserve the entire cap. A real provider is never contacted. This is stronger than testing two promises inside one Node process.

## Encrypted reply recovery candidate
The earlier temporary response receipt stored a plaintext reply in a single server process and could not recover after an Edge restart. The §34 Node prototype accepts injected shared rows and a backend-managed AES-256-GCM keyring. Its encrypted envelope stores only request ID, hashed full identity (user, session, request fingerprint, source hash, revision, locale, route), ciphertext, nonce, authentication tag, key reference and expiry. It stores neither prompt nor transcript or learner identifiers in cleartext in the record.

The prototype uses the existing 120-second QA TTL, without introducing a production retention rule. It enforces a verified **completed** quota+delivery transaction before saving and again on recovery. Recovery also requires a separate **fresh authoritative** server recheck, expected to include the original authenticated user, current subject, protected assessment, source publication/revocation, session and rollout. A missing/throwing check, wrong user/source/session/locale, corrupted ciphertext, missing key or expired row always denies. No paid model is called on retrieval, and repeated request IDs cannot overwrite a receipt.

Test-only crypto keys are freshly generated in memory, never placed in the repository. The shared Map is a **synthetic stand-in**, not persistent cross-worker DB storage. Therefore these tests DO NOT mean real lost replies can yet be recovered after server restart. For an approved production implementation, a securely provisioned external key vault, database RLS, real durable encrypted record, atomicity with quota settlement, cleanup/retention, revocation and incident handling must be reviewed and approved first. Until then the existing §31 preflight and missing RPCs keep Global AI provider calls blocked.

## Guardrails
No production, main, real Supabase writes, Vercel preview/deployments, actual AI model, academic text or existing Mathematics P1/P5 code were changed.
