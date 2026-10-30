#!/usr/bin/env python3
"""Private fail-closed QA for a 71-item retest v8 with 13 targeted AO2 revisions.

This checks source integrity, version lineage, canonical skill and paper membership,
trilingual structure and locked release flags. It never prints answer keys, stems,
or per-item digests. Passing is NOT independent academic-examiner approval.
"""
import argparse
import collections
import copy
import csv
import hashlib
import json
import re
from pathlib import Path

LANGUAGES=('en','ru','uz')
RELEASE_FLAGS=('release_enabled','ready_for_public_exam','ready_for_server_authorization')
EXAMINER_STATUS='internal_authoring_first_pass_not_independent_examiner_approved'

def digest(obj):
    return hashlib.sha256(json.dumps(obj,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode('utf-8')).hexdigest()

def file_sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path):return json.loads(path.read_text(encoding='utf-8'))

def canonical_map(path):
    with path.open(encoding='utf-8-sig',newline='') as h:rows=list(csv.DictReader(h))
    assert len(rows)==498,'must validate against complete 498-skill canonical matrix'
    result={}
    for entry in rows:
        skill=entry['internal_skill_key']
        assert skill and skill not in result and re.fullmatch(r'ECON-9708-\d+\.\d+\.\d+-(BASE|\d+)',skill)
        result[skill]=entry
    return result

def check(old_path,new_path,seed_path,canonical_path):
    parent=read(old_path);new=read(new_path);seed=read(seed_path)
    matrix=canonical_map(canonical_path)
    assert len(parent['items'])==len(new['items'])==71 and len(seed['items'])==13
    assert parent['items_canonical_sha256']==digest(parent['items'])
    assert new['items_canonical_sha256']==digest(new['items'])
    assert seed['items_canonical_sha256']==digest(seed['items'])
    assert new['revision_v8']['parent_basename']==old_path.name
    assert new['revision_v8']['parent_sha256']==file_sha(old_path)
    assert new['revision_v8']['new_items_source']==seed_path.name
    assert new['revision_v8']['new_items_sha256']==file_sha(seed_path)
    assert new['revision_v8']['replaced']==13 and new['revision_v8']['preserved_unchanged']==58
    assert new['revision_v8']['AO_labels_are_provisional'] is True
    assert parent['candidate_version']!=new['candidate_version']
    assert parent['academic_status']==new['academic_status']==EXAMINER_STATUS
    assert parent['private_server_import_status']==new['private_server_import_status']=='not_imported'
    assert parent['retest_authorization_status']==new['retest_authorization_status']=='hold'
    assert parent['papers']==new['papers']=={'P1':35,'P3':36}
    assert len(new['source_files'])==len(parent['source_files'])+1
    assert new['source_files'][:-1]==parent['source_files']
    assert new['source_files'][-1]['name']==seed_path.name
    assert new['source_files'][-1]['sha256']==file_sha(seed_path)
    assert new['source_files'][-1]['count']==13
    for obj in (parent,new,seed):
        for flag in RELEASE_FLAGS:assert obj.get(flag) is False,'release remains false'
    original_keys={a['item_key'] for a in parent['items']}
    original_skill={(a['paper_code'],a['skill_key']) for a in parent['items']}
    assert len(original_keys)==len(original_skill)==71
    by_seed={(x['paper_code'],x['skill_key']):x for x in seed['items']}
    assert len(by_seed)==13
    assert not {x['item_key'] for x in seed['items']} & original_keys
    changed=0
    cnt=collections.Counter();key_positions=collections.Counter()
    for old,new_item in zip(parent['items'],new['items']):
        match=(old['paper_code'],old['skill_key'])
        assert (old['paper_code'],old['skill_key'],old['syllabus_point'])==(new_item['paper_code'],new_item['skill_key'],new_item['syllabus_point'])
        if match in by_seed:
            assert new_item==by_seed[match],'replacement differs from reviewed source'
            assert new_item['item_key']!=old['item_key']
            assert old['ao']=='AO1' and new_item['ao']=='AO2'
            assert new_item['academic_status']=='internal_draft_awaiting_independent_release_review'
            assert new_item.get('release_enabled') is False
            changed+=1
        else:assert new_item==old,'unexpected modification to preserved question'
        assert new_item['content_sha256']==digest({k:v for k,v in new_item.items() if k!='content_sha256'})
        assert new_item['correct_answer'] in 'ABCD'
        assert set(new_item['distractor_notes_en'])==set('ABCD')-{new_item['correct_answer']}
        info=matrix.get(new_item['skill_key'])
        assert info is not None,'noncanonical skill'
        assert info['official_point']==new_item['syllabus_point']
        assert info['level']==('AS' if new_item['paper_code']=='P1' else 'A')
        assert new_item['paper_code'] in info['direct_papers'].split(';')
        for l in LANGUAGES:
            entry=new_item[l]
            assert isinstance(entry['question'],str) and len(entry['question'])>38
            assert isinstance(entry['explanation'],str) and len(entry['explanation'])>40
            assert len(entry['options'])==4 and all(isinstance(v,str) and len(v.strip())>0 for v in entry['options'])
            if match in by_seed:assert all(len(v)>18 for v in entry['options'])
            assert len(set(entry['options']))==4
        if match in by_seed:
            correct_i='ABCD'.index(new_item['correct_answer'])
            assert len(new_item['en']['options'][correct_i])<max(map(len,new_item['en']['options'])),'answer-length cue'
        cnt[(new_item['paper_code'],new_item['ao'])]+=1
        key_positions[(new_item['paper_code'],new_item['correct_answer'])]+=1
    assert changed==13
    assert len(set(x['item_key'] for x in new['items']))==71
    assert cnt=={('P1','AO1'):17,('P1','AO2'):14,('P1','AO3'):4,('P3','AO1'):17,('P3','AO2'):14,('P3','AO3'):5}
    assert all(6 <=key_positions[(p,a)]<=11 for p in ('P1','P3') for a in 'ABCD')
    return changed, cnt

if __name__=='__main__':
    pa=argparse.ArgumentParser()
    pa.add_argument('parent',type=Path)
    pa.add_argument('candidate',type=Path)
    pa.add_argument('new_13',type=Path)
    pa.add_argument('--canonical-csv',required=True,type=Path)
    z=pa.parse_args();changed,counts=check(z.parent,z.candidate,z.new_13,z.canonical_csv)
    print('PASS: 71 closed retest items; 13 AO2 revisions, 58 immutable preserved; all 498 skills present')
    print('Release OFF, keys withheld; AO tags provisional, independent academic/locale signoff still required')
    print('AO split:',dict(counts))
