-- AI-4 Practice AI coverage snapshot v1.
-- Read-only service-role diagnostic for governed source/diagnosis expansion.
-- Does not enable AI, expose answer material, or mutate academic/user state.

create or replace function public.get_practice_ai_coverage_snapshot_service_v1(
  p_subject_key text default null
)
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
with active_questions as (
  select
    s.id as subject_id,
    s.subject_key,
    pp.id as pool_id,
    pp.tour_no,
    q.id as question_id,
    q.topic,
    q.subtopic
  from public.practice_pools pp
  join public.subjects s
    on s.id=pp.subject_id
  join public.practice_pool_questions ppq
    on ppq.pool_id=pp.id
   and ppq.is_active
  join public.questions q
    on q.id=ppq.question_id
   and q.is_active
  where pp.is_active
    and (p_subject_key is null or s.subject_key=p_subject_key)
),
coverage as (
  select
    aq.*,
    exists (
      select 1
      from public.question_answer_diagnostics d
      where d.question_id=aq.question_id
        and d.quality_status='published'
        and d.is_correct=false
        and d.mistake_type is not null
    ) as deterministic_diagnosis,
    exists (
      select 1
      from private.practice_ai_source_cards c
      where c.subject_key=aq.subject_key
        and c.locale='ru'
        and c.card_type='answer_explanation'
        and c.approval_status='approved'
        and c.is_runtime_allowed
        and c.rights_status in ('original_iclub','official_public_metadata','licensed')
        and (
          c.question_id=aq.question_id
          or (
            c.question_id is null
            and c.topic=aq.topic
            and (c.subtopic is null or c.subtopic=aq.subtopic)
          )
          or (
            c.question_id is null
            and c.topic is null
          )
        )
    ) as source_ru,
    exists (
      select 1
      from private.practice_ai_source_cards c
      where c.subject_key=aq.subject_key
        and c.locale='uz'
        and c.card_type='answer_explanation'
        and c.approval_status='approved'
        and c.is_runtime_allowed
        and c.rights_status in ('original_iclub','official_public_metadata','licensed')
        and (
          c.question_id=aq.question_id
          or (
            c.question_id is null
            and c.topic=aq.topic
            and (c.subtopic is null or c.subtopic=aq.subtopic)
          )
          or (
            c.question_id is null
            and c.topic is null
          )
        )
    ) as source_uz,
    exists (
      select 1
      from private.practice_ai_source_cards c
      where c.subject_key=aq.subject_key
        and c.locale='en'
        and c.card_type='answer_explanation'
        and c.approval_status='approved'
        and c.is_runtime_allowed
        and c.rights_status in ('original_iclub','official_public_metadata','licensed')
        and (
          c.question_id=aq.question_id
          or (
            c.question_id is null
            and c.topic=aq.topic
            and (c.subtopic is null or c.subtopic=aq.subtopic)
          )
          or (
            c.question_id is null
            and c.topic is null
          )
        )
    ) as source_en
  from active_questions aq
),
pool_rows as (
  select
    c.subject_key,
    c.pool_id,
    c.tour_no,
    count(*)::int as total_questions,
    count(*) filter (where c.source_ru)::int as source_ru_questions,
    count(*) filter (where c.source_uz)::int as source_uz_questions,
    count(*) filter (where c.source_en)::int as source_en_questions,
    count(*) filter (where c.source_ru and c.source_uz and c.source_en)::int as source_all_locales_questions,
    count(*) filter (where c.deterministic_diagnosis)::int as deterministic_diagnosis_questions,
    count(*) filter (
      where c.deterministic_diagnosis
        and c.source_ru
        and c.source_uz
        and c.source_en
    )::int as diagnostic_source_ready_questions
  from coverage c
  group by c.subject_key,c.pool_id,c.tour_no
),
subject_rows as (
  select
    c.subject_key,
    count(*)::int as total_questions,
    count(*) filter (where c.source_ru)::int as source_ru_questions,
    count(*) filter (where c.source_uz)::int as source_uz_questions,
    count(*) filter (where c.source_en)::int as source_en_questions,
    count(*) filter (where c.source_ru and c.source_uz and c.source_en)::int as source_all_locales_questions,
    count(*) filter (where c.deterministic_diagnosis)::int as deterministic_diagnosis_questions,
    count(*) filter (
      where c.deterministic_diagnosis
        and c.source_ru
        and c.source_uz
        and c.source_en
    )::int as diagnostic_source_ready_questions
  from coverage c
  group by c.subject_key
)
select jsonb_build_object(
  'subjects',
  coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'subject_key',s.subject_key,
        'total_questions',s.total_questions,
        'source_ru_questions',s.source_ru_questions,
        'source_uz_questions',s.source_uz_questions,
        'source_en_questions',s.source_en_questions,
        'source_all_locales_questions',s.source_all_locales_questions,
        'deterministic_diagnosis_questions',s.deterministic_diagnosis_questions,
        'diagnostic_source_ready_questions',s.diagnostic_source_ready_questions
      )
      order by s.subject_key
    )
    from subject_rows s
  ),'[]'::jsonb),
  'pools',
  coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'subject_key',p.subject_key,
        'pool_id',p.pool_id,
        'tour_no',p.tour_no,
        'total_questions',p.total_questions,
        'source_ru_questions',p.source_ru_questions,
        'source_uz_questions',p.source_uz_questions,
        'source_en_questions',p.source_en_questions,
        'source_all_locales_questions',p.source_all_locales_questions,
        'deterministic_diagnosis_questions',p.deterministic_diagnosis_questions,
        'diagnostic_source_ready_questions',p.diagnostic_source_ready_questions
      )
      order by p.subject_key,p.tour_no,p.pool_id
    )
    from pool_rows p
  ),'[]'::jsonb)
);
$$;

revoke all on function public.get_practice_ai_coverage_snapshot_service_v1(text)
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_coverage_snapshot_service_v1(text)
  to service_role;
