-- P2-04: official Cambridge June 2026 reference patch v1.
-- Additive metadata-only reference and learner-safe annotation for the already deployed
-- Stage 4 Timed Consolidation wrapper.
-- No learner evidence, mastery, Practice/Tour history, certificates or feature flags are changed.

begin;

do $source_preflight$
begin
  if exists(
    select 1 from private.exam_prep_source_registry
    where id in (7,8)
      and (source_key,source_version) not in (
        ('cambridge_9709_june_2026_p1_reference','9709/12:June 2026'),
        ('cambridge_9709_june_2026_p5_reference','9709/52:June 2026')
      )
  ) then
    raise exception 'P2-04 Cambridge June 2026 source-registry id collision';
  end if;
end
$source_preflight$;

insert into private.exam_prep_source_registry(
  id,source_key,source_version,source_level,source_kind,
  title_en,title_ru,title_uz,
  role_en,role_ru,role_uz,
  can_define_scope,can_define_coverage_denominator,can_support_assessment_evidence,
  downstream_only,rights_status,official_url,status,checked_at
)
values
(
  7,
  'cambridge_9709_june_2026_p1_reference',
  '9709/12:June 2026',
  4,
  'official_exam_workflow',
  'Cambridge 9709/12 June 2026 official series reference',
  'Официальный reference Cambridge 9709/12, серия June 2026',
  'Cambridge 9709/12 June 2026 rasmiy seriya reference',
  'Official Cambridge June 2026 P1 series reference for format and timing context only. Cambridge states that the 29 April 2026 Paper 12 in administrative zones 3 and 4 was cancelled after premature sharing and a replacement paper was sat on 9 June. iClub stores no Cambridge question content and does not use the cancelled paper as a direct score-calibration benchmark.',
  'Официальный reference Cambridge June 2026 для P1 используется только для сверки формата и условий по времени. Cambridge сообщает, что Paper 12 от 29 апреля 2026 года в административных зонах 3 и 4 был отменён после преждевременного распространения, а новый вариант проводился 9 июня. iClub не хранит текст заданий Cambridge и не использует отменённый вариант как прямой эталон баллов.',
  'Cambridge June 2026 P1 rasmiy reference faqat format va vaqt shartlarini tekshirish uchun ishlatiladi. Cambridge ma’lumotiga ko‘ra, 2026-yil 29-apreldagi 3 va 4 ma’muriy zonalardagi Paper 12 muddatidan oldin tarqalganidan keyin bekor qilingan va yangi variant 9-iyunda o‘tkazilgan. iClub Cambridge savol matnlarini saqlamaydi va bekor qilingan variantni ballarni bevosita kalibrlash mezoni sifatida ishlatmaydi.',
  false,false,false,false,
  'metadata_only_external',
  'https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/',
  'active',
  now()
),
(
  8,
  'cambridge_9709_june_2026_p5_reference',
  '9709/52:June 2026',
  4,
  'official_exam_workflow',
  'Cambridge 9709/52 June 2026 official series reference',
  'Официальный reference Cambridge 9709/52, серия June 2026',
  'Cambridge 9709/52 June 2026 rasmiy seriya reference',
  'Official Cambridge June 2026 P5 series reference for format and timing context only. Cambridge states that Paper 52 in administrative zones 3 and 4 was shared prematurely and assessed marks were used. iClub stores no Cambridge question content and does not use this affected paper as a direct score-calibration benchmark.',
  'Официальный reference Cambridge June 2026 для P5 используется только для сверки формата и условий по времени. Cambridge сообщает, что Paper 52 в административных зонах 3 и 4 был преждевременно распространён и для него применялись assessed marks. iClub не хранит текст заданий Cambridge и не использует этот затронутый вариант как прямой эталон баллов.',
  'Cambridge June 2026 P5 rasmiy reference faqat format va vaqt shartlarini tekshirish uchun ishlatiladi. Cambridge ma’lumotiga ko‘ra, 3 va 4 ma’muriy zonalardagi Paper 52 muddatidan oldin tarqalgan va assessed marks qo‘llangan. iClub Cambridge savol matnlarini saqlamaydi va ushbu ta’sirlangan variantni ballarni bevosita kalibrlash mezoni sifatida ishlatmaydi.',
  false,false,false,false,
  'metadata_only_external',
  'https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-a-level-mathematics-june-2026-exam-series-paper-52/',
  'active',
  now()
)
on conflict(source_key,source_version) do update
set title_en=excluded.title_en,
    title_ru=excluded.title_ru,
    title_uz=excluded.title_uz,
    role_en=excluded.role_en,
    role_ru=excluded.role_ru,
    role_uz=excluded.role_uz,
    rights_status=excluded.rights_status,
    official_url=excluded.official_url,
    status='active',
    checked_at=excluded.checked_at;

