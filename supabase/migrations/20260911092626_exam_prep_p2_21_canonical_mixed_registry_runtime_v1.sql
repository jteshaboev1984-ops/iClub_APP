begin;

-- P2-21 turns the signed owner-component mixed registry into executable assessment sets.
-- It does not alter legacy Practice/Tours/history and does not change any question text/answer.
-- The canonical mixed registry remains an evidence layer outside the 81-skill denominator.

create table if not exists private.exam_prep_assessment_mixed_nodes(
  assessment_id bigint primary key references private.exam_prep_assessments(id) on delete cascade,
  program_version_id bigint not null,
  mixed_code text not null,
  component_code text not null check(component_code in ('P1','P5')),
  created_at timestamptz not null default now(),
  foreign key(program_version_id,mixed_code)
    references private.exam_prep_mixed_nodes(program_version_id,mixed_code) on delete restrict
);
create index if not exists exam_prep_assessment_mixed_nodes_lookup_idx
  on private.exam_prep_assessment_mixed_nodes(program_version_id,mixed_code,component_code);
revoke all on private.exam_prep_assessment_mixed_nodes from public,anon,authenticated;
grant select,insert,update,delete on private.exam_prep_assessment_mixed_nodes to service_role;

-- Build one executable set for each canonical P1/P5 mixed node from the already QA-approved withheld mixed reserve.
with registry as (
  select mn.program_version_id,mn.mixed_code,mn.owner_component_code,
         min(m.content_version_id) as anchor_content_version_id,
         count(*)::int as linked_skill_count,
         count(m.question_id)::int as ready_question_count
  from private.exam_prep_mixed_nodes mn
  join private.exam_prep_mixed_links ml
    on ml.program_version_id=mn.program_version_id
   and ml.mixed_code=mn.mixed_code
   and ml.linked_node_kind='skill'
  left join lateral (
    select qm.content_version_id,qm.question_id
    from private.exam_prep_question_content_meta qm
    join private.exam_prep_content_versions qcv
      on qcv.id=qm.content_version_id
     and qcv.program_version_id=mn.program_version_id
     and qcv.component_code=mn.owner_component_code
     and qcv.status='published'
    where qm.primary_skill_code=ml.linked_node_code
      and qm.reserve_role='mixed'
      and qm.lifecycle_state='reserve'
      and qm.exposure_state='withheld'
      and qm.qa_scope_status='pass'
      and qm.qa_math_status='pass'
      and qm.qa_language_status='pass'
      and qm.qa_technical_status='pass'
    order by qm.id
    limit 1
  ) m on true
  where mn.owner_component_code in ('P1','P5')
  group by mn.program_version_id,mn.mixed_code,mn.owner_component_code
), inserted as (
  insert into private.exam_prep_assessments(
    content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
    title_en,title_ru,title_uz,approved_at
  )
  select
    r.anchor_content_version_id,
    'canonical_'||lower(replace(r.mixed_code,'-','_')),
    'av1',r.owner_component_code,'mixed','published',
    'Canonical mixed set · '||r.mixed_code,
    'Канонический смешанный набор · '||r.mixed_code,
    'Kanonik aralash to‘plam · '||r.mixed_code,
    now()
  from registry r
  where r.anchor_content_version_id is not null
    and r.linked_skill_count=r.ready_question_count
  on conflict(content_version_id,assessment_key,assessment_version) do nothing
  returning id
)
select count(*) from inserted;

insert into private.exam_prep_assessment_mixed_nodes(
  assessment_id,program_version_id,mixed_code,component_code
)
select a.id,mn.program_version_id,mn.mixed_code,mn.owner_component_code
from private.exam_prep_mixed_nodes mn
join private.exam_prep_mixed_links ml0
  on ml0.program_version_id=mn.program_version_id and ml0.mixed_code=mn.mixed_code and ml0.linked_node_kind='skill'
