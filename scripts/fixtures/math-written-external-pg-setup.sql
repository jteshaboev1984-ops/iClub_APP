-- Disposable PostgreSQL 17 test-only schema for written-learning migration.
-- No connection to Supabase. No real learner data.
create schema private;
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create table private.exam_prep_sessions(
 id uuid primary key, user_id uuid not null,
 component_code text not null, session_type text not null,
 status text not null, total_items smallint not null,
 last_activity_at timestamptz not null default now(),
 finalized_at timestamptz, finalize_idempotency_key text
);
create table private.exam_prep_written_tasks(
 id bigint primary key, component_code text not null, task_version text not null,
 lifecycle_state text not null, qa_math_status text not null, qa_language_status text not null,
 qa_technical_status text not null, rubric_json jsonb not null
);
create table private.exam_prep_session_items(
 session_id uuid not null references private.exam_prep_sessions(id),
 item_order smallint not null,
 item_kind text not null,
 written_task_id bigint references private.exam_prep_written_tasks(id),
 item_version text not null, primary key(session_id,item_order)
);
create table private.exam_prep_responses(
 id uuid primary key default gen_random_uuid(),
 session_id uuid not null, item_order smallint not null, user_id uuid not null,
 response_kind text not null, is_correct boolean, unique(session_id,item_order),
 foreign key(session_id,item_order) references private.exam_prep_session_items(session_id,item_order)
);
create table private.exam_prep_evidence_events(id int generated always as identity primary key);

create function private.exam_prep_require_core_access_v1()
returns uuid language plpgsql security definer set search_path='' as $fn$
declare v_uid uuid;
begin
  v_uid:=nullif(current_setting('iclub.test_uid',true),'')::uuid;
  if v_uid is null then raise exception 'no_auth'; end if;
  return v_uid;
end $fn$;
create function private.exam_prep_localized_written_rubric_v1(p jsonb,l text)
returns jsonb language plpgsql stable as $fn$
declare missing int;key text; translated jsonb;
begin
  if l='en' then return p||jsonb_build_object('localization_status','complete');end if;
  key:=case when l='ru' then 'rule_ru' else 'rule_uz' end;
  select count(*) into missing from jsonb_array_elements(p->'criteria') e(c)
    where nullif(btrim(coalesce(c->>key,'')),'') is null;
  if missing>0 then return jsonb_build_object('criteria','[]'::jsonb,
    'localization_status','unavailable');end if;
  select coalesce(jsonb_agg((c-'rule'-'rule_ru'-'rule_uz')
    ||jsonb_build_object('rule',c->>key) order by ord),'[]'::jsonb)
    into translated from jsonb_array_elements(p->'criteria') with ordinality e(c,ord);
  return (p-'criteria')||jsonb_build_object('criteria',translated,'localization_status','complete');
end $fn$;
create function public.get_exam_prep_session_safe_v1(p_session_id uuid,p_language text default 'en')
returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare v_uid uuid:=private.exam_prep_require_core_access_v1();v_s private.exam_prep_sessions%rowtype;v_items jsonb;
begin
 select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid;
 if v_s.id is null then raise exception 'session_not_found';end if;
 select coalesce(jsonb_agg(jsonb_build_object('item_order',i.item_order,'item_kind',i.item_kind,
   'answered',r.session_id is not null,'text','Sample')
   order by i.item_order),'[]'::jsonb) into v_items
 from private.exam_prep_session_items i
 left join private.exam_prep_responses r on r.session_id=i.session_id and r.item_order=i.item_order
 where i.session_id=p_session_id;
 return jsonb_build_object('session_id',p_session_id,'component_code',v_s.component_code,
   'session_type',v_s.session_type,'status',v_s.status,'total_items',v_s.total_items,'items',v_items);
