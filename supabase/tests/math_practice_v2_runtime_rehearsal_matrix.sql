-- Disposable runtime matrix for Mathematics Practice v2.
-- Exercises real v5 selector, feedback/finalizer, topic drill, mistakes drill,
-- non-Mathematics compatibility, cutover blocking and rollback-only fallback.

\set ON_ERROR_STOP on

insert into public.subjects(id,subject_key,title,type,is_active) values
  (5,'mathematics','Mathematics','main',true),
  (7,'economics','Economics','main',true);

insert into public.seasons(id,season_no,status,title)
values(1,1,'current','Runtime rehearsal season');

insert into public.tours(id,subject_id,season_id,tour_no,start_date,end_date,is_active)
values(11,5,1,1,'2020-01-01','2099-12-31',true);

insert into public.practice_pools(id,subject_id,tour_no,title,is_active) values
  (501,5,1,'Math v2',true),
  (502,5,1,'Math legacy-only cutover probe',true),
  (701,7,1,'Economics legacy compatibility',true);

-- Twelve governed Mathematics v2 questions.
insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,
  explanation_en,book_ref,time_limit_sec,quality_status
)
select
  2000+g,5,'Algebra','Basics',
  case when g<=3 then 'easy' when g<=8 then 'medium' else 'hard' end,
  'mcq',
  'Question '||g,'A|B|C|D','A','Explanation '||g,null,true,
  'RU '||g,'UZ '||g,'EN '||g,
  'A|B|C|D','A|B|C|D','A|B|C|D',
  'RU explanation','UZ explanation','EN explanation',
  'Runtime fixture',60,'published'
from generate_series(1,12) g;

insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
select 501,2000+g,g,true from generate_series(1,12) g;

insert into private.practice_v2_question_meta(
  question_id,content_key,release_version,practice_no,primary_skill_code,
  secondary_skill_codes,question_role,source_ref,answer_contract,content_hash,
  qa_math_status,qa_language_status,qa_technical_status,qa_tour_separation_status,
  lifecycle_state,is_runtime_allowed,approved_at,published_at
)
select
  2000+g,
  'runtime_math_'||g,
  'math_p1_practice_v2_2026_10_07',
  1,
  'ALG_'||(((g-1)%4)+1),
  case when g in (4,8,12) then array['ALG_TRANSFER']::text[] else '{}'::text[] end,
  case when g in (4,8,12) then 'transfer' else 'direct_application' end,
  'runtime fixture',
  '{"kind":"mcq"}'::jsonb,
  md5(g::text),
  'passed','passed','passed','passed',
  'published',true,now(),now()
from generate_series(1,12) g;

-- A Mathematics legacy-only question must be blocked before publish/cutover signal.
insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,is_active,question_text_ru,question_text_uz,question_text_en,
  options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,
  explanation_en,book_ref,time_limit_sec,quality_status
) values(
  1500,5,'Legacy','Legacy','medium','mcq','Legacy Math','A|B|C|D','A',
  'Legacy explanation',true,'RU legacy','UZ legacy','EN legacy',
  'A|B|C|D','A|B|C|D','A|B|C|D','RU','UZ','EN','Legacy',60,'published'
);
insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
values(502,1500,1,true);

-- Non-Mathematics legacy questions must remain compatible with v5.
insert into public.questions(
  id,subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,
  explanation,is_active,question_text_en,options_text_en,explanation_en,book_ref,time_limit_sec,quality_status
)
select
  7000+g,7,'Economics','Basics','medium','mcq','Economics '||g,'A|B|C|D','A',
  'Economics explanation',true,'Economics '||g,'A|B|C|D','Economics explanation',
  'Runtime fixture',60,'published'
from generate_series(1,10) g;
insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)
select 701,7000+g,g,true from generate_series(1,10) g;

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000001',
  false
);

do $runtime$
declare
  v_start jsonb;
  v_sid bigint;
  v_qids bigint[];
  v_qid bigint;
  v_wrong_qid bigint;
  v_i integer:=0;
  v_submit jsonb;
  v_finish jsonb;
  v_attempt bigint;
  v_count integer;
  v_diag_count integer;
  v_mistake_count integer;
  v_drill jsonb;
  v_drill_sid bigint;
  v_topic jsonb;
  v_econ jsonb;
  v_econ_sid bigint;
  v_legacy jsonb;
  v_legacy_sid bigint;