join lateral (
  select min(qm.content_version_id) anchor_content_version_id,
         count(*)::int ready_count
  from private.exam_prep_mixed_links mlx
  join lateral (
    select qm.content_version_id,qm.question_id
    from private.exam_prep_question_content_meta qm
    join private.exam_prep_content_versions qcv
      on qcv.id=qm.content_version_id
     and qcv.program_version_id=mn.program_version_id
     and qcv.component_code=mn.owner_component_code
     and qcv.status='published'
    where mlx.program_version_id=mn.program_version_id
      and mlx.mixed_code=mn.mixed_code
      and mlx.linked_node_kind='skill'
      and qm.primary_skill_code=mlx.linked_node_code
      and qm.reserve_role='mixed'
      and qm.lifecycle_state='reserve'
      and qm.exposure_state='withheld'
      and qm.qa_scope_status='pass' and qm.qa_math_status='pass'
      and qm.qa_language_status='pass' and qm.qa_technical_status='pass'
    order by qm.id limit 1
  ) qm on true
  where mlx.program_version_id=mn.program_version_id
    and mlx.mixed_code=mn.mixed_code
    and mlx.linked_node_kind='skill'
) pack on true
join private.exam_prep_assessments a
  on a.content_version_id=pack.anchor_content_version_id
 and a.assessment_key='canonical_'||lower(replace(mn.mixed_code,'-','_'))
 and a.assessment_version='av1'
 and a.component_code=mn.owner_component_code
 and a.assessment_type='mixed'
 and a.status='published'
where mn.owner_component_code in ('P1','P5')
group by a.id,mn.program_version_id,mn.mixed_code,mn.owner_component_code
on conflict(assessment_id) do update set
  program_version_id=excluded.program_version_id,
  mixed_code=excluded.mixed_code,
  component_code=excluded.component_code;

insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select
  a.id,
  row_number() over(partition by a.id order by ml.link_order,ml.linked_node_code)::smallint,
  qm.question_id,null,ml.linked_node_code,'mixed',true
from private.exam_prep_assessment_mixed_nodes amn
join private.exam_prep_assessments a on a.id=amn.assessment_id
join private.exam_prep_mixed_links ml
  on ml.program_version_id=amn.program_version_id
 and ml.mixed_code=amn.mixed_code
 and ml.linked_node_kind='skill'
join lateral (
  select m.question_id
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions qcv
    on qcv.id=m.content_version_id
   and qcv.program_version_id=amn.program_version_id
   and qcv.component_code=amn.component_code
   and qcv.status='published'
  where m.primary_skill_code=ml.linked_node_code
    and m.reserve_role='mixed'
    and m.lifecycle_state='reserve'
    and m.exposure_state='withheld'
    and m.qa_scope_status='pass' and m.qa_math_status='pass'
    and m.qa_language_status='pass' and m.qa_technical_status='pass'
  order by m.id limit 1
) qm on true
where not exists(
  select 1 from private.exam_prep_assessment_items x
  where x.assessment_id=a.id
);

-- Canonical mixed mastery is stricter than ordinary mixed transfer:
-- the assessment must be tied to the signed mixed registry AND span >=2 official syllabus areas.
create or replace function private.exam_prep_mixed_mastery_assessment_qualifies_v1(
  p_assessment_id bigint,p_component_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_mixed_nodes amn on amn.assessment_id=a.id
    join private.exam_prep_content_versions acv on acv.id=a.content_version_id
    where a.id=p_assessment_id
      and p_component_code in ('P1','P5')
      and a.component_code=p_component_code
      and amn.component_code=p_component_code
      and amn.program_version_id=acv.program_version_id
      and a.assessment_type='mixed'
      and a.status='published'
      and (
        select count(distinct sn.official_syllabus_section)
        from private.exam_prep_assessment_items ai
        join private.exam_prep_syllabus_nodes sn
          on sn.program_version_id=amn.program_version_id
         and sn.component_code=p_component_code
         and sn.skill_code=ai.primary_skill_code
        where ai.assessment_id=a.id
      )>=2
  );
