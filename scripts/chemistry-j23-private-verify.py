#!/usr/bin/env python3
"""Verify exact PRIVATE Chemistry J23 v9 files, without publication or persistently writing SQL.

No network/DB calls; no lesson, answer or tutor plaintext appears in standard output.
Input source files MUST be supplied from protected storage outside this public repo.
Never commit their contents or generated SQL to GitHub.

Usage (only after authorised private source export):
    python scripts/chemistry-j23-private-verify.py \
        --theory /secure/path/v9_theory.json \
        --tutor /secure/path/v9_tutor.json

This script does not establish the origin of the files or constitute a backup/restore test.
"""
import argparse
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
PACKAGER = pathlib.Path(__file__).resolve().with_name("subject-release-packager.py")
EXPECTED_VERSION = "chemistry9701_j23_20261029_as_91_sixfield_candidate_v9"
EXPECTED = {
    "theory_sha256": "3389e6a77d0347ab34fcfb9ad01b50bfceaa916552f8da197dad7c856954d302",
    "tutor_sha256": "28e7dfe84e36136daed48635f44c32cb7a670d9243c9425785032f1ea9c2ed93",
    "package_sha256": "c17a1b193d4f713d44e77b9b1a1ce3e42427c2fdce7a99599b56dcb6da1f64eb",
}

def fail(message):
    raise SystemExit("PRIVATE J23 CHECK FAILED: " + message)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    args = argparse.ArgumentParser(description="Closed Chemistry v7 exact-byte packaging check")
    args.add_argument("--theory", required=True, type=pathlib.Path)
    args.add_argument("--tutor", required=True, type=pathlib.Path)
    parsed = args.parse_args()
    theory_file = parsed.theory.resolve(strict=True)
    tutor_file = parsed.tutor.resolve(strict=True)

    if theory_file.is_relative_to(REPO_ROOT) or tutor_file.is_relative_to(REPO_ROOT):
        fail("Protected sources must remain OUTSIDE public GitHub checkout")
    if theory_file == tutor_file or not theory_file.is_file() or not tutor_file.is_file():
        fail("Two distinct private source files are required")
    if not PACKAGER.is_file():
        fail("Repository's actual subject-release-packager.py is missing")

    tb = theory_file.read_bytes()
    ub = tutor_file.read_bytes()
    current = {
        "theory_sha256": digest(tb),
        "tutor_sha256": digest(ub),
        "package_sha256": digest(tb + b"\0" + ub),
    }
    if current != EXPECTED:
        fail("Exact source SHA-256 mismatch: wrong version, modified export or corrupted bytes")

    try:
        parsed_theory = json.loads(tb)
        parsed_tutor = json.loads(ub)
    except (UnicodeError, ValueError):
        fail("Protected input was not valid UTF-8 JSON")
    if len(parsed_theory.get("cards", [])) != 91 or len(parsed_tutor.get("data", [])) != 273:
        fail("Wrong Theory/Tutor cardinality")
    if parsed_tutor.get("source_theory_sha256") != current["theory_sha256"]:
        fail("Tutor references a different Theory export")

    # The real packager builds generated SQL into a PRIVATE temporary directory.
    # The directory is automatically removed on success OR error.
    with tempfile.TemporaryDirectory(prefix="iclub-j23-closed-", dir=None) as temp:
        dest = pathlib.Path(temp) / "package"
        cmd = [
            sys.executable, str(PACKAGER),
            "--theory", str(theory_file), "--tutor", str(tutor_file),
            "--subject", "chemistry",
            "--version", EXPECTED_VERSION,
            "--title-en", "Chemistry AS",
            "--title-ru", "Химия AS",
            "--title-uz", "Kimyo AS",
            "--out", str(dest),
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        except subprocess.TimeoutExpired:
            fail("Python packager timed out")
        if result.returncode != 0:
            # Don't expose arbitrary private source excerpts from traceback/error output.
            fail("Actual Python packager rejected protected v9 source inputs")
        try:
            manifest = json.loads((dest / "manifest.json").read_text(encoding="utf-8"))
        except (OSError, ValueError):
            fail("Packager did not create a valid manifest")
        for key, value in EXPECTED.items():
            if manifest.get(key) != value:
                fail("Generated manifest checksum did not match: " + key)
        if manifest.get("skills") != 91 or manifest.get("tutor_locales") != 273:
            fail("Generated package has unexpected record counts")
        if manifest.get("mode") != "STAGED_NOT_PUBLISHED":
            fail("Packager attempted a non-staged release mode")
        if not (dest / "99_postcheck_READ_ONLY.sql").is_file():
            fail("Missing required post-import read-only verification SQL")

    print(json.dumps({
        "passed": True,
        "source_version": EXPECTED_VERSION,
        "theory_cards": 91,
        "tutor_locales": 273,
        "package_sha256": EXPECTED["package_sha256"],
        "private_generated_sql_retained": False,
        "learner_release": False,
        "independent_external_backup_proven": False,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
