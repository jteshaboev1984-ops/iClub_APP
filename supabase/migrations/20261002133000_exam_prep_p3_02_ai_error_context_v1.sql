-- P3-02 AI established-error context v1.
-- Additive, AI remains independently disabled. No academic-state mutation.
-- Makes one additional AI value flow possible only from a completed, incorrect
-- diagnostic response that already has an approved deterministic diagnostic rule.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

create or replace function private.exam_prep_ai_error_context_payload_v1(
  p_user_id uuid,
  p_component_code text,
  p_session_id uuid,
  p_item_order integer,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_locale text:=lower(coalesce(p_locale,''));
  v_payload jsonb;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_ai_error_context_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;
  if p_session_id is null or coalesce(p_item_order,0)<1 then
    raise exception 'exam_prep_ai_error_context_reference_required';
  end if;
  if v_locale not in ('en','ru','uz') then
    raise exception 'exam_prep_bad_language';
  end if;

  if not exists(
    select 1
    from private.exam_prep_sessions s
    where s.id=p_session_id
      and s.user_id=p_user_id
      and s.component_code=p_component_code
      and s.status='finalized'
      and s.finalized_at is not null
  ) then
    return jsonb_build_object(
      'mapped',false,
      'component_code',p_component_code,
      'session_id',p_session_id,
      'item_order',p_item_order,
      'reason','finalized_session_not_found'
    );
  end if;

  select jsonb_build_object(
    'mapped',true,
    'component_code',p_component_code,
    'session_id',p_session_id,
    'item_order',si.item_order,
    'skill_code',si.primary_skill_code,
    'skill_description',coalesce(n.canonical_description,si.primary_skill_code),
    'diagnostic_feedback',
      case v_locale when 'ru' then d.feedback_ru when 'uz' then d.feedback_uz else d.feedback_en end,
    'next_action',
      case v_locale when 'ru' then d.next_action_ru when 'uz' then d.next_action_uz else d.next_action_en end,
    'locale',v_locale
  )
  into v_payload
  from private.exam_prep_session_items si
  join private.exam_prep_sessions s
    on s.id=si.session_id
   and s.id=p_session_id
   and s.user_id=p_user_id
   and s.component_code=p_component_code
   and s.status='finalized'
   and s.finalized_at is not null
  join private.exam_prep_responses r
    on r.session_id=si.session_id
   and r.item_order=si.item_order
   and r.user_id=p_user_id
   and r.response_kind='machine'
   and r.is_correct is false
  join private.exam_prep_diagnostic_rules d
    on d.content_meta_id=si.content_meta_id
   and d.status='approved'
   and d.answer_match=r.selected_answer
  left join private.exam_prep_syllabus_nodes n
    on n.program_version_id=s.program_version_id
   and n.component_code=p_component_code
   and n.skill_code=si.primary_skill_code
  where si.session_id=p_session_id
    and si.item_order=p_item_order
    and si.item_kind='question'
    and si.reserve_role='diagnostic'
  order by d.approved_at desc nulls last,d.id desc
  limit 1;

  if v_payload is null then
    return jsonb_build_object(
      'mapped',false,
      'component_code',p_component_code,
      'session_id',p_session_id,
      'item_order',p_item_order,
      'reason','no_approved_diagnostic_mapping'
    );
  end if;

  return v_payload;
end;
$$;

revoke all on function private.exam_prep_ai_error_context_payload_v1(uuid,text,uuid,integer,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_ai_error_context_payload_v1(uuid,text,uuid,integer,text)
  to service_role;

create or replace function public.get_exam_prep_ai_error_context_safe_v1(
  p_component_code text,
  p_session_id uuid,
  p_item_order integer,
  p_locale text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_ai_error_context_payload_v1(
    v_uid,p_component_code,p_session_id,p_item_order,p_locale
  );
end;
$$;

revoke all on function public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)
  from public,anon;
grant execute on function public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)
  to authenticated,service_role;

insert into private.exam_prep_ai_source_cards(
  source_card_key,component_code,skill_code,card_type,locale,source_version,title,body_text,
  approval_status,rights_status,is_runtime_allowed,content_hash,approved_at
) values
(
  'p1:error_explanation:en:v1','P1',null,'error_explanation','en','p3_02_error_context_v1_2026_10_02',
  'Understanding a recorded Paper 1 error',
  'For a completed Paper 1 diagnostic item, an approved iClub diagnostic rule may describe the learner''s established error and next action. Explain only that recorded feedback and action. Do not infer a different misconception, reveal the correct answer, award marks, or change mastery or readiness.',
  'approved','original_iclub',true,'554f6bf9f54bc9fdbf4beb842601e3c5f6db3b19d6d21ae67a224b757fcdef27',now()
),
(
  'p1:error_explanation:ru:v1','P1',null,'error_explanation','ru','p3_02_error_context_v1_2026_10_02',
  'Разбор зафиксированной ошибки Paper 1',
  'Для завершённого диагностического задания Paper 1 утверждённое правило iClub может описывать зафиксированную ошибку ученика и следующий шаг. Объясняйте только это подтверждённое описание и действие. Не придумывайте другую причину ошибки, не раскрывайте правильный ответ, не выставляйте баллы и не меняйте mastery или готовность.',
  'approved','original_iclub',true,'af891388330bdd30f33d87b4173b361bff7cac91a257bf7214cc5b0f95751679',now()
),
(
  'p1:error_explanation:uz:v1','P1',null,'error_explanation','uz','p3_02_error_context_v1_2026_10_02',
  'Paper 1 dagi qayd etilgan xatoni tushunish',
  'Yakunlangan Paper 1 diagnostika topshirig‘i uchun tasdiqlangan iClub qoidasi o‘quvchining qayd etilgan xatosi va keyingi qadamini ko‘rsatishi mumkin. Faqat shu tasdiqlangan izoh va amalni tushuntiring. Boshqa xato sababini o‘ylab topmang, to‘g‘ri javobni oshkor qilmang, ball bermang va mastery yoki tayyorlikni o‘zgartirmang.',
  'approved','original_iclub',true,'181719afed9afdc7de176ca746c3f415a9f74c085e58773da112526db6420257',now()
),
(
  'p5:error_explanation:en:v1','P5',null,'error_explanation','en','p3_02_error_context_v1_2026_10_02',
  'Understanding a recorded Paper 5 error',
  'For a completed Paper 5 diagnostic item, an approved iClub diagnostic rule may describe the learner''s established error and next action. Explain only that recorded feedback and action. Do not infer a different misconception, reveal the correct answer, award marks, or change mastery or readiness.',
  'approved','original_iclub',true,'50d3969633eb4b6937b0be0e0efc7877c88566d676eb2cf4f16405f7585d7f95',now()
),
(
  'p5:error_explanation:ru:v1','P5',null,'error_explanation','ru','p3_02_error_context_v1_2026_10_02',
  'Разбор зафиксированной ошибки Paper 5',
  'Для завершённого диагностического задания Paper 5 утверждённое правило iClub может описывать зафиксированную ошибку ученика и следующий шаг. Объясняйте только это подтверждённое описание и действие. Не придумывайте другую причину ошибки, не раскрывайте правильный ответ, не выставляйте баллы и не меняйте mastery или готовность.',
  'approved','original_iclub',true,'764877fe595125d53f2a770dfc4887fe446f003fdabef70b671e690e15702647',now()
),
(
  'p5:error_explanation:uz:v1','P5',null,'error_explanation','uz','p3_02_error_context_v1_2026_10_02',
  'Paper 5 dagi qayd etilgan xatoni tushunish',
  'Yakunlangan Paper 5 diagnostika topshirig‘i uchun tasdiqlangan iClub qoidasi o‘quvchining qayd etilgan xatosi va keyingi qadamini ko‘rsatishi mumkin. Faqat shu tasdiqlangan izoh va amalni tushuntiring. Boshqa xato sababini o‘ylab topmang, to‘g‘ri javobni oshkor qilmang, ball bermang va mastery yoki tayyorlikni o‘zgartirmang.',
  'approved','original_iclub',true,'937877e337416a64bbfa2aee1de94793f51ea0f29c3f2c568d0886818e615b73',now()
)
on conflict(source_card_key) do nothing;

do $$
declare
  v_cards integer;
begin
  if to_regprocedure('public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)') is null then
    raise exception 'P3-02 AI error context safe RPC missing';
  end if;
  if has_function_privilege('anon','public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_ai_error_context_safe_v1(text,uuid,integer,text)','EXECUTE')
  then
    raise exception 'P3-02 AI error context execute boundary drift';
  end if;
  if has_function_privilege('authenticated','private.exam_prep_ai_error_context_payload_v1(uuid,text,uuid,integer,text)','EXECUTE') then
    raise exception 'P3-02 private AI error context leaked to browser role';
  end if;

  select count(*) into v_cards
  from private.exam_prep_ai_source_cards
  where source_card_key in (
    'p1:error_explanation:en:v1','p1:error_explanation:ru:v1','p1:error_explanation:uz:v1',
    'p5:error_explanation:en:v1','p5:error_explanation:ru:v1','p5:error_explanation:uz:v1'
  )
    and approval_status='approved'
    and rights_status='original_iclub'
    and is_runtime_allowed
    and card_type='error_explanation';
  if v_cards<>6 then
    raise exception 'P3-02 error source-card contract failed expected=6 actual=%',v_cards;
  end if;
end
$$;

commit;
