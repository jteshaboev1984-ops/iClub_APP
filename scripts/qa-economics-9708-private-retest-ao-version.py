#!/usr/bin/env python3
"""Validate private Economics 9708 retest AO-only updates. Never prints item content or keys.

Provisional Cambridge AO categorisation is not independent examiner certification.
"""
import argparse
import collections
import hashlib
import json
from pathlib import Path

FIELDS=('release_enabled','ready_for_public_exam','ready_for_server_authorization')
LANGUAGES=('en','ru','uz')

def canonical_sha(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode('utf-8')).hexdigest()

def raw_sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def check(parent_path,new_path):
    assert parent_path.resolve()!=new_path.resolve(),'new and old files must be different'
    original=json.loads(parent_path.read_text(encoding='utf-8'))
    new=json.loads(new_path.read_text(encoding='utf-8'))
    assert len(original['items'])==len(new['items'])==71
    assert original['items_canonical_sha256']==canonical_sha(original['items'])
    assert new['items_canonical_sha256']==canonical_sha(new['items'])
    assert new['revision_v4']['parent_basename']==parent_path.name
    assert new['revision_v4']['parent_raw_sha256']==raw_sha(parent_path)
    assert new['revision_v4']['AO_labels_are_provisional'] is True
    assert new['academic_status']==original['academic_status']=='internal_authoring_first_pass_not_independent_examiner_approved'
    for k in FIELDS:assert original[k] is False and new[k] is False
    for key in ('source_files','papers','private_server_import_status','retest_authorization_status'):
        assert original[key]==new[key],f'protected {key} changed'
    assert new['private_server_import_status']=='not_imported'
    assert new['retest_authorization_status']=='hold'
    counts=collections.Counter()
    modified=0
    for prev,it in zip(original['items'],new['items']):
        assert prev['item_key']==it['item_key'] and prev['paper_code']==it['paper_code']
        assert prev['content_sha256']==canonical_sha({k:v for k,v in prev.items() if k!='content_sha256'})
        assert it['content_sha256']==canonical_sha({k:v for k,v in it.items() if k!='content_sha256'})
        assert it['ao'] in ('AO1','AO2','AO3'),'unreviewed/ambiguous AO label'
        assert it['release_enabled'] is False
        for lang in LANGUAGES:
            assert len(it[lang]['options'])==4 and len(set(it[lang]['options']))==4
            assert it[lang]==prev[lang],'question, options or explanation changed'
        for k in prev:
            if k in ('ao','content_sha256'):continue
            assert prev[k]==it[k],f'non-AO field changed: {k}'
        assert prev['correct_answer']==it['correct_answer']
        counts[(it['paper_code'],it['ao'])]+=1
        if prev['ao']!=it['ao']:modified+=1
    assert modified==new['revision_v4']['items_changed_AO_only']
    assert modified>=1
    assert sum(counts.values())==71
    return dict(counts),modified

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('parent',type=Path)
    p.add_argument('child',type=Path)
    args=p.parse_args()
    counts,changed=check(args.parent,args.child)
    print('PASS: 71 private originals; all keys/text/options/explanations intact; AO metadata-only changes:',changed)
    print('Provisional dominant AO counts:',str(counts))
    print('RELEASE OFF; NOT EXAMINER APPROVED')
