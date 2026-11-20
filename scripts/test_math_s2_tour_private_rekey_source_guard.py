#!/usr/bin/env python3
"""Synthetic-only regression tests. No production keys, questions, identifiers, clients."""
import copy
import json
import pathlib
import random
import runpy
import unittest

guard = runpy.run_path(str(pathlib.Path(__file__).with_name(
    "math-s2-tour-private-rekey-source-guard.py")), run_name="_source_guard_test")
check = guard["validate"]
Hold = guard["BankHold"]


def make_fake():
    randomizer = random.Random(70711)
    rows = []
    for tour in range(1, 8):
        for attempt in range(10000):
            answers = list("AAAABBBBCCCCDDDD")
            randomizer.shuffle(answers)
            sequence = "".join(answers)
            if (not any(sequence[i:i+p] == sequence[i+p:i+2*p]
                        for p in (2, 3, 4) for i in range(17-2*p))
                    and not any(sequence[i] == sequence[i+1] == sequence[i+2]
                                for i in range(14))
                    and not any(sequence[i:i+4] in (
                        "ABCD","BCDA","CDAB","DABC","DCBA","CBAD","BADC","ADCB")
                        for i in range(13))):
                break
        else:
            raise AssertionError("synthetic test generator exhausted")
        for index, letter in enumerate(sequence):
            perm = [0,1,2,3]
            j = "ABCD".index(letter)
            perm[0],perm[j] = perm[j],perm[0]
            rows.append({
                "tour_no":tour,
                "old_question_id":990000+tour*100+index,
                "old_key":"A", "new_key":letter,
                "option_indices_new_to_old":perm,
                "replace_stem_source":"old_published_unmodified"
            })
    reps = []
    for tour,index in ((2,3),(4,5),(5,7)):
        old_id = 990000+tour*100+index
        row = next(r for r in rows if r["old_question_id"]==old_id)
        row["replace_stem_source"]="private_fresh_item"
        record={"replacement_for_question_id":old_id, "target_tour":tour,
                "correct_answer":row["new_key"],"new_is_active":False,
                "new_quality_status":"draft"}
        for lang in ("en","ru","uz"):
            record["question_text_"+lang]="Synthetic test question "+lang
            record["explanation_"+lang]="Synthetic test explanation "+lang
            record["options_text_"+lang]=[
                "invented_"+lang+"_"+str(x) for x in range(4)]
        reps.append(record)
    return {
        "classification":"CONFIDENTIAL_QUESTION_KEYS_AND_OPTION_ORDER_NOT_FOR_PUBLIC_GITHUB",
        "status":"PRIVATE_STAGING_ONLY_NOT_APPLIED_NO_OWNER_RELEASE_GO",
        "source_preflight_md5_by_tour":{str(t):"0"*32 for t in range(1,8)},
        "per_question_rekey":rows,"replacements_after_rekey":reps
    }


class TestMathS2Rekey(unittest.TestCase):
    def setUp(self):
        self.doc=make_fake()

    def test_valid_fixture(self):
        result=check(self.doc)
        self.assertEqual(result["mcq"],112)
        self.assertEqual(result["tours"],7)
        self.assertEqual(result["semantic_replacements"],3)
        self.assertFalse(result["release_authorized"])

    def test_duplicate_source(self):
        self.doc["per_question_rekey"][1]["old_question_id"]=self.doc["per_question_rekey"][0]["old_question_id"]
        with self.assertRaises(Hold): check(self.doc)

    def test_bad_localized_stem(self):
        self.doc["replacements_after_rekey"][0]["question_text_ru"]=""
        with self.assertRaises(Hold): check(self.doc)

    def test_wrong_semantic_option_index(self):
        row=self.doc["per_question_rekey"][0]
        row["option_indices_new_to_old"]=[0,1,2,3]
        row["old_key"]="D" if row["new_key"]!="D" else "C"
        with self.assertRaises(Hold): check(self.doc)

    def test_missing_source_pin(self):
        self.doc["source_preflight_md5_by_tour"].pop("7")
        with self.assertRaises(Hold): check(self.doc)

    def test_unbalanced_and_patterned_sequence(self):
        for i,row in enumerate(self.doc["per_question_rekey"][:16]):
            k="ABCD"[i%4]
            row["new_key"]=k
            perm=[0,1,2,3]
            perm[0],perm["ABCD".index(k)]=perm["ABCD".index(k)],perm[0]
            row["option_indices_new_to_old"]=perm
        with self.assertRaises(Hold): check(self.doc)

    def test_published_replacement_rejected(self):
        self.doc["replacements_after_rekey"][0]["new_quality_status"]="published"
        with self.assertRaises(Hold): check(self.doc)

    def test_cross_tour_replacement_rejected(self):
        self.doc["replacements_after_rekey"][0]["target_tour"]=7
        with self.assertRaises(Hold): check(self.doc)

    def test_mismatched_replacement_key(self):
        r=self.doc["replacements_after_rekey"][0]
        r["correct_answer"]="ABCD"[("ABCD".index(r["correct_answer"])+1)%4]
        with self.assertRaises(Hold): check(self.doc)


if __name__=="__main__":
    unittest.main()
