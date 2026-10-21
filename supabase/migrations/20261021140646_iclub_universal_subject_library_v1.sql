
begin;
set local lock_timeout = '3s';
set local statement_timeout = '90s';

create table if not exists private.iclub_subject_library (
 subject_key text primary key check (subject_key ~ '^[a-z][a-z0-9_]{2,49}$'),
 title_locales jsonb not null check (jsonb_typeof(title_locales)='object'),
 syllabus_ref text not null,
 active_version text,
 visible_to_learners boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 check (not visible_to_learners or active_version is not null)
);

create table if not exists private.iclub_subject_library_releases (
 subject_key text not null references private.iclub_subject_library(subject_key) on update restrict on delete restrict,
 version_key text not null check (version_key ~ '^[a-zA-Z0-9_.-]{3,120}$'),
 package_sha256 text not null check (package_sha256 ~ '^[a-f0-9]{64}$'),
 expected_skills int not null check (expected_skills between 1 and 10000),
 state text not null default 'draft' check (state in ('draft','validated','retired')),
 created_at timestamptz not null default now(),
 validated_at timestamptz,
 primary key (subject_key,version_key)
);

alter table private.iclub_subject_library
 add constraint iclub_subject_library_active_release_fk
 foreign key (subject_key,active_version)
 references private.iclub_subject_library_releases(subject_key,version_key)
 on update restrict on delete restrict;

create table if not exists private.iclub_subject_library_theory (
 subject_key text not null,
 version_key text not null,
 skill_key text not null check (char_length(skill_key) between 5 and 180),
 tour_no int not null check (tour_no between 1 and 100),
 syllabus_point text not null,
 content_hash text not null check (content_hash ~ '^sha256:[a-f0-9]{64}$'),
 locales jsonb not null check (jsonb_typeof(locales)='object' and locales ?& array['en','ru','uz']),
 created_at timestamptz not null default now(),
 primary key (subject_key,version_key,skill_key),
 foreign key (subject_key,version_key)
  references private.iclub_subject_library_releases(subject_key,version_key)
  on update restrict on delete restrict
);

create table if not exists private.iclub_subject_library_tutor (
 subject_key text not null,
 version_key text not null,
 skill_key text not null,
 locale text not null check (locale in ('en','ru','uz')),
 tutor_card_key text not null,
 content_version text not null,
 title text not null check (length(btrim(title))>0),
 main_explanation text not null check (length(btrim(main_explanation))>0),
 simple_explanation text not null check (length(btrim(simple_explanation))>0),
 alternative_explanation text not null check (length(btrim(alternative_explanation))>0),
 focus_explanation text not null check (length(btrim(focus_explanation))>0),
 source_card_hash text not null check (source_card_hash ~ '^sha256:[a-f0-9]{64}$'),
 created_at timestamptz not null default now(),
 primary key (subject_key,version_key,skill_key,locale),
 unique (subject_key,version_key,tutor_card_key),
 foreign key (subject_key,version_key,skill_key)
  references private.iclub_subject_library_theory(subject_key,version_key,skill_key)
  on update restrict on delete restrict
);

create table if not exists private.iclub_subject_library_release_events (
 event_id bigint generated always as identity primary key,
 subject_key text not null,
 from_version text,
 to_version text,
 action text not null check (action in ('publish','hide')),
 created_at timestamptz not null default now()
);

create index if not exists iclub_subject_library_tutor_lookup
 on private.iclub_subject_library_tutor(subject_key,version_key,skill_key,locale);

alter table private.iclub_subject_library enable row level security;
alter table private.iclub_subject_library force row level security;
alter table private.iclub_subject_library_releases enable row level security;
alter table private.iclub_subject_library_releases force row level security;
alter table private.iclub_subject_library_theory enable row level security;
alter table private.iclub_subject_library_theory force row level security;
alter table private.iclub_subject_library_tutor enable row level security;
alter table private.iclub_subject_library_tutor force row level security;
alter table private.iclub_subject_library_release_events enable row level security;
alter table private.iclub_subject_library_release_events force row level security;

