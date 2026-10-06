-- Normalize learner-facing whitespace in the just-promoted Tutor v3 corpus.
-- Non-semantic formatting repair only. No learner state/history data is touched.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 whitespace normalization expected 243 active v3 cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 whitespace normalization expected 243 active atomic sources, found %',v; end if;
end
$pre$;

update private.exam_prep_ai_tutor_cards
set main_explanation=regexp_replace(main_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),
    simple_explanation=regexp_replace(simple_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),
    alternative_explanation=regexp_replace(alternative_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),
    focus_explanation=regexp_replace(focus_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),
    content_hash=md5(concat_ws('||',
      content_version,title,regexp_replace(main_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),regexp_replace(simple_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),
      regexp_replace(alternative_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),regexp_replace(focus_explanation,'^[[:space:]]+|[[:space:]]+$','','g'),source_card_key
    )),
    updated_at=now()
where content_version='tutor_v3_learner_first';

with built as (
  select
    s.source_card_key,
    case t.locale
      when 'ru' then 'Фокус темы: '||t.title||E'.\n\nОсновное объяснение:\n'||t.main_explanation||E'\n\nКритическая проверка:\n'||t.focus_explanation
      when 'uz' then 'Mavzu fokusi: '||t.title||E'.\n\nAsosiy tushuntirish:\n'||t.main_explanation||E'\n\nMuhim tekshiruv:\n'||t.focus_explanation
      else 'Topic focus: '||t.title||E'.\n\nCore explanation:\n'||t.main_explanation||E'\n\nCritical check:\n'||t.focus_explanation
    end as body
  from private.exam_prep_ai_source_cards s
  join private.exam_prep_ai_tutor_cards t on t.source_card_key=s.source_card_key
  where s.source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and t.content_version='tutor_v3_learner_first'
)
update private.exam_prep_ai_source_cards s
set body_text=b.body,
    content_hash=encode(digest(convert_to(b.body,'UTF8'),'sha256'),'hex'),
    updated_at=now()
from built b
where s.source_card_key=b.source_card_key;

do $post$
declare v integer;
begin
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and (
        main_explanation<>regexp_replace(main_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
        or simple_explanation<>regexp_replace(simple_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
        or alternative_explanation<>regexp_replace(alternative_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
        or focus_explanation<>regexp_replace(focus_explanation,'^[[:space:]]+|[[:space:]]+$','','g')
      )
  ) then raise exception 'Tutor v3 whitespace normalization left leading/trailing whitespace'; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and content_hash<>md5(concat_ws('||',
        content_version,title,main_explanation,simple_explanation,
        alternative_explanation,focus_explanation,source_card_key
      ))
  ) then raise exception 'Tutor v3 whitespace normalization left stale Tutor hash'; end if;

  if exists(
    select 1
    from private.exam_prep_ai_source_cards
    where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
      and content_hash<>encode(digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
  ) then raise exception 'Tutor v3 whitespace normalization left stale source hash'; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 whitespace normalization changed runtime ownership'; end if;

  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='retired' and not is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 whitespace normalization changed retired v2 state'; end if;
end
$post$;

commit;