$$;
revoke all on function private.exam_prep_mixed_mastery_assessment_qualifies_v1(bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_mastery_assessment_qualifies_v1(bigint,text) to service_role;

-- Ordinary transfer planner may use any canonical same-component mixed node.
-- The stricter cross-area rule is evaluated separately by the state engine above.
create or replace function private.exam_prep_mixed_assessment_eligible_v1(
  p_user_id uuid,p_component_code text,p_active_week_no smallint,p_assessment_id bigint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_mixed_nodes amn on amn.assessment_id=a.id
    where a.id=p_assessment_id
      and a.component_code=p_component_code
      and amn.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and (
        select count(distinct ai.primary_skill_code)
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
      )>=2
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        left join private.exam_prep_skill_states s
          on s.user_id=p_user_id
         and s.component_code=p_component_code
         and s.skill_code=ai.primary_skill_code
         and s.engine_version='objective_state_v1'
        where ai.assessment_id=a.id
          and (s.skill_code is null or s.objective_level<2 or coalesce(s.unresolved_correction_count,0)>0)
      )
      and exists(
        select 1
        from private.exam_prep_assessment_items ai
        join private.exam_prep_skill_states s
          on s.user_id=p_user_id
         and s.component_code=p_component_code
         and s.skill_code=ai.primary_skill_code
         and s.engine_version='objective_state_v1'
        where ai.assessment_id=a.id
          and s.hold_reason in ('mixed_transfer_missing','transfer_evidence_missing')
      )
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
          and not exists(
            select 1
            from private.exam_prep_content_runway_releases r
            join private.exam_prep_content_runway_release_skills rs
              on rs.release_id=r.id
             and rs.required_for_release
             and rs.skill_code=ai.primary_skill_code
            where r.program_version_id=amn.program_version_id
              and r.component_code=p_component_code
              and r.schedule_status='active'
              and r.active_week_from<=p_active_week_no
          )
      )
  );
$$;
revoke all on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) to service_role;

