-- iClub Practice · Issue #574 · candidate only; production owner GO required.
-- Correct one PostgreSQL regexp escaping defect in the installed shared v4 scorer.
-- DO NOT replay the historic October v4 definition: live v4 has later Chemistry
-- branches that must remain byte-for-byte unchanged.
--
-- Existing regexp_split_to_table(correct_answer, '\\|') treats '\\|' as
-- a zero-width alternation, splitting an answer into characters. As a result,
-- a wrong positive number can match one character of a negative correct answer.
-- Use literal pipe delimiter; preserve optional pipe-separated accepted answers.
--
-- No DML, scoring history rewrite, question edit, RLS/access/role change.
-- Additive migration source only. Apply to existing production DB ONLY after
-- explicit owner release approval, schema fingerprint/preflight and rollback plan.

begin;

do $patch$
declare
  v_signature constant text :=
    'public.iclub_eval_practice_question_safe_v4(bigint,text,integer)';
  v_function regprocedure;
  v_before text;
  v_after text;
  v_installed text;
  v_old constant text := $old$from regexp_split_to_table(coalesce(v_q.correct_answer,''), '\\|') accepted_answer$old$;
  v_new constant text := $new$from unnest(string_to_array(coalesce(v_q.correct_answer,''), '|')) accepted_answer$new$;
  v_occurrences integer;
begin
  v_function := to_regprocedure(v_signature);
  if v_function is null then
    raise exception 'practice_v4_evaluator_missing__do_not_install';
  end if;

  select pg_get_functiondef(v_function) into v_before;

  if position(v_new in v_before)>0 then
    raise exception 'practice_v4_evaluator_already_patched__stop_and_reconcile';
  end if;

  v_occurrences :=
    (length(v_before)-length(replace(v_before,v_old,'')))/nullif(length(v_old),0);

  if v_occurrences is distinct from 1
     or position('v_selected_norm:=public.iclub_normalize_answer(v_selected)' in v_before)=0
     or position('public.iclub_numeric_value(v_selected)' in v_before)=0
     or position('security definer' in lower(v_before))=0 then
    raise exception 'practice_v4_unexpected_source__fail_closed';
  end if;

  -- Recreate from the actual installed definition, with EXACTLY one expression
  -- replacement. All newer subject-specific code and function attributes survive.
  v_after := replace(v_before,v_old,v_new);
  execute v_after;

  select pg_get_functiondef(v_function) into v_installed;
  if v_installed is distinct from v_after then
    raise exception 'practice_v4_source_changed_beyond_literal_split__rollback';
  end if;
end
$patch$;

commit;
