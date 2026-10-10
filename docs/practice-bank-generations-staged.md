# Practice bank generations — all subjects

Design gate only; do not apply schema changes to production.

Every subject starts at generation 1. Only an explicit, audited full bank replacement activates generation 2. Later replacements increment the generation; routine question corrections do not.

Capture generation on the server when the Practice session starts, not at completion. Keep it immutable across bank switches and retries. Recommendations inherit generation only from a verified originating session, never from a client-provided value or the recommendation timestamp. Existing unlinked recommendations remain unclassified until audited. Tours, certificates and other progress are independent.

Before activation: verify safe-v4 session and recommendation RPCs; create subject-specific generation registry and session/attempt/recommendation linkage in an isolated migration; reconcile historical records with exact publication times; test in-flight sessions, retries, RLS, topic drills, and multiple subjects; only then add read-only active-generation filtering and RU/UZ/EN user notice. Never infer Mathematics publication time from the earliest recommendation.
