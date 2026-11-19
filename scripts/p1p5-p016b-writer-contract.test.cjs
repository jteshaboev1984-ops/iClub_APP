#!/usr/bin/env node
"use strict";
// P0-16B: source/runtime test, no Supabase/production connection or learner data.
// The signed HTTP PostgREST/PG17 test runs separately in the isolated E2E job.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");
const root=path.resolve(__dirname,"..");
const apiSource=fs.readFileSync(path.join(root,"exam-prep/exam-prep-api.js"),"utf8");
const sql=fs.readFileSync(path.join(root,"supabase/candidates/math_p1p5_p016b_writer_contract_v1_dormant.sql"),"utf8");
const build="math-p1p5-p016b-v1";

assert.match(apiSource,/const MATH_WRITER_CONTRACT = "math-p1p5-p016b-v1"/);
assert.match(sql,/writer_min_jwt_iat bigint/);
assert.match(sql,/writer_client_contract text/);
assert.match(sql,/v_iat::bigint<v_min/);
assert.match(sql,/request\.headers/);
assert.match(sql,/CREATE OR REPLACE FUNCTION private\.exam_prep_require_writer_contract_v1/);
assert.match(sql,/record_exam_prep_integrity_event_safe_v1 is an/);
assert.match(sql,/IF private\.exam_prep_writer_contract_current_v1\(\) THEN/);
assert.match(sql,/get_exam_prep_state_safe_v1/);
assert.match(sql,/get_exam_prep_diagnostic_progress_safe_v1/);
assert.match(sql,/get_exam_prep_placement_safe_v1/);
assert(!/\bUPDATE\s+private\.exam_prep_feature_config\b/i.test(sql),
  "A dormant candidate must never activate a cutoff or mutate the feature row");
const writerList=sql.slice(sql.indexOf("FOREACH v_name IN ARRAY ARRAY["),sql.indexOf("] LOOP",sql.indexOf("FOREACH v_name IN ARRAY ARRAY[")));
const names=[...writerList.matchAll(/'([a-z0-9_]+)'/g)].map(m=>m[1]);
assert.equal(names.length,39,"One exact independently reviewed writer list");
assert.equal(new Set(names).size,39,"No duplicate writer route");
assert(names.includes("submit_exam_prep_response_safe_v1"));
assert(names.includes("finish_exam_prep_hybrid_s4_paper_safe_v1"));
assert(names.includes("save_exam_prep_exam_profile_v2"));
assert(names.includes("save_my_exam_prep_weekly_choice_s3_safe_v1"));
assert(!names.includes("record_exam_prep_integrity_event_safe_v1"),
  "Append-only anti-cheat evidence must not be silently blocked");
assert(!names.includes("get_exam_prep_state_safe_v1"),
  "Read projection history must remain accessible to stale tabs");

