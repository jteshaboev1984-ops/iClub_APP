-- STAGED ONLY: authenticated, server-owned Practice recommendations.
-- Install only after practice_bank_generations_all_subjects_v1.
begin;
create or replace function public.sync_practice_recommendations_safe_v1(
 p_subject_key text,p_session_id bigint,p_items jsonb
) returns jsonb language plpgsql security definer
set search_path = pg_catalog,public,auth,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_subject bigint; v_session public.practice_sessions_v4%rowtype;
 v_item jsonb; v_topic text; v_subtopic text; v_count int:=0;
begin
 if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
 if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)>30 then
   raise exception 'invalid_recommendations' using errcode='22023';
 end if;
 select id into v_subject from public.subjects where subject_key=trim(p_subject_key);
 if v_subject is null then raise exception 'invalid_subject' using errcode='22023'; end if;
 select * into v_session from public.practice_sessions_v4
 where id=p_session_id and user_id=v_uid and subject_id=v_subject and status='finalized';
 if v_session.id is null or v_session.bank_generation is null then
   raise exception 'practice_session_not_finalized_or_unclassified' using errcode='22023';
 end if;
 for v_item in select value from jsonb_array_elements(p_items) loop
   v_topic:=trim(coalesce(v_item->>'topic',''));
   v_subtopic:=nullif(trim(coalesce(v_item->>'subtopic','')),'');
   if length(v_topic) not between 1 and 200 or length(coalesce(v_subtopic,''))>200 then
     raise exception 'invalid_recommendation_topic' using errcode='22023';
   end if;
   -- Session question membership is checked using server-owned answers, not client claims.
   if not exists (
     select 1 from public.practice_session_answers_v4 a
     join public.questions q on q.id=a.question_id
     where a.session_id=v_session.id and a.is_correct=false
       and q.topic=v_topic and coalesce(q.subtopic,'')=coalesce(v_subtopic,'')
   ) then
     raise exception 'recommendation_not_supported_by_mistake' using errcode='22023';
   end if;
   insert into public.recommendations
     (user_id,subject_id,source_type,topic,subtopic,practice_session_id)
   select v_uid,v_subject,'practice',v_topic,v_subtopic,v_session.id
   where not exists (
     select 1 from public.recommendations r
     where r.user_id=v_uid and r.subject_id=v_subject and r.source_type='practice'
       and r.practice_session_id=v_session.id and r.topic=v_topic
       and coalesce(r.subtopic,'')=coalesce(v_subtopic,'')
   );
   v_count:=v_count+1;
 end loop;
 return jsonb_build_object('ok',true,'generation',v_session.bank_generation,'processed',v_count);
end $$;
revoke all on function public.sync_practice_recommendations_safe_v1(text,bigint,jsonb) from public,anon;
grant execute on function public.sync_practice_recommendations_safe_v1(text,bigint,jsonb) to authenticated;

create or replace function public.get_current_practice_recommendations_safe_v1(p_subject_key text)
returns jsonb language plpgsql stable security definer
set search_path = pg_catalog,public,auth,pg_temp as $$
declare v_uid uuid:=auth.uid(); v_subject bigint; v_generation integer; v_items jsonb;
begin
 if v_uid is null then raise exception 'not_authenticated' using errcode='28000'; end if;
 select id into v_subject from public.subjects where subject_key=trim(p_subject_key);
 if v_subject is null then raise exception 'invalid_subject' using errcode='22023'; end if;
 select generation into v_generation from public.practice_bank_generations
 where subject_id=v_subject and activated_at<=statement_timestamp()
 order by activated_at desc,generation desc limit 1;
 if v_generation is null then v_generation:=1; end if;
 select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc),'[]'::jsonb) into v_items
 from (
   select id,source_type,topic,subtopic,book_id,book_reference,created_at,bank_generation
   from public.recommendations
   where user_id=v_uid and subject_id=v_subject and source_type='practice'
     and bank_generation=v_generation
   order by created_at desc limit 100
 ) x;
 return jsonb_build_object('ok',true,'subject_key',trim(p_subject_key),
   'generation',v_generation,'recommendations',v_items);
end $$;
revoke all on function public.get_current_practice_recommendations_safe_v1(text) from public,anon;
grant execute on function public.get_current_practice_recommendations_safe_v1(text) to authenticated;
commit;
