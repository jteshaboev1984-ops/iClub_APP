-- Atomic existing-function upgrade for Practice topic mistakes and review.
-- No data backfill, no user-progress or Tour modifications.
DO $safe_patch$
DECLARE
  v_function text;
  v_old text;
  v_new text;
  v_oid oid;
  v_count integer;
BEGIN
  -- A) The existing submit RPC: on first FINALIZATION of a voluntary topic attempt,
  -- add one source-bound recommendation per mistaken topic/subtopic (no backfill).
  SELECT p.oid INTO v_oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='submit_practice_drill_answer_safe_v5'
    AND pg_get_function_identity_arguments(p.oid)='p_session_id bigint, p_question_id bigint, p_user_answer text, p_picked_index integer, p_time_spent integer';
  IF v_oid IS NULL THEN RAISE EXCEPTION 'submit_rpc_signature_changed'; END IF;
  v_function:=pg_get_functiondef(v_oid);
  v_old:='    where id=p_session_id'||chr(10)||'      and user_id=v_uid;'||chr(10)||'  end if;'||chr(10)||chr(10)||'  return jsonb_build_object(';
  v_new:='    where id=p_session_id'||chr(10)||'      and user_id=v_uid;'||chr(10)||
'    -- Only voluntarily chosen Practice-by-topic; never recommendation drills or Tours.'||chr(10)||
'    if v_s.drill_type=''rec_topic'' and left(v_s.client_session_id,22)=''practice_topic_choice_'' then'||chr(10)||
'      insert into public.recommendations'||chr(10)||
'        (user_id,subject_id,source_type,topic,subtopic,practice_drill_session_id)'||chr(10)||
'      select v_uid,v_s.subject_id,''practice'',q.topic,q.subtopic,v_s.id'||chr(10)||
'      from public.practice_drill_answers_v4 a'||chr(10)||
'      join public.questions q on q.id=a.question_id and q.subject_id=v_s.subject_id'||chr(10)||
'      where a.session_id=v_s.id and a.is_correct is false and nullif(trim(q.topic),'''') is not null'||chr(10)||
'        and not exists ('||chr(10)||
'          select 1 from public.recommendations r'||chr(10)||
'          where r.user_id=v_uid and r.subject_id=v_s.subject_id'||chr(10)||
'            and r.source_type=''practice'' and r.bank_generation=v_s.bank_generation'||chr(10)||
'            and r.practice_drill_session_id is not null'||chr(10)||
'            and r.topic=q.topic and coalesce(r.subtopic,'''')=coalesce(q.subtopic,'''')'||chr(10)||
'        )'||chr(10)||
'      group by q.topic,q.subtopic'||chr(10)||
'      on conflict do nothing;'||chr(10)||
'    end if;'||chr(10)||
'  end if;'||chr(10)||chr(10)||'  return jsonb_build_object(';
  v_count:=(length(v_function)-length(replace(v_function,v_old,'')))/length(v_old);
  IF v_count<>1 THEN RAISE EXCEPTION 'submit_rpc_anchor_mismatch_%',v_count; END IF;
  EXECUTE replace(v_function,v_old,v_new);

  -- B) Existing retest RPC: allow an owned wrong answer from any of the two
  -- Practice session stores or a completed voluntary topic attempt.
  SELECT p.oid INTO v_oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='start_practice_mistakes_drill_safe_v5'
    AND pg_get_function_identity_arguments(p.oid)='p_subject_key text, p_question_ids bigint[], p_client_session_id text';
  IF v_oid IS NULL THEN RAISE EXCEPTION 'retest_rpc_signature_changed'; END IF;
  v_function:=pg_get_functiondef(v_oid);
  v_old:='    and exists('||chr(10)||
'      select 1'||chr(10)||
'      from public.practice_answers pa'||chr(10)||
'      join public.practice_attempts pat'||chr(10)||
'        on pat.id=pa.attempt_id'||chr(10)||
'       and pat.user_id=v_uid'||chr(10)||
'       and pat.subject_id=v_subject_id'||chr(10)||
'      where pa.question_id=q.id'||chr(10)||
'        and pa.is_correct is false'||chr(10)||
'    );';
  v_new:='    and ('||chr(10)||
'      exists (select 1 from public.practice_answers a join public.practice_attempts p on p.id=a.attempt_id'||chr(10)||
'        where p.user_id=v_uid and p.subject_id=v_subject_id and a.question_id=q.id and a.is_correct is false)'||chr(10)||
'      or exists (select 1 from public.practice_session_answers_v4 a join public.practice_sessions_v4 s on s.id=a.session_id'||chr(10)||
'        where s.user_id=v_uid and s.subject_id=v_subject_id and s.status=''finalized'''||chr(10)||
'          and a.question_id=q.id and a.is_correct is false)'||chr(10)||
'      or exists (select 1 from public.practice_drill_answers_v4 a join public.practice_drill_sessions_v4 s on s.id=a.session_id'||chr(10)||
'        where s.user_id=v_uid and s.subject_id=v_subject_id and s.status=''finalized'''||chr(10)||
'          and s.drill_type=''rec_topic'' and left(s.client_session_id,22)=''practice_topic_choice_'''||chr(10)||
'          and a.question_id=q.id and a.is_correct is false)'||chr(10)||
'    );';
  v_count:=(length(v_function)-length(replace(v_function,v_old,'')))/length(v_old);
  IF v_count<>1 THEN RAISE EXCEPTION 'retest_rpc_anchor_mismatch_%',v_count; END IF;
  EXECUTE replace(v_function,v_old,v_new);

  -- C) Existing recommendations RPC: expose the already-present session
  -- references, retaining its JSON contract and bank-generation scope.
  SELECT p.oid INTO v_oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_current_practice_recommendations_safe_v1'
    AND pg_get_function_identity_arguments(p.oid)='p_subject_key text';
  IF v_oid IS NULL THEN RAISE EXCEPTION 'recommendations_rpc_signature_changed'; END IF;
  v_function:=pg_get_functiondef(v_oid);
  v_old:='select id,source_type,topic,subtopic,book_id,book_reference,created_at,bank_generation';
  v_new:='select id,source_type,topic,subtopic,book_id,book_reference,created_at,bank_generation,practice_session_id,practice_drill_session_id';
  v_count:=(length(v_function)-length(replace(v_function,v_old,'')))/length(v_old);
  IF v_count<>1 THEN RAISE EXCEPTION 'recommendations_rpc_anchor_mismatch_%',v_count; END IF;
  EXECUTE replace(v_function,v_old,v_new);

  -- D) Existing topic history RPC: add the source session ID so a completed
  -- attempt can be opened; no score, count or ordering changes.
  SELECT p.oid INTO v_oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_practice_topic_history_safe_v1'
    AND pg_get_function_identity_arguments(p.oid)='p_subject_key text';
  IF v_oid IS NULL THEN RAISE EXCEPTION 'topic_history_rpc_signature_changed'; END IF;
  v_function:=pg_get_functiondef(v_oid);
  v_old:='''finished_at'',finished_at';
  v_new:='''finished_at'',finished_at,''session_id'',id,''mistakes'',total-correct,'||
    '''review'',(select coalesce(jsonb_agg(jsonb_build_object('||
    '''question_id'',q.id,''question_en'',q.question_text_en,''question_ru'',q.question_text_ru,''question_uz'',q.question_text_uz,'||
    '''options_en'',q.options_text_en,''options_ru'',q.options_text_ru,''options_uz'',q.options_text_uz,'||
    '''user_answer'',a.user_answer,''correct_answer'',q.correct_answer,'||
    '''explanation_en'',q.explanation_en,''explanation_ru'',q.explanation_ru,''explanation_uz'',q.explanation_uz,'||
    '''feedback_en'',dg.d->>''feedback_en'',''feedback_ru'',dg.d->>''feedback_ru'',''feedback_uz'',dg.d->>''feedback_uz'''||
    ')),''[]''::jsonb) from public.practice_drill_answers_v4 a'||
    ' join public.questions q on q.id=a.question_id'||
    ' left join lateral (select private.practice_match_answer_diagnostic_v5(q.id,a.user_answer) as d) dg on true'||
    ' where a.session_id=ranked.id and a.is_correct=false' ||chr(10)||
    ' and not public.iclub_practice_drill_question_protected_v4(q.id))';
  v_count:=(length(v_function)-length(replace(v_function,v_old,'')))/length(v_old);
  IF v_count<>3 THEN RAISE EXCEPTION 'topic_history_rpc_anchor_mismatch_%',v_count; END IF;
  EXECUTE replace(v_function,v_old,v_new);

  -- E) Existing owned drill resume RPC: allow answered, finalized voluntary
  -- topic attempts to be reviewed after bank rotation. Current active sessions
  -- remain unchanged and unanswered old keys are never disclosed.
  SELECT p.oid INTO v_oid FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.proname='get_practice_drill_resume_safe_v4'
    AND pg_get_function_identity_arguments(p.oid)='p_session_id bigint';
  IF v_oid IS NULL THEN RAISE EXCEPTION 'drill_resume_rpc_signature_changed'; END IF;
  v_function:=pg_get_functiondef(v_oid);
  v_old:='join public.questions q on q.id=x.qid and q.is_active is true';
  v_new:='join public.questions q on q.id=x.qid and (q.is_active is true or ('||chr(10)||
'    s.status=''finalized'' and s.drill_type=''rec_topic'''||chr(10)||
'    and left(s.client_session_id,22)=''practice_topic_choice_'''||chr(10)||
'    and exists(select 1 from public.practice_drill_answers_v4 a0 where a0.session_id=s.id and a0.question_id=q.id)'||chr(10)||
'    and not public.iclub_practice_drill_question_protected_v4(q.id)'||chr(10)||
'  ))';
  v_count:=(length(v_function)-length(replace(v_function,v_old,'')))/length(v_old);
  IF v_count<>1 THEN RAISE EXCEPTION 'drill_resume_rpc_anchor_mismatch_%',v_count; END IF;
  EXECUTE replace(v_function,v_old,v_new);
END
$safe_patch$;
