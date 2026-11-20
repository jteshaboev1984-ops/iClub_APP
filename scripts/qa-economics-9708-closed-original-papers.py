#!/usr/bin/env python3
"""Fail-closed structural, privacy and source-consistency QA of closed iClub Economics 9708 MCQ paper JSON.

Run inside a PRIVATE working folder holding the source JSON files. This tool prints only aggregate
checks; never prints stems, options, explanations or keys. It does NOT certify correctness,
linguistic equivalence or Cambridge AO classification and cannot approve content for release.
"""
import argparse
import collections
import csv
import hashlib
import json
import re
from pathlib import Path

AO_COUNTS={'AO1':14,'AO2':12,'AO3':4}
QUOTAS={'P1':{'1':4,'2':12,'3':3,'4':3,'5':3,'6':5},'P3':{'7':8,'8':7,'9':4,'10':3,'11':8}}
FIELDS=('item_key','syllabus_point','skill_key','ao','correct_answer','en','ru','uz')
LANGS=('en','ru','uz')


def sha(o):
    return hashlib.sha256(json.dumps(o,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode('utf8')).hexdigest()


def load(path):
    return json.loads(path.read_text(encoding='utf8'))


def normalize(s):
    return re.sub(r'[^\w]+',' ',s.casefold()).strip()


def load_canonical_skills(csv_path):
    """Read the trusted 498-row canonical skill audit from this repository, never private answer data."""
    required={'internal_skill_key','official_point','level','direct_papers'}
    with csv_path.open(encoding='utf-8-sig',newline='') as f:
        reader=csv.DictReader(f)
        assert reader.fieldnames and required.issubset(set(reader.fieldnames)), 'canonical CSV missing required columns'
        result={}
        for row in reader:
            key=(row.get('internal_skill_key') or '').strip()
            assert key and key not in result, 'blank or duplicate canonical skill key'
            assert re.fullmatch(r'ECON-9708-\d+\.\d+\.\d+-(?:BASE|\d+)',key), 'invalid canonical skill key'
            assert row['official_point'] and row['level'] in ('AS','A'), 'invalid canonical row'
            result[key]={'point':row['official_point'],'level':row['level'],'papers':row['direct_papers'].split(';')}
    assert len(result)==498,f'Expected signed-off 498-row canonical economics matrix, got {len(result)}'
    return result


def check_canonical(it, paper_code, canonical):
    mapped=canonical.get(it['skill_key'])
    assert mapped is not None,'item references noncanonical skill key'
    assert mapped['point']==it['syllabus_point'],'canonical official point mismatch'
    assert paper_code in mapped['papers'],'skill is not a direct skill for this paper'
    assert mapped['level']==('AS' if paper_code=='P1' else 'A'),'paper level / canonical skill mismatch'

def check(root,paper,canonical,expected=None):
    obj=load(paper)
    paper_code=obj.get('paper_code')
    assert paper_code in QUOTAS,'unexpected paper'
    if expected:assert paper_code==expected,'wrong paper code'
    assert obj['state']=='PRIVATE_DRAFT_NOT_SERVABLE'
    assert obj['release_enabled'] is False
    for f in ('ready_for_server_authorization','ready_for_public_exam','examiner_signoff','semantic_unseen_proven'):
        assert obj.get(f) is False,(f,'must be False')
    assert obj.get('student_attempts_unmodified') is True
    assert obj['selected_item_count']==30 and len(obj['items'])==30
    assert obj['candidate_item_count']>=30
    assert obj['paper_quotas']==QUOTAS[paper_code]
    assert obj['target_AO']==AO_COUNTS
    assert obj['selected_ordered_item_hash_sha256']==sha(obj['items']),'paper item hash mismatch'
    assert len(set(i['item_key'] for i in obj['items']))==30,'duplicate item key'
    assert len(set(i['skill_key'] for i in obj['items']))==30,'duplicate primary skill'
    assert all(isinstance(v,str) and re.fullmatch(r'[0-9a-f]{64}',v) for v in obj['source_closed_file_sha256'].values())
    referenced_sources={i['source_closed_library_basename'] for i in obj['items']}
    assert set(obj['source_closed_file_sha256'])==referenced_sources, 'source dependency manifest must exactly equal used sources'
    cache={}
    for basename,digest in obj['source_closed_file_sha256'].items():
        # For path security, do not open nested locations or accept parent traversal from untrusted JSON.
        assert Path(basename).name==basename and not basename.startswith('.'),'invalid source basename'
        path=root/basename
        assert path.exists(),f'missing source: {basename}'
        assert hashlib.sha256(path.read_bytes()).hexdigest()==digest,f'source file mutated: {basename}'
        source=load(path)
        cache[basename]={i['item_key']:i for i in source.get('items',[])}
    unit=collections.Counter()
    ao=collections.Counter()
    stems={l:set() for l in LANGS}
    sources_used=collections.Counter()
    for it in obj['items']:
        assert it.get('release_enabled') is False
        assert it.get('correct_answer') in ('A','B','C','D')
        assert re.fullmatch(r'\d+\.\d+\.\d+',it['syllabus_point'])
        assert it['skill_key'].startswith('ECON-9708-'+it['syllabus_point']+'-')
        check_canonical(it,paper_code,canonical)
        assert it.get('exam_item_content_sha256')==sha({k:it[k] for k in FIELDS}),'item content hash mismatch'
        assert it['ao'][:3] in AO_COUNTS,'invalid provisional AO'
        unit[it['syllabus_point'].split('.')[0]]+=1
        ao[it['ao'][:3]]+=1
        basename=it['source_closed_library_basename']
        assert basename in cache and it['item_key'] in cache[basename],'unverifiable source lineage'
        source=cache[basename][it['item_key']]
        for k in FIELDS:
            assert source[k]==it[k],f'content drift from source in {it["item_key"]} / {k}'
        sources_used[basename]+=1
        for lg in LANGS:
            trans=it[lg]
            assert isinstance(trans['question'],str) and len(trans['question'])>15
            assert isinstance(trans['explanation'],str) and len(trans['explanation'])>30
            assert len(trans['options'])==4 and len(set(trans['options']))==4
            normalized=normalize(trans['question'])
            assert normalized not in stems[lg],f'duplicate {lg} stem'
            stems[lg].add(normalized)
    assert dict(unit)==QUOTAS[paper_code],f'unit quotas wrong {dict(unit)}'
    assert dict(ao)==AO_COUNTS,f'AO approximate blueprint target changed {dict(ao)}'
    return {'paper':paper_code,'count':len(obj['items']),'sources_verified':len(cache),'sources_selected':len(sources_used),'canonical_primary_skills_unique':30,'unit_quotas_pass':True,'AO_metadata_quota_pass':True,'key_isolation_flag_pass':True,'content_integrity_pass':True,'academic_examiner_signoff':False}


def check_private_answer_manifest(root, paper_file, manifest, label):
    """Optional private independent-answer-lock check. Never print correct letters or questions."""
    assert manifest.get('contract')=='iclub_econ_9708_private_firstpass_answer_key_challenge_v1'
    assert manifest.get('release_enabled') is False
    assert manifest.get('status')=='FIRST_PASS_ASSISTANT_REVIEW_NOT_EXAMINER_APPROVED'
    record=manifest['reviewed_papers'][label]
    assert record['source_basename']==paper_file.name, 'review manifest paper mismatch'
    assert record['source_sha256']==hashlib.sha256(paper_file.read_bytes()).hexdigest(), 'review manifest source integrity mismatch'
    obj=load(paper_file)
    assert len(record['entries'])==30 and set(record['entries'])=={x['item_key'] for x in obj['items']}
    for it in obj['items']:
        rec=record['entries'][it['item_key']]
        assert rec['expected_correct_answer']==it['correct_answer'], 'independently reviewed key mismatch'
        assert rec['syllabus_point']==it['syllabus_point'], 'reviewed syllabus point mismatch'
        idx='ABCD'.index(rec['expected_correct_answer'])
        for lg in LANGS:
            test=sha({'question':it[lg]['question'],'correct_option':it[lg]['options'][idx]})
            assert test==rec['expected_correct_option_fingerprint_by_locale'][lg], 'reviewed option meaning drift'
    return True


def main():
    p=argparse.ArgumentParser()
    p.add_argument('p1',type=Path)
    p.add_argument('p3',type=Path)
    p.add_argument('--private-answer-review',type=Path,required=True,help='REQUIRED private first-pass answer manifest; never commit the manifest')
    p.add_argument('--canonical-skills-csv',type=Path,required=True,help='REQUIRED trusted 498-skill master CSV in GitHub audit branch')
    args=p.parse_args()
    assert args.p1.parent.resolve()==args.p3.parent.resolve(),'both files must be in same private source folder'
    root=args.p1.parent
    canonical=load_canonical_skills(args.canonical_skills_csv)
    a=check(root,args.p1,canonical,'P1');b=check(root,args.p3,canonical,'P3')
    k1=load(args.p1);k3=load(args.p3)
    m=load(args.private_answer_review)
    assert check_private_answer_manifest(root,args.p1,m,'P1')
    assert check_private_answer_manifest(root,args.p3,m,'P3')
    assert not set(i['item_key'] for i in k1['items']).intersection(i['item_key'] for i in k3['items']),'cross paper item-key overlap'
    assert not set(i['skill_key'] for i in k1['items']).intersection(i['skill_key'] for i in k3['items']),'cross paper skill collision'
    print('PASS closed-candidate technical integrity; verified canonical 498 skills;'+' exact-source dependency set; first-pass key manifest consistent;'+' no release approval or examiner certification.')
    for out in [a,b]:print(json.dumps(out,ensure_ascii=False,sort_keys=True))

if __name__=='__main__':main()
