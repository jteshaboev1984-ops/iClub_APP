#!/usr/bin/env python3
"""Synthetic-only regression for the REAL subject-release-packager.py.
No private J23 records, answers or production connections."""
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
import unittest

PACKAGER=pathlib.Path(__file__).with_name("subject-release-packager.py")
FIELDS=("title","explanation","original_example","common_trap","check_question","check_answer")
TUTOR=("title","main_explanation","simple_explanation","alternative_explanation","focus_explanation")

def dump(obj):
    return json.dumps(obj,ensure_ascii=False,separators=(",",":")).encode()

def sha(data):
    return hashlib.sha256(data).hexdigest()

def fixture():
    key="TEST-CHEM-ONLY"
    locs={lang:{field:f"{lang} fictional {field} text" for field in FIELDS} for lang in ("en","ru","uz")}
    digest="sha256:"+sha(json.dumps({"skill_key":key,"locales":locs},ensure_ascii=False,sort_keys=True,separators=(",",":")).encode())
    theory={"syllabus":"SYNTHETIC TEST ONLY","cards":[{"skill_key":key,"tour_no":1,"official_syllabus_point":"TEST.1","content_hash":digest,"locales":locs}]}
    tutor={"data":[{"subject_key":"chemistry","skill_key":key,"locale":lang,"tutor_card_key":"synthetic-"+lang,"content_version":"synthetic_v1","source_card_hash":digest,**{field:(locs[lang]["title"] if field=="title" else f"{lang} synthetic {field}") for field in TUTOR}} for lang in ("en","ru","uz")]}
    return theory,tutor

class Contract(unittest.TestCase):
    def check(self,mutate=None,expect=None):
        theory,tutor=fixture()
        if mutate:mutate(theory,tutor)
        with tempfile.TemporaryDirectory() as d:
            root=pathlib.Path(d)
            tbytes=dump(theory)
            tutor.setdefault("source_theory_sha256",sha(tbytes))
            ubytes=dump(tutor)
            (root/"theory.json").write_bytes(tbytes)
            (root/"tutor.json").write_bytes(ubytes)
            args=[sys.executable,str(PACKAGER),"--theory",str(root/"theory.json"),"--tutor",str(root/"tutor.json"),"--subject","chemistry","--version","synthetic_v1","--title-ru","TEST RU","--title-en","TEST EN","--title-uz","TEST UZ","--out",str(root/"out")]
            p=subprocess.run(args,text=True,capture_output=True)
            if expect:
                self.assertNotEqual(p.returncode,0)
                self.assertIn(expect,p.stderr+p.stdout)
                return
            self.assertEqual(p.returncode,0,p.stderr)
            manifest=json.loads((root/"out"/"manifest.json").read_text())
            self.assertEqual((manifest["skills"],manifest["tutor_locales"]),(1,3))
            self.assertEqual(manifest["mode"],"STAGED_NOT_PUBLISHED")
            self.assertEqual(manifest["theory_sha256"],sha(tbytes))
            self.assertEqual(manifest["tutor_sha256"],sha(ubytes))
            self.assertEqual(manifest["package_sha256"],sha(tbytes+bytes([0])+ubytes))
            self.assertTrue((root/"out"/"99_postcheck_READ_ONLY.sql").exists())
            check_sql=(root/"out"/"99_postcheck_READ_ONLY.sql").read_text()
            self.assertIn("stage_matches_exact_source",check_sql)
            self.assertIn("theory_missing_or_changed",check_sql)
            self.assertIn("tutor_missing_or_changed",check_sql)
            self.assertIn("t.locales->\'ru\'->>\'explanation\'",check_sql)
            self.assertIn("u.focus_explanation",check_sql)
            self.assertIn("chr(31)",check_sql)
            self.assertNotIn("fictional explanation text",check_sql)
    def test_success(self):self.check()
    def test_bad_card_hash(self):self.check(lambda t,u:t["cards"][0]["locales"]["ru"].update(check_answer="modified"),"Canonical Theory hash mismatch")
    def test_missing_locale(self):self.check(lambda t,u:t["cards"][0]["locales"].pop("uz"),"Theory locale set mismatch")
    def test_empty_answer(self):self.check(lambda t,u:t["cards"][0]["locales"]["en"].update(check_answer=""),"Empty Theory field")
    def test_tutor_hash_mismatch(self):self.check(lambda t,u:u["data"][0].update(source_card_hash="bad"),"Tutor source hash mismatch")
    def test_wrong_parent_digest(self):self.check(lambda t,u:u.update(source_theory_sha256="bad"),"Tutor points to different Theory source bytes")
    def test_wrong_tutor_version(self):self.check(lambda t,u:u["data"][0].update(content_version="older"),"Tutor content version mismatch")
    def test_wrong_tutor_title(self):self.check(lambda t,u:u["data"][0].update(title="Mismatch"),"Tutor title disagrees with Theory")
    def test_empty_tutor_key(self):self.check(lambda t,u:u["data"][0].update(tutor_card_key=""),"Empty Tutor card key")
    def test_reserved_fingerprint_separator(self):
        def bad(t,u):
            c=t["cards"][0]
            c["locales"]["ru"]["explanation"]+="\\u001f"
            c["content_hash"]="sha256:"+sha(json.dumps({"skill_key":c["skill_key"],"locales":c["locales"]},ensure_ascii=False,sort_keys=True,separators=(",",":")).encode())
            for row in u["data"]:row["source_card_hash"]=c["content_hash"]
        self.check(bad,"Reserved control character")

if __name__=="__main__":unittest.main()
