'use strict';
// Stage 03 read-only contract: never calls Supabase or changes learner data.
const fs=require('node:fs');
const path=require('node:path');
const root=__dirname;
const migration=fs.readFileSync(path.join(root,'supabase/migrations/20261008150000_practice_topic_switch_atomic_v1.sql'),'utf8');
const app=fs.readFileSync(path.join(root,'dist/app.js'),'utf8');
const api=fs.readFileSync(path.join(root,'dist/security/legacy-assessment-safe-api.js'),'utf8');
const choice=fs.readFileSync(path.join(root,'dist/practice-topic-choice.js'),'utf8');
let checked=0;
function assert(test,description) {
  ++checked;
  if(!test)throw Error('Stage03 topic safety regression: '+description);
}
function before(hay,a,b) {
  const start=hay.indexOf(a),end=hay.indexOf(b,start);
  return start>=0&&end>start;
}
const requiredMigration=[
  'security definer',
  'v_uid uuid := auth.uid()',
  "s.user_id=v_uid",
  "s.id=p_expected_old_session_id",
  "s.client_session_id=trim(p_expected_old_client_session_id)",
  "left(s.client_session_id,22)='practice_topic_choice_'",
  "s.drill_type='rec_topic'",
  "s.subject_id=v_subject_id",
  "if v_old.status='abandoned' then",
  "s.client_session_id=trim(p_new_client_session_id)",
  "s.status='in_progress'",
  "if v_old.status<>'in_progress' then",
  "update public.practice_drill_sessions_v4 s",
  "set status='abandoned'",
  "old_session_abandoned',true",
  "grant execute on function public.replace_practice_topic_drill_choice_safe_v1"
];
for(const token of requiredMigration) assert(migration.includes(token),'migration invariant '+token);
assert(!/\b(delete\s+from|truncate\s+|drop\s+table)\b/i.test(migration),'migration must not delete rows');
assert(before(migration,'pg_advisory_xact_lock','select s.* into v_old'),'per-account transaction lock before selecting old attempt');
assert(before(migration,'for update;','v_start:=public.start_practice_topic_drill_choice_safe_v1'),'old attempt row locked before creating next');
assert(before(migration,'v_start:=public.start_practice_topic_drill_choice_safe_v1','update public.practice_drill_sessions_v4 s'),'new attempt prepared before old marked abandoned');
assert(before(migration,"if v_old.status='abandoned' then","if v_old.status<>'in_progress' then"),'idempotent retry before new attempt');
assert(migration.includes("old_topic_session_not_owned_or_not_found"),'wrong owner must fail closed');
assert(api.includes('replace_practice_topic_drill_choice_safe_v1'),'API calls exact planned RPC');
assert(app.includes('async function resumePendingPracticeTopicChoice(draft)'),'async pending recovery remains present');
assert(app.includes('if (decision === "resume")'),'resume choice calls current attempt');
assert(app.includes('if (decision !== "replace") return;'),'cancelled dialog does not start new attempt');
assert(app.includes("if (loadPracticeDraft()?.pendingTopicSwitch?.clientSessionId!==p.clientSessionId)"),'draft ownership checked before activation');
assert(app.includes("started?.old_session_abandoned!==true"),'server confirmation required');
assert(app.includes("const rows=await dbWriteWithRetry(()=>api.questions(newId)"),'new attempt questions verified');
const recoverStart=app.indexOf('async function resumePendingPracticeTopicChoice(draft)');
const recoverEnd=app.indexOf('async function startPracticeByRec(',recoverStart);
const recovery=app.slice(recoverStart,recoverEnd>recoverStart?recoverEnd:recoverStart+8000);
const saved=recovery.search(/saveState\s*\(\s*\)/);
const cleared=recovery.search(/clearPracticeDraft\s*\(\s*\)/);
assert(recoverStart>=0 && saved>=0 && cleared>saved,
  'draft retained until resumed replacement is saved');
for(const text of ['Продолжить незавершённую попытку?','Tugallanmagan urinishni davom ettirasizmi?','Resume your unfinished attempt?'])
  assert(app.includes(text),'localization '+text);
for(const text of ['Последние попытки','So‘nggi urinishlar','Recent attempts'])
  assert(choice.includes(text),'history term '+text);
new Function(app);new Function(choice);
console.log('STAGE03_TOPIC_SWITCH_CONTRACT_OK assertions='+checked+' sql_executed=0 student_rows_changed=0');
