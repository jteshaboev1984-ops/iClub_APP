"use strict";
/**
 * QA ONLY: real loopback HTTP + Auth identity shim + disposable PostgreSQL.
 * Never accepts a hosted backend, production credentials or live learner data.
 * Verifies the proposed resolver RPC against synthetic student records.
 */
const {spawn,spawnSync}=require("node:child_process");
const {createServer}=require("node:http");
const {readFileSync,writeFileSync,unlinkSync}=require("node:fs");
const {resolve}=require("node:path");
const assert=require("node:assert/strict");
const ROOT=resolve(__dirname,"..");
const DB="iclub_ai_v21_scratch_ci_resolver_http";
const ROOT_SQL=resolve(ROOT,"qa/sql_drafts");
const TEMPLATE=resolve(ROOT_SQL,"iclub_ai_v21_practice_attempt_resolution_local_pg.psql");
const GENERATED=resolve(ROOT_SQL,".iclub_ai_v21_practice_resolver_HTTP_TEMP.psql");
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const ANON="synthetic-resolver-anon";
const ROLE="synthetic-resolver-service";
const ORIGIN="https://preview.synthetic.invalid";
let server=null,created=false,generated=false;
function command(program,args){
 const result=spawnSync(program,args,{
  cwd:ROOT,encoding:"utf8",timeout:60000,
  env:{...process.env,PGAPPNAME:"iclub_ai_v21_local_scratch",
   PGCONNECT_TIMEOUT:"5"}
 });
 if(result.status!==0)
  throw Error(program+" failed: "+String(result.stderr||result.error).slice(-1200));
 return result.stdout.trim();
}
const pgArgs=()=>["-h","127.0.0.1","-p","5432","-U","postgres"];
function sql(statement){
 const raw=command("psql",[...pgArgs(),"-X","-q","-t","-A","-v","ON_ERROR_STOP=1",
  "-d",DB,"-c",statement]);
 return raw.split(/\r?\n/).map(x=>x.trim()).filter(Boolean).at(-1)||"";
}
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function postgresResolve(input){
 const names=["p_user_id","p_attempt_reference","p_question_id"];
 if(!input||typeof input!=="object"||Array.isArray(input)||
    Object.keys(input).length!==names.length||
    names.some(x=>!Object.hasOwn(input,x)))return null;
 const {p_user_id:u,p_attempt_reference:attempt,p_question_id:qid}=input;
 if(!UUID.test(u)||![attempt,qid].every(x=>Number.isSafeInteger(x)&&x>0))
  return null;
 // Values are validated numeric + UUID; never interpolates arbitrary strings.
 const row=sql("SET ROLE service_role; SELECT public.resolve_iclub_ai_v21_practice_attempt_service("+
  "'"+u+"'::uuid,"+attempt+"::bigint,"+qid+"::bigint)::text;");
 const data=JSON.parse(row);
 if(!data||typeof data!=="object"||Array.isArray(data))return null;
 return data;
}
function reply(res,status,data){
 const bytes=Buffer.from(JSON.stringify(data),"utf8");
 res.writeHead(status,{"content-type":"application/json","cache-control":"no-store",
  "content-length":bytes.length,"x-content-type-options":"nosniff"});
 res.end(bytes);
}
async function handle(req,res){
 try{
  if(!["127.0.0.1","::ffff:127.0.0.1"].includes(req.socket.remoteAddress))
   return reply(res,403,{error:"localhost_only"});
  if(req.method!=="POST"&&req.method!=="GET")
   return reply(res,405,{error:"method_not_allowed"});
  const parts=[];let length=0;
  for await(const p of req){
   length+=p.length;
   if(length>4096)return reply(res,413,{error:"too_large"});
   parts.push(p);
  }
  const route=new URL(req.url,"http://127.0.0.1").pathname;
  const api=req.headers.apikey;
  const auth=req.headers.authorization;
  if(route==="/auth/v1/user"){
   if(req.method!=="GET"||api!==ANON)
    return reply(res,401,{error:"missing_anon_api_key"});
   if(auth==="Bearer qa-local-user-a")
    return reply(res,200,{id:A,role:"authenticated"});
   if(auth==="Bearer qa-local-user-b")
    return reply(res,200,{id:B,role:"authenticated"});
   return reply(res,401,{error:"invalid_synthetic_identity"});
  }
  if(route==="/__qa/control"){
   if(req.method!=="POST"||req.headers["x-local-qa-test"]!=="only-synthetic")
    return reply(res,403,{error:"local_control_denied"});
   const action=JSON.parse(Buffer.concat(parts).toString("utf8")).action;
   const id="'"+A+"'::uuid";
   const commands={
    protect_a:"DELETE FROM private.qa_protected WHERE user_id="+id+"; INSERT INTO private.qa_protected VALUES("+id+",true);",
    unprotect_a:"DELETE FROM private.qa_protected WHERE user_id="+id+";",
    unenroll_a:"DELETE FROM public.user_subjects WHERE user_id="+id+";",
    reenroll_a:"INSERT INTO public.user_subjects(user_id,subject_id) VALUES("+id+",10);",
    kill:"UPDATE private.iclub_global_ai_runtime_config SET kill_switch=true WHERE id=1;"
   };
   if(!Object.hasOwn(commands,action))return reply(res,400,{error:"invalid_test_action"});
   sql(commands[action]);
   return reply(res,200,{ok:true});
  }
  if(route.startsWith("/rest/v1/rpc/")){
   if(req.method!=="POST"||api!==ROLE||auth!=="Bearer "+ROLE)
    return reply(res,401,{error:"service_role_required"});
   const name=route.slice("/rest/v1/rpc/".length);
   if(name!=="resolve_iclub_ai_v21_practice_attempt_service")
    return reply(res,404,{error:"v21_rpc_uninstalled_in_scratch"});
   const input=JSON.parse(Buffer.concat(parts).toString("utf8"));
   const data=postgresResolve(input);
   return data?reply(res,200,data):reply(res,400,{error:"invalid_rpc_selector"});
  }
  return reply(res,404,{error:"unrecognized_local_path"});
 }catch{
  return reply(res,503,{error:"synthetic_backend_unavailable"});
 }
}
async function main(){
 if(process.env.CI!=="true"||
    process.env.ICLUB_QA_ALLOW_RESOLVER!=="synthetic-only")
  throw Error("QA-only HTTP resolver requires explicit CI synthetic flag");
 if(process.env.SUPABASE_URL||process.env.SUPABASE_SERVICE_ROLE_KEY)
  throw Error("Real Supabase environment variables must not be present");
 if(process.env.PGHOST!=="127.0.0.1"||
    !process.env.PGPASSWORD||process.env.PGPORT!=="5432")
  throw Error("Strict localhost scratch PostgreSQL required");
 const template=readFileSync(TEMPLATE,"utf8");
 const cut=template.indexOf("DO $closed$");
 assert(cut>0,"Missing trusted exact SQL bootstrap fixture");
 assert.equal(template.indexOf("DO $closed$",cut+1),-1);
 const prepared=template.slice(0,cut)+
  "UPDATE private.iclub_global_ai_runtime_config SET kill_switch=false,gateway_enabled=true;\nCOMMIT;\n";
 assert(prepared.includes("BEGIN;")&&prepared.includes(
  "\\ir iclub_ai_v21_practice_attempt_resolution_UNAPPLIED.sql"));
 writeFileSync(GENERATED,prepared,{flag:"wx",mode:0o600});generated=true;
 command("createdb",[...pgArgs(),DB]);created=true;
 command("psql",[...pgArgs(),"-X","-v","ON_ERROR_STOP=1","-d",DB,"-f",GENERATED]);
 assert.equal(sql("SELECT count(*) FROM public.practice_sessions_v4;"),"2");
 server=createServer((req,res)=>{void handle(req,res);});
 await new Promise((resolve,reject)=>server.listen(0,"127.0.0.1",
  error=>error?reject(error):resolve()));
 const port=server.address().port;
 const env={...process.env,
  ICLUB_QA_BACKEND_URL:"http://127.0.0.1:"+port,
  ICLUB_QA_ORIGIN:ORIGIN,ICLUB_QA_ANON:ANON,ICLUB_QA_ROLE:ROLE};
 const child=spawn("deno",["test","--no-check","--allow-net=127.0.0.1",
  "--allow-env=ICLUB_QA_BACKEND_URL,ICLUB_QA_ORIGIN,ICLUB_QA_ANON,ICLUB_QA_ROLE",
  "qa/edge_v21/practice_resolver_real_pg_http_test.ts"],{
   cwd:ROOT,env,stdio:"inherit"
  });
 const status=await new Promise((resolve,reject)=>{
  child.on("error",reject);child.on("exit",resolve);
 });
 assert.equal(status,0,"Deno HTTP-to-real-PG integration failed");
 assert.equal(sql("SELECT count(*) FROM public.practice_session_answers_v4;"),"2",
  "QA resolver must never change answers");
 console.log("ICLUB_QA_HTTP_TO_REAL_PG_RESOLVER_GREEN: JWT identity shim, PostgreSQL, no academic writes");
}
(async()=>{
 let failure=null;
 try{await main();}
 catch(e){failure=e;console.error("QA resolver integration failed:",e.message);}
 finally{
  if(server)await new Promise(resolve=>server.close(resolve));
  if(created)try{command("dropdb",[...pgArgs(),"--force",DB]);}
   catch(e){console.error("SCRATCH_DB_CLEANUP_FAIL",e.message);failure??=e;}
  if(generated)try{unlinkSync(GENERATED);}
   catch(e){console.error("TEMP_SQL_CLEANUP_FAIL",e.message);failure??=e;}
 }
 if(failure)process.exitCode=1;
})();
