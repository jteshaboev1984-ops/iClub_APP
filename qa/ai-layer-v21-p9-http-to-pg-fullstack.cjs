"use strict";
// §120-123: an actual LOCAL HTTP Auth -> Deno Edge -> psql PostgreSQL bridge.
// NO remote Supabase, real JWT, Vercel, provider, or user records.
const {spawn,spawnSync}=require("node:child_process");
const {createServer}=require("node:http");
const {readFileSync,writeFileSync,unlinkSync}=require("node:fs");
const {resolve}=require("node:path");
const {strict:assert}=require("node:assert");
const ROOT=resolve(__dirname,"..");
const DB="iclub_ai_v21_scratch_ci_fullstack";
const TEMPLATE=resolve(ROOT,"qa/sql_drafts/iclub_ai_v21_nine_drafts_integrated_local_pg.psql");
const GENERATED=resolve(ROOT,"qa/sql_drafts/.iclub_ai_v21_http_fullstack_TEMP.psql");
const ORIGIN="https://preview.synthetic.invalid";
const ANON="qa-anon-only-synthetic";
const SERVICE="qa-service-only-synthetic";
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const tokens=new Map([["Bearer qa-local-user-a",A],["Bearer qa-local-user-b",B]]);
const revoked=new Set();
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
let server=null,created=false;
function command(program,args,options={}){
 const r=spawnSync(program,args,{cwd:ROOT,encoding:"utf8",timeout:60000,
  env:{...process.env,PGAPPNAME:"iclub_ai_v21_local_scratch",PGPASSWORD:process.env.PGPASSWORD||"synthetic-only",PGCONNECT_TIMEOUT:"5"},...options});
 if(r.status!==0)throw Error(program+" failed: "+String(r.stderr||r.error).slice(-1300));
 return r.stdout.trim();
}
const pgArgs=()=>["-h","127.0.0.1","-p",process.env.ICLUB_QA_PG_PORT||"5432","-U","postgres"];
function sql(query){
 const result=command("psql",[...pgArgs(),"-X","-q","-t","-A","-v","ON_ERROR_STOP=1","-d",DB,"-c",query]);
 return result.split(/\r?\n/).map(x=>x.trim()).filter(Boolean).at(-1)||"";
}
function pgRpc(name,args){
 const rules={
  mint_iclub_ai_v21_practice_context_service:["p_user_id","p_session_id","p_question_id"],
  mint_iclub_ai_v21_tour_archive_context_service:["p_user_id","p_attempt_id"],
  get_iclub_ai_v21_scoped_context_service:["p_user_id","p_context_handle"],
  revoke_iclub_ai_v21_scoped_context_service:["p_user_id","p_context_handle"],
  get_iclub_ai_v21_runtime_service:[],
  get_iclub_ai_v21_provider_budget_service:["p_user_id","p_source_id","p_route_class"]
 };
 const keys=rules[name];
 if(!keys||Object.keys(args).length!==keys.length||
   keys.some(key=>!Object.prototype.hasOwnProperty.call(args,key)))return null;
 const list=keys.map(key=>{
  const value=args[key];
  if(key==="p_user_id"||key==="p_context_handle"){
   if(typeof value!=="string"||!UUID.test(value))throw Error("invalid UUID");
   return "'"+value+"'"+(key==="p_user_id"?"::uuid":"::text");
  }
  if(key==="p_session_id"||key==="p_question_id"||key==="p_attempt_id"){
   if(!Number.isSafeInteger(value)||value<=0)throw Error("invalid selector");
   return String(value)+"::bigint";
  }
  if(typeof value!=="string"||!/^[-_a-z0-9]{1,64}$/.test(value))
   throw Error("invalid text");
  return "'"+value+"'::text";
 });
 return JSON.parse(sql("SET ROLE service_role; SELECT public."+name+"("+list.join(",")+")::text;"));
}
function respond(res,status,obj){
 const body=JSON.stringify(obj);
 res.writeHead(status,{"content-type":"application/json","cache-control":"no-store",
  "content-length":Buffer.byteLength(body)});
 res.end(body);
}
async function handle(req,res){
 try{
  if(req.socket.remoteAddress!=="127.0.0.1"&&req.socket.remoteAddress!=="::ffff:127.0.0.1")
   return respond(res,403,{error:"localhost_only"});
  const chunks=[];let size=0;
  for await(const part of req){
   size+=part.length;if(size>4096)return respond(res,413,{error:"too_large"});
   chunks.push(part);
  }
  const input=Buffer.concat(chunks).toString("utf8");
  const path=new URL(req.url,"http://127.0.0.1").pathname;
  const api=req.headers.apikey,auth=req.headers.authorization;
  if(path==="/auth/v1/user"){
   if(req.method!=="GET"||api!==ANON)return respond(res,403,{error:"auth_api_key"});
   const uid=tokens.get(auth);
   return uid&&!revoked.has(auth)?
    respond(res,200,{id:uid,role:"authenticated"}):
    respond(res,401,{error:"invalid_token"});
  }
  if(path==="/__qa/control"){
   if(req.method!=="POST"||req.headers["x-qa-local-control"]!=="synthetic-control-secret")
    return respond(res,403,{error:"control_denied"});
   const body=JSON.parse(input);
   if(body.action==="revoke_a"){revoked.add("Bearer qa-local-user-a");return respond(res,200,{ok:true});}
   if(body.action==="unenroll_a"){
    sql("DELETE FROM public.user_subjects WHERE user_id='"+A+"'::uuid;");
    return respond(res,200,{ok:true});
   }
   if(body.action==="exam_b"){
    sql("UPDATE private.qa_http_protected_assessment SET active=true WHERE user_id='"+B+"'::uuid;");
    return respond(res,200,{ok:true});
   }
   if(body.action==="kill"){
    sql("UPDATE private.iclub_global_ai_runtime_config SET kill_switch=true WHERE id=1;");
    return respond(res,200,{ok:true});
   }
   return respond(res,400,{error:"unrecognized_control"});
  }
  if(path.startsWith("/rest/v1/rpc/")){
   if(req.method!=="POST"||api!==SERVICE||auth!=="Bearer "+SERVICE)
    return respond(res,401,{error:"service_role_required"});
   const data=JSON.parse(input);
   if(!data||typeof data!=="object"||Array.isArray(data))
    return respond(res,400,{error:"invalid_rpc_args"});
   const result=pgRpc(path.slice("/rest/v1/rpc/".length),data);
   return result?respond(res,200,result):respond(res,404,{error:"rpc_absent"});
  }
  return respond(res,404,{error:"unknown_api"});
 }catch(err){return respond(res,503,{error:"synthetic_backend_unavailable"});}
}
async function main(){
 if(process.env.CI!=="true"||process.env.ICLUB_QA_ALLOW_FULLSTACK!=="synthetic-only")
  throw Error("§120 local HTTP integration only in explicitly authorized QA CI");
 assert(!process.env.SUPABASE_URL||!process.env.SUPABASE_URL.includes("supabase.co"),
  "No production backend environment allowed");
 const fixture=readFileSync(TEMPLATE,"utf8");
 const marker="\\ir iclub_ai_v21_two_owner_proof_LOCAL_ONLY.psql";
 const index=fixture.indexOf(marker);
 if(index<0||fixture.indexOf(marker,index+marker.length)>=0)
  throw Error("Integrated SQL source changed: cannot extract safe 10-draft setup");
 const prepared=fixture.slice(0,index)+
   "\\ir iclub_ai_v21_http_owner_seed_LOCAL_ONLY.psql\nCOMMIT;\n";
 assert(prepared.includes("BEGIN;")&&prepared.includes("iclub_ai_v21_real_schema_screen_proof_UNAPPLIED.sql"));
 writeFileSync(GENERATED,prepared,{flag:"wx",mode:0o600});
 command("createdb",[...pgArgs(),DB]);created=true;
 command("psql",[...pgArgs(),"-X","-v","ON_ERROR_STOP=1","-d",DB,"-f",GENERATED]);
 assert.equal(sql("SELECT count(*) FROM public.practice_session_answers_v4;"),"2");
 server=createServer((req,res)=>{handle(req,res);});
 await new Promise((resolve,reject)=>server.listen(0,"127.0.0.1",err=>err?reject(err):resolve()));
 const port=server.address().port;
 const env={...process.env,
  ICLUB_QA_BACKEND_URL:"http://127.0.0.1:"+port,
  ICLUB_QA_ANON:ANON,ICLUB_QA_ROLE:SERVICE,ICLUB_QA_ORIGIN:ORIGIN};
 const child=spawn("deno",["test","--no-check","--allow-net=127.0.0.1",
  "--allow-env=ICLUB_QA_BACKEND_URL,ICLUB_QA_ANON,ICLUB_QA_ROLE,ICLUB_QA_ORIGIN",
  "qa/edge_v21/qa_local_pg_http_test.ts"],
  {cwd:ROOT,env,stdio:"inherit"});
 const code=await new Promise((resolve,reject)=>{child.on("error",reject);child.on("exit",resolve);});
 if(code!==0)throw Error("Deno/real PostgreSQL HTTP tests failed, code "+code);
 assert.equal(sql("SELECT count(*) FROM public.practice_session_answers_v4;"),"2");
 assert.equal(sql("SELECT count(*) FROM public.tour_attempts;"),"2");
 assert.equal(sql("SELECT kill_switch::text FROM private.iclub_global_ai_runtime_config WHERE id=1;"),"true");
 assert.equal(sql("SELECT count(*) FROM private.iclub_ai_v21_release_control WHERE release_approved;"),"0");
 console.log("AUTH_TO_REAL_PG_GREEN: two users, revocations, live SQL, zero provider, academic evidence preserved");
}
(async()=>{let failure=null;
 try{await main();}catch(e){failure=e;console.error("QA fullstack failed:",e.message);}
 finally{
  if(server)await new Promise(resolve=>server.close(resolve));
  if(created)try{command("dropdb",[...pgArgs(),"--force",DB]);}
   catch(e){console.error("FAILED TO DROP QA SCRATCH DB",e.message);failure??=e;}
  try{unlinkSync(GENERATED);}catch(e){console.error("FAILED TO REMOVE QA SQL TEMP",e.message);failure??=e;}
 }
 if(failure)process.exitCode=1;
})();