revoke all on private.iclub_subject_library from public,anon,authenticated;
revoke all on private.iclub_subject_library_releases from public,anon,authenticated;
revoke all on private.iclub_subject_library_theory from public,anon,authenticated;
revoke all on private.iclub_subject_library_tutor from public,anon,authenticated;
revoke all on private.iclub_subject_library_release_events from public,anon,authenticated;

grant select,insert,update on private.iclub_subject_library to service_role;
grant select,insert,update on private.iclub_subject_library_releases to service_role;
grant select,insert on private.iclub_subject_library_theory to service_role;
grant select,insert on private.iclub_subject_library_tutor to service_role;
grant select,insert on private.iclub_subject_library_release_events to service_role;
grant usage,select on sequence private.iclub_subject_library_release_events_event_id_seq to service_role;

create or replace function public.iclub_subject_library_content_service_v1(
 p_subject_key text,p_skill_key text,p_locale text
) returns jsonb
language sql stable security definer set search_path=''
as $fn$
 select coalesce((
  select jsonb_build_object(
   'subject_key',s.subject_key,'version_key',s.active_version,
   'skill_key',t.skill_key,'tour_no',t.tour_no,
   'syllabus_point',t.syllabus_point,
   'theory',t.locales->lower(p_locale),
   'tutor',jsonb_build_object(
     'title',u.title,'main_explanation',u.main_explanation,
     'simple_explanation',u.simple_explanation,
     'alternative_explanation',u.alternative_explanation,
     'focus_explanation',u.focus_explanation
   )
  )
  from private.iclub_subject_library s
  join private.iclub_subject_library_theory t
    on t.subject_key=s.subject_key and t.version_key=s.active_version
  join private.iclub_subject_library_tutor u
    on u.subject_key=t.subject_key and u.version_key=t.version_key
   and u.skill_key=t.skill_key and u.locale=lower(p_locale)
  where s.subject_key=p_subject_key and s.visible_to_learners
    and t.skill_key=p_skill_key
  limit 1
 ),'{}'::jsonb);
$fn$;

create or replace function public.iclub_subject_library_catalog_service_v1(
 p_subject_key text,p_locale text
) returns jsonb
language sql stable security definer set search_path=''
as $fn$
 select coalesce((
  select jsonb_build_object(
   'subject_key',s.subject_key,
   'version_key',s.active_version,
   'title',s.title_locales->>lower(p_locale),
   'skills',coalesce((
    select jsonb_agg(jsonb_build_object(
      'skill_key',t.skill_key,'tour_no',t.tour_no,
      'syllabus_point',t.syllabus_point,
      'title',coalesce(t.locales->lower(p_locale)->>'title',u.title)
    ) order by t.tour_no,t.skill_key)
    from private.iclub_subject_library_theory t
    join private.iclub_subject_library_tutor u
     on u.subject_key=t.subject_key and u.version_key=t.version_key
      and u.skill_key=t.skill_key and u.locale=lower(p_locale)
    where t.subject_key=s.subject_key and t.version_key=s.active_version
   ),'[]'::jsonb)
  )
  from private.iclub_subject_library s
  where s.subject_key=p_subject_key and s.visible_to_learners
  limit 1
 ),'{}'::jsonb);
$fn$;

create or replace function public.iclub_subject_library_publish_service_v1(
 p_subject_key text,p_version_key text,p_package_sha256 text
) returns jsonb
language plpgsql security definer set search_path=''
as $fn$
declare
 v_subject record;
 v_release record;
 v_skills int;
 v_tutors int;
 v_missing int;
 v_bad_hash int;
 v_bad_locales int;
 v_prev text;