begin
  -- Before the rollback signal, a Math pool containing only legacy rows fails closed.
  begin
    perform public.start_practice_session_auto_safe_v5(
      502,'runtime-cutover-block-001'
    );
    raise exception 'math_legacy_cutover_probe_should_have_failed';
  exception
    when sqlstate '55000' then
      if position('practice_v2_cutover_pending' in sqlerrm)=0 then
        raise;
      end if;
  end;

  -- Main Mathematics v2 session selects only governed runtime-allowed questions.
  v_start:=public.start_practice_session_auto_safe_v5(
    501,'runtime-math-main-001'
  );
  v_sid:=(v_start->>'session_id')::bigint;

  select question_ids into v_qids
  from public.practice_sessions_v4
  where id=v_sid;

  if coalesce(cardinality(v_qids),0)<>10 then
    raise exception 'runtime_math_selector_expected_10_found_%',coalesce(cardinality(v_qids),0);
  end if;

  select count(*) into v_count
  from unnest(v_qids) x(qid)
  join private.practice_v2_question_meta m on m.question_id=x.qid
  where m.lifecycle_state='published' and m.is_runtime_allowed is true;

  if v_count<>10 then
    raise exception 'runtime_math_selector_leaked_non_v2_question_count_%',v_count;
  end if;

  v_wrong_qid:=v_qids[1];

  insert into public.question_answer_diagnostics(
    question_id,answer_kind,answer_key,is_correct,mistake_type,weak_skill,
    feedback_ru,feedback_uz,feedback_en,
    next_action_ru,next_action_uz,next_action_en,
    rule_json,quality_status
  ) values(
    v_wrong_qid,'mcq_option','B',false,'sign_error','ALG_1',
    'RU feedback','UZ feedback','EN feedback',
    'RU next','UZ next','EN next',
    '{"diagnostic_code":"RUNTIME_SIGN"}'::jsonb,'published'
  );

  foreach v_qid in array v_qids loop
    v_i:=v_i+1;
    v_submit:=public.submit_practice_session_answer_safe_v5(
      v_sid,
      v_qid,
      case when v_i=1 then 'B' else 'A' end,
      case when v_i=1 then 1 else 0 end,
      5
    );

    if v_i=1 then
      if coalesce((v_submit->>'is_correct')::boolean,true) is true
         or v_submit->>'diagnostic_status'<>'mapped' then
        raise exception 'runtime_wrong_answer_diagnostic_failed_%',v_submit;
      end if;
    elsif coalesce((v_submit->>'is_correct')::boolean,false) is not true then
      raise exception 'runtime_correct_answer_failed_%',v_submit;
    end if;
  end loop;

  v_finish:=public.finalize_practice_session_safe_v5(v_sid,50);
  v_attempt:=(v_finish->>'attempt_id')::bigint;

  if v_attempt is null or (v_finish->>'score')::integer<>9 then
    raise exception 'runtime_finalize_expected_score_9_%',v_finish;
  end if;

  select count(*) into v_count
  from public.practice_answers
  where attempt_id=v_attempt;
  if v_count<>10 then
    raise exception 'runtime_finalize_answers_expected_10_found_%',v_count;
  end if;

  select count(*) into v_diag_count
  from public.user_answer_diagnosis
  where attempt_id=v_attempt and attempt_type='practice';
  if v_diag_count<>10 then
    raise exception 'runtime_finalize_diagnoses_expected_10_found_%',v_diag_count;
  end if;

  select count(*) into v_count
  from public.get_practice_review_full_safe_v5(v_attempt);
  if v_count<>10 then
    raise exception 'runtime_review_expected_10_found_%',v_count;
  end if;

  select count(*) into v_mistake_count
  from public.get_recent_practice_mistakes_safe_v5(
    'mathematics','Algebra','Basics',10
  );
  if v_mistake_count<>1 then
    raise exception 'runtime_recent_mistakes_expected_1_found_%',v_mistake_count;
  end if;

  v_drill:=public.start_practice_mistakes_drill_safe_v5(
    'mathematics',array[v_wrong_qid],'runtime-mistake-drill-001'
  );
  v_drill_sid:=(v_drill->>'session_id')::bigint;
  v_submit:=public.submit_practice_drill_answer_safe_v5(
    v_drill_sid,v_wrong_qid,'A',0,5
  );
  if coalesce((v_submit->>'is_correct')::boolean,false) is not true
     or coalesce((v_submit->>'complete')::boolean,false) is not true then
    raise exception 'runtime_mistake_drill_submit_failed_%',v_submit;
  end if;

  v_topic:=public.start_practice_topic_drill_safe_v5(
    'mathematics','Algebra','Basics','runtime-topic-drill-001'
  );
  if coalesce((v_topic->>'question_count')::integer,0) not between 1 and 10 then
    raise exception 'runtime_topic_drill_bad_count_%',v_topic;
  end if;

  -- Non-Mathematics subjects retain legacy no-metadata compatibility.
  v_econ:=public.start_practice_session_auto_safe_v5(
    701,'runtime-economics-001'
  );
  v_econ_sid:=(v_econ->>'session_id')::bigint;
  select count(*) into v_count
  from public.practice_sessions_v4 s,
       unnest(s.question_ids) qid
  where s.id=v_econ_sid
    and qid between 7001 and 7010;
  if v_count<>10 then
    raise exception 'runtime_non_math_legacy_compatibility_failed_%',v_econ;
  end if;

  -- Exact rollback signature: published v2 metadata + runtime disabled.
  update private.practice_v2_question_meta
  set is_runtime_allowed=false
  where release_version='math_p1_practice_v2_2026_10_07';

  v_legacy:=public.start_practice_session_auto_safe_v5(
    502,'runtime-rollback-legacy-001'
  );
  v_legacy_sid:=(v_legacy->>'session_id')::bigint;

  select count(*) into v_count
  from public.practice_sessions_v4 s,
       unnest(s.question_ids) qid
  where s.id=v_legacy_sid and qid=1500;

  if v_count<>1 then
    raise exception 'runtime_rollback_legacy_fallback_failed_%',v_legacy;
  end if;
end;
$runtime$;

select 'MATHEMATICS_PRACTICE_V2_RUNTIME_REHEARSAL_GREEN' as result;
