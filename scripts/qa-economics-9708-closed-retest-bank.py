#!/usr/bin/env python3
"""Private versioned provenance and answer-position gate for iClub Economics 9708 retest MCQs.

This verifies file integrity and exact preservation of old meaning under answer-position
permutations. It does NOT certify economic or linguistic correctness, source provenance,
psychometric quality, or authorization for publication. Never print answer keys.
"""
import argparse
import collections
import csv
import hashlib
import json
import re
from pathlib import Path

TOTAL = 71
LANGS = ('en', 'ru', 'uz')
REVISED_KEY = 'EC9708-P3-RETEST-ORIG-20261029-004'
ALLOWED_FLAGS = ('release_enabled','ready_for_public_exam','ready_for_server_authorization')


def sha(value):
    return hashlib.sha256(json.dumps(value,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode()).hexdigest()


def raw_sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text(encoding='utf8'))


def canonical(path):
    required = {'official_point','internal_skill_key','level','direct_papers'}
    with path.open(encoding='utf-8-sig',newline='') as file:
        data = csv.DictReader(file)
        assert set(data.fieldnames or []).issuperset(required), 'invalid canonical CSV fields'
        rows = list(data)
    result = {}
    for entry in rows:
        key=entry['internal_skill_key']
        assert key and key not in result
        assert re.fullmatch(r'ECON-9708-\d+\.\d+\.\d+-(?:BASE|\d+)',key)
        result[key] = (entry['official_point'],entry['level'],set(entry['direct_papers'].split(';')))
    assert len(result)==498, 'canonical taxonomy is not the verified 498-skill version'
    return result


def is_cyclic(letters):
    return any(letters[i:i+4]==letters[i+4:i+8] for i in range(len(letters)-7))


