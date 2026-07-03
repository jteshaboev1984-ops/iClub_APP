begin;

-- iClub Question Content Change Governance
-- Safe additive layer for deciding what can be changed when a question already has user history.

create table if not exists public.question_content_change_decisions (
  id bigserial primary key,
  question_id bigint not null references public.questions(id) on delete cascade,
  decision_type text not null check (
    decision_type in (
      'no_change',
      'diagnostic_mapping_only',
      'future_evaluator_rule_only',
      'minor_text_fix_no_semantic_change',
      'retire_and_clone_new_version',
      'historical_recalculation_candidate',
      'manual_review_required'
    )
  ),
  risk_level text not null default 'medium' check (risk_level in ('low', 'medium', 'high', 'critical')),
  history_policy text not null check (
    history_policy in (
      'preserve_history_as_is',
      'preserve_scores_add_diagnostic_note',
      'future_only_no_retroactive_change',
      'clone_for_future_keep_old_history',
      'requires_architect_approval_before_recalc'
    )
  ),
  rationale text not null,
  proposed_change jsonb not null default '{}'::jsonb,
  evidence_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check (status in ('draft', 'approved', 'applied', 'rejected')),
  decided_by text not null default 'system',
  decided_at timestamptz not null default now(),
  applied_at timestamptz
);

create index if not exists qccd_question_idx
on public.question_content_change_decisions(question_id, decided_at desc);

create index if not exists qccd_status_idx
on public.question_content_change_decisions(status, decision_type);

alter table public.question_content_change_decisions enable row level security;
revoke all on table public.question_content_change_decisions from anon;
revoke all on table public.question_content_change_decisions from authenticated;

create table if not exists public.question_version_links (
  id bigserial primary key,
  old_question_id bigint not null references public.questions(id) on delete restrict,
  new_question_id bigint not null references public.questions(id) on delete restrict,
  link_type text not null default 'replacement' check (
    link_type in ('replacement', 'semantic_fix', 'language_fix', 'evaluator_fix')
  ),
  reason text not null,
  created_at timestamptz not null default now(),
  constraint question_version_links_not_self check (old_question_id <> new_question_id),
  constraint question_version_links_unique unique (old_question_id, new_question_id, link_type)
);

create index if not exists qvl_old_question_idx
on public.question_version_links(old_question_id);

create index if not exists qvl_new_question_idx
on public.question_version_links(new_question_id);

alter table public.question_version_links enable row level security;
revoke all on table public.question_version_links from anon;
revoke all on table public.question_version_links from authenticated;

create or replace function public.get_question_history_impact(
  p_question_ids bigint[]
)
returns table (
  request_order integer,
  question_id bigint,
  subject_id bigint,
  qtype text,
  difficulty text,
  quality_status text,
  is_active boolean,
  practice_answer_count integer,
  tour_answer_count integer,
  total_answer_count integer,
  practice_correct_count integer,
  tour_correct_count integer,
  existing_decisions integer,
  has_user_history boolean,
  recommended_history_policy text
)
language sql
stable
security definer
set search_path to 'public'
as $function$
  with input_ids as (
    select *
    from unnest(coalesce(p_question_ids, array[]::bigint[])) with ordinality
      as x(question_id, request_order)
  ),
  usage_stats as (
    select
      ids.request_order::integer,
      q.id as question_id,
      q.subject_id,
      q.qtype,
      q.difficulty,
      q.quality_status,
      q.is_active,
      count(distinct pa.id)::integer as practice_answer_count,
      count(distinct ta.id)::integer as tour_answer_count,
      count(distinct pa.id) filter (where pa.is_correct is true)::integer as practice_correct_count,
      count(distinct ta.id) filter (where ta.is_correct is true)::integer as tour_correct_count,
      count(distinct d.id)::integer as existing_decisions
    from input_ids ids
    join public.questions q on q.id = ids.question_id
    left join public.practice_answers pa on pa.question_id = q.id
    left join public.tour_answers ta on ta.question_id = q.id
    left join public.question_content_change_decisions d on d.question_id = q.id
    group by ids.request_order, q.id
  )
  select
    u.request_order,
    u.question_id,
    u.subject_id,
    u.qtype,
    u.difficulty,
    u.quality_status,
    u.is_active,
    u.practice_answer_count,
    u.tour_answer_count,
    (u.practice_answer_count + u.tour_answer_count)::integer as total_answer_count,
    u.practice_correct_count,
    u.tour_correct_count,
    u.existing_decisions,
    ((u.practice_answer_count + u.tour_answer_count) > 0) as has_user_history,
    case
      when (u.practice_answer_count + u.tour_answer_count) = 0 then 'future_edit_allowed_with_qa'
      when u.tour_answer_count > 0 then 'clone_for_future_keep_old_history'
      else 'future_only_no_retroactive_change'
    end as recommended_history_policy
  from usage_stats u
  order by u.request_order;
$function$;

comment on function public.get_question_history_impact(bigint[]) is
'Internal QA helper: shows whether selected questions have practice/tour history and recommends a safe history policy before changing content.';

revoke all on function public.get_question_history_impact(bigint[]) from public;
revoke execute on function public.get_question_history_impact(bigint[]) from anon;
grant execute on function public.get_question_history_impact(bigint[]) to authenticated;

commit;
