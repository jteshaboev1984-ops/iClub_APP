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
 "qa/ai-layer-v21-sql-draft.test.cjs"
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
process.exit(smoke.status||0);
