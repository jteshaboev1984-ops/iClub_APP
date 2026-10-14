import {makeContextCore} from "./context_core.ts";
import {makeHttpHandler} from "./http.ts";
const U="11111111-1111-4111-8111-111111111111";
const H="33333333-3333-4333-8333-333333333333";
const origin="https://preview.synthetic.invalid";
function assert(v:boolean){if(!v)throw new Error("context QA failed");}
function fixture(){
 let mints=0,revokes=0,userid=U,throwMint=false;
 const services={
  authenticate:async(t:string)=>t==="Bearer synthetic-test-token"?{authenticated:true,userId:userid}:null,
  mintScopedContext:async(a:{userId:string;sessionId:number;questionId:number})=>{
   mints++;if(throwMint)throw new Error("private DB error");
   return{allowed:a.userId===U,context_handle:H,expires_in_seconds:90};
  },
  mintLessonContext:async(a:{userId:string;lessonId:number})=>{
   mints++;if(throwMint)throw new Error("private DB error");
   return{allowed:a.userId===U&&a.lessonId>0,
    context_handle:H,expires_in_seconds:90};
  },
  mintTourArchiveContext:async(a:{userId:string;attemptId:number})=>{
   mints++;if(throwMint)throw new Error("private DB error");
   return{allowed:a.userId===U&&a.attemptId===401,
    context_handle:H,expires_in_seconds:90};
  },
  revokeScopedContext:async(a:{userId:string;contextHandle:string})=>{
   revokes++;return{ok:a.userId===U&&a.contextHandle===H};
  }
 };
 const h=makeHttpHandler(makeContextCore(services),[origin]);
 const send=async(b:object,extra:{origin?:string;token?:string}={})=>{
  const response=await h(new Request("https://preview.synthetic.invalid/context",{
   method:"POST",headers:{"origin":extra.origin??origin,"content-type":"application/json",
     authorization:extra.token??"Bearer synthetic-test-token"},body:JSON.stringify(b)
  }));
  return{status:response.status,data:await response.json()};
 };
 return{send,counts:()=>[mints,revokes],badMint:()=>{throwMint=true},
  switchUser:()=>{userid="22222222-2222-4222-8222-222222222222"}};
}
Deno.test("Mint only verified owner, not browser content",async()=>{
 const x=fixture();const r=await x.send({action:"mint",sessionId:12,questionId:43});
 assert(r.status===200&&r.data.contextHandle===H&&r.data.ok===true);
 assert(x.counts()[0]===1);
});
Deno.test("Subject and plan forgery blocked before service role RPC",async()=>{
 const x=fixture();
 for(const field of ["subject","topic","plan","sourceId","userId"]){
  const r=await x.send({action:"mint",sessionId:12,questionId:43,[field]:"fake"});
  assert(r.status===400);
 }
 assert(x.counts()[0]===0);
});
Deno.test("Invalid request selectors fail closed",async()=>{
 const x=fixture();
 for(const data of [{sessionId:-1,questionId:1},{sessionId:1,questionId:0},
  {sessionId:1.5,questionId:2},{sessionId:"1",questionId:2}]){
  const r=await x.send({action:"mint",...data});assert(r.status===400);
 }
 assert(x.counts()[0]===0);
});
Deno.test("Wrong origin and missing authorization never reach RPC",async()=>{
 const x=fixture();
 assert((await x.send({action:"mint",sessionId:1,questionId:2},
  {origin:"https://invalid.example"})).status===403);
 assert((await x.send({action:"mint",sessionId:1,questionId:2},
  {token:"Bearer expired-synthetic"})).status===401);
 assert(x.counts()[0]===0);
});
Deno.test("Unavailable backend cannot leak exception",async()=>{
 const x=fixture();x.badMint();
 const r=await x.send({action:"mint",sessionId:12,questionId:43});
 assert(r.status===503&&!JSON.stringify(r.data).includes("private DB"));
});
Deno.test("Owner can revoke context but foreign user cannot",async()=>{
 const x=fixture();assert((await x.send({action:"revoke",contextHandle:H})).data.ok===true);
 x.switchUser();assert((await x.send({action:"revoke",contextHandle:H})).data.ok===false);
 assert(x.counts()[1]===2);
});
Deno.test("Malformed revoke cannot call privileged service",async()=>{
 const x=fixture();
 for(const arg of [{action:"revoke",contextHandle:"bad"},
  {action:"revoke",contextHandle:H,sessionId:1}]){
  assert((await x.send(arg)).status===400);
 }
 assert(x.counts()[1]===0);
});

Deno.test("Lesson mint works for enrolled student only with verified lesson ID",async()=>{
 const x=fixture();
 const r=await x.send({action:"mintLesson",lessonId:47});
 assert(r.status===200&&r.data.ok===true&&r.data.contextHandle===H);
 assert(x.counts()[0]===1);
});
Deno.test("Lesson context refuses foreign subject, guessed topic and forged progress",async()=>{
 for(const key of ["subject","topic","sourceId","userId","plan","sessionId","questionId"]){
  const x=fixture(),r=await x.send({action:"mintLesson",lessonId:47,[key]:"forged"});
  assert(r.status===400&&x.counts()[0]===0);
 }
});
Deno.test("Lesson mint cannot spoof old Practice selectors or malformed lesson IDs",async()=>{
 for(const fields of [
  {action:"mintLesson",lessonId:-1},{action:"mintLesson",lessonId:0},
  {action:"mintLesson",lessonId:"1"},{action:"mintLesson",lessonId:1.5},
  {action:"mint",lessonId:2,sessionId:1,questionId:1}
 ]){
  const x=fixture();assert((await x.send(fields)).status===400);
  assert(x.counts()[0]===0);
 }
});

Deno.test("Opened Tour is the same protected /context lifecycle, not a new AI",async()=>{
 const x=fixture(),r=await x.send({action:"mintTourArchive",tourAttemptId:401});
 assert(r.status===200&&r.data.ok===true&&r.data.contextHandle===H);
 assert(x.counts()[0]===1);
 assert((await x.send({action:"revoke",contextHandle:H})).data.ok===true);
});
Deno.test("Tour selector cannot impersonate user, topic, answer, plan or legacy Practice",async()=>{
 for(const x of [
  {action:"mintTourArchive",tourAttemptId:0},
  {action:"mintTourArchive",tourAttemptId:"401"},
  {action:"mintTourArchive",tourAttemptId:401.5},
  {action:"mintTourArchive",tourAttemptId:401,sessionId:8},
  {action:"mintTourArchive",tourAttemptId:401,lessonId:2},
  {action:"mintTourArchive",tourAttemptId:401,subject:"economics"},
  {action:"mintTourArchive",tourAttemptId:401,topic:"guessed"},
  {action:"mintTourArchive",tourAttemptId:401,plan:"plus"},
  {action:"mintTourArchive",tourAttemptId:401,userId:U}
 ]){
  const t=fixture();assert((await t.send(x)).status===400&&t.counts()[0]===0);
 }
 const t=fixture(),r=await t.send({action:"mintTourArchive",tourAttemptId:402});
 assert(r.data.ok===false);
}
