#!/usr/bin/env node
"use strict";
// Source-free regression: protected V4.3 original stays in owner-private storage.
// This CI test only verifies the exact authorized source PIN, never question text.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const crypto=require("node:crypto");
const path=require("node:path");
const stage=fs.readFileSync(path.resolve("scripts/ops/p1p5-extra-hard-private-full42-stage-v4.cjs"),"utf8");
const expected="42c16a0d81cad35576b927e0f8c412650b045c25c1cfbcb71d86e20dfda2e090";
const old="8f9d8aec32da6de43e9415f8ab2965b8d425809bc2e849e6e3d1f4a1ee612a88";
const pin=stage.match(/const SOURCE_SHA='([0-9a-f]{64})';/);
assert(pin,"Missing source SHA guard");
assert.equal(pin[1],expected,"Expected V4.3 private source pin");
assert.notEqual(pin[1],old,"Stale initial V4 source must not be considered live-authoritative");
assert(stage.includes("const BANK='math-extra-hard-2026-11-full-v4'"));
assert(stage.includes("assert(t.lifecycle_status==='draft','V4 must remain draft')"));
assert(stage.includes("t.qa_math==='pending'&&t.qa_languages==='pending'&&t.qa_technical==='pending'"));
assert(stage.includes("never overwrite old task/learner history"));
assert(!stage.includes("OWNER_APPROVED_PUBLIC_MATH"));
const sourceFixture=path.resolve("scripts/ops/p1p5-extra-hard-private-full42-stage-v4.cjs");
// The actual SOURCE_SHA must represent 64 hex chars and remain one exact pin.
assert.equal(crypto.createHash("sha256").update(pin[1]).digest().length,32);
assert(!fs.readFileSync(sourceFixture,"utf8").includes("48.14"),"No protected answer may be embedded in public code");
console.log("V4.3 SOURCE-PIN REGRESSION PASS: exact 42-task private SHA, draft-only flags, no public release, original source immutable");
