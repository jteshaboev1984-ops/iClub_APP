# iClub AI v2.1 — §53–55 offline P6 editorial integrity & safety hardening

**Date:** 2026-10-14. **Worktree:** `qa/iclub-ai-layer-v21-20261012`. **Status:** offline QA only. **Global AI:** NO-GO.

## §53 — Three-locale prepared response packet for independent editors

The QA draft of 18 navigational replies is derived from the existing iClub HTML, routing handlers and RU/UZ/EN literal labels. `qa/ai-layer-v21-p6-editorial-source-packet.cjs` creates only three **unpublished candidate payloads**, one per language, with the exact six prepared variants per locale. It has no importer, signing key, database access, write permission or provider route. Every packet is explicitly `ready=false`, `releaseAllowed=false`, `rightsApproved=false`, `contentApproved=false` and `publicationState='draft'`.

The packet's SHA-256 `draftFingerprint` is only a local editorial-diff checksum of the exact candidate text and locale. **It is NOT the PostgreSQL publication `source_hash`**, which requires `source_text || LF || jsonb::text`, a separate canonical payload and independent approval. It is never used as an attestation or proof to grant access.

Strict validators deny missing locale text, unexpected navigation actions, wrong starting screen, modified selectors, changed route kind, duplicate route, unauthorized approval flag or missing editorial reviews. No translation is silently inferred from another language. The original drafts are not mutated or promoted. This enables copy review without falsely claiming publication.

For later independent review, **content/language/UX accessibility** must confirm each of these six paths in RU/UZ/EN, while security/release/rights reviewers must verify versioned signed payloads and the existing independent publication gate. Specifically, About opens from Home through the existing “About project” English entry button, and Support opens from Profile. These are factual routes, not an approved recommendation algorithm.

## §54 — Immutable, rechecked Home plan proposal

`qa/ai-layer-v21-p6-home-next-action-proof.cjs` remains **not wired** into the Edge, SQL or UI. It cannot rank, create or display student next actions. Its original technical proposal required a current Home handle, backend owner, separate signed planner result, per-action independent academic evidence, locale release and rechecked screen.

The §54 hardening adds a **pre-async immutable plan snapshot**, re-reads the exact plan after the first checks, revalidates the planner's authority, then revalidates *each* academic evidence hash/revision and editorial source hash/version. A final screen/TTL reread follows the second pass. The extra tests deny plan priority/version/hash changes, revocation of any one of the three independent proof domains, and mutation of a shared plan object while awaiting a backend response. These tests use synthetic proofs only.

This is still a **candidate admission mechanism**: atomicity across all future independent services is not established. A future real planner must supply a transactionally comparable revision and survive changes during actual response delivery; the UI must rebind and revoke contexts. The three candidate action types are not approved product priorities.

## §55 — Exact prepared-only navigation intent allowlist

The existing **UNAPPLIED** `qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql` already blocked generated General Help. §55 additionally binds General Help to **exactly six** recognized prepared intent keys: `nav_home`, `nav_courses`, `nav_ratings`, `nav_profile`, `nav_about`, and `nav_support`. Any unexpected key (including one present in a signed prepared-variants JSONB) fails closed. The entire route still requires all the pre-existing: owner/current screen, source release, rights, three locale approvals, digest, version, topic, protected-exam state and capability. The scratch PostgreSQL context suite deliberately seeds a synthetic extra key `nav_billing` and asserts that it is denied while a properly reviewed synthetic `nav_about` route continues to work.

**No source is actually published or whitelisted for real learners.** The QA positive fixtures are isolated, synthetic and rolled back. Global AI provider, billing, Vercel, production Supabase, academic records, existing Mathematics Tutor and student progress are not touched.

## Remaining hard NO-GO blockers

1. Sign-off on all 18 actual learner-facing responses including RU, UZ, EN, exact UI path and accessibility. Unreviewed JSON is **not** authorization.
2. A real independent signed release & publisher path, source hashes recomputed using the database's canonical JSONB representation, not editorial draft fingerprints.
3. An architect-approved Home action priority policy, trustworthy cross-subject planner and an end-to-end atomic security model; `home_next_actions` remains denied by the server evidence service.
4. Protected isolated UI/Edge browser flow with real context revision/revoke behavior, content source/locale parity, monetary limits and Mathematics Tutor parity.
5. Explicit owner authorization before any beta cohort, RPC deployment or production release.
