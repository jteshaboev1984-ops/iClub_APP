-- READ ONLY, private admin environment only; no learner IDs or criterion text returned.
with base as (
 select wt.component_code,wt.id,wt.task_version,
        c.value->>'id' criterion_id,c.value->>'rule' rule_en,
        nullif(btrim(coalesce(c.value->>'rule_ru','')),'') original_ru,
        nullif(btrim(coalesce(c.value->>'rule_uz','')),'') original_uz
 from private.exam_prep_written_tasks wt
 cross join lateral jsonb_array_elements(wt.rubric_json->'criteria') c(value)
 where wt.component_code in ('P1','P5') and wt.lifecycle_state='published'
   and wt.qa_math_status='pass' and wt.qa_language_status='pass'
   and wt.qa_technical_status='pass'
), coverage as (
 select b.component_code,b.id,
   (b.original_ru is not null or
    (ru.review_state='approved' and ru.source_rule_md5=md5(b.rule_en))) ru_ok,
   (b.original_uz is not null or
    (uz.review_state='approved' and uz.source_rule_md5=md5(b.rule_en))) uz_ok
 from base b
 left join private.exam_prep_written_criteria_locale_v1 ru
   on ru.written_task_id=b.id and ru.task_version=b.task_version
  and ru.criterion_id=b.criterion_id and ru.language='ru'
 left join private.exam_prep_written_criteria_locale_v1 uz
   on uz.written_task_id=b.id and uz.task_version=b.task_version
  and uz.criterion_id=b.criterion_id and uz.language='uz'
)
select component_code,count(distinct id) tasks,count(*) total_criteria,
       count(*) filter(where ru_ok) approved_ru,
       count(*) filter(where uz_ok) approved_uz,
       count(*) filter(where not ru_ok) missing_ru,
       count(*) filter(where not uz_ok) missing_uz
from coverage group by component_code order by component_code;
