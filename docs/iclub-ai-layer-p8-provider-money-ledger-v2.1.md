# iClub AI v2.1 — §33 Independent Provider Spend Ledger

**QA-only / UNAPPLIED / production unchanged.** The new server-side ledger tracks provider liability separately from the 1:3 learner allowance. All numbers used by its tests (200 and 80 micro-USD units) are synthetic, not approved provider prices or tariffs.

Money control defaults OFF with zero cap. Neither the learner, service_role nor the content publisher can change the ceiling through a learner RPC. A reserve requires current global release permission, active generation approval, a valid protected-assessment check, the exact already-reserved learner usage and an exclusive first-writer delivery claim. Reserve takes a PostgreSQL advisory lock and counts all pending and unknown money at full maximum exposure, while confirmed invoiced cost counts its bounded actual amount.

A dispatch is permitted once and is rechecked for current protected exam, owner release and kill switch. Money is released only before actual provider dispatch. After dispatch, an ambiguous timeout consumes the full held exposure even if learner quota is refunded. A known cost may be finalized within its worst-case reserved ceiling; over-ceiling billing is not silently accepted. Leases and tombstones have no TTL deletion or reuse.

Native scratch PostgreSQL uses the original v1 runtime table migration, not a competing definition. The QA Deno adapter has fail-closed reserve, dispatch and settlement calls, but the existing budget preflight still returns DENY and synthetic generation is deliberately nonoperational. No live paid provider integration, credential, academic content, production DB write or Vercel deployment was authorized.

Remaining: genuine model pricing and token cap, provider invoicing/reconciliation, distributed edge integration, encrypted short-lived reply recovery, one protected synthetic Preview, owner-controlled beta and tariff sign-off.
