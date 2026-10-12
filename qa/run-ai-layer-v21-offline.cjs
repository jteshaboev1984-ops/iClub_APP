// Run from repository root: node qa/run-ai-layer-v21-offline.cjs
// Local-only and GitHub Actions friendly: never calls Vercel, Supabase or provider.
"use strict";
const { spawnSync } = require("node:child_process");
const { join } = require("node:path");
const { existsSync } = require("node:fs");
const root = join(__dirname, "..");
const cases = [
 "qa/ai-layer-v21-preview-gateway.test.cjs",
 "qa/ai-layer-v21-authority-gate.test.cjs",
 "qa/ai-layer-v21-readiness-registry.test.cjs",
 "qa/ai-layer-v21-synthetic-pipeline.test.cjs",
 "qa/ai-layer-v21-interface-guard.test.cjs",
 "qa/ai-layer-v21-sql-draft.test.cjs",
 "qa/ai-layer-v21-math-frozen-parity.test.cjs",
 "qa/ai-layer-v21-math-tutor-bridge.test.cjs",
 "qa/ai-layer-v21-math-source-catalog.test.cjs",
 "qa/ai-layer-v21-reply-receipts.test.cjs",
 "qa/ai-layer-v21-request-delivery.test.cjs",
 "qa/ai-layer-v21-math-source-rpc-bridge.test.cjs",
 "qa/ai-layer-v21-server-context-existing-db.test.cjs"
];
for (const file of cases) {
 if (!existsSync(join(root,file))) {
  console.error("MISSING offline test:",file);
  process.exit(2);
 }
}
const r = spawnSync(process.execPath, ["--test",...cases],{
 cwd:root,stdio:"inherit",env:{PATH:process.env.PATH||"",HOME:process.env.HOME||""}
});
if (r.error) {console.error(r.error.message);process.exit(3);}
if (r.status !== 0) process.exit(r.status||1);
const smoke = spawnSync(process.execPath, ["qa/ai-layer-metering-v21.synthetic.js"],{
 cwd:root,stdio:"inherit",env:{PATH:process.env.PATH||"",HOME:process.env.HOME||""}
});
if (smoke.error) {console.error(smoke.error.message);process.exit(4);}
if (smoke.status !== 0) process.exit(smoke.status||1);
// Preserve existing subject-isolation regression (Economics/Informatics must NOT open P1/P5).
const isolation=spawnSync(process.execPath, ["scripts/exam-prep-subject-isolation-regression.cjs"],{
 cwd:root,stdio:"inherit",env:{PATH:process.env.PATH||"",HOME:process.env.HOME||""}
});
if (isolation.error){console.error(isolation.error.message);process.exit(5);}
process.exit(isolation.status||0);
