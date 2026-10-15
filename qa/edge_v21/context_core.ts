// QA-only HTTP contract for requesting/leaving one verified Practice screen.
// No client-supplied subject, topic, progress, plan, rights, source or user ID.
export type ContextServices={
 authenticate(token:string):Promise<{authenticated:boolean;userId:string}|null>;
 // Exact server-resolved legacy Practice marker -> canonical V4 selector.
 // This does NOT grant any AI answer; the subsequent mint & source check do.
 resolvePracticeV4?(args:{userId:string;attemptReference:number;questionId:number}):
  Promise<Record<string,unknown>>;
 mintScopedContext(args:{userId:string;sessionId:number;questionId:number}):
  Promise<Record<string,unknown>>;
 mintLessonContext(args:{userId:string;lessonId:number}):
  Promise<Record<string,unknown>>;
 mintTourArchiveContext(args:{userId:string;attemptId:number}):
  Promise<Record<string,unknown>>;
 mintAppViewContext(args:{userId:string;view:string}):
  Promise<Record<string,unknown>>;
 revokeScopedContext(args:{userId:string;contextHandle:string}):
  Promise<Record<string,unknown>>;
};
const UUID=/^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i;
const KEYS=new Set(["action","sessionId","questionId","lessonId","tourAttemptId","view","contextHandle","attemptReference"]);
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
   // Extending the shared action-key vocabulary must not accidentally allow
   // a resolver reference to be smuggled into legacy mint/revoke requests.
   if(input.action!=="resolvePracticeV4"&&hasOwn(input,"attemptReference"))
     return result(400,{ok:false,reason:"invalid_request"});
   if(input.action==="resolvePracticeV4"){
    // Deliberately no client-supplied user, session, source, subject, status,
    // progress, correct answer, topic, rollout flag or role.
    if(Object.keys(input).length!==3||
       !hasOwn(input,"attemptReference")||!hasOwn(input,"questionId")||
       !Number.isSafeInteger(input.attemptReference)||
       !Number.isSafeInteger(input.questionId)||
       Number(input.attemptReference)<=0||Number(input.questionId)<=0)
      return result(400,{ok:false,reason:"invalid_context_selector"});
    if(typeof services.resolvePracticeV4!=="function")
      return result(503,{ok:false,reason:"unavailable"});
    let record:Record<string,unknown>;
    try{
      record=await services.resolvePracticeV4({
        userId:principal.userId,
        attemptReference:Number(input.attemptReference),
        questionId:Number(input.questionId)
      });
    }catch{return result(503,{ok:false,reason:"unavailable"});}
    // Construct response from trusted checked fields ONLY. A mistaken RPC
    // must never pass user id, question text, answer keys, score or readiness.
    if(record?.ok!==true||
       record.kind!=="server_resolved_practice_v4"||
       record.attemptReference!==input.attemptReference||
       record.questionId!==input.questionId||
       !Number.isSafeInteger(record.sessionId)||Number(record.sessionId)<=0)
      return result(200,{ok:false,reason:"server_verification_required"});
    return result(200,{
      ok:true,kind:"server_resolved_practice_v4",
      attemptReference:input.attemptReference,
      questionId:input.questionId,
      sessionId:record.sessionId
    });
   }
   if(input.action==="mint"){
    if(!hasOwn(input,"sessionId")||!hasOwn(input,"questionId")||
      hasOwn(input,"contextHandle")||hasOwn(input,"lessonId")||hasOwn(input,"tourAttemptId")||hasOwn(input,"view")||
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
      hasOwn(input,"contextHandle")||hasOwn(input,"tourAttemptId")||hasOwn(input,"view")||
      !Number.isSafeInteger(input.lessonId)||
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
   if(input.action==="mintTourArchive"){
    if(hasOwn(input,"sessionId")||hasOwn(input,"questionId")||
      hasOwn(input,"lessonId")||hasOwn(input,"contextHandle")||hasOwn(input,"view")||
      !Number.isSafeInteger(input.tourAttemptId)||Number(input.tourAttemptId)<=0)
      return result(400,{ok:false,reason:"invalid_context_selector"});
    let data:Record<string,unknown>;
    try{
     data=await services.mintTourArchiveContext({
      userId:principal.userId,attemptId:Number(input.tourAttemptId)});
    }catch{return result(503,{ok:false,reason:"unavailable"});}
    if(data?.allowed!==true||typeof data.context_handle!=="string"||
       !UUID.test(data.context_handle))
      return result(200,{ok:false,reason:typeof data?.reason==="string"?
       data.reason:"context_unavailable"});
    return result(200,{ok:true,contextHandle:data.context_handle,
     expiresInSeconds:Math.min(90,Math.max(1,Number(data.expires_in_seconds)||90))});
   }
   if(input.action==="mintAppView"){
    if(hasOwn(input,"sessionId")||hasOwn(input,"questionId")||
      hasOwn(input,"lessonId")||hasOwn(input,"tourAttemptId")||
      hasOwn(input,"contextHandle")||
      typeof input.view!=="string"||
      !["home","profile","courses","ratings","about","support"].includes(input.view))
      return result(400,{ok:false,reason:"invalid_context_selector"});
    let data:Record<string,unknown>;
    try{
     data=await services.mintAppViewContext({
      userId:principal.userId,view:input.view});
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
      hasOwn(input,"lessonId")||hasOwn(input,"tourAttemptId")||hasOwn(input,"view")||
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
