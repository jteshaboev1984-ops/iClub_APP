// iClub AI v2.1 read-only compatibility and Preview release preflight.
// CI passing validates a truthful NO-GO, not an authorization to deploy.
"use strict";
const {readFileSync}=require("node:fs"),{resolve}=require("node:path");
const root=resolve(__dirname,".."),read=p=>readFileSync(resolve(root,p),"utf8");
function inspectActualAppPreviewAdmission(){
 const index=read("index.html"),app=read("app.js"),ui=read("global-ai-ui.js");
 const context=read("qa/edge_v21/context_core.ts");
 const sql=read("qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql");
 const o=Object.freeze({
  routeV1:/functions\.invoke\("global-ai"/.test(ui),
  lessonInternal:/state\.courses\.lessonId\s*=\s*lesson\.id/.test(app),
  lessonCardsDynamic:/select\("id,title,topic,order_no"\)/.test(app),
  lessonScreen:/<section id="courses-video"/.test(index),
  hasV2LessonScreenBinding:/data-iclub-ai-v21-lesson-id/.test(index),
  legacyAttempt:/state\?\.practiceLastAttempt/.test(app)&&
   /attempt\?\.db\?\.attemptId/.test(app),
  attemptAttribute:/dataset\.practiceAiAttemptId/.test(app),
  canonicalPractice:/public\.practice_sessions_v4/.test(sql)&&
   /public\.practice_session_answers_v4/.test(sql),
  explicitV2PracticeBinding:/data-iclub-ai-v21-session-id/.test(index)&&
   /data-iclub-ai-v21-question-id/.test(index),
  indexImportsV2:/ai-layer-v21-ui-transport/.test(index),
  v2Separate:/mintLessonContext/.test(context)&&/mintScopedContext/.test(context)
 });
 const blockers=[
  ...(o.routeV1&&!o.indexImportsV2?["legacy_global_ai_route_not_replaced"]:[]),
  ...(o.lessonInternal&&o.lessonCardsDynamic&&o.lessonScreen&&!o.hasV2LessonScreenBinding?
   ["lesson_id_not_safely_bound_to_v2_context"]:[]),
  ...(o.legacyAttempt&&o.attemptAttribute&&o.canonicalPractice&&!o.explicitV2PracticeBinding?
   ["legacy_practice_attempt_id_not_verified_as_v4_session_id"]:[]),
  ...(!o.v2Separate?["v2_context_contract_missing"]:[]),
  "isolated_qa_db_and_auth_not_verified",
  "preview_has_no_separate_owner_authorization"
 ];
 return Object.freeze({status:"NO_GO",existingQaBranchOnly:true,
  observations:o,blockers:Object.freeze(blockers)});
}
if(require.main===module)console.log("PREVIEW_"+JSON.stringify(inspectActualAppPreviewAdmission()));
module.exports={inspectActualAppPreviewAdmission};
