#!/usr/bin/env python3
"""Prepare a validated, append-only SQL import for iClub Universal Subject Library.

This tool never connects to production. Its output is not a publication trigger.
Future subjects can use the same Theory/Tutor JSON envelope and CLI.
"""
import argparse,collections,csv,hashlib,json,pathlib,re,sys

LOCALES = ('en','ru','uz')
THEORY_FIELDS = ('title','explanation','original_example','common_trap','check_question','check_answer')
TUTOR_FIELDS = ('title','main_explanation','simple_explanation','alternative_explanation','focus_explanation')

def must(cond,msg):
    if not cond: raise ValueError(msg)
def lit(v):
    if v is None: return 'NULL'
    if isinstance(v,int): return str(v)
    return "'"+str(v).replace("'","''")+"'"
def digest(value): return hashlib.sha256(value).hexdigest()
def compact_json(obj): return json.dumps(obj,ensure_ascii=False,separators=(',',':'))

# Hash a fixed-order tuple; no lesson/answer text is embedded in postcheck SQL.
# Unit separator is rejected in content so field boundaries are unambiguous.
SEP = '\x1f'
def fingerprint(parts):
    values=[str(part) for part in parts]
    must(all(SEP not in part for part in values),'Reserved control character in release input')
    return digest(SEP.join(values).encode('utf-8'))

