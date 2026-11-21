-- Disposable fixture rollback to exact pre-cutover 2026-11-20 production-source
-- evaluator. NEVER apply this to live without separately reviewed rollback GO.
CREATE OR REPLACE FUNCTION public.iclub_eval_tour_question_safe_v4(p_question_id bigint, p_user_answer text, p_picked_index integer DEFAULT NULL::integer, p_answered boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'auth', 'pg_temp'
AS $function$
declare
  v_q public.questions%rowtype;
  v_selected text;
  v_correct boolean := false;
begin
  select q.* into v_q from public.questions q where q.id=p_question_id and q.is_active is true;
  if v_q.id is null then raise exception 'question_not_found_or_inactive' using errcode='P0002'; end if;
  if coalesce(p_answered,true) is false then return jsonb_build_object('selected_answer',null,'is_correct',false); end if;
  if lower(coalesce(v_q.qtype,''))='mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected := chr(65+p_picked_index);
    elsif upper(trim(coalesce(p_user_answer,''))) ~ '^[A-Z]$' then
      v_selected := upper(trim(p_user_answer));
    elsif trim(coalesce(p_user_answer,'')) ~ '^[0-9]+$' and trim(p_user_answer)::integer between 0 and 25 then
      v_selected := chr(65+trim(p_user_answer)::integer);
    else
      v_selected := upper(trim(coalesce(p_user_answer,'')));
    end if;
    v_correct := upper(trim(coalesce(v_selected,'')))=upper(trim(coalesce(v_q.correct_answer,'')));
  else
    v_selected := trim(coalesce(p_user_answer,''));
    if v_q.subject_id=4 and (v_q.id IN (1946,1965) or exists (
      select 1 from private.chemistry_t1_stage_20261015 s where s.question_id=v_q.id and s.payload->>'candidate_id'=s.candidate_id and v_q.qtype='input'
    )) then
      v_correct:=private.iclub_chemistry_t1_typed_correct_20261015(v_q.id,p_user_answer);
    elsif v_q.subject_id=4 and exists (
      select 1 from private.chemistry_t3_stage_20261015 s
       where s.question_id=v_q.id and s.payload->>'qtype'='input'
    ) then
      v_correct:=private.iclub_chem_t3_numeric_correct_20261015(v_q.id,v_selected);
    elsif v_q.subject_id=4 and exists (
      select 1 from private.chemistry_release_staging_20261015 s
      where s.question_id=v_q.id and s.payload->>'qtype'='input'
    ) then
      v_correct:=private.iclub_chemistry_release_numeric_correct_20261015(v_q.id,v_selected);
    elsif v_q.subject_id=4 and exists (
      select 1 from private.chemistry_t2_stage_20261015 s
       where s.question_id=v_q.id and s.payload->>'qtype'='input'
    ) then
      v_correct:=private.iclub_chem_t2_numeric_correct_20261015(v_q.id,v_selected);
    else
      v_correct := public.iclub_tour_input_is_correct_v4(v_selected,v_q.correct_answer);
    end if;
  end if;
  return jsonb_build_object('selected_answer',nullif(v_selected,''),'is_correct',v_correct);
end;
$function$
;
