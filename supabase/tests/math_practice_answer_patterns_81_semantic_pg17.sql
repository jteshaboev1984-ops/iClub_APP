-- #574 read-only against disposable authored 81-version PG17 staging.
-- Ensures changing correct-letter positions preserves correct *meaning* in EN/RU/UZ.
do $math_rekey_81$
declare
  v_count int;
begin
  select count(*) into v_count
  from public.questions o
  join private.practice_v2_question_meta mo on mo.question_id=o.id
  join private.practice_v2_question_meta mn
    on mn.content_key=mo.content_key||'-V20261120'
  join public.questions n on n.id=mn.question_id
  where o.id in (7662,7926,7970)
    and mn.release_version='math_p1_practice_v2_fix_20261120'
    and o.is_active=true and o.quality_status='published'
    and n.is_active=false and n.quality_status='draft'
    and mn.qa_math_status='pending'
    and mn.qa_language_status='pending'
    and mn.qa_technical_status='pending'
    and mn.qa_tour_separation_status='pending'
    and o.correct_answer<>n.correct_answer
    and jsonb_array_length(o.options_text_en::jsonb)=4
    and jsonb_array_length(n.options_text_en::jsonb)=4
    and o.options_text_en::jsonb ->> (ascii(o.correct_answer)-ascii('A'))
      = n.options_text_en::jsonb ->> (ascii(n.correct_answer)-ascii('A'))
    and o.options_text_ru::jsonb ->> (ascii(o.correct_answer)-ascii('A'))
      = n.options_text_ru::jsonb ->> (ascii(n.correct_answer)-ascii('A'))
    and o.options_text_uz::jsonb ->> (ascii(o.correct_answer)-ascii('A'))
      = n.options_text_uz::jsonb ->> (ascii(n.correct_answer)-ascii('A'));
  if v_count<>3 then raise exception 'versioned_81_rekey_semantic_mismatch';end if;
  raise notice 'MATH_81_STAGE_THREE_REKEY_OPTIONS_TRILINGUAL_PG17_PASS';
end $math_rekey_81$;