def check(parent_path,candidate_path,canonical_path):
    assert parent_path.resolve()!=candidate_path.resolve(), 'source must never be overwritten'
    parent = load(parent_path)
    candidate = load(candidate_path)
    skills = canonical(canonical_path)
    assert len(parent['items'])==len(candidate['items'])==TOTAL
    assert parent['items_canonical_sha256']==sha(parent['items']), 'parent integrity mismatch'
    assert candidate['items_canonical_sha256']==sha(candidate['items']), 'candidate integrity mismatch'
    assert candidate.get('revision_v3',{}).get('parent_raw_sha256')==raw_sha(parent_path), 'parent SHA mismatch'
    assert candidate['revision_v3']['parent_basename']==parent_path.name, 'parent basename mismatch'
    assert candidate['revision_v3']['semantic_revised_item_key']==REVISED_KEY, 'wrong semantic revision target'
    assert candidate['revision_v3']['semantic_revision_point']=='9.4.6'
    assert candidate['academic_status']=='internal_authoring_first_pass_not_independent_examiner_approved'
    assert candidate['private_server_import_status']=='not_imported'
    assert candidate['retest_authorization_status']=='hold'
    for f in ALLOWED_FLAGS:
        assert parent.get(f) is False and candidate.get(f) is False,'publication flag enabled'
    assert candidate['papers']=={'P1':35,'P3':36}
    assert [q['item_key'] for q in parent['items']]==[q['item_key'] for q in candidate['items']], 'items reordered or changed'
    assert len(set(q['skill_key'] for q in candidate['items']))==TOTAL, 'duplicate primary skill'
    assert len(set(q['item_key'] for q in candidate['items']))==TOTAL, 'duplicate original item key'
    assert candidate['source_files']==parent['source_files'], 'authorship provenance changed'

    letters=''.join(q['correct_answer'] for q in candidate['items'])
    distribution=collections.Counter(letters)
    assert distribution==collections.Counter({'A':18,'B':18,'C':18,'D':17}), 'imbalanced answer positions'
    assert not is_cyclic(letters), 'predictable repeated A-B-C-D sequence'
    assert not any(len(set(letters[i:i+4]))==1 for i in range(len(letters)-3)),'long identical-key run'

    for before,after in zip(parent['items'],candidate['items']):
        assert before['item_key']==after['item_key']
        assert after['content_sha256']==sha({k:v for k,v in after.items() if k!='content_sha256'}), 'corrupted content hash'
        assert before['content_sha256']==sha({k:v for k,v in before.items() if k!='content_sha256'}), 'corrupted source item'
        for k in before:
            if k in (*LANGS,'correct_answer','distractor_notes_en','content_sha256'):continue
            assert before[k]==after[k], 'item identity or metadata drift'
        key=after['skill_key']
        assert key in skills and skills[key][0]==after['syllabus_point'],'noncanonical item skill/point'
        assert after['paper_code'] in skills[key][2], 'wrong paper for canonical skill'
        assert skills[key][1]==('AS' if after['paper_code']=='P1' else 'A'),'wrong level'
        assert after['release_enabled'] is False
        assert after['academic_status']==before['academic_status']
        assert after['academic_status'] in ('internal_draft_awaiting_independent_release_review','internal_first_pass_draft_pending_technical_semantic_and_release_review')
        assert len(after['distractor_notes_en'])==3 and after['correct_answer'] not in after['distractor_notes_en']
        assert set(after['distractor_notes_en'])==set('ABCD')-{after['correct_answer']}
        old_correct='ABCD'.index(before['correct_answer'])
        new_correct='ABCD'.index(after['correct_answer'])
        for lang in LANGS:
            orig=before[lang];now=after[lang]
            assert set(now)==set(orig), 'locale schema changed'
            assert len(now['options'])==len(orig['options'])==4 and len(set(now['options']))==4
            assert len(now['question'])>30 and len(now['explanation'])>40
            if before['item_key']!=REVISED_KEY:
                assert orig['question']==now['question'] and orig['explanation']==now['explanation'], 'unexpected question/explanation change'
            assert sorted(orig['options'])==sorted(now['options']) if before['item_key']!=REVISED_KEY else True, 'unexpected option rewrite'
            if before['item_key']!=REVISED_KEY:
                assert orig['options'][old_correct]==now['options'][new_correct], 'correct-answer meaning changed under permutation'
                reverse={k:orig['options'].index(o) for k,o in enumerate(now['options'])}
                for new_idx,old_idx in reverse.items():
                    old_letter='ABCD'[old_idx];new_letter='ABCD'[new_idx]
                    assert (old_letter in before['distractor_notes_en']) == (new_letter in after['distractor_notes_en']), 'distractor note moved to incorrect option'
                    if old_letter in before['distractor_notes_en']:
                        assert before['distractor_notes_en'][old_letter] == after['distractor_notes_en'][new_letter], 'wrong distractor note mapping'
        if before['item_key']==REVISED_KEY:
            assert after['syllabus_point']=='9.4.6' and after['skill_key']=='ECON-9708-9.4.6-BASE'
            # Semantic equivalence of the revision's three languages still needs academic review.
            assert all('port' in after[lang]['question'].casefold() or 'порт' in after[lang]['question'].casefold() for lang in LANGS),'semantic revision not present in a locale'
    return {'questions':TOTAL,'paper1':35,'paper3':36,'new_correct_positions':dict(distribution),'canonical':498,'academic_examiner_approved':False,'released':False}


def main():
    p=argparse.ArgumentParser()
    p.add_argument('parent',type=Path)
    p.add_argument('candidate',type=Path)
    p.add_argument('--canonical-csv',type=Path,required=True)
    args=p.parse_args()
    stats=check(args.parent,args.candidate,args.canonical_csv)
    print('PASS: private 71 retest questions, exact source/permutation/canonical-skill invariants; production release remains false')
    print('P1:',stats['paper1'],'P3:',stats['paper3'],'canonical:',stats['canonical'])
    print('Academic examiner approved:',stats['academic_examiner_approved'])

if __name__=='__main__':main()
