// DORMANT prepared Practice route, not deployed or called by production UI.
// Never calls an AI provider; only service-verified V4 result and approved sources.
const URL=(Deno.env.get("SUPABASE_URL")||"").replace(/\/+$/,"");
const ANON=Deno.env.get("SUPABASE_ANON_KEY")||"";
const SERVICE=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")||"";
const BASE="https://mmmduffgpvwjdpruzikw.supabase.co";
const ORIGIN=/^https:\/\/(?:i-club-app\.vercel\.app|i-club-[a-z0-9-]+-jasurbeks-projects-c5451f97\.vercel\.app)$/i;
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const PURPOSES=new Set(["practice_visibility","practice_result","practice_error","practice_next_step","practice_history_comparison"]);
const LOCALES=new Set(["ru","uz","en"]);
type Row=Record<string,unknown>;
const object=(x:unknown):x is Row=>!!x&&typeof x==="object"&&!Array.isArray(x);
const id=(x:unknown)=>Number.isSafeInteger(x)&&Number(x)>0;
function send(status:number,payload:Row,origin:string|null):Response{
 const h=new Headers({"content-type":"application/json; charset=utf-8",
  "cache-control":"no-store, private","vary":"Origin",
  "x-content-type-options":"nosniff","referrer-policy":"no-referrer"});
 if(origin&&ORIGIN.test(origin)){
  h.set("access-control-allow-origin",origin);
  h.set("access-control-allow-headers","authorization, apikey, content-type, x-client-info");
  h.set("access-control-allow-methods","POST, OPTIONS");
 }
 return new Response(status===204?null:JSON.stringify(payload),{status,headers:h});
}
async function json(task:Promise<Response>):Promise<Row|null>{
 try{const res=await task;if(!res.ok)return null;const data=await res.json();return object(data)?data:null;}
 catch{return null;}
}
async function rpc(name:string,args:Row):Promise<Row|null>{
 return json(fetch(URL+"/rest/v1/rpc/"+name,{method:"POST",
  headers:{"apikey":SERVICE,"authorization":"Bearer "+SERVICE,
   "content-type":"application/json"},body:JSON.stringify(args),
  signal:AbortSignal.timeout(7000)}));
}
const STRINGS={
 ru:{
   result:(ok:number,total:number,pct:string,wrong:number,ids:string)=>
    `Результат: ${ok} из ${total} (${pct}%). Неправильных ответов: ${wrong}.${ids ? ' В разборе доступны задания: '+ids+'.' : ''}`,
   next:(ids:string,hasWrong:boolean)=>ids
    ? `Начните с разбора заданий ${ids}. Найдите причину каждой ошибки, повторите эти темы и затем решите похожие задачи без подсказок.`
    : hasWrong
      ? "В этой попытке есть неправильные ответы, но их подробный разбор сейчас недоступен. Повторите материал и попробуйте похожие задачи."
      : "Проверьте пройденные темы и попробуйте более сложные задачи, чтобы закрепить результат.",
   missing:"Нет подтверждённой сопоставимой предыдущей попытки. По одной попытке нельзя судить об ухудшении знаний.",
   comparison:(a:string,b:string)=>`В предыдущей сопоставимой попытке было ${a}%, сейчас — ${b}%. Это сравнение результатов, а не доказательство изменения уровня знаний.`
 },
 uz:{
   result:(ok:number,total:number,pct:string,wrong:number,ids:string)=>
    `Natija: ${total} ta savoldan ${ok} tasi to‘g‘ri (${pct}%). Noto‘g‘ri javoblar: ${wrong}.${ids ? ' Tahlilda mavjud savollar: '+ids+'.' : ''}`,
   next:(ids:string,hasWrong:boolean)=>ids
    ? `Avval ${ids} topshiriqlarini tahlil qiling. Xatolar sababini aniqlang, tegishli mavzularni takrorlang va shunga o‘xshash masalalarni yordamsiz yeching.`
    : hasWrong
      ? "Bu urinishda xatolar bor, ammo ularning batafsil tahlili hozircha mavjud emas. Mavzuni takrorlab, o‘xshash topshiriqlarni yeching."
      : "O‘rganilgan mavzularni mustahkamlang va murakkabroq topshiriqlarni yeching.",
   missing:"Oldingi tasdiqlangan taqqoslanadigan urinish yo‘q. Bitta urinish bilim darajasi pasayganini bildirmaydi.",
   comparison:(a:string,b:string)=>`Oldingi taqqoslanadigan urinishda ${a}%, hozir ${b}%. Bu natijalar farqi, bilim darajasi o‘zgarganini isbotlamaydi.`
 },
 en:{
   result:(ok:number,total:number,pct:string,wrong:number,ids:string)=>
    `Result: ${ok} of ${total} correct (${pct}%). Incorrect answers: ${wrong}.${ids ? ' Questions available for review: '+ids+'.' : ''}`,
   next:(ids:string,hasWrong:boolean)=>ids
    ? `Start by reviewing questions ${ids}. Work out why each answer was wrong, revisit the related topics, then try similar problems without hints.`
    : hasWrong
      ? "This attempt has incorrect answers, but their detailed review is unavailable. Revise the material and try similar questions."
      : "Consolidate the topics you have studied and try more challenging questions.",
   missing:"No verified comparable earlier attempt is available. One attempt cannot establish a decline in understanding.",
   comparison:(a:string,b:string)=>`Your previous comparable result was ${a}%, and now it is ${b}%. This compares scores, not overall understanding.`
 }
};
function prepared(c:Row,purpose:string,locale:"ru"|"uz"|"en"):string|null{
 const total=c.total,correct=c.correct,incorrect=c.incorrect,unattempted=c.unattempted;
 const percentage=c.percentage,reviewable=c.reviewable_error_ordinals;
 if(c.completed!==true||!Number.isSafeInteger(total)||Number(total)<1||
  !Number.isSafeInteger(correct)||Number(correct)<0||
  !Number.isSafeInteger(incorrect)||Number(incorrect)<0||
  !Number.isSafeInteger(unattempted)||Number(unattempted)<0||
  Number(correct)+Number(incorrect)+Number(unattempted)!==Number(total)||
  !Number.isFinite(percentage)||Math.abs(Number(percentage)-Number(correct)*100/Number(total))>0.11||
  !Array.isArray(reviewable)||
  reviewable.some(n=>!Number.isSafeInteger(n)||n<1||n>Number(total))||
  new Set(reviewable).size!==reviewable.length||reviewable.length>Number(incorrect))return null;
 const text=STRINGS[locale];
 const fmt=(n:number)=>{const v=String(Math.round(n*10)/10);return locale==="en"?v:v.replace(".",",");};
 const ids=reviewable.map(n=>(locale==="en"?"#":"№")+n).join(", ");
 if(purpose==="practice_result")
  return text.result(Number(correct),Number(total),fmt(Number(percentage)),Number(incorrect),ids);
 if(purpose==="practice_next_step"){
  if(!Array.isArray(c.available_actions))return null;
  if(ids&&!c.available_actions.includes("correct_mistakes"))return null;
  return text.next(ids,Number(incorrect)>0);
 }
 if(purpose==="practice_history_comparison"){
  const cmp=c.comparison;
  if(!object(cmp))return null;
  if(cmp.available===false)return text.missing;
  if(cmp.available===true&&cmp.basis==="same_subject_pool_bank_generation_question_count"&&
    cmp.causation_claim_allowed===false&&typeof cmp.previous_percentage==="number"&&
    cmp.previous_percentage>=0&&cmp.previous_percentage<=100)
    return text.comparison(fmt(cmp.previous_percentage),fmt(Number(percentage)));
 }
 return null;
}
Deno.serve(async(req:Request):Promise<Response>=>{
 const origin=req.headers.get("origin");
 if(!origin||!ORIGIN.test(origin))return send(403,{ok:false,reason:"origin_not_authorized"},null);
 const reply=(status:number,data:Row)=>send(status,data,origin);
 if(req.method==="OPTIONS")return reply(204,{});
 if(req.method!=="POST")return reply(405,{ok:false,reason:"method_not_allowed"});
 if(URL!==BASE||ANON.length<24||SERVICE.length<24||ANON===SERVICE)
   return reply(503,{ok:false,reason:"not_released"});
 const bearer=req.headers.get("authorization")||"";
 if(!/^Bearer [a-zA-Z0-9._-]{24,4000}$/.test(bearer))
   return reply(401,{ok:false,reason:"not_authorized"});
 let data:Row;
 try{const raw=await req.text();if(new TextEncoder().encode(raw).length>4096)
  return reply(413,{ok:false,reason:"invalid_request"});
  const v=JSON.parse(raw);if(!object(v))throw Error("invalid");data=v;
 }catch{return reply(400,{ok:false,reason:"invalid_request"});}
 const keys=Object.keys(data);
 if(keys.length!==6||keys.some(k=>!["intent","request_id","purpose","attempt_ref","question_ref","locale"].includes(k))||
  data.intent!=="practice_prepared"||typeof data.request_id!=="string"||!UUID.test(data.request_id)||
  !PURPOSES.has(String(data.purpose))||!LOCALES.has(String(data.locale))||!id(data.attempt_ref)||
  (data.purpose==="practice_error"?!id(data.question_ref):data.question_ref!==null))
  return reply(400,{ok:false,reason:"invalid_request"});
 const user=await json(fetch(URL+"/auth/v1/user",{
  headers:{"apikey":ANON,"authorization":bearer},signal:AbortSignal.timeout(5000)}));
 if(user?.role!=="authenticated"||typeof user.id!=="string"||!UUID.test(user.id))
  return reply(401,{ok:false,reason:"not_authorized"});
 const context=await rpc("get_iclub_ai_practice_context_v1_service",{
  p_user_id:user.id,p_attempt_id:data.attempt_ref,p_intent:data.purpose,
  p_question_id:data.question_ref,p_locale:data.locale});
 if(context?.ok!==true||!object(context.context))
  return reply(403,{ok:false,reason:String(context?.reason||"context_unavailable")});
 // Visibility is a no-spend, read-only server permission check.
 // Never send scores, question IDs, source records or assessment details.
 if(data.purpose==="practice_visibility"){
  const c=context.context;
  if(c.completed!==true||c.intent!=="practice_visibility"||
     c.attempt_ref!==data.attempt_ref||
     typeof c.total!=="number"||!Number.isSafeInteger(c.total)||c.total<1||
     typeof c.correct!=="number"||!Number.isSafeInteger(c.correct)||
     c.correct<0||c.correct>c.total)
   return reply(409,{ok:false,reason:"verified_context_unavailable"});
  return reply(200,{ok:true,available:true,mode:"availability",
   provider_called:false,academic_state_changed:false});
 }
 if(data.purpose==="practice_error"){
  if(context.source_status!=="ready")return reply(403,{ok:false,reason:"source_not_ready"});
  // This existing RPC independently re-checks owner, protected exam,
  // approved source, and charges the one-unit prepared beta quota atomically.
  const result=await rpc("deliver_iclub_ai_v21_academic_service",{
   p_user_id:user.id,p_request_id:data.request_id,p_surface:"practice_error",
   p_record_id:data.attempt_ref,p_question_id:data.question_ref,p_locale:data.locale});
  if(result?.ok!==true||result.mode!=="prepared"||result.provider_called!==false||
   result.academic_state_changed!==false||typeof result.message!=="string"||
   result.message.length<20||result.message.length>6000)
   return reply(409,{ok:false,reason:String(result?.reason||"source_not_ready")});
  return reply(200,{ok:true,mode:"prepared",message:result.message,
   provider_called:false,academic_state_changed:false});
 }
 const message=prepared(context.context,String(data.purpose),data.locale as "ru"|"uz"|"en");
 if(!message)return reply(409,{ok:false,reason:"verified_context_unavailable"});
 return reply(200,{ok:true,mode:"verified_summary",message,
  provider_called:false,academic_state_changed:false});
});