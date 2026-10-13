// QA-only HTTP contract for requesting/leaving one verified Practice screen.
// No client-supplied subject, topic, progress, plan, rights, source or user ID.
export type ContextServices={
 authenticate(token:string):Promise<{authenticated:boolean;userId:string}|null>;
 mintScopedContext(args:{userId:string;sessionId:number;questionId:number}):
  Promise<Record<string,unknown>>;
 mintLessonContext(args:{userId:string;lessonId:number}):
  Promise<Record<string,unknown>>;
 revokeScopedContext(args:{userId:string;contextHandle:string}):
  Promise<Record<string,unknown>>;
};
const UUID=/^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i;
const KEYS=new Set(["action","sessionId","questionId","lessonId","contextHandle"]);
const hasOwn=(o:Record<string,unknown>,k:string)=>Object.prototype.hasOwnProperty.call(o,k);
const isObject=(v:unknown):v is Record<string,unknown>=>v!==null&&
 typeof v==="object"&&!Array.isArray(v);
const result=(status:number,body:Record<string,unknown>)=>({status,body});
export function makeContextCore(services:ContextServices){
 return{
  async serve({authorization,bodyText}:{method:string;origin:string;authorization:string;bodyText:string}){
   if(!/^Bearer [A-Za-z0-9._-]{8,2048}$/.test(authorization))
    return result(401,{ok:false,reason:"authentication_required"});
   let principal;
   try{principal=await services.authenticate(authorization);}catch{}
   if(!principal?.authenticated||!UUID.test(principal.userId))
    return result(401,{ok:false,reason:"authentication_required"});
   let input:unknown;
   try{input=JSON.parse(bodyText);}catch{}
   if(!isObject(input)||Object.keys(input).some(k=>!KEYS.has(k)))
    return result(400,{ok:false,reason:"invalid_request"});
   if(input.action==="mint"){
    if(!hasOwn(input,"sessionId")||!hasOwn(input,"questionId")||
      hasOwn(input,"contextHandle")||hasOwn(input,"lessonId")||
      !Number.isSafeInteger(input.sessionId)||
      !Number.isSafeInteger(input.questionId)||Number(input.sessionId)<=0||
      Number(input.questionId)<=0)
      return result(400,{ok:false,reason:"invalid_context_selector"});
    let data:Record<string,unknown>;
    try{
     data=await services.mintScopedContext({userId:principal.userId,
      sessionId:Number(input.sessionId),questionId:Number(input.questionId)});
    }catch{return result(503,{ok:false,reason:"unavailable"});}
    if(data?.allowed!==true||typeof data.context_handle!=="string"||
       !UUID.test(data.context_handle))
      return result(200,{ok:false,reason:typeof data?.reason==="string"
       ?data.reason:"context_unavailable"});
    return result(200,{ok:true,contextHandle:data.context_handle,
      expiresInSeconds:Math.min(90,Math.max(1,Number(data.expires_in_seconds)||90))});
   }
   if(input.action==="mintLesson"){
    if(hasOwn(input,"sessionId")||hasOwn(input,"questionId")||
      hasOwn(input,"contextHandle")||!Number.isSafeInteger(input.lessonId)||
      Number(input.lessonId)<=0)
      return result(400,{ok:false,reason:"invalid_context_selector"});
    let data:Record<string,unknown>;
    try{
     data=await services.mintLessonContext({userId:principal.userId,
      lessonId:Number(input.lessonId)});
    }catch{return result(503,{ok:false,reason:"unavailable"});}
    if(data?.allowed!==true||typeof data.context_handle!=="string"||
      !UUID.test(data.context_handle))
      return result(200,{ok:false,reason:typeof data?.reason==="string"?
       data.reason:"context_unavailable"});
    return result(200,{ok:true,contextHandle:data.context_handle,
     expiresInSeconds:Math.min(90,Math.max(1,Number(data.expires_in_seconds)||90))});
   }
   if(input.action==="revoke"){
    if(hasOwn(input,"sessionId")||hasOwn(input,"questionId")||
      typeof input.contextHandle!=="string"||!UUID.test(input.contextHandle))
      return result(400,{ok:false,reason:"invalid_context_handle"});
    try{
     const data=await services.revokeScopedContext({
      userId:principal.userId,contextHandle:input.contextHandle});
     return result(200,{ok:data?.ok===true});
    }catch{return result(503,{ok:false,reason:"unavailable"});}
   }
   return result(400,{ok:false,reason:"invalid_action"});
  }
 };
}
