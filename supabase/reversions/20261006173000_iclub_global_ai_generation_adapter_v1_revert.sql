-- Safe pre-activation reversion for Global AI generated adapter v1.
-- Refuses rollback after Global AI generation has been activated or used.

begin;

do $guard$
declare
  v_runtime private.iclub_global_ai_runtime_config%rowtype;
  v_generated integer:=0;
begin
  select * into v_runtime
  from private.iclub_global_ai_runtime_config
  where id=1;

  if found and (
    v_runtime.generation_enabled
    or v_runtime.global_ai_rollout_mode<>'off'
  ) then
    raise exception 'Global AI generation reversion refused: generation/rollout is active';
  end if;

  select count(*) into v_generated
  from private.iclub_global_ai_gateway_audit
  where mode='generated'
     or model_provider is not null
     or coalesce(input_tokens,0)>0
     or coalesce(output_tokens,0)>0
     or coalesce(estimated_cost_usd,0)>0;

  if v_generated<>0 then
    raise exception 'Global AI generation reversion refused: generated/provider audit rows exist=%',v_generated;
  end if;
end;
$guard$;

drop function if exists public.record_iclub_global_ai_gateway_audit_service_v2(
  uuid,uuid,text,text,text,text,text,text,text,text,integer,text,text[],text[],text,text,integer,integer,numeric
);

drop function if exists public.finalize_iclub_global_ai_provider_call_service_v1(
  uuid,text,numeric
);

drop function if exists public.reserve_iclub_global_ai_provider_call_service_v1(
  uuid,uuid,text,text,text,numeric
);

alter table private.iclub_global_ai_gateway_audit
  drop column if exists estimated_cost_usd,
  drop column if exists output_tokens,
  drop column if exists input_tokens,
  drop column if exists model_id,
  drop column if exists model_provider,
  drop column if exists safety_flags,
  drop column if exists source_card_keys;

commit;
