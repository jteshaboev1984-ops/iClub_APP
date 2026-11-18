#!/usr/bin/env node
"use strict";
/**
 * Issue #450: execute the real source openReadiness branch in a narrow
 * source-function harness. THIS IS NOT a browser/authenticated E2E test.
 * The separately run PG17/JWT/PostgREST/Chromium workflow proves server gates.
 * Never display the legacy comparable-Paper view on an RPC failure.
 */
const fs=require("node:fs");
const assert=require("node:assert/strict");
const source=fs.readFileSync("exam-prep/exam-prep-live.js","utf8");
const start="  async function openReadiness(component) {";
const stop="  function renderOperationalReadiness(component, status, calibration) {";
assert.equal(source.split(start).length,2,"exact single source function");
assert.equal(source.split(stop).length,2,"exact single following render function");
const from=source.indexOf(start),to=source.indexOf(stop,from);
assert(from>=0&&to>from,"readiness must precede operational renderer");
const body=source.slice(from,to);
const make=new Function("internal","clearTimer","renderLoading","renderError",
  "renderOperationalReadiness","renderReadiness","normalizeReadiness",
  body+"\nreturn openReadiness;");
async function check(name,status,expected,opts={}){
 const trace=[];
 const internal={api:{
   hybridS4StageStatus:opts.missing?undefined:async()=> {
     trace.push("hybrid"); if(opts.throwStatus) throw new Error("network");
     return status;
   },
   readinessSummary:async()=> {trace.push("legacy");return{ok:true,data:{p1_p5_separate:true}};},
   readiness:async()=> {throw Error("deprecated readiness fallback");},
   finalCalibration:async()=> {trace.push("calibration");return{ok:true,data:{available:false}};}
 }};
 const open=make(internal,()=>trace.push("clear"),
   (...args)=>trace.push("loading:"+args.join("/")),
   ()=>trace.push("error"),
   (...args)=>trace.push("operational:"+args[0]),
   (...args)=>trace.push("legacy-view:"+args[0]),
   x=>x);
 await open("P1");
 for(const x of expected)assert(trace.includes(x),name+" missing "+x+" "+trace);
 for(const bad of opts.absent||[])assert(!trace.includes(bad),name+" unexpected "+bad+" "+trace);
}
async function run(){
 const blocked={absent:["legacy","legacy-view:P1","operational:P1","calibration"]};
 await check("RPC 503",{ok:false,reason:"unavailable"},["error"],blocked);
 await check("RPC network throw",null,["error"],{...blocked,throwStatus:true});
 await check("missing service",null,["error"],{...blocked,missing:true});
 await check("missing enabled",{ok:true,data:{}},["error"],blocked);
 await check("string enabled",{ok:true,data:{enabled:"false"}},["error"],blocked);
 await check("flag explicitly OFF",{ok:true,data:{enabled:false}},
   ["legacy","legacy-view:P1"],{absent:["error","operational:P1"]});
 await check("flag explicitly ON",{ok:true,data:{enabled:true}},
   ["calibration","operational:P1"],{absent:["error","legacy","legacy-view:P1"]});
 console.log("PASS source-function: erroneous/ambiguous Stage3-6 is fail-closed; explicit OFF preserves legacy; ON uses objective stage only.");
}
run().catch(e=>{console.error(e.stack||e);process.exitCode=1;});
