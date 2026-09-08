-- P2-06 exam-calendar integrity v1.
-- A row may be marked final_verified only with an explicit verification time and official Cambridge source URL.
-- Also audit checklist-definition changes because learner-facing exam-operation instructions are governed content.

begin;

alter table private.exam_prep_exam_calendar
  drop constraint if exists exam_prep_exam_calendar_final_source_check;
alter table private.exam_prep_exam_calendar
  add constraint exam_prep_exam_calendar_final_source_check check(
    status<>'final_verified' or (
      verified_at is not null and
      source_url ~* '^https://www\.cambridgeinternational\.org/'
    )
  );

drop trigger if exists exam_prep_exam_ops_checklist_items_audit_v1 on private.exam_prep_exam_ops_checklist_items;
create trigger exam_prep_exam_ops_checklist_items_audit_v1
after insert or update or delete on private.exam_prep_exam_ops_checklist_items
for each row execute function private.exam_prep_audit_row_change_v1();

do $$ declare v_def text; v_count int; begin
  select pg_get_constraintdef(oid) into v_def from pg_constraint
  where conrelid='private.exam_prep_exam_calendar'::regclass and conname='exam_prep_exam_calendar_final_source_check';
  if position('cambridgeinternational' in lower(coalesce(v_def,'')))=0 or position('verified_at' in lower(coalesce(v_def,'')))=0 then
    raise exception 'P2-06 final timetable source guard missing';
  end if;
  select count(*) into v_count from private.exam_prep_exam_calendar where status='final_verified';
  if v_count<>0 then raise exception 'P2-06 calendar integrity release must not add final timetable rows'; end if;
end $$;

commit;