begin
 select * into v_subject from private.iclub_subject_library
 where subject_key=p_subject_key for update;
 if not found then raise exception 'unknown_subject'; end if;
 select * into v_release from private.iclub_subject_library_releases
 where subject_key=p_subject_key and version_key=p_version_key for update;
 if not found or v_release.state='retired'
  or v_release.package_sha256 is distinct from p_package_sha256
 then raise exception 'release_not_found_or_digest_mismatch'; end if;

 select count(*) into v_skills from private.iclub_subject_library_theory
 where subject_key=p_subject_key and version_key=p_version_key;
 select count(*) into v_tutors from private.iclub_subject_library_tutor
 where subject_key=p_subject_key and version_key=p_version_key;
 select count(*) into v_bad_locales
 from private.iclub_subject_library_theory t
 where t.subject_key=p_subject_key and t.version_key=p_version_key
  and (select count(*) from jsonb_object_keys(t.locales))<>3;
 select count(*) into v_missing
 from private.iclub_subject_library_theory t
 cross join (values ('en'),('ru'),('uz')) as l(locale)
 left join private.iclub_subject_library_tutor u
  on u.subject_key=t.subject_key and u.version_key=t.version_key
   and u.skill_key=t.skill_key and u.locale=l.locale
 where t.subject_key=p_subject_key and t.version_key=p_version_key
  and u.skill_key is null;
 select count(*) into v_bad_hash
 from private.iclub_subject_library_tutor u
 join private.iclub_subject_library_theory t
  on t.subject_key=u.subject_key and t.version_key=u.version_key
   and t.skill_key=u.skill_key
 where u.subject_key=p_subject_key and u.version_key=p_version_key
  and u.source_card_hash<>t.content_hash;

 if v_skills<>v_release.expected_skills or v_tutors<>v_skills*3
    or v_missing<>0 or v_bad_hash<>0 or v_bad_locales<>0
 then raise exception 'release_validation_failed: skills %, tutors %, missing %, hashes %, locales %',
   v_skills,v_tutors,v_missing,v_bad_hash,v_bad_locales;
 end if;

 update private.iclub_subject_library_releases set state='validated',
  validated_at=now() where subject_key=p_subject_key and version_key=p_version_key;
 v_prev:=v_subject.active_version;
 update private.iclub_subject_library set active_version=p_version_key,
  visible_to_learners=true,updated_at=now() where subject_key=p_subject_key;
 insert into private.iclub_subject_library_release_events(subject_key,from_version,to_version,action)
 values(p_subject_key,v_prev,p_version_key,'publish');
 return jsonb_build_object('published',true,'subject',p_subject_key,
  'version',p_version_key,'skills',v_skills,'tutor_locales',v_tutors);
end;
$fn$;

create or replace function public.iclub_subject_library_hide_service_v1(
 p_subject_key text
) returns jsonb
language plpgsql security definer set search_path=''
as $fn$
declare v_prev text;
begin
 select active_version into v_prev from private.iclub_subject_library
 where subject_key=p_subject_key for update;
 if not found then raise exception 'unknown_subject'; end if;
 update private.iclub_subject_library set visible_to_learners=false,
  updated_at=now() where subject_key=p_subject_key;
 insert into private.iclub_subject_library_release_events(subject_key,from_version,to_version,action)
 values(p_subject_key,v_prev,v_prev,'hide');
 return jsonb_build_object('hidden',true,'subject',p_subject_key);
end;
$fn$;

revoke all on function public.iclub_subject_library_content_service_v1(text,text,text) from public,anon,authenticated;
revoke all on function public.iclub_subject_library_catalog_service_v1(text,text) from public,anon,authenticated;
revoke all on function public.iclub_subject_library_publish_service_v1(text,text,text) from public,anon,authenticated;
revoke all on function public.iclub_subject_library_hide_service_v1(text) from public,anon,authenticated;
grant execute on function public.iclub_subject_library_content_service_v1(text,text,text) to service_role;
grant execute on function public.iclub_subject_library_catalog_service_v1(text,text) to service_role;
grant execute on function public.iclub_subject_library_publish_service_v1(text,text,text) to service_role;
grant execute on function public.iclub_subject_library_hide_service_v1(text) to service_role;

do $verify$
begin
 if has_table_privilege('anon','private.iclub_subject_library_theory','SELECT')
  or has_table_privilege('authenticated','private.iclub_subject_library_tutor','SELECT')
  or has_function_privilege('anon','public.iclub_subject_library_content_service_v1(text,text,text)','EXECUTE')
  or has_function_privilege('authenticated','public.iclub_subject_library_catalog_service_v1(text,text)','EXECUTE')
 then raise exception 'subject_library_browser_privilege_leak'; end if;
end;
$verify$;
commit;