function element(tag){
  return {tag,id:"",textContent:"",value:"",readOnly:false,rows:0,
    style:{cssText:""},handlers:{},children:[],attributes:{},
    append(...children){this.children.push(...children);},
    setAttribute(name,value){this.attributes[name]=value;},
    addEventListener(name,fn){this.handlers[name]=fn;},
    focus(){this.focused=true;},
    select(){this.selected=true;}};
}
function fixture({stale=false,lang="ru",draft=""}={}){
  const nodes=[],calls=[],events=[];
  const document={
    currentScript:{src:""},documentElement:{lang},
    body:{append(el){nodes.push(el);}},
    getElementById(id){return nodes.find(x=>x.id===id)||null;},
    querySelector(selector){
      if(selector.includes("ep_live_written_answer"))return draft?{value:draft}:null;
      return null;
    },
    createElement:element
  };
  const win={
    iClubExamPrepHostInternal:{},i18n:{getLang:()=>lang},
    sb:{rpc(name,args){
      const req={headers:{"x-client-info":"supabase-js-web/2"},then(resolve,reject){
        calls.push({name,args,headers:{...req.headers}});
        const result=stale?
          {data:null,error:{code:"42501",message:"exam_prep_writer_contract_stale"}}:
          {data:{ok:true},error:null};
        return Promise.resolve(result).then(resolve,reject);
      }};
      return req;
    }},
    navigator:{clipboard:{async writeText(value){win.copied=value;}}},
    location:{reload(){win.reloads++;}},
    reloads:0,
    dispatchEvent(event){events.push(event.type);}
  };
  const sandbox={window:win,document,CustomEvent:class{constructor(type,obj){this.type=type;this.detail=obj?.detail;}},setTimeout};
  vm.runInNewContext(apiSource,sandbox,{filename:"exam-prep-api.js"});
  return {win,document,nodes,calls,events,api:win.iClubExamPrepHostInternal.api};
}
(async()=>{
  for(const lang of ["ru","uz","en"]){
    const t=fixture({lang});
    const ok=await t.api.saveExamProfile({examSeries:"June 2027",targetGrade:"A"});
    assert.equal(ok.ok,true,lang+" working client");
    assert.equal(t.calls.length,1);
    assert.equal(t.calls[0].name,"save_exam_prep_exam_profile_v2");
    assert.equal(t.calls[0].headers["x-client-info"],"supabase-js-web/2; iclub.math/"+build,
      "SDK identity is preserved on only this Math request");
    assert.equal(t.win.sb.rest,undefined,"Cannot mutate shared Supabase headers");
    assert.equal(t.nodes.length,0,"No update notice on normal requests");
    assert.equal(t.win.reloads,0,"Never reload automatically");
  }
  for(const lang of ["ru","uz","en"]){
    const t=fixture({stale:true,lang,draft:"my UNsent private solution"});
    const error=await t.api.saveExamProfile({examSeries:"June 2027",targetGrade:"A"});
    assert.equal(error.ok,false);
    assert.equal(error.reason,"client_update_required");
    assert(t.events.includes("iclub:exam-prep-update-required"));
    assert.equal(t.nodes.length,1,"Exactly one accessible update dialog");
    assert.equal(t.nodes[0].attributes.role,"alertdialog");
    const card=t.nodes[0].children[0];
    const saved=card.children.find(x=>x.tag==="textarea");
    assert.equal(saved.value,"my UNsent private solution");
    assert.equal(saved.readOnly,true,"Unsent answer visible, never erased or rewritten");
    assert.equal(t.win.reloads,0,"No unsafe reload before user action");
    const copy=card.children.find(x=>x.tag==="button" && x!==card.children.at(-1));
    await copy.handlers.click();
    assert.equal(t.win.copied,saved.value,"Copy is a deliberate user gesture");
    // Retry on a stale tab must not multiply overlays or clear the draft.
    await t.api.saveExamProfile({examSeries:"June 2027",targetGrade:"A"});
    assert.equal(t.nodes.length,1,"One notice after multiple errors");
    assert.equal(t.win.reloads,0,"No auto retry/reload on stale token");
  }
  // Real host replaces some assessment forms with a loading screen before
  // PostgREST returns. Verify the exact rejected answer remains copyable
  // without any input still attached to the document.
  for(const lang of ["ru","uz","en"]){
    for(const [name,call,expected] of [
      ["written",t=>t.api.submitResponse("session",1,{artifact:{text:"Unsent written proof"}}, "retry-key",15,lang),"Unsent written proof"],
      ["input",t=>t.api.submitResponse("session",2,{answer:"x²+1"}, "retry-key",15,lang),"x²+1"],
      ["mcq",t=>t.api.submitResponse("session",3,{picked_index:2}, "retry-key",15,lang),"MCQ option #3"],
      ["extra-hard",t=>t.api.extraHardSubmit("attempt","Original written explanation","key",lang),"Original written explanation"]
    ]){
      const t=fixture({stale:true,lang,draft:""});
      assert.equal(t.document.querySelector('textarea[name="ep_live_written_answer"]'),null,
        "The input really must be absent in this regression");
      const denied=await call(t);
      assert.equal(denied.reason,"client_update_required",name+" rejection");
      assert.equal(t.nodes.length,1,"One accessible notice "+lang+"/"+name);
      const saved=t.nodes[0].children[0].children.find(x=>x.tag==="textarea");
      assert.equal(saved?.value,expected,"Copy EXACT rejected payload "+lang+"/"+name);
      assert.equal(saved.readOnly,true);
      assert.equal(t.win.reloads,0);
      const buttons=t.nodes[0].children[0].children.filter(x=>x.tag==="button");
      await buttons[0].handlers.click();
      assert.equal(t.win.copied,expected,"Copy before manual refresh");
    }
  }
  // Profile-only errors must not serialize server IDs or exam metadata into
  // the rescue textarea. No unsent answer was present in this scenario.
  const noDraft=fixture({stale:true,lang:"en"});
  await noDraft.api.saveExamProfile({examSeries:"June 2027",targetGrade:"A"});
  assert(!noDraft.nodes[0].children[0].children.some(x=>x.tag==="textarea"),
    "Never expose unrelated RPC payloads as rejected answers");
  console.log("P0-16B PASS: signed writer source, RU/UZ/EN marker, current and removed-form draft rescue, MCQ, written and Extra Hard");
})().catch(e=>{console.error(e);process.exitCode=1;});
