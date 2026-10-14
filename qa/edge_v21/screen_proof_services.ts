// QA ONLY: ONE guarded server-side evidence RPC interface for ALL iClub AI screens.
// The RPC below is a proposed UNAPPLIED contract, not proof that production has it.
// It may return only user-bound metadata, never questions/answer keys/chat/credentials.
// A missing RPC, owner mismatch, stale selector or unknown evidence kind returns null.
type RecordData=Record<string,unknown>;
type ReadRpc=(name:string,args:RecordData)=>Promise<RecordData>;
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const positive=(v:unknown):v is number=>typeof v==="number"&&Number.isSafeInteger(v)&&v>0;
const obj=(v:unknown):RecordData|null=>v!==null&&typeof v==="object"&&!Array.isArray(v)?v as RecordData:null;
const KIND="get_iclub_ai_v21_screen_evidence_service";
type Query={userId:string;view?:string;subject?:string;lessonId?:number;
 sessionId?:number;questionId?:number;attemptId?:number};
export function createReadOnlyScreenProofReaders(rpc:ReadRpc){
 async function read(kind:string,x:Query):Promise<RecordData|null>{
  if(!UUID.test(x.userId||""))return null;
  if(x.lessonId!==undefined&&!positive(x.lessonId))return null;
  if(x.sessionId!==undefined&&!positive(x.sessionId))return null;
  if(x.questionId!==undefined&&!positive(x.questionId))return null;
  if(x.attemptId!==undefined&&!positive(x.attemptId))return null;
  const args:RecordData={p_user_id:x.userId,p_kind:kind,
   p_view:x.view??null,p_subject:x.subject??null,p_lesson_id:x.lessonId??null,
   p_session_id:x.sessionId??null,p_question_id:x.questionId??null,
   p_attempt_id:x.attemptId??null};
  try{
   const d=await rpc(KIND,args);
   if(d?.allowed!==true)return null;
   const proof=obj(d.evidence);
   if(!proof||proof.user_id!==x.userId||proof.evidence_kind!==kind)return null;
   // Selector echo confirms a proof for the requested exact domain record.
   if(x.view!==undefined&&proof.requested_view!==x.view)return null;
   if(x.subject!==undefined&&proof.requested_subject!==x.subject)return null;
   if(x.lessonId!==undefined&&proof.id!==x.lessonId)return null;
   if(x.sessionId!==undefined&&proof.session_id!==x.sessionId&&
     !(kind==="practice_session_v4"&&proof.id===x.sessionId))return null;
   if(x.questionId!==undefined&&proof.question_id!==x.questionId)return null;
   if(x.attemptId!==undefined&&proof.attempt_id!==x.attemptId&&
     !(kind==="tour_attempt"&&proof.id===x.attemptId))return null;
   // Only vetted server-derived claims enter the in-process admission.
   return proof;
  }catch{return null;}
 }
 return{
  getCurrentScreen:(userId:string)=>read("current_screen",{userId}),
  readNavigationSource:(x:{userId:string;view:string})=>
   read("navigation",{...x}),
  readSubjectOverview:(x:{userId:string;subject:string})=>
   read("subject_overview",{...x}),
  readHomeNextActions:(x:{userId:string})=>read("home_next_actions",x),
  readProfileAggregate:(x:{userId:string})=>read("profile_aggregate",x),
  readLesson:(x:{userId:string;lessonId:number})=>read("lesson",x),
  readPracticeSessionV4:(x:{userId:string;sessionId:number})=>
   read("practice_session_v4",x),
  readPracticeAnswerV4:(x:{userId:string;sessionId:number;questionId:number})=>
   read("practice_answer_v4",x),
  readTourAttempt:(x:{userId:string;attemptId:number})=>read("tour_attempt",x),
  readTourRuntime:(x:{userId:string;attemptId:number})=>read("tour_runtime",x),
  readTourArchiveAccess:(x:{userId:string;attemptId:number})=>
   read("tour_archive_access",x)
 };
}
