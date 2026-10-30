#!/usr/bin/env python3
"""Fail-closed private 9708 71-retest bank replacement gate, no public answers.

Checks version lineage, source bank, canonical mapping, exactly 8 replacements,
unchanged 63 items, trilingual answer options and release flags. NOT examiner signoff.
"""
import argparse,collections,csv,hashlib,json,re
from pathlib import Path
LANGS=('en','ru','uz'); STATUS=('release_enabled','ready_for_public_exam','ready_for_server_authorization')
def sha(o):return hashlib.sha256(json.dumps(o,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()
def raw(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def canon(p):
    with p.open(encoding='utf-8-sig',newline='') as f: rows=list(csv.DictReader(f))
    assert len(rows)==498
    r={}
    for q in rows:
        key=q['internal_skill_key'];assert key not in r and re.fullmatch(r'ECON-9708-\d+\.\d+\.\d+-(?:BASE|\d+)',key)
        r[key]=(q['official_point'],q['level'],q['direct_papers'].split(';'))
    return r

def check(previous,updated,alternatives,canon_path):
    old=load(previous);new=load(updated);seed=load(alternatives);skills=canon(canon_path)
    assert all(len(q['items'])==n for q,n in ((old,71),(new,71),(seed,8)))
    assert len({q['skill_key'] for q in new['items']})==71
    assert len({q['item_key'] for q in new['items']})==71
    assert len({q['item_key'] for q in seed['items']})==8
    assert all(v is False for d in (old,new,seed) for k in STATUS if (v:=d.get(k)) is not None)
    assert new['private_server_import_status']=='not_imported' and new['retest_authorization_status']=='hold'
    assert new['academic_status']==old['academic_status']=='internal_authoring_first_pass_not_independent_examiner_approved'
    assert new['papers']==old['papers']=={'P1':35,'P3':36}
    assert old['items_canonical_sha256']==sha(old['items'])
    assert new['items_canonical_sha256']==sha(new['items'])
    assert seed['items_canonical_sha256']==sha(seed['items'])
    rev=new['revision_v7']
    assert rev['parent_basename']==previous.name and rev['parent_sha256']==raw(previous)
    assert rev['new_items_source']==alternatives.name and rev['new_items_sha256']==raw(alternatives)
    assert rev['replaced']==8 and rev['preserved_unchanged']==63
    assert len(new['source_files'])==len(old['source_files'])+1
    assert new['source_files'][:len(old['source_files'])]==old['source_files']
    assert new['source_files'][-1]['name']==alternatives.name
    assert new['source_files'][-1]['sha256']==raw(alternatives)
    candidate={(q['paper_code'],q['skill_key']):q for q in seed['items']}
    assert len(candidate)==8
    replaced=0
    keys=collections.Counter();aos=collections.Counter()
    for prev,item in zip(old['items'],new['items']):
        assert (prev['paper_code'],prev['skill_key'],prev['syllabus_point'])==(item['paper_code'],item['skill_key'],item['syllabus_point'])
        old_key=(prev['paper_code'],prev['skill_key']);isnew=old_key in candidate
        if isnew:
            assert item==candidate[old_key] and item['item_key']!=prev['item_key']
            assert item['ao']=='AO3' and item.get('release_enabled') is False
            assert item['academic_status']=='internal_draft_awaiting_independent_release_review'
            replaced+=1
        else:assert prev==item,'unauthorised mutation of an unchanged item'
        assert item['content_sha256']==sha({k:v for k,v in item.items() if k!='content_sha256'})
        assert item['correct_answer'] in 'ABCD'
        assert set(item['distractor_notes_en'])==set('ABCD')-{item['correct_answer']}
        assert item['skill_key'] in skills
        point,level,papers=skills[item['skill_key']]
        assert item['syllabus_point']==point
        assert item['paper_code'] in papers and level==('AS' if item['paper_code']=='P1' else 'A')
        for lang in LANGS:
            x=item[lang];assert len(x['options'])==4 and len(set(x['options']))==4
            assert len(x['question'])>30 and len(x['explanation'])>50
        if isnew:
            opts=item['en']['options'];correct='ABCD'.index(item['correct_answer'])
            assert len(opts[correct])<max(map(len,opts)),'correct answer is conspicuously longest'
        keys[item['paper_code']]+=1;aos[(item['paper_code'],item['ao'])]+=1
    assert replaced==8 and keys=={'P1':35,'P3':36}
    assert aos[('P1','AO3')]==4 and aos[('P3','AO3')]==5
    return replaced,keys,aos

if __name__=='__main__':
 p=argparse.ArgumentParser()
 p.add_argument('parent',type=Path);p.add_argument('new',type=Path);p.add_argument('eight_new',type=Path)
 p.add_argument('--canonical-csv',type=Path,required=True)
 args=p.parse_args();rep,keys,aos=check(args.parent,args.new,args.eight_new,args.canonical_csv)
 print('PASS: private 71 retest questions, 8 source-bound genuine AO3 draft replacements, 63 unchanged, no release')
 print('Validated primary canonical skills: 71; official matrix: 498; answer positions redacted; academic examiner signoff absent')
 print('Provisional AO composition:',dict(aos))
