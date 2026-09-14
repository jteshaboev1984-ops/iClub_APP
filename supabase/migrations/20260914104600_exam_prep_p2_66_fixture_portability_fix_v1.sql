begin;

-- P2-66 portability fix: use only the auth/public user columns shared by the
-- isolated CI contract and production. Synthetic accounts remain non-login
-- identities because no password or confirmation credential is created.
create or replace function private.create_exam_prep_synthetic_identity_v1(
  p_run_id text,
  p_identity_kind text,
  p_fixture_profile_key text,
  p_evidence_ref text,
  p_purpose text,
  p_locale text default 'en'
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_user uuid:=gen_random_uuid();
  v_email text;
  v_locale text:=lower(coalesce(nullif(trim(p_locale),''),'en'));
begin
  select * into v_run
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;
  if v_run.run_status not in ('registered','running') or v_run.cleanup_status<>'not_started' then
    raise exception 'exam_prep_synthetic_identity_run_not_open_for_fixture_registration';
  end if;
  if p_identity_kind not in ('learner','mentor') then raise exception 'exam_prep_synthetic_identity_kind_invalid'; end if;
  if v_locale not in ('en','ru','uz') then raise exception 'exam_prep_synthetic_locale_invalid'; end if;
  if p_fixture_profile_key is null or trim(p_fixture_profile_key)!~'^SVF-[A-Z0-9][A-Z0-9-]{3,63}$' then
    raise exception 'exam_prep_synthetic_fixture_profile_key_invalid';
  end if;

  v_email:='exam-prep-sv-'||substr(md5(p_run_id||v_user::text),1,12)||'-'||replace(v_user::text,'-','')||'@invalid.example';

  insert into auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  values(v_user,'authenticated','authenticated',v_email,now(),now(),false,false);

  insert into public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  values(
    v_user,
    case when p_identity_kind='mentor' then 'SV Mentor' else 'SV Learner' end,
    trim(p_fixture_profile_key),v_locale,now(),false
  );

  insert into private.exam_prep_synthetic_identities(
    user_id,run_id,identity_kind,fixture_profile_key,identity_status,evidence_ref,purpose
  ) values(
    v_user,p_run_id,p_identity_kind,trim(p_fixture_profile_key),'active',trim(p_evidence_ref),trim(p_purpose)
  );

  return v_user;
end;
$$;
revoke all on function private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text) from public,anon,authenticated;
grant execute on function private.create_exam_prep_synthetic_identity_v1(text,text,text,text,text,text) to service_role;

commit;
