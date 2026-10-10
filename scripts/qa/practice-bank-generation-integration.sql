-- Assert historical backfill, server-issued generation, RLS-safe reads and provenance.
set app.test_uid = '11111111-1111-4111-8111-111111111111';
do $$
declare v int; v_id bigint; v_failed boolean; v_result jsonb;
begin
 select bank_generation into v from public.practice_sessions_v4 where id=10;
 if v<>1 then raise exception 'pre-publication session not gen1: %',v; end if;
 select bank_generation into v from public.practice_sessions_v4 where id=11;
 if v<>2 then raise exception 'post-publication session not gen2: %',v; end if;
 select bank_generation into v from public.practice_sessions_v4 where id=12;
 if v<>1 then raise exception 'biology must remain gen1: %',v; end if;
 select bank_generation into v from public.recommendations where id=1;
 if v<>1 then raise exception 'legacy old recommendation not gen1'; end if;
 select bank_generation into v from public.recommendations where id=2;
 if v<>2 then raise exception 'legacy new recommendation not gen2'; end if;
 select bank_generation into v from public.recommendations where id=4;
 if v is not null then raise exception 'Tours generation must stay NULL'; end if;
 insert into public.practice_sessions_v4(user_id,subject_id,status)
 values ('11111111-1111-4111-8111-111111111111',5,'finalized') returning id into v_id;
 select bank_generation into v from public.practice_sessions_v4 where id=v_id;
 if v<>2 then raise exception 'new Math session not gen2'; end if;
 v_failed:=false;
 begin
  update public.practice_sessions_v4 set bank_generation=1 where id=v_id;
 exception when others then v_failed:=true;
 end;
 if not v_failed then raise exception 'session generation mutable'; end if;
 select public.sync_practice_recommendations_safe_v1(
  'mathematics',11,'[{"topic":"Algebra","subtopic":"Linear"}]'::jsonb
 ) into v_result;
 if (v_result->>'generation')::int<>2 then raise exception 'safe sync wrong generation'; end if;
 select public.sync_practice_recommendations_safe_v1(
  'mathematics',11,'[{"topic":"Algebra","subtopic":"Linear"}]'::jsonb
 ) into v_result;
 if (select count(*) from public.recommendations where practice_session_id=11)<>1
 then raise exception 'retry duplicated recommendations'; end if;
 v_failed:=false;
 begin
  perform public.sync_practice_recommendations_safe_v1(
   'mathematics',11,'[{"topic":"Geometry","subtopic":"Circles"}]'::jsonb);
 exception when others then v_failed:=true;
 end;
 if not v_failed then raise exception 'server accepted a correct-answer recommendation'; end if;
 v_failed:=false;
 begin
  insert into public.recommendations(user_id,subject_id,source_type,topic,subtopic,practice_session_id)
  values('22222222-2222-4222-8222-222222222222',5,'practice','Algebra','Linear',11);
 exception when others then v_failed:=true;
 end;
 if not v_failed then raise exception 'cross-user origin accepted'; end if;
 select public.get_current_practice_recommendations_safe_v1('mathematics') into v_result;
 if (v_result->>'generation')::int<>2 then raise exception 'read wrong active generation'; end if;
 if exists(select 1 from jsonb_array_elements(v_result->'recommendations') x
           where (x->>'bank_generation')::int<>2)
 then raise exception 'read leaked previous generation'; end if;
end $$;
select 'PRACTICE_GENERATIONS_POSTGRES_INTEGRATION_GREEN' as result;