def package(theory_path,tutor_path,subject,version,names,output,batch=75):
    theory_bytes=pathlib.Path(theory_path).read_bytes(); tutor_bytes=pathlib.Path(tutor_path).read_bytes()
    t=json.loads(theory_bytes); u=json.loads(tutor_bytes)
    cards=t['cards']; tutors=u['data']
    must(re.fullmatch(r'[a-z][a-z0-9_]{2,49}',subject) is not None,'Invalid subject key')
    must(re.fullmatch(r'[a-zA-Z0-9_.-]{3,120}',version) is not None,'Invalid release version')
    must(len(cards)>0 and len(tutors)==3*len(cards),'Expected exactly 3 tutor records per Theory skill')
    must(u.get('source_theory_sha256')==digest(theory_bytes),'Tutor points to different Theory source bytes')
    must(set(names)==set(LOCALES) and all(names[l] for l in LOCALES),'All titles EN/RU/UZ required')
    theory_by_key={}; locales=collections.defaultdict(set)
    for c in cards:
        key=c['skill_key']; must(key not in theory_by_key,'Duplicate Theory: '+key)
        must(isinstance(c['tour_no'],int) and 1<=c['tour_no']<=100,'Bad tour: '+key)
        must(set(c['locales'])==set(LOCALES),'Theory locale set mismatch: '+key)
        for l in LOCALES:
            must(all(isinstance(c['locales'][l].get(f),str) and c['locales'][l][f].strip() for f in THEORY_FIELDS),'Empty Theory field: '+key+' '+l)
        actual='sha256:'+digest(json.dumps({'skill_key':key,'locales':c['locales']},ensure_ascii=False,sort_keys=True,separators=(',',':')).encode())
        must(c['content_hash']==actual,'Canonical Theory hash mismatch: '+key)
        theory_by_key[key]=c
    tutor_keys=set()
    for c in tutors:
        key=c['skill_key']; locale=c['locale']; pair=(key,locale)
        must(key in theory_by_key,'Orphan Tutor: '+key)
        must(locale in LOCALES,'Bad Tutor locale')
        must(pair not in tutor_keys,'Duplicate Tutor '+str(pair))
        must(c['source_card_hash']==theory_by_key[key]['content_hash'],'Tutor source hash mismatch: '+str(pair))
        must(c.get('content_version')==version,'Tutor content version mismatch: '+str(pair))
        must(c.get('title')==theory_by_key[key]['locales'][locale]['title'],'Tutor title disagrees with Theory: '+str(pair))
        must(isinstance(c.get('tutor_card_key'),str) and c['tutor_card_key'].strip(),'Empty Tutor card key: '+str(pair))
        must(all(isinstance(c.get(f),str) and c[f].strip() for f in TUTOR_FIELDS),'Empty Tutor field: '+str(pair))
        must(c.get('subject_key')==subject,'Tutor subject mismatch: '+str(pair))
        tutor_keys.add(pair);locales[key].add(locale)
    must(all(locales[k]==set(LOCALES) for k in theory_by_key),'Not all EN/RU/UZ Tutor records exist')
    package_hash=digest(theory_bytes+b'\0'+tutor_bytes)
    out=pathlib.Path(output);out.mkdir(parents=True,exist_ok=True)
    (out/'manifest.json').write_text(json.dumps({'format':'iclub-universal-subject-v1','subject_key':subject,'version_key':version,'package_sha256':package_hash,'theory_sha256':digest(theory_bytes),'tutor_sha256':digest(tutor_bytes),'skills':len(cards),'tutor_locales':len(tutors),'languages':list(LOCALES),'mode':'STAGED_NOT_PUBLISHED'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    syllabus=t.get('syllabus','')
    header=f"""-- GENERATED. Immutable import for {subject} / {version}.
-- IMPORTANT: SQL below only creates OFFLINE/STAGED records. It never publishes to learners.
-- On conflict, rows are preserved; post-import verification must detect conflicting contents.
set local lock_timeout='3s';
set local statement_timeout='180s';
insert into private.iclub_subject_library(subject_key,title_locales,syllabus_ref)
 values({lit(subject)},{lit(compact_json(names))}::jsonb,{lit(syllabus)})
 on conflict (subject_key) do nothing;
insert into private.iclub_subject_library_releases(subject_key,version_key,package_sha256,expected_skills)
 values({lit(subject)},{lit(version)},{lit(package_hash)},{len(cards)})
 on conflict (subject_key,version_key) do nothing;
"""
    (out/'00_release_registry.sql').write_text('begin;\n'+header+'commit;\n',encoding='utf-8')
    statements=[]
    for c in cards:
        params=[subject,version,c['skill_key'],c['tour_no'],c['official_syllabus_point'],c['content_hash'],compact_json(c['locales'])]
        vals=','.join(lit(v)+('::jsonb' if i==6 else '') for i,v in enumerate(params))
        statements.append('insert into private.iclub_subject_library_theory(subject_key,version_key,skill_key,tour_no,syllabus_point,content_hash,locales) values ('+vals+') on conflict (subject_key,version_key,skill_key) do nothing;')
    for i in range(0,len(statements),batch):
        (out/f'{10+i//batch:02d}_theory_{i//batch+1:03d}.sql').write_text('begin;\nset local lock_timeout=\'3s\';\n'+ '\n'.join(statements[i:i+batch])+'\ncommit;\n',encoding='utf-8')
    statements=[]
    for c in tutors:
        cols=('subject_key','version_key','skill_key','locale','tutor_card_key','content_version',*TUTOR_FIELDS,'source_card_hash')
        vals=(subject,version,c['skill_key'],c['locale'],c['tutor_card_key'],c['content_version'],*(c[f] for f in TUTOR_FIELDS),c['source_card_hash'])
        statements.append('insert into private.iclub_subject_library_tutor('+','.join(cols)+') values ('+','.join(lit(v) for v in vals)+') on conflict (subject_key,version_key,skill_key,locale) do nothing;')
    for i in range(0,len(statements),batch):
        (out/f'{30+i//batch:02d}_tutor_{i//batch+1:03d}.sql').write_text('begin;\nset local lock_timeout=\'3s\';\n'+ '\n'.join(statements[i:i+batch])+'\ncommit;\n',encoding='utf-8')
    checks=f"""-- Read-only verifier; do not publish when any result disagrees with expected.
select r.subject_key,r.version_key,r.package_sha256,r.expected_skills,
 (select count(*) from private.iclub_subject_library_theory t where t.subject_key=r.subject_key and t.version_key=r.version_key) as theory_rows,
 (select count(*) from private.iclub_subject_library_tutor u where u.subject_key=r.subject_key and u.version_key=r.version_key) as tutor_rows,
 (select count(*) from private.iclub_subject_library_tutor u join private.iclub_subject_library_theory t on t.subject_key=u.subject_key and t.version_key=u.version_key and t.skill_key=u.skill_key where u.subject_key=r.subject_key and u.version_key=r.version_key and u.source_card_hash<>t.content_hash) as hash_mismatches
 from private.iclub_subject_library_releases r
 where r.subject_key={lit(subject)} and r.version_key={lit(version)};
"""
    (out/'99_postcheck_READ_ONLY.sql').write_text(checks,encoding='utf-8')
    print(json.dumps({'subject':subject,'version':version,'skills':len(cards),'tutors':len(tutors),'digest':package_hash,'sql_chunks':len(list(out.glob('*.sql'))),'bytes':sum(x.stat().st_size for x in out.glob('*.sql'))},ensure_ascii=False))

if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--theory',required=True);a.add_argument('--tutor',required=True);a.add_argument('--subject',required=True);a.add_argument('--version',required=True);a.add_argument('--title-ru',required=True);a.add_argument('--title-uz',required=True);a.add_argument('--title-en',required=True);a.add_argument('--out',required=True)
    x=a.parse_args();package(x.theory,x.tutor,x.subject,x.version,{'ru':x.title_ru,'uz':x.title_uz,'en':x.title_en},x.out)