-- Issue #574. Disposable PG17 fixture ONLY (never run on live iClub).
-- Run after the normal Practice runtime fixture and the 20261118122500 candidate.
-- Assertions intentionally use fictional examples: no private bank or answer keys.
\set ON_ERROR_STOP on

begin;

insert into public.subjects(id,subject_key,title,type,is_active) values
  (95,'qa_practice_math','Synthetic Math','main',true),
  (97,'qa_practice_other','Synthetic Other','main',true);

insert into public.questions(id,subject_id,qtype,correct_answer,is_active) values
  (990101,95,'input','-4',true),
  (990102,95,'input','4.5',true),
  (990103,95,'input','10|10.0',true),
  (990104,95,'mcq','C',true),
  (990105,97,'input','-7',true);

do $regression$
declare
  v_def text;
  v_case record;
  v_actual boolean;
begin
  v_def := pg_get_functiondef(
    'public.iclub_eval_practice_question_safe_v4(bigint,text,integer)'::regprocedure
  );
  if position(
    $lit$from unnest(string_to_array(coalesce(v_q.correct_answer,''), '|')) accepted_answer$lit$
    in v_def
  )=0 then
    raise exception 'practice_literal_delimiter_source_missing';
  end if;
  if position('regexp_split_to_table(coalesce(v_q.correct_answer' in v_def)>0 then
    raise exception 'practice_old_regexp_split_still_installed';
  end if;
  if position('security definer' in lower(v_def))=0 then
    raise exception 'practice_scorer_security_mode_drift';
  end if;

  for v_case in
    select * from (values
      (990101::bigint,'-4'::text,null::integer,true),
      (990101::bigint,'−4'::text,null::integer,true),
      (990101::bigint,'-4,0'::text,null::integer,true),
      (990101::bigint,'4'::text,null::integer,false),
      (990101::bigint,'-3'::text,null::integer,false),
      (990101::bigint,'-5'::text,null::integer,false),
      (990101::bigint,'0'::text,null::integer,false),
      (990102::bigint,'4.5'::text,null::integer,true),
      (990102::bigint,'4,50'::text,null::integer,true),
      (990102::bigint,'4'::text,null::integer,false),
      (990102::bigint,'5'::text,null::integer,false),
      (990103::bigint,'10'::text,null::integer,true),
      (990103::bigint,'10.0'::text,null::integer,true),
      (990103::bigint,'1'::text,null::integer,false),
      (990103::bigint,'0'::text,null::integer,false),
      (990104::bigint,'C'::text,null::integer,true),
      (990104::bigint,'B'::text,null::integer,false),
      (990104::bigint,''::text,2,true),
      (990104::bigint,''::text,1,false),
      (990105::bigint,'-7'::text,null::integer,true),
      (990105::bigint,'7'::text,null::integer,false)
    ) as cases(question_id,user_answer,picked_index,expected)
  loop
    v_actual:=coalesce(
      (public.iclub_eval_practice_question_safe_v4(
        v_case.question_id,v_case.user_answer,v_case.picked_index
      )->>'is_correct')::boolean,false
    );
    if v_actual is distinct from v_case.expected then
      raise exception 'practice_evaluator_regression_failed_question_%',v_case.question_id;
    end if;
  end loop;

  raise notice 'PRACTICE_V4_LITERAL_DELIMITER_21_SYNTHETIC_CASES_PASS';
end;
$regression$;

rollback;