-- Mixed sets may intentionally package approved reserve items that live in several
-- source content versions. Freeze each item against its own immutable source meta,
-- while the assessment's content version remains the packaging/version anchor.
create or replace function public.start_exam_prep_session_safe_v1(p_authorization_id uuid,p_idempotency_key text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_auth private.exam_prep_session_authorizations%rowtype;
  v_s private.exam_prep_sessions%rowtype;
  v_ass private.exam_prep_assessments%rowtype;
  v_cv private.exam_prep_content_versions%rowtype;
  v_program bigint;
  v_total int;
  v_inserted int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_authorization_id is null then raise exception 'exam_prep_authorization_required'; end if;
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160 then raise exception 'exam_prep_bad_idempotency_key'; end if;

  select * into v_s from private.exam_prep_sessions where user_id=v_uid and client_idempotency_key=p_idempotency_key;
  if v_s.id is not null then
    if v_s.authorization_id<>p_authorization_id then raise exception 'exam_prep_idempotency_conflict'; end if;
    return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'component_code',v_s.component_code,'session_type',v_s.session_type,'total_items',v_s.total_items,'resumed',true);
  end if;

  select * into v_auth from private.exam_prep_session_authorizations where id=p_authorization_id for update;
  if v_auth.id is null or v_auth.user_id<>v_uid then raise exception 'exam_prep_authorization_not_found' using errcode='P0002'; end if;
  if v_auth.status<>'issued' then raise exception 'exam_prep_authorization_not_usable'; end if;
  if v_auth.valid_until is not null and v_auth.valid_until<=now() then
    update private.exam_prep_session_authorizations set status='expired' where id=v_auth.id;
    raise exception 'exam_prep_authorization_expired';
  end if;

  select * into v_ass from private.exam_prep_assessments where id=v_auth.assessment_id and status='published';
  if v_ass.id is null then raise exception 'exam_prep_assessment_not_published'; end if;
  if v_ass.component_code<>v_auth.component_code or v_ass.assessment_type<>v_auth.purpose then raise exception 'exam_prep_authorization_scope_mismatch'; end if;

  select * into v_cv from private.exam_prep_content_versions where id=v_ass.content_version_id and status='published';
  if v_cv.id is null or v_cv.component_code<>v_ass.component_code then raise exception 'exam_prep_content_version_not_published'; end if;
  v_program:=v_cv.program_version_id;

  select count(*) into v_total from private.exam_prep_assessment_items where assessment_id=v_ass.id;
  if v_total<1 or v_total>32767 then raise exception 'exam_prep_empty_or_invalid_assessment'; end if;

  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,
    component_code,session_type,status,client_idempotency_key,total_items,timing_contract
  ) values(
    v_auth.id,v_uid,v_program,v_cv.id,v_ass.id,v_ass.assessment_version,v_ass.component_code,
    v_ass.assessment_type,'active',p_idempotency_key,v_total::smallint,jsonb_build_object('assessment_type',v_ass.assessment_type)
  )
  on conflict(user_id,client_idempotency_key) do nothing returning * into v_s;

  if v_s.id is null then
    select * into v_s from private.exam_prep_sessions where user_id=v_uid and client_idempotency_key=p_idempotency_key;
    if v_s.id is null or v_s.authorization_id<>v_auth.id then raise exception 'exam_prep_idempotency_conflict'; end if;
    return jsonb_build_object('session_id',v_s.id,'status',v_s.status,'component_code',v_s.component_code,'session_type',v_s.session_type,'total_items',v_s.total_items,'resumed',true);
  end if;

  insert into private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,reserve_role,
    is_holdout,content_meta_id,question_snapshot_md5,item_version
  )
  select
    v_s.id,ai.item_order,
    case when ai.question_id is not null then 'question' else 'written' end,
    ai.question_id,ai.written_task_id,ai.primary_skill_code,ai.reserve_role,ai.is_holdout,
    m.id,m.question_snapshot_md5,
    case when ai.question_id is not null
      then 'qmd5:'||m.question_snapshot_md5
      else 'written:'||wt.task_version
    end
  from private.exam_prep_assessment_items ai
  left join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id
  left join private.exam_prep_content_versions qcv
    on qcv.id=m.content_version_id
   and qcv.program_version_id=v_program
   and qcv.component_code=v_ass.component_code
   and qcv.status='published'
  left join private.exam_prep_written_tasks wt
    on wt.id=ai.written_task_id
   and wt.content_version_id=v_cv.id
   and wt.lifecycle_state='published'
  where ai.assessment_id=v_ass.id
    and (
      (
        ai.question_id is not null
        and m.id is not null
        and qcv.id is not null
        and ai.primary_skill_code=m.primary_skill_code
        and (
          (m.lifecycle_state='published' and m.exposure_state='released' and m.reserve_role='learning')
          or
          (m.lifecycle_state='reserve' and m.exposure_state='withheld' and m.reserve_role in ('diagnostic','retest','mixed','timed','unseen'))
        )
      )
      or
      (ai.written_task_id is not null and wt.id is not null and ai.primary_skill_code=wt.primary_skill_code)
    );

  get diagnostics v_inserted=row_count;
  if v_inserted<>v_total then raise exception 'exam_prep_membership_freeze_failed expected %, inserted %',v_total,v_inserted; end if;

  update private.exam_prep_session_authorizations
  set status='consumed',consumed_at=now(),consumed_session_id=v_s.id
  where id=v_auth.id and status='issued';
  if not found then raise exception 'exam_prep_authorization_consume_failed'; end if;

  return jsonb_build_object('session_id',v_s.id,'status','active','component_code',v_s.component_code,'session_type',v_s.session_type,'total_items',v_s.total_items,'resumed',false);
end;
$$;
revoke execute on function public.start_exam_prep_session_safe_v1(uuid,text) from public,anon;
grant execute on function public.start_exam_prep_session_safe_v1(uuid,text) to authenticated,service_role;

commit;