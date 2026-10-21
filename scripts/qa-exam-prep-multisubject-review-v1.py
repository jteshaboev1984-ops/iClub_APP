"""Fail-closed deterministic acceptance checks for multi-subject Exam Prep Phase 2.
The checks do not connect to databases and NEVER mutate production.
"""
from pathlib import Path
import json,hashlib,os
ROOT=Path(__file__).resolve().parent
sql=(ROOT/'20261021_iclub_exam_core_review_queue_and_shell_v1.sql').read_text()
ui=json.loads((ROOT/'Exam_Prep_Shared_UI_Function_Contract_v1.json').read_text())
report=(ROOT/'PHASE2_Review_And_Parity_Report_RU.md').read_text()
checks={
 'SQL is one bounded transaction':sql.strip().startswith('-- iClub') and sql.strip().endswith('COMMIT;'),
 'SQL no DROP/TRUNCATE legacy':not any(tok in sql.upper() for tok in ('DROP TABLE','TRUNCATE','DELETE FROM PUBLIC.','UPDATE PUBLIC.','ALTER TABLE PUBLIC.')),
 'Review queue additive': 'CREATE TABLE IF NOT EXISTS private.iclub_exam_core_question_review_v1' in sql,
 'Source snapshot hash stored': 'source_snapshot_md5' in sql and 'md5(jsonb_build_object(' in sql,
 'Source immutable by DML': 'UPDATE private.iclub_exam_core_question_review_v1' not in sql,
 'Review table private RLS': 'ALTER TABLE private.iclub_exam_core_question_review_v1 FORCE ROW LEVEL SECURITY;' in sql,
 'Browser review query revoked': 'REVOKE ALL ON private.iclub_exam_core_question_review_v1 FROM PUBLIC,anon,authenticated;' in sql,
 'Only service role insert': 'GRANT SELECT,INSERT ON private.iclub_exam_core_question_review_v1 TO service_role;' in sql,
 'No answer keys in shell contract': "'correct_answer'" not in sql.split('CREATE OR REPLACE FUNCTION public.get_my_exam_prep_program_shell_v1')[1],
 'Native program shell only': "p.integration_mode='native'" in sql,
 'Shell demands approved launch': "p.status='published' AND p.launch_enabled=true" in sql,
 'Shell demands active subject selection': 'public.user_subjects' in sql and 'subj.is_active=true' in sql,
 'Shell requires real authenticated user': 'auth.uid()' in sql,
 'Anonymous shell revoked': 'REVOKE ALL ON FUNCTION public.get_my_exam_prep_program_shell_v1(text,text)' in sql,
 'No Math feature toggles': 'UPDATE private.exam_prep_' not in sql and 'INSERT INTO private.exam_prep_' not in sql,
 'No old question writes': 'INSERT INTO public.questions' not in sql,
 'Postchecks preserve Math runtime': "program_key='math_as_p1_p5' AND status='active'" in sql,
 'Excluded written short inputs': "WHEN q.qtype='input' THEN 'excluded_input'" in sql,
 'Excluded unpublished questions': "'excluded_unpublished'" in sql,
 'All content approvals pending':all(f"review_{f} text NOT NULL DEFAULT 'pending'" in sql for f in ('scope','answer_key','languages','exam_format')),
 'Exact queued QA cardinality': 'v_total<>1702 OR v_unmapped<>1644 OR v_inactive<>19 OR v_input<>39' in sql,
 'One shared exam host':ui['policy']['one_host_for_all_subjects'],
 'No custom Economics alternative':ui['policy']['no_second_custom_economics_exam_prep'],
 'Preserve live Math UI':ui['policy']['preserve_existing_math_runtime'] and not ui['runtime_adapter']['mathematics']['change_existing_math_code_now'],
 'Canonical root exact':ui['source_of_truth']['host_root']=='#exam-prep-host-root',
 'Canonical entry exact':ui['source_of_truth']['entry_card']=='#subject-hub-exam-prep-entry',
 'Mathematics canonical stylesheet':ui['source_of_truth']['styles']=='exam-prep/exam-prep-host.css',
 'Same EN RU UZ':set(ui['policy']['same_language_choices'])=={'ru','en','uz'},
 'No learner progress migration':ui['policy']['no_cross_subject_score_or_mastery_migration'],
 'No AI fabricated essay marks':ui['policy']['written_marking_not_fabricated'],
 'Paper metadata four':set(ui['economics_paper_specific_rules'])=={'P1','P2','P3','P4'},
 'Exam Prep disabled':ui['runtime_adapter']['economics']['launch_enabled'] is False,
 'Report states no live UI': 'не запущен' in report and 'NO-GO' in report,
 'RU report notes 815 unclassified': '815' in report,
}
for name,passed in checks.items():
 print(('PASS' if passed else 'FAIL')+' | '+name)
summary={'phase':'2','status':'PASS' if all(checks.values()) else 'FAIL', 'checks':len(checks),'passed':sum(checks.values()),'failed':[name for name,yes in checks.items() if not yes], 'live_browser_qa':'NOT_RUN_NEW_EXAM_PREP_OFF', 'database_postcheck':{'question_sources':1702,'review_unmapped':1644,'explicit_AS_candidates':326,'explicit_A_candidates':503,'unclassified_mcq':815,'excluded_input':39,'excluded_unpublished':19,'source_drift':0,'Math_sessions':543,'Math_responses':1976,'Practice_attempts':502,'Practice_answers':4816,'subject_selections':2098,'economics_launch_enabled':False,'notes':'Grounded in Supabase SELECT checks in this turn; not independently recomputed here.'}}
(ROOT/'PHASE2_Deterministic_QA.json').write_text(json.dumps(summary,indent=2,ensure_ascii=False)+'\n')
assert not summary['failed'],summary['failed']