create or replace function public.get_exam_prep_stage4_consolidation_safe_v1(
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_result jsonb;
  v_timed jsonb;
  v_stage smallint:=0;
  v_reason text;
  v_reference_url text;
begin
  v_uid:=private.exam_prep_require_core_access_v1();

  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select program_version_id
  into v_program
  from private.exam_prep_exam_profiles
  where user_id=v_uid;

  if v_program is null then
    raise exception 'exam_prep_profile_required';
  end if;

  select coalesce(s.operational_stage,0)
  into v_stage
  from private.exam_prep_stage_states s
  where s.user_id=v_uid
    and s.program_version_id=v_program
    and s.component_code=p_component_code
  order by s.derived_at desc
  limit 1;

  v_result:=private.exam_prep_stage4_exit_status_v1(
    v_uid,
    v_program,
    p_component_code
  );
  v_timed:=coalesce(v_result->'timed_section_gate','{}'::jsonb);
  v_reason:=coalesce(v_result->>'reason_code','evidence_incomplete');

  select official_url
  into v_reference_url
  from private.exam_prep_source_registry
  where source_key=case
      when p_component_code='P1' then 'cambridge_9709_june_2026_p1_reference'
      else 'cambridge_9709_june_2026_p5_reference'
    end
    and source_version=case
      when p_component_code='P1' then '9709/12:June 2026'
      else '9709/52:June 2026'
    end
    and status='active';

  return jsonb_build_object(
    'component_code',p_component_code,
    'operational_stage',coalesce(v_stage,0),
    'ready',coalesce((v_result->>'ready')::boolean,false),
    'reason_code',v_reason,
    'stage3_complete',coalesce((v_result->>'stage3_exit_ready')::boolean,false),

    'comparable_full_attempts',coalesce((v_result->>'selected_family_attempt_count')::int,0),
    'comparable_full_required',coalesce((v_result->>'min_compatible_full_attempts')::int,2),

    'timed_sections_completed',coalesce((v_timed->>'completed_distinct_timed_section_count')::int,0),
    'timed_sections_required',coalesce((v_timed->>'required_majority_count')::int,0),
    'timed_section_gate_ready',coalesce((v_result->>'timed_section_gate_ready')::boolean,false),

    'trend_ready',coalesce((v_result->>'trend_gate_ready')::boolean,false),
    'previous_unattempted_share',case when v_result->>'previous_unattempted_share' is null then null else (v_result->>'previous_unattempted_share')::numeric end,
    'latest_unattempted_share',case when v_result->>'latest_unattempted_share' is null then null else (v_result->>'latest_unattempted_share')::numeric end,
    'previous_after_time_share',case when v_result->>'previous_after_time_share' is null then null else (v_result->>'previous_after_time_share')::numeric end,
    'latest_after_time_share',case when v_result->>'latest_after_time_share' is null then null else (v_result->>'latest_after_time_share')::numeric end,

    'skills_below_required_level',coalesce((v_result->>'below_l3_count')::int,0),
    'skills_without_qualified_plan',coalesce((v_result->>'unqualified_below_l3_count')::int,0),
    'corrective_plan_ready',coalesce((v_result->>'corrective_plan_gate_ready')::boolean,false),

    'next_action_code',case v_reason
      when 'stage3_exit_incomplete' then 'complete_syllabus_closure'
      when 'two_comparable_full_attempts_incomplete' then 'complete_full_paper'
      when 'timing_trend_incomplete' then 'improve_timed_completion'
      when 'timed_section_majority_incomplete' then 'complete_timed_practice'
      when 'l3_or_corrective_plan_incomplete' then 'work_corrections'
      when 'ready' then 'continue_exam_readiness'
      else 'continue_evidence'
    end,

    'component_isolation',true,
    'modified_or_topic_results_count_as_comparable_full',false,

    'official_reference_series','Cambridge International AS & A Level Mathematics 9709 · June 2026',
    'official_reference_component',case when p_component_code='P1' then '9709/12' else '9709/52' end,
    'official_reference_url',v_reference_url,
    'official_reference_scope','format_and_timing_context_only',
    'official_reference_used_for_direct_score_calibration',false,
    'official_reference_question_content_copied',false
  );
end;
$$;

revoke all on function public.get_exam_prep_stage4_consolidation_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_stage4_consolidation_safe_v1(text) to authenticated,service_role;

do $$
declare
  v_rule_count int;
  v_p1_scope int;
  v_p5_scope int;
  v_cfg private.exam_prep_feature_config%rowtype;
begin
  if (select count(*) from private.exam_prep_source_registry
      where source_key in (
        'cambridge_9709_june_2026_p1_reference',
        'cambridge_9709_june_2026_p5_reference'
      )
        and source_level=4
        and source_kind='official_exam_workflow'
        and rights_status='metadata_only_external'
        and can_define_scope=false
        and can_define_coverage_denominator=false
        and can_support_assessment_evidence=false
        and status='active'
        and official_url like 'https://www.cambridgeinternational.org/%')<>2
  then
    raise exception 'P2-04 official Cambridge June 2026 reference rows missing';
  end if;

  if to_regprocedure('private.exam_prep_stage4_exit_status_v1(uuid,bigint,text)') is null then
    raise exception 'P2-04 private Stage-4 evaluator missing';
  end if;
  if to_regprocedure('private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)') is null then
    raise exception 'P2-04 timed-section gate missing';
  end if;
  if to_regprocedure('public.get_exam_prep_stage4_consolidation_safe_v1(text)') is null then
    raise exception 'P2-04 learner-safe Stage-4 RPC missing';
  end if;

  select count(*) into v_rule_count
  from private.exam_prep_stage4_exit_rules
  where status='active';
  if v_rule_count<>1 then
    raise exception 'P2-04 expected exactly one active Stage-4 rule, got %',v_rule_count;
  end if;

  select count(*) into v_p1_scope
  from private.exam_prep_stage4_timed_section_scope sc
  join private.exam_prep_stage4_exit_rules r on r.rule_version=sc.rule_version
  where r.status='active' and sc.component_code='P1' and sc.required;

  select count(*) into v_p5_scope
  from private.exam_prep_stage4_timed_section_scope sc
  join private.exam_prep_stage4_exit_rules r on r.rule_version=sc.rule_version
  where r.status='active' and sc.component_code='P5' and sc.required;

  if v_p1_scope<1 or v_p5_scope<1 then
    raise exception 'P2-04 governed timed-section scope missing P1=% P5=%',v_p1_scope,v_p5_scope;
  end if;

  if has_function_privilege('anon','public.get_exam_prep_stage4_consolidation_safe_v1(text)','EXECUTE') then
    raise exception 'P2-04 anon must not execute learner Stage-4 RPC';
  end if;
  if not has_function_privilege('authenticated','public.get_exam_prep_stage4_consolidation_safe_v1(text)','EXECUTE') then
    raise exception 'P2-04 authenticated learner RPC privilege missing';
  end if;

  select * into v_cfg
  from private.exam_prep_feature_config
  where id=1;
  if v_cfg.rollout_state<>'controlled_beta'
     or not v_cfg.core_enabled
     or v_cfg.ai_enabled
     or v_cfg.mentor_enabled
     or v_cfg.kill_switch then
    raise exception 'P2-04 Core-only controlled-beta boundary drift';
  end if;
end
$$;

commit;
