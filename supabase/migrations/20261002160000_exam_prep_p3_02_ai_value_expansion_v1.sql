-- P3-02 AI value expansion v1.
-- Additive/read-only contexts plus approved original iClub source cards.
-- This migration does NOT enable AI, does NOT change learner entitlements,
-- and does NOT mutate academic state, legacy history, Practice, Tours or certificates.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

create or replace function private.exam_prep_ai_repeated_error_context_payload_v1(
  p_user_id uuid,
  p_component_code text,
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
  v_queue jsonb;
  v_items jsonb;
  v_count integer;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_ai_repeated_error_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;
  if v_locale not in ('en','ru','uz') then raise exception 'exam_prep_bad_language'; end if;

  v_queue:=private.exam_prep_correction_queue_payload_v1(p_user_id,p_component_code);

  select coalesce(jsonb_agg(jsonb_build_object(
    'skill_code',x.item->>'skill_code',
    'description',x.item->>'description',
    'official_syllabus_section',x.item->>'official_syllabus_section',
    'status',x.item->>'status',
    'process_step',x.item->>'process_step',
    'updated_at',x.item->>'updated_at'
  ) order by (x.item->>'updated_at')::timestamptz desc nulls last,x.item->>'skill_code'),'[]'::jsonb)
  into v_items
  from (
    select q.item
    from jsonb_array_elements(coalesce(v_queue->'cases','[]'::jsonb)) q(item)
    where q.item->>'focus_reason'='repeated_gap'
      and q.item->>'focus_kind'='correction'
      and q.item->>'status' in ('reopened','remediating')
    order by (q.item->>'updated_at')::timestamptz desc nulls last,q.item->>'skill_code'
    limit 3
  ) x;

  v_count:=jsonb_array_length(v_items);
  if v_count=0 then
    return jsonb_build_object(
      'mapped',false,
      'component_code',p_component_code,
      'locale',v_locale,
      'reason','no_repeated_gap'
    );
  end if;

  return jsonb_build_object(
    'mapped',true,
    'component_code',p_component_code,
    'locale',v_locale,
    'repeated_gap_count',v_count,
    'items',v_items
  );
end
$fn$;

revoke all on function private.exam_prep_ai_repeated_error_context_payload_v1(uuid,text,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_ai_repeated_error_context_payload_v1(uuid,text,text)
  to service_role;

create or replace function public.get_exam_prep_ai_repeated_error_context_safe_v1(
  p_component_code text,
  p_locale text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_ai_repeated_error_context_payload_v1(v_uid,p_component_code,p_locale);
end
$fn$;

revoke all on function public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)
  from public,anon;
grant execute on function public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)
  to authenticated,service_role;

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

  return jsonb_build_object(
    'mapped',true,
    'component_code',p_component_code,
    'skill_code',v_node.skill_code,
    'official_syllabus_section',v_node.official_syllabus_section,
    'description',v_node.canonical_description,
    'locale',v_locale
  );
end
$fn$;

revoke all on function private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)
  to service_role;

create or replace function public.get_exam_prep_ai_skill_theory_context_safe_v1(
  p_component_code text,
  p_skill_code text,
  p_locale text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_ai_skill_theory_context_payload_v1(
    v_uid,p_component_code,p_skill_code,p_locale
  );
end
$fn$;

revoke all on function public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)
  from public,anon;
grant execute on function public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)
  to authenticated,service_role;

