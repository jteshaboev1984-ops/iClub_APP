begin;

-- iClub President Tech Award Diagnostic Foundation
-- Safe additive migration: no existing app flow is removed.

create or replace view public.safe_questions_public as
select
  q.id,
  q.subject_id,
  q.topic,
  q.subtopic,
  q.difficulty,
  q.qtype,
  q.question_text,
  q.options_text,
  q.image_url,
  q.is_active,
  q.created_at,
  q.question_text_ru,
  q.question_text_uz,
  q.question_text_en,
  q.options_text_ru,
  q.options_text_uz,
  q.options_text_en,
  q.book_ref,
  q.time_limit_sec,
  q.quality_status
from public.questions q
where q.is_active is true;

comment on view public.safe_questions_public is
'Safe public question payload for frontend delivery. Intentionally excludes correct_answer and all explanation fields.';

revoke all on public.safe_questions_public from anon;
revoke all on public.safe_questions_public from authenticated;
grant select on public.safe_questions_public to anon;
grant select on public.safe_questions_public to authenticated;

create or replace function public.get_safe_questions_by_ids(
  p_question_ids bigint[]
)
returns table (
  request_order integer,
  id bigint,
  subject_id bigint,
  topic text,
  subtopic text,
  difficulty text,
  qtype text,
  question_text text,
  options_text text,
  image_url text,
  is_active boolean,
  created_at timestamptz,
  question_text_ru text,
  question_text_uz text,
  question_text_en text,
  options_text_ru text,
  options_text_uz text,
  options_text_en text,
  book_ref text,
  time_limit_sec integer,
  quality_status text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  select
    ids.request_order::integer,
    q.id,
    q.subject_id,
    q.topic,
    q.subtopic,
    q.difficulty,
    q.qtype,
    q.question_text,
    q.options_text,
    q.image_url,
    q.is_active,
    q.created_at,
    q.question_text_ru,
    q.question_text_uz,
    q.question_text_en,
    q.options_text_ru,
    q.options_text_uz,
    q.options_text_en,
    q.book_ref,
    q.time_limit_sec,
    q.quality_status
  from unnest(coalesce(p_question_ids, array[]::bigint[])) with ordinality
    as ids(question_id, request_order)
  join public.questions q
    on q.id = ids.question_id
   and q.is_active is true
  order by ids.request_order;
$function$;

comment on function public.get_safe_questions_by_ids(bigint[]) is
'Returns frontend-safe question payload by IDs. Does not expose correct_answer or explanation fields.';

revoke all on function public.get_safe_questions_by_ids(bigint[]) from public;
grant execute on function public.get_safe_questions_by_ids(bigint[]) to anon;
grant execute on function public.get_safe_questions_by_ids(bigint[]) to authenticated;

create or replace function public.iclub_normalize_answer(p_answer text)
returns text
language sql
immutable
as $function$
  select lower(regexp_replace(trim(replace(coalesce(p_answer, ''), ',', '.')), '\s+', ' ', 'g'));
$function$;

create or replace function public.iclub_is_numeric(p_answer text)
returns boolean
language sql
immutable
as $function$
  select coalesce(trim(p_answer), '') ~ '^-?[0-9]+([\.,][0-9]+)?$';
$function$;

create or replace function public.iclub_touch_updated_at()
returns trigger
language plpgsql
as $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

revoke all on function public.iclub_normalize_answer(text) from public;
revoke all on function public.iclub_is_numeric(text) from public;
revoke all on function public.iclub_touch_updated_at() from public;

create table if not exists public.question_answer_diagnostics (
  id bigserial primary key,
  question_id bigint not null references public.questions(id) on delete cascade,
  answer_kind text not null check (answer_kind in ('mcq_option','input_exact','input_tolerance','input_pattern','fallback')),
  answer_key text,
  answer_value text,
  is_correct boolean not null default false,
  mistake_type text,
  weak_skill text,
  feedback_ru text,
  feedback_uz text,
  feedback_en text,
  next_action_ru text,
  next_action_uz text,
  next_action_en text,
  recommended_topic text,
  recommended_subtopic text,
  recommended_lesson_id bigint references public.lessons(id) on delete set null,
  rule_json jsonb not null default '{}'::jsonb,
  quality_status text not null default 'draft' check (quality_status in ('draft','published','rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists qad_question_kind_idx on public.question_answer_diagnostics(question_id, answer_kind);
create index if not exists qad_question_status_idx on public.question_answer_diagnostics(question_id, quality_status);

alter table public.question_answer_diagnostics enable row level security;
revoke all on table public.question_answer_diagnostics from anon;
revoke all on table public.question_answer_diagnostics from authenticated;

drop trigger if exists question_answer_diagnostics_touch_updated_at on public.question_answer_diagnostics;
create trigger question_answer_diagnostics_touch_updated_at
before update on public.question_answer_diagnostics
for each row execute function public.iclub_touch_updated_at();

create table if not exists public.user_answer_diagnosis (
  id bigserial primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id bigint not null references public.subjects(id) on delete cascade,
  attempt_type text not null check (attempt_type in ('practice','tour')),
  attempt_id bigint not null,
  practice_answer_id bigint references public.practice_answers(id) on delete cascade,
  tour_answer_id bigint references public.tour_answers(id) on delete cascade,
  question_id bigint not null references public.questions(id) on delete cascade,
  selected_answer text,
  is_correct boolean not null,
  diagnostic_id bigint references public.question_answer_diagnostics(id) on delete set null,
  mistake_type text,
  weak_skill text,
  feedback_ru text,
  feedback_uz text,
  feedback_en text,
  next_action_ru text,
  next_action_uz text,
  next_action_en text,
  created_at timestamptz not null default now(),
  constraint user_answer_diagnosis_source_check check (
    (attempt_type = 'practice' and practice_answer_id is not null and tour_answer_id is null)
    or
    (attempt_type = 'tour' and practice_answer_id is null and tour_answer_id is not null)
  )
);

create unique index if not exists user_answer_diagnosis_practice_answer_uidx
on public.user_answer_diagnosis(practice_answer_id)
where practice_answer_id is not null;

create unique index if not exists user_answer_diagnosis_tour_answer_uidx
on public.user_answer_diagnosis(tour_answer_id)
where tour_answer_id is not null;

create index if not exists uad_user_subject_created_idx
on public.user_answer_diagnosis(user_id, subject_id, created_at desc);

alter table public.user_answer_diagnosis enable row level security;
revoke all on table public.user_answer_diagnosis from anon;
revoke all on table public.user_answer_diagnosis from authenticated;
grant select on table public.user_answer_diagnosis to authenticated;

drop policy if exists uad_user_read_own on public.user_answer_diagnosis;
create policy uad_user_read_own
on public.user_answer_diagnosis
for select
to authenticated
using (auth.uid() = user_id);

create table if not exists public.learning_roadmaps (
  id bigserial primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  subject_id bigint not null references public.subjects(id) on delete cascade,
  source_type text not null check (source_type in ('practice_attempt','tour_attempt')),
  source_id bigint not null,
  main_weakness text,
  priority_topics jsonb not null default '[]'::jsonb,
  plan_json jsonb not null default '{}'::jsonb,
  message_ru text,
  message_uz text,
  message_en text,
  ai_enhanced boolean not null default false,
  ai_model text,
  created_at timestamptz not null default now()
);

create index if not exists learning_roadmaps_user_subject_created_idx
on public.learning_roadmaps(user_id, subject_id, created_at desc);

alter table public.learning_roadmaps enable row level security;
revoke all on table public.learning_roadmaps from anon;
revoke all on table public.learning_roadmaps from authenticated;
grant select on table public.learning_roadmaps to authenticated;

drop policy if exists learning_roadmaps_user_read_own on public.learning_roadmaps;
create policy learning_roadmaps_user_read_own
on public.learning_roadmaps
for select
to authenticated
using (auth.uid() = user_id);

create or replace function public.submit_practice_answer_safe(
  p_attempt_id bigint,
  p_question_id bigint,
  p_user_answer text,
  p_time_spent integer default 0,
  p_picked_index integer default null
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_uid uuid;
  v_subject_id bigint;
  v_question public.questions%rowtype;
  v_selected_answer text;
  v_selected_norm text;
  v_is_correct boolean := false;
  v_practice_answer_id bigint;
  v_diag public.question_answer_diagnostics%rowtype;
  v_score integer := 0;
  v_answered integer := 0;
  v_percent numeric := 0;
begin
  v_uid := auth.uid();
  if v_uid is null then raise exception 'Not authenticated'; end if;

  select pa.subject_id into v_subject_id
  from public.practice_attempts pa
  where pa.id = p_attempt_id and pa.user_id = v_uid;

  if v_subject_id is null then
    raise exception 'Practice attempt not found or not owned by current user';
  end if;

  select q.* into v_question
  from public.questions q
  where q.id = p_question_id and q.is_active is true;

  if v_question.id is null then raise exception 'Question not found or inactive'; end if;
  if v_question.subject_id <> v_subject_id then raise exception 'Question subject does not match practice attempt subject'; end if;

  if v_question.qtype = 'mcq' then
    if p_picked_index is not null and p_picked_index between 0 and 25 then
      v_selected_answer := chr(65 + p_picked_index);
    else
      v_selected_answer := upper(trim(coalesce(p_user_answer, '')));
    end if;

    v_is_correct := (
      upper(trim(v_selected_answer)) = upper(trim(coalesce(v_question.correct_answer, '')))
      or public.iclub_normalize_answer(v_selected_answer) = public.iclub_normalize_answer(v_question.correct_answer)
    );

    select d.* into v_diag
    from public.question_answer_diagnostics d
    where d.question_id = p_question_id
      and d.answer_kind = 'mcq_option'
      and upper(trim(coalesce(d.answer_key, d.answer_value, ''))) = upper(trim(v_selected_answer))
      and d.quality_status = 'published'
    order by d.is_correct desc, d.id
    limit 1;
  else
    v_selected_answer := trim(coalesce(p_user_answer, ''));
    v_selected_norm := public.iclub_normalize_answer(v_selected_answer);

    v_is_correct := exists (
      select 1
      from regexp_split_to_table(coalesce(v_question.correct_answer, ''), '\|') as accepted_answer
      where public.iclub_normalize_answer(accepted_answer) = v_selected_norm
    );

    if not v_is_correct and public.iclub_is_numeric(v_selected_answer) and public.iclub_is_numeric(v_question.correct_answer) then
      v_is_correct := replace(v_selected_answer, ',', '.')::numeric = replace(v_question.correct_answer, ',', '.')::numeric;
    end if;

    select d.* into v_diag
    from public.question_answer_diagnostics d
    where d.question_id = p_question_id
      and d.answer_kind = 'input_exact'
      and d.quality_status = 'published'
      and (public.iclub_normalize_answer(coalesce(d.answer_value, d.answer_key, '')) = v_selected_norm or d.is_correct = v_is_correct)
    order by d.is_correct desc, d.id
    limit 1;

    if v_diag.id is null and public.iclub_is_numeric(v_selected_answer) then
      select d.* into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = p_question_id
        and d.answer_kind = 'input_tolerance'
        and d.quality_status = 'published'
        and coalesce(d.rule_json->>'target', '') ~ '^-?[0-9]+([\.,][0-9]+)?$'
        and coalesce(d.rule_json->>'tolerance', '') ~ '^[0-9]+([\.,][0-9]+)?$'
        and abs(replace(v_selected_answer, ',', '.')::numeric - replace(d.rule_json->>'target', ',', '.')::numeric)
            <= replace(d.rule_json->>'tolerance', ',', '.')::numeric
      order by d.is_correct desc, d.id
      limit 1;
    end if;

    if v_diag.id is null then
      select d.* into v_diag
      from public.question_answer_diagnostics d
      where d.question_id = p_question_id
        and d.answer_kind = 'input_pattern'
        and d.quality_status = 'published'
        and d.answer_value is not null
        and v_selected_answer ~* d.answer_value
      order by d.is_correct desc, d.id
      limit 1;
    end if;
  end if;

  if v_diag.id is null then
    select d.* into v_diag
    from public.question_answer_diagnostics d
    where d.question_id = p_question_id
      and d.answer_kind = 'fallback'
      and d.quality_status = 'published'
    order by d.is_correct desc, d.id
    limit 1;
  end if;

  insert into public.practice_answers(attempt_id, question_id, user_answer, is_correct, time_spent)
  values (p_attempt_id, p_question_id, nullif(v_selected_answer, ''), v_is_correct, greatest(coalesce(p_time_spent, 0), 0))
  on conflict (attempt_id, question_id)
  do update set user_answer = excluded.user_answer, is_correct = excluded.is_correct, time_spent = excluded.time_spent
  returning id into v_practice_answer_id;

  insert into public.user_answer_diagnosis(
    user_id, subject_id, attempt_type, attempt_id, practice_answer_id, question_id,
    selected_answer, is_correct, diagnostic_id, mistake_type, weak_skill,
    feedback_ru, feedback_uz, feedback_en, next_action_ru, next_action_uz, next_action_en
  )
  values (
    v_uid, v_subject_id, 'practice', p_attempt_id, v_practice_answer_id, p_question_id,
    nullif(v_selected_answer, ''), v_is_correct, v_diag.id, v_diag.mistake_type, v_diag.weak_skill,
    v_diag.feedback_ru, v_diag.feedback_uz, v_diag.feedback_en,
    v_diag.next_action_ru, v_diag.next_action_uz, v_diag.next_action_en
  )
  on conflict (practice_answer_id) where practice_answer_id is not null
  do update set
    selected_answer = excluded.selected_answer,
    is_correct = excluded.is_correct,
    diagnostic_id = excluded.diagnostic_id,
    mistake_type = excluded.mistake_type,
    weak_skill = excluded.weak_skill,
    feedback_ru = excluded.feedback_ru,
    feedback_uz = excluded.feedback_uz,
    feedback_en = excluded.feedback_en,
    next_action_ru = excluded.next_action_ru,
    next_action_uz = excluded.next_action_uz,
    next_action_en = excluded.next_action_en;

  select count(*)::integer, count(*) filter (where pa.is_correct is true)::integer into v_answered, v_score
  from public.practice_answers pa
  where pa.attempt_id = p_attempt_id;

  v_percent := case when v_answered > 0 then round((v_score::numeric / v_answered::numeric) * 100, 2) else 0 end;

  update public.practice_attempts pa
  set score = v_score,
      percent = v_percent,
      time_seconds = greatest(coalesce(pa.time_seconds, 0), greatest(coalesce(p_time_spent, 0), 0))
  where pa.id = p_attempt_id and pa.user_id = v_uid;

  return jsonb_build_object(
    'attempt_id', p_attempt_id,
    'practice_answer_id', v_practice_answer_id,
    'question_id', p_question_id,
    'selected_answer', nullif(v_selected_answer, ''),
    'is_correct', v_is_correct,
    'score', v_score,
    'answered', v_answered,
    'percent', v_percent,
    'diagnostic', jsonb_build_object(
      'diagnostic_id', v_diag.id,
      'mistake_type', v_diag.mistake_type,
      'weak_skill', v_diag.weak_skill,
      'feedback_ru', v_diag.feedback_ru,
      'feedback_uz', v_diag.feedback_uz,
      'feedback_en', v_diag.feedback_en,
      'next_action_ru', v_diag.next_action_ru,
      'next_action_uz', v_diag.next_action_uz,
      'next_action_en', v_diag.next_action_en,
      'recommended_topic', v_diag.recommended_topic,
      'recommended_subtopic', v_diag.recommended_subtopic,
      'recommended_lesson_id', v_diag.recommended_lesson_id
    )
  );
end;
$function$;

comment on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) is
'Pilot-safe practice answer submission. Client sends only user answer; server reads correct_answer privately, computes is_correct, and records optional diagnosis.';

revoke all on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) from public;
grant execute on function public.submit_practice_answer_safe(bigint, bigint, text, integer, integer) to authenticated;

create or replace function public.get_diagnostic_pilot_audit(p_subject_id bigint default null)
returns table (
  subject_id bigint,
  pilot_questions integer,
  questions_with_any_rule integer,
  mcq_questions integer,
  mcq_questions_with_4_option_rules integer,
  input_questions integer,
  input_questions_with_rule integer,
  published_diagnostic_rows integer,
  ready boolean
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with q as (
    select qq.id, qq.subject_id, qq.qtype
    from public.questions qq
    where qq.is_active is true and (p_subject_id is null or qq.subject_id = p_subject_id)
  ),
  d as (
    select dd.* from public.question_answer_diagnostics dd where dd.quality_status = 'published'
  ),
  per_q as (
    select
      q.subject_id,
      q.id,
      q.qtype,
      count(d.id)::integer as rule_count,
      count(distinct upper(trim(coalesce(d.answer_key, d.answer_value, '')))) filter (
        where d.answer_kind = 'mcq_option' and coalesce(d.answer_key, d.answer_value, '') <> ''
      )::integer as mcq_option_rule_count,
      count(d.id) filter (where d.answer_kind in ('input_exact','input_tolerance','input_pattern','fallback'))::integer as input_rule_count
    from q
    left join d on d.question_id = q.id
    group by q.subject_id, q.id, q.qtype
  )
  select
    per_q.subject_id,
    count(*)::integer,
    count(*) filter (where per_q.rule_count > 0)::integer,
    count(*) filter (where per_q.qtype = 'mcq')::integer,
    count(*) filter (where per_q.qtype = 'mcq' and per_q.mcq_option_rule_count >= 4)::integer,
    count(*) filter (where per_q.qtype = 'input')::integer,
    count(*) filter (where per_q.qtype = 'input' and per_q.input_rule_count > 0)::integer,
    sum(per_q.rule_count)::integer,
    (
      count(*) > 0
      and count(*) filter (where per_q.rule_count > 0) = count(*)
      and count(*) filter (where per_q.qtype = 'mcq' and per_q.mcq_option_rule_count >= 4) = count(*) filter (where per_q.qtype = 'mcq')
      and count(*) filter (where per_q.qtype = 'input' and per_q.input_rule_count > 0) = count(*) filter (where per_q.qtype = 'input')
    )
  from per_q
  group by per_q.subject_id
  order by per_q.subject_id;
$function$;

comment on function public.get_diagnostic_pilot_audit(bigint) is
'Diagnostic pilot readiness metrics: question coverage, MCQ option completeness, and input rule coverage.';

revoke all on function public.get_diagnostic_pilot_audit(bigint) from public;
grant execute on function public.get_diagnostic_pilot_audit(bigint) to authenticated;

commit;
