create or replace function public.sync_user_credentials_safe_v1(p_snapshot jsonb default '{}'::jsonb)
returns table(code text, status text, evidence_snapshot jsonb, achieved_at timestamptz, last_evaluated_at timestamptz)
language plpgsql
security definer
set search_path to 'public','auth','pg_temp'
as $function$
declare
  v_uid uuid := auth.uid();
  v_preview jsonb;
  v_code text;
  v_def_id bigint;
  v_candidate text;
  v_existing public.user_credentials%rowtype;
  v_desired text;
  v_evidence jsonb;
  v_achieved timestamptz;
  v_now timestamptz := now();
  v_rule_active boolean;
  v_rule_status text;
begin
  if v_uid is null then
    raise exception 'not_authenticated' using errcode='28000';
  end if;
  if p_snapshot is null then p_snapshot := '{}'::jsonb; end if;
  if jsonb_typeof(p_snapshot) <> 'object' then
    raise exception 'invalid_credential_snapshot' using errcode='22023';
  end if;

  v_preview := public.iclub_preview_credential_evidence_v1(v_uid);

  foreach v_code in array array[
    'consistent_learner',
    'focused_study_streak',
    'active_video_learner',
    'practice_mastery_subject',
    'error_driven_learner',
    'research_oriented_learner',
    'fair_play_participant'
  ] loop
    v_def_id := null;
    select cd.id into v_def_id
    from public.credential_definitions cd
    where cd.code=v_code and coalesce(cd.is_active,true)=true
    limit 1;
    if v_def_id is null then continue; end if;

    select * into v_existing
    from public.user_credentials uc
    where uc.user_id=v_uid and uc.credential_id=v_def_id
    limit 1;

    v_candidate := lower(coalesce(p_snapshot->v_code->>'status','inactive'));
    if v_candidate not in ('active','inactive','expired','revoked') then v_candidate := 'inactive'; end if;
    v_desired := 'inactive';
    v_evidence := '{}'::jsonb;
    v_achieved := v_existing.achieved_at;

    if v_code='consistent_learner' then
      v_rule_active := coalesce((v_preview->v_code->>'rule_active')::boolean,false);
      if v_rule_active and v_candidate='active' then
        v_desired := 'active';
      elsif v_existing.status='active' and v_candidate='active' then
        v_desired := 'active';
      else
        v_desired := 'inactive';
      end if;
      v_evidence := coalesce(v_preview->v_code,'{}'::jsonb) || jsonb_build_object('validated_by','server_v1');

    elsif v_code='focused_study_streak' then
      v_rule_active := coalesce((v_preview->v_code->>'rule_active')::boolean,false);
      if (v_rule_active and v_candidate='active') or (v_existing.status='active' and v_candidate='active') then
        v_desired := 'active';
      elsif v_existing.achieved_at is not null and v_candidate in ('expired','inactive') then
        v_desired := 'expired';
      else
        v_desired := 'inactive';
      end if;
      v_evidence := coalesce(v_preview->v_code,'{}'::jsonb) || jsonb_build_object('validated_by','server_v1');

    elsif v_code='research_oriented_learner' then
      v_rule_active := coalesce((v_preview->v_code->>'rule_active')::boolean,false);
      if v_existing.status='active' or (v_candidate='active' and v_rule_active) then
        v_desired := 'active';
      else
        v_desired := 'inactive';
      end if;
      v_evidence := coalesce(v_preview->v_code,'{}'::jsonb) || jsonb_build_object('validated_by','server_v1');

    elsif v_code='fair_play_participant' then
      v_rule_status := coalesce(v_preview->v_code->>'rule_status','inactive');
      if v_existing.status='revoked' or v_rule_status='revoked' then
        v_desired := 'revoked';
      elsif v_existing.status='active' or (v_candidate='active' and v_rule_status='active') then
        v_desired := 'active';
      else
        v_desired := 'inactive';
      end if;
      v_evidence := coalesce(v_preview->v_code,'{}'::jsonb) || jsonb_build_object('validated_by','server_v1');

    else
      v_desired := 'inactive';
      v_evidence := jsonb_build_object(
        'canonical_ready',false,
        'validated_by','server_v1',
        'reason',case v_code
          when 'active_video_learner' then 'video_completion_signal_not_wired'
          when 'practice_mastery_subject' then 'legacy_evaluator_not_wired'
          when 'error_driven_learner' then 'legacy_attempt_evaluator_not_wired'
          else 'unsupported'
        end
      );
    end if;

    if v_desired='active' and v_achieved is null then v_achieved := v_now; end if;

    insert into public.user_credentials(user_id,credential_id,status,evidence_snapshot,last_evaluated_at,achieved_at)
    values(v_uid,v_def_id,v_desired,v_evidence,v_now,v_achieved)
    on conflict(user_id,credential_id) do update
      set status=excluded.status,
          evidence_snapshot=excluded.evidence_snapshot,
          last_evaluated_at=excluded.last_evaluated_at,
          achieved_at=coalesce(public.user_credentials.achieved_at,excluded.achieved_at);
  end loop;

  return query
  select cd.code, uc.status, uc.evidence_snapshot, uc.achieved_at, uc.last_evaluated_at
  from public.user_credentials uc
  join public.credential_definitions cd on cd.id=uc.credential_id
  where uc.user_id=v_uid
    and cd.code = any(array[
      'consistent_learner','focused_study_streak','active_video_learner',
      'practice_mastery_subject','error_driven_learner','research_oriented_learner','fair_play_participant'
    ])
  order by cd.id;
end;
$function$;

revoke all on function public.sync_user_credentials_safe_v1(jsonb) from public, anon;
grant execute on function public.sync_user_credentials_safe_v1(jsonb) to authenticated, service_role;

comment on function public.sync_user_credentials_safe_v1(jsonb) is
'Server-authoritative credential sync. Client snapshot may request transitions, but status is validated against canonical DB evidence. Unsupported legacy credential paths remain inactive.';
