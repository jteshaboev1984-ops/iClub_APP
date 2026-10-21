begin;
set local lock_timeout='3s';
set local statement_timeout='30s';
create or replace function public.get_my_subject_learning_catalog_v1(p_subject_key text,p_locale text default 'ru')
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
declare uid uuid;
begin
 uid:=auth.uid();
 if uid is null or p_subject_key is null or p_locale not in ('en','ru','uz') then return '{}'::jsonb; end if;
 if not exists(
  select 1 from public.user_subjects us
  join public.subjects sub on sub.id=us.subject_id
  where us.user_id=uid and sub.subject_key=p_subject_key and sub.is_active
 ) then return '{}'::jsonb; end if;
 return public.iclub_subject_library_catalog_service_v1(p_subject_key,p_locale);
end;
$fn$;
create or replace function public.get_my_subject_learning_content_v1(p_subject_key text,p_skill_key text,p_locale text default 'ru')
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
declare uid uuid;
begin
 uid:=auth.uid();
 if uid is null or p_subject_key is null or p_skill_key is null or p_locale not in ('en','ru','uz') then return '{}'::jsonb; end if;
 if not exists(
  select 1 from public.user_subjects us
  join public.subjects sub on sub.id=us.subject_id
  where us.user_id=uid and sub.subject_key=p_subject_key and sub.is_active
 ) then return '{}'::jsonb; end if;
 return public.iclub_subject_library_content_service_v1(p_subject_key,p_skill_key,p_locale);
end;
$fn$;
revoke all on function public.get_my_subject_learning_catalog_v1(text,text) from public,anon,authenticated;
revoke all on function public.get_my_subject_learning_content_v1(text,text,text) from public,anon,authenticated;
grant execute on function public.get_my_subject_learning_catalog_v1(text,text) to authenticated;
grant execute on function public.get_my_subject_learning_content_v1(text,text,text) to authenticated;
do $checks$
begin
 if has_function_privilege('anon','public.get_my_subject_learning_catalog_v1(text,text)','EXECUTE')
  or has_function_privilege('anon','public.get_my_subject_learning_content_v1(text,text,text)','EXECUTE')
 then raise exception 'anonymous_exposure'; end if;
end;
$checks$;
commit;