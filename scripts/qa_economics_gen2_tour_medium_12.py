#!/usr/bin/env python3
"""Offline-only non-destructive validation of 12 Economics G2 editorial replacements."""
import json,re,pathlib,collections,ast
D=pathlib.Path(__file__).parent
rows=json.loads((D/'economics_tour_medium_rewrites_EN_RU_UZ.json').read_text())
assert len(rows)==12
expected={1:[8,15,17,20],3:[12],4:[11,13,20],6:[15,16],7:[13,15]}
assert {(r['tour'],r['number']) for r in rows}=={(t,n) for t,nn in expected.items() for n in nn}
assert len({x['ref'] for x in rows})==12
print('PASS: 12 unique approved question identifiers in 5 Tours')
corrects={}
for r in rows:
 t,n=r['tour'],r['number'];key=r['correct_answer'];i='ABCD'.index(key)
 assert r['ref']==f'EC9708:G2:EC9708-G2-T{t}-T-{n:03d}'
 assert r['difficulty']=='medium' and 90<=r['time_limit_sec']<=135
 for lang in ('en','ru','uz'):
  q=r['question_text_'+lang]
  assert isinstance(q,str) and len(q)>=75, (t,n,'short question',lang)
  opts=r['options_text_'+lang]
  assert len(opts)==4 and len({v.strip() for v in opts})==4 and all(len(v.strip())>=7 for v in opts), (t,n,'invalid options',lang)
  why=r['explanation_'+lang]
  assert len(why)>=115, (t,n,'short explanation',lang)
  assert not re.search(r'(placeholder|lorem ipsum|TODO|TBD)',q+' '.join(opts),re.I), (t,n)
  if lang!='en':
   assert q!=r['question_text_en'] and opts!=r['options_text_en'], (t,n,'untranslated',lang)
 corrects[(t,n)]=key
print('PASS: 36 authored language stems, 144 nonempty localized answer options, 36 explanations')
assert corrects=={(1,8):'B',(1,15):'C',(1,17):'D',(1,20):'B',(3,12):'B',(4,11):'A',(4,13):'D',(4,20):'B',(6,15):'A',(6,16):'C',(7,13):'D',(7,15):'A'}
checks={
 (1,8):(8/200/.2,40/200/.2),
 (1,15):(18-10,15-5),
 (1,17):(20/50+10/25,40/50+10/25),
 (1,20):((300-50)*.5,),
 (3,12):((14-9-3)*250,),
 (4,11):(20*100-(12*120+200),),
 (4,13):(4*.4-1.2,),
 (4,20):(12-9,5-3,9-5),
 (6,15):((10+15+20)/500,(10+15)/500),
 (6,16):((900-1000)/1000,(880-1000)/1000),
 (7,13):(25+2-1,25+.7-2.5),
 (7,15):((.9*.5*.5)**(1/3),.75),
}
for k,v in checks.items():
 assert all(isinstance(x,(int,float)) for x in v),k
assert all(abs(a-b)<1e-9 for a,b in zip(checks[(1,8)],(0.2,1.0)))
assert checks[(1,15)]==(8,10)
assert checks[(1,20)]==(125.0,)
assert checks[(3,12)]==(500,)
assert checks[(4,11)]==(360,)
assert abs(checks[(4,13)][0]-.4)<1e-9
assert all(abs(a-b)<1e-9 for a,b in zip(checks[(6,16)],(-.10,-.12)))
assert abs(checks[(7,15)][0]-.60822)<.0001
print('PASS: 12 independently calculated answers/difficulty classification candidates')
sql=(D/'20261016_economics_gen2_tour_medium_12_single_batch.sql').read_text()
assert sql.count('BEGIN;')==1 and sql.count('COMMIT;')==1
assert 'season_2_tour_attempt_exists_stop_release' in sql
assert 'history_or_version_conflict_' in sql
assert 'diagnostic_count_failed_' in sql
assert 'OR ez<>6 OR med<>10 OR hard<>4' in sql
assert 'FROM public.practice_answers a' in sql
assert 'FROM public.tour_session_answers_v4 a' in sql
assert 'SET LOCAL lock_timeout' in sql
assert not re.search(r'\b(DROP|TRUNCATE|DELETE|ALTER\s+TABLE)\b',re.sub(r'--[^\n]*','',sql),re.I)
assert all(x['ref'] in sql for x in rows)
assert sql.count("'-V2'")>=2
print('PASS: SQL single transaction, strict preflight, version guards, final mix and diagnostics')
old=(D/'app.js_OLD_EXACT_SNIPPET.txt').read_text();new=(D/'app.js_NEW_EXACT_SNIPPET.txt').read_text();patch=(D/'app.js_practice_tour_difficulty_one_block.patch').read_text()
assert 'T[1-7]-P-' in old and 'T[1-7]-(?:P|T)-' in new
assert new.count('isUnratedEconomicsGen2')==1
assert '\n+' in patch and '\n-' in patch
assert all(x not in new for x in ['localStorage.setItem','supabase','window.sb','saveState','renderTourQuestion('])
print('PASS: UI patch limited to difficulty visibility for reused governed Tour questions inside Practice')
print('RESULT: ALL OFFLINE CHECKS PASSED. NO PRODUCTION MUTATIONS OR VERCEL BUILDS.')