insert into private.exam_prep_ai_source_cards(
  source_card_key,component_code,skill_code,card_type,locale,source_version,title,body_text,
  approval_status,rights_status,is_runtime_allowed,content_hash,approved_at,updated_at
) values
(
  'p1:repeated_error_summary:en:v1','P1',null,'error_explanation','en','p3_02_ai_value_v1_2026_10_02',
  'Understanding repeated Paper 1 difficulties',
  'When iClub has already marked a Paper 1 topic as a repeated gap, summarise only the recorded repeated-gap topics and their current correction step. Do not infer a new misconception, reveal correct answers, award marks, or change mastery, readiness, stage or progression.',
  'approved','original_iclub',true,'7a7f27d677c827617785f35085bcef1ff8778ba4a95d52628754880224581ec8',now(),now()
),
(
  'p1:repeated_error_summary:ru:v1','P1',null,'error_explanation','ru','p3_02_ai_value_v1_2026_10_02',
  'Повторяющиеся трудности Paper 1',
  'Если iClub уже отметил тему Paper 1 как повторяющуюся трудность, кратко объясняйте только зафиксированные темы и текущий шаг исправления. Не придумывайте новую причину ошибки, не раскрывайте правильные ответы, не выставляйте баллы и не меняйте mastery, готовность, этап или progression.',
  'approved','original_iclub',true,'db806c21fb8942de4114af29e10ea223f93b8fc1686cc5ef641c7ad4627d17a6',now(),now()
),
(
  'p1:repeated_error_summary:uz:v1','P1',null,'error_explanation','uz','p3_02_ai_value_v1_2026_10_02',
  'Paper 1 dagi takroriy qiyinchiliklar',
  'Agar iClub Paper 1 mavzusini takroriy qiyinchilik sifatida qayd etgan bo‘lsa, faqat qayd etilgan mavzular va joriy tuzatish qadamini qisqacha tushuntiring. Yangi xato sababini o‘ylab topmang, to‘g‘ri javoblarni oshkor qilmang, ball bermang va mastery, tayyorlik, bosqich yoki progressionni o‘zgartirmang.',
  'approved','original_iclub',true,'ebe3db21790d855b1ff83a7c914e4e58ada4ea60a22c3ca5a8182c50b9487560',now(),now()
),
(
  'p5:repeated_error_summary:en:v1','P5',null,'error_explanation','en','p3_02_ai_value_v1_2026_10_02',
  'Understanding repeated Paper 5 difficulties',
  'When iClub has already marked a Paper 5 topic as a repeated gap, summarise only the recorded repeated-gap topics and their current correction step. Do not infer a new misconception, reveal correct answers, award marks, or change mastery, readiness, stage or progression.',
  'approved','original_iclub',true,'8be3c7af7aa94aa7c0e0e3b1a87a3906fab775eb34c6252d08dd734962f5c1c8',now(),now()
),
(
  'p5:repeated_error_summary:ru:v1','P5',null,'error_explanation','ru','p3_02_ai_value_v1_2026_10_02',
  'Повторяющиеся трудности Paper 5',
  'Если iClub уже отметил тему Paper 5 как повторяющуюся трудность, кратко объясняйте только зафиксированные темы и текущий шаг исправления. Не придумывайте новую причину ошибки, не раскрывайте правильные ответы, не выставляйте баллы и не меняйте mastery, готовность, этап или progression.',
  'approved','original_iclub',true,'0de3c3d34b506100dbb9c34923bacdb6b42aa43466fc17724c821817f799c361',now(),now()
),
(
  'p5:repeated_error_summary:uz:v1','P5',null,'error_explanation','uz','p3_02_ai_value_v1_2026_10_02',
  'Paper 5 dagi takroriy qiyinchiliklar',
  'Agar iClub Paper 5 mavzusini takroriy qiyinchilik sifatida qayd etgan bo‘lsa, faqat qayd etilgan mavzular va joriy tuzatish qadamini qisqacha tushuntiring. Yangi xato sababini o‘ylab topmang, to‘g‘ri javoblarni oshkor qilmang, ball bermang va mastery, tayyorlik, bosqich yoki progressionni o‘zgartirmang.',
  'approved','original_iclub',true,'90f64cfd044daf7a8ca9ec41e6b753ffec4679a374fd962e6e9e1b685f6dbda8',now(),now()
),
(
  'p1:P1-QUA-02:theory:en:v1','P1','P1-QUA-02','theory','en','p3_02_ai_value_v1_2026_10_02',
  'Quadratic discriminant and real roots',
  'For ax^2 + bx + c = 0, the discriminant is D = b^2 - 4ac. If D > 0 there are two distinct real roots; if D = 0 there is one repeated real root; if D < 0 there are no real roots.',
  'approved','original_iclub',true,'a5d739580e396b7e36be0fe6b519f5e935d149078ba5e3b3f45abb14b891f3d9',now(),now()
),
(
  'p1:P1-QUA-02:theory:ru:v1','P1','P1-QUA-02','theory','ru','p3_02_ai_value_v1_2026_10_02',
  'Дискриминант квадратного уравнения и действительные корни',
  'Для ax^2 + bx + c = 0 дискриминант D = b^2 - 4ac. Если D > 0, есть два различных действительных корня; если D = 0, есть один повторяющийся действительный корень; если D < 0, действительных корней нет.',
  'approved','original_iclub',true,'4c316ede56ee8e44ddb60b07fc8c24042afa221b663b597769b44e3cf441dadd',now(),now()
),
(
  'p1:P1-QUA-02:theory:uz:v1','P1','P1-QUA-02','theory','uz','p3_02_ai_value_v1_2026_10_02',
  'Kvadrat tenglama diskriminanti va haqiqiy ildizlar',
  'ax^2 + bx + c = 0 uchun diskriminant D = b^2 - 4ac. Agar D > 0 bo‘lsa, ikkita turli haqiqiy ildiz bor; D = 0 bo‘lsa, bitta takroriy haqiqiy ildiz bor; D < 0 bo‘lsa, haqiqiy ildiz yo‘q.',
  'approved','original_iclub',true,'c771f7ca7bbf6f74f074a32799e55aad677f2f9e1f70f5ded0c4cd2de7757020',now(),now()
),
(
  'p5:P5-NOR-02:theory:en:v1','P5','P5-NOR-02','theory','en','p3_02_ai_value_v1_2026_10_02',
  'Standardising a normal random variable',
  'If X is normally distributed with mean mu and standard deviation sigma, standardise with Z = (X - mu) / sigma. Then use the standard normal distribution to evaluate the required probability, taking care to choose the correct tail or interval.',
  'approved','original_iclub',true,'c4f886a656a5392b25b16cfb84ac7fdb6155a47a621f73da6604890ac5ad46d8',now(),now()
),
(
  'p5:P5-NOR-02:theory:ru:v1','P5','P5-NOR-02','theory','ru','p3_02_ai_value_v1_2026_10_02',
  'Стандартизация нормальной случайной величины',
  'Если X имеет нормальное распределение со средним mu и стандартным отклонением sigma, стандартизируйте через Z = (X - mu) / sigma. Затем используйте стандартное нормальное распределение для нужной вероятности, правильно выбрав хвост или интервал.',
  'approved','original_iclub',true,'503071526705190becef0ecd614f4f6531d0eaea319c9ab69192ccee50f82cd3',now(),now()
),
(
  'p5:P5-NOR-02:theory:uz:v1','P5','P5-NOR-02','theory','uz','p3_02_ai_value_v1_2026_10_02',
  'Normal tasodifiy o‘zgaruvchini standartlashtirish',
  'Agar X o‘rtacha qiymati mu va standart og‘ishi sigma bo‘lgan normal taqsimotga ega bo‘lsa, Z = (X - mu) / sigma orqali standartlashtiring. So‘ng kerakli ehtimolni standart normal taqsimotdan toping va to‘g‘ri dum yoki intervalni tanlang.',
  'approved','original_iclub',true,'06090eed415f2907081dfb54c2cfa4e88c2726b6faff0afdc4e0628d439bba9a',now(),now()
)
on conflict(source_card_key) do update
set component_code=excluded.component_code,
    skill_code=excluded.skill_code,
    card_type=excluded.card_type,
    locale=excluded.locale,
    source_version=excluded.source_version,
    title=excluded.title,
    body_text=excluded.body_text,
    approval_status=excluded.approval_status,
    rights_status=excluded.rights_status,
    is_runtime_allowed=excluded.is_runtime_allowed,
    content_hash=excluded.content_hash,
    approved_at=coalesce(private.exam_prep_ai_source_cards.approved_at,excluded.approved_at),
    updated_at=now();

do $postcheck$
declare
  v_cards integer;
begin
  if to_regprocedure('public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)') is null
     or to_regprocedure('public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)') is null
  then
    raise exception 'P3-02 AI value expansion safe context RPC missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)','EXECUTE')
     or has_function_privilege('anon','public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_ai_repeated_error_context_payload_v1(uuid,text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)','EXECUTE')
  then
    raise exception 'P3-02 AI value expansion privilege boundary drift';
  end if;

  select count(*) into v_cards
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_ai_value_v1_2026_10_02'
    and approval_status='approved'
    and rights_status='original_iclub'
    and is_runtime_allowed;
  if v_cards<>12 then
    raise exception 'P3-02 AI value source-card contract expected=12 actual=%',v_cards;
  end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where source_version='p3_02_ai_value_v1_2026_10_02' and card_type='theory' and skill_code is not null)<>6
     or (select count(*) from private.exam_prep_ai_source_cards
      where source_version='p3_02_ai_value_v1_2026_10_02' and card_type='error_explanation' and skill_code is null)<>6
  then
    raise exception 'P3-02 AI value source-card type/scope drift';
  end if;
end
$postcheck$;

commit;
