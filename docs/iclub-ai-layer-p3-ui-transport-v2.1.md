# iClub AI v2.1 — §37 browser-to-Edge adapter (QA ONLY)

**Scope:** no new Git branches, PRs, live accounts, migrations, Vercel Preview, paid model, or production code changes. Uses only the existing QA branch.

The current dormant application UI (\`global-ai-ui.js\`) still uses the V1 \`global-ai\` RPC/bootstrap contract. The tested V2 Edge requires different \`/context\` and \`/answer\` routes with a server-minted selector-owned scope. For safety we DO NOT make an automatic partial cutover: it might break the old Mathematics Tutor and could bypass completion/rights gates.

The new isolated \`qa/ai-layer-v21-ui-transport.cjs\` defines the correct learner-side request state machine for a future preview: after fresh JWT retrieval, Lesson sends only its lessonId; Practice sends only finalized sessionId and questionId (server checks actual completion); server returns opaque contextHandle. No browser subject, plan, answer key or academic progress is authoritative. Status is read-only. Answers use a unique requestId and exact locale and source-specific prepared prompt or generated question. On navigation the client drops its handle before remote revoke; late mint/answer results are discarded. Unknown HTTP delivery does not auto-retry and cannot double charge. No localStorage or full conversation persistence.

**Limits:** This is a tested candidate client, not a browser screenshot, deployed UI, real Supabase auth integration or proof of response retention after reload. The server is responsible for JWT verification, source/rollout/rights and exam gate on every operation. Its use in production requires separate owner approval and final RLS/privacy review. No monetization or provider was enabled.