end $fn$;
create function public.finalize_exam_prep_session_safe_v1(p_session_id uuid,p_idempotency_key text)
returns jsonb language plpgsql security definer set search_path='' as $fn$
declare v_uid uuid:=private.exam_prep_require_core_access_v1();v_s private.exam_prep_sessions%rowtype;n int;
begin
 select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid for update;
 if v_s.id is null then raise exception 'session_not_found';end if;
 select count(*) into n from private.exam_prep_responses where session_id=p_session_id;
 if n<>v_s.total_items then raise exception 'incomplete';end if;
 update private.exam_prep_sessions set status='finalized',finalized_at=now() where id=p_session_id;
 return jsonb_build_object('session_id',p_session_id,'status','finalized');
end $fn$;
create function public.get_exam_prep_session_review_safe_v1(p_session_id uuid,p_language text default 'en')
returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare v_uid uuid:=private.exam_prep_require_core_access_v1();v_s private.exam_prep_sessions%rowtype;v_n int;v_w int;
begin
 select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid;
 if v_s.status<>'finalized' then raise exception 'not_finished';end if;
 select count(*) filter(where response_kind='machine'),count(*) filter(where response_kind='written') into v_n,v_w
 from private.exam_prep_responses where session_id=p_session_id;
 return jsonb_build_object('session_id',p_session_id,'component_code',v_s.component_code,
 'session_type',v_s.session_type,'summary',jsonb_build_object('machine_total',v_n,
 'machine_correct',v_n,'written_total',v_w,'written_completed',v_w),
 'items',(select coalesce(jsonb_agg(jsonb_build_object('item_order',item_order,'item_kind',item_kind,
 'text','Sample') order by item_order),'[]'::jsonb)
 from private.exam_prep_session_items where session_id=p_session_id));
end $fn$;
create function public.get_exam_prep_recent_results_safe_v1(p_component_code text,p_limit integer default 10)
returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare v_uid uuid:=private.exam_prep_require_core_access_v1();
begin
 return jsonb_build_object('component_code',p_component_code,
 'results',(select coalesce(jsonb_agg(jsonb_build_object('session_id',id,'component_code',
 component_code,'session_type',session_type,'written_total',0,'written_completed',0)),'[]'::jsonb)
 from private.exam_prep_sessions where user_id=v_uid and component_code=p_component_code
 and status='finalized'));
end $fn$;

insert into private.exam_prep_sessions(id,user_id,component_code,session_type,status,total_items)
 values('00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000001','P1','learning','active',4),
 ('00000000-0000-4000-8000-000000000102','00000000-0000-4000-8000-000000000002','P1','learning','active',1),
 ('00000000-0000-4000-8000-000000000103','00000000-0000-4000-8000-000000000001','P5','learning','active',1);
insert into private.exam_prep_written_tasks(id,component_code,task_version,
 lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,rubric_json)
values(91,'P1','t1','published','pass','pass','pass',
 '{"criteria":[{"id":"p1-power","rule":"Power rule"}]}'),
 (92,'P5','t1','published','pass','pass','pass',
 '{"criteria":[{"id":"p5-stat","rule":"Sample statistic"}]}');
insert into private.exam_prep_session_items(session_id,item_order,item_kind,written_task_id,item_version)
values
 ('00000000-0000-4000-8000-000000000101',1,'question',null,'q1'),
 ('00000000-0000-4000-8000-000000000101',2,'question',null,'q2'),
 ('00000000-0000-4000-8000-000000000101',3,'question',null,'q3'),
 ('00000000-0000-4000-8000-000000000101',4,'written',91,'written:t1'),
 ('00000000-0000-4000-8000-000000000102',1,'written',91,'written:t1'),
 ('00000000-0000-4000-8000-000000000103',1,'written',92,'written:t1');
insert into private.exam_prep_responses(session_id,item_order,user_id,response_kind,is_correct)
values('00000000-0000-4000-8000-000000000101',1,'00000000-0000-4000-8000-000000000001','machine',true),
('00000000-0000-4000-8000-000000000101',2,'00000000-0000-4000-8000-000000000001','machine',true),
('00000000-0000-4000-8000-000000000101',3,'00000000-0000-4000-8000-000000000001','machine',true);
