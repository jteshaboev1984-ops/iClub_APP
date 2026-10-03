-- Exam Prep AI skill-context personalization v1.
-- Read-only context enrichment for AI Tutor.
-- No feature flags, entitlements, academic state, legacy rows, Practice, Tours,
-- ratings, certificates or learner progress are changed by this migration.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

create or replace function private.exam_prep_ai_skill_theory_context_payload_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_locale text:=lower(coalesce(p_locale,''));
  v_program bigint;
  v_node private.exam_prep_syllabus_nodes%rowtype;
  v_has_source boolean:=false;
  v_detail jsonb;
  v_state jsonb;
  v_status text;
  v_attempt_count integer:=0;
  v_correct_count integer:=0;
  v_unresolved integer:=0;
  v_has_successful_retest boolean:=false;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_ai_theory_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if p_skill_code is null or btrim(p_skill_code)='' then raise exception 'exam_prep_skill_code_required'; end if;
  if v_locale not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then raise exception 'exam_prep_ai_theory_program_missing'; end if;

  select * into v_node
  from private.exam_prep_syllabus_nodes n
  where n.program_version_id=v_program
    and n.component_code=p_component_code
    and n.skill_code=p_skill_code;
  if v_node.skill_code is null then
    raise exception 'exam_prep_skill_not_found' using errcode='P0002';
  end if;

  select exists(
    select 1
    from private.exam_prep_ai_source_cards c
    where c.component_code=p_component_code
      and c.skill_code=p_skill_code
      and c.card_type='theory'
      and c.locale=v_locale
      and c.approval_status='approved'
      and c.is_runtime_allowed
      and c.rights_status in ('original_iclub','official_public_metadata','licensed')
  ) into v_has_source;

  if not v_has_source then
    return jsonb_build_object(
      'mapped',false,
      'component_code',p_component_code,
      'skill_code',p_skill_code,
      'locale',v_locale,
      'reason','approved_theory_source_missing'
    );
  end if;

  -- Reuse the same authoritative read model as the learner skill-detail screen,
  -- but expose only a minimized, non-authoritative subset to AI.
  v_detail:=private.exam_prep_skill_detail_payload_v1(
    p_user_id,p_component_code,p_skill_code
  );
  v_state:=coalesce(v_detail->'state','{}'::jsonb);

  v_attempt_count:=coalesce((v_state->>'objective_evidence_count')::integer,0);
  v_correct_count:=coalesce((v_state->>'correct_objective_count')::integer,0);
  v_unresolved:=coalesce((v_state->>'unresolved_correction_count')::integer,0);
  v_has_successful_retest:=coalesce((v_state->>'has_successful_retest')::boolean,false);

  v_status:=case
    when v_unresolved>0 then 'needs_correction'
    when coalesce((v_state->>'objective_level')::integer,0)>=2 then 'confirmed'
    when coalesce((v_state->>'evidence_total')::integer,0)>0 then 'in_progress'
    else 'not_started'
  end;

  return jsonb_build_object(
    'mapped',true,
    'component_code',p_component_code,
    'skill_code',v_node.skill_code,
    'official_syllabus_section',v_node.official_syllabus_section,
    'description',v_node.canonical_description,
    'locale',v_locale,
    'learner_context',jsonb_build_object(
      'status',v_status,
      'attempt_count',v_attempt_count,
      'correct_count',v_correct_count,
      'unresolved_correction_count',v_unresolved,
      'has_successful_retest',v_has_successful_retest
    )
  );
end
$fn$;

revoke all on function private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)
  to service_role;

do $postcheck$
begin
  if to_regprocedure('private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)') is null then
    raise exception 'AI skill-context personalization function missing';
  end if;

  if has_function_privilege(
      'authenticated',
      'private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)',
      'EXECUTE'
    )
  then
    raise exception 'AI skill-context private function leaked to authenticated';
  end if;

  if not has_function_privilege(
      'service_role',
      'private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)',
      'EXECUTE'
    )
  then
    raise exception 'AI skill-context service_role execution missing';
  end if;
end
$postcheck$;

commit;
