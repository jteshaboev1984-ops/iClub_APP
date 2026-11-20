#!/usr/bin/env python3
"""Private, source-only 112-MCQ Mathematics S2 Tour rekey validator.

Never print answer keys or question text. Never connect to Supabase.
Never create or edit a question, tour, answer, score or learner record.
Owner-provided private JSON must remain OUTSIDE the public GitHub repository.
"""
import argparse
import collections
import json
from pathlib import Path


class BankHold(ValueError):
    pass


def validate(doc):
    if doc.get("classification") != "CONFIDENTIAL_QUESTION_KEYS_AND_OPTION_ORDER_NOT_FOR_PUBLIC_GITHUB":
        raise BankHold("private_manifest_required")
    if doc.get("status") != "PRIVATE_STAGING_ONLY_NOT_APPLIED_NO_OWNER_RELEASE_GO":
        raise BankHold("release_state_not_hold")
    rows = doc.get("per_question_rekey")
    sources = doc.get("source_preflight_md5_by_tour")
    if not isinstance(rows, list) or len(rows) != 112:
        raise BankHold("expected_exactly_112_mcq")
    if not isinstance(sources, dict) or sorted(sources) != [str(t) for t in range(1, 8)]:
        raise BankHold("missing_seven_tour_source_pins")
    if any(not isinstance(h, str) or len(h) != 32 or
           any(c not in "0123456789abcdef" for c in h) for h in sources.values()):
        raise BankHold("invalid_tour_source_pin")
    by_tour = collections.defaultdict(list)
    ids = set()
    for q in rows:
        t, qid = q.get("tour_no"), q.get("old_question_id")
        if type(t) is not int or not 1 <= t <= 7 or type(qid) is not int or qid <= 0:
            raise BankHold("bad_tour_or_id")
        if qid in ids:
            raise BankHold("same_source_question_repeated")
        ids.add(qid)
        old, new = q.get("old_key"), q.get("new_key")
        perm = q.get("option_indices_new_to_old")
        if old not in ("A", "B", "C", "D") or new not in ("A", "B", "C", "D"):
            raise BankHold("bad_answer_key")
        if not isinstance(perm, list) or sorted(perm) != [0, 1, 2, 3] or perm[ord(new)-65] != ord(old)-65:
            raise BankHold("key_does_not_follow_reordered_semantic_option")
        if q.get("replace_stem_source") not in ("old_published_unmodified", "private_fresh_item"):
            raise BankHold("unexpected_question_source")
        by_tour[t].append(q)
    for t in range(1, 8):
        ordered = by_tour[t]
        if len(ordered) != 16:
            raise BankHold("tour_not_16_mcq")
        new = "".join(q["new_key"] for q in ordered)
        if any(new.count(letter) != 4 for letter in "ABCD"):
            raise BankHold("unbalanced_tour_mcq")
        if any(new[i] == new[i+1] == new[i+2] for i in range(14)):
            raise BankHold("overlong_letter_run")
        if any(new[i:i+p] == new[i+p:i+2*p]
               for p in (2, 3, 4) for i in range(17-2*p)):
            raise BankHold("repeated_short_period")
        if any(new[i:i+4] in ("ABCD", "BCDA", "CDAB", "DABC",
                              "DCBA", "CBAD", "BADC", "ADCB") for i in range(13)):
            raise BankHold("predictable_four_letter_cycle")
        if sum(q["old_key"] != q["new_key"] for q in ordered) < 11:
            raise BankHold("insufficient_answer_position_changes")
    replacements = doc.get("replacements_after_rekey")
    if not isinstance(replacements, list) or len(replacements) != 4:
        raise BankHold("requires_four_original_replacements")
    if sum(q["replace_stem_source"] == "private_fresh_item" for q in rows) != 4:
        raise BankHold("four_only_fresh_stems")
    rep_ids = set()
    for r in replacements:
        id_ = r.get("replacement_for_question_id")
        if id_ in rep_ids or id_ not in ids:
            raise BankHold("duplicate_or_unknown_replacement")
        rep_ids.add(id_)
        q = next(row for row in rows if row["old_question_id"] == id_)
        if q["replace_stem_source"] != "private_fresh_item" or q["tour_no"] != r.get("target_tour"):
            raise BankHold("replacement_not_linked_to_correct_tour")
        if q["new_key"] != r.get("correct_answer") or r.get("new_is_active") is not False or r.get("new_quality_status") != "draft":
            raise BankHold("replacement_key_or_draft_state_bad")
        for lang in ("en", "ru", "uz"):
            opts = r.get("options_text_"+lang)
            if not isinstance(opts, list) or len(opts) != 4 or len(set(opts)) != 4 or not all(isinstance(o, str) and o.strip() for o in opts):
                raise BankHold("missing_or_duplicate_localized_option")
            if not all(isinstance(r.get(field+"_"+lang), str) and r[field+"_"+lang].strip()
                       for field in ("question_text", "explanation")):
                raise BankHold("missing_localized_stem_or_explanation")
    return {"tours": 7, "mcq": 112, "semantic_replacements": 4,
            "moved_answer_positions": sum(q["old_key"] != q["new_key"] for q in rows),
            "source_records_modified": 0, "release_authorized": False}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--private-plan", required=True, type=Path)
    args = parser.parse_args()
    try:
        result = validate(json.loads(args.private_plan.read_text(encoding="utf-8")))
    except (BankHold, ValueError, TypeError, OSError, KeyError) as e:
        raise SystemExit("MATH_S2_PRIVATE_REKEY_HOLD: " + str(e))
    print("MATH_S2_PRIVATE_REKEY_SOURCE_CONTRACT_PASS:", result)
