# iClub Question Diagnostic Change Protocol

Date: 2026-07-03
Status: governance protocol for diagnostic mapping and content fixes

## 1. Core rule

A question that already has user answers is not just content anymore. It is part of the app history.

Therefore, do not casually rewrite:

- question text;
- options;
- correct answer;
- explanations;
- time limit;
- difficulty;
- topic/subtopic.

Every change must first be classified by history impact.

## 2. Decision matrix

### Case A — options are valid, but diagnostics are missing

Action:

- keep the original question;
- add `question_answer_diagnostics` rows;
- do not recalculate old scores;
- do not rewrite options.

History policy:

- `future_only_no_retroactive_change`.

Example:

- wrong option shows a real misconception;
- selected answer can be mapped to weak skill and next action.

### Case B — wrong option is weak, but still unambiguously wrong

Action:

- do not rewrite the old question if it has user history;
- use existing option for broad diagnostic mapping;
- if stronger diagnostic distractors are needed, clone a new version for future use.

History policy:

- practice-only history: `future_only_no_retroactive_change`;
- tour history: `clone_for_future_keep_old_history`.

### Case C — input answer was conceptually correct but marked incorrect

Action:

- do not rewrite historical user answers;
- add future evaluator rules, such as numeric normalization, tolerance, or pattern matching;
- record as `historical_recalculation_candidate` only if there is clear evidence;
- do not recalculate rankings/certificates automatically.

History policy:

- `requires_architect_approval_before_recalc`.

Example:

- correct answer is `3`, user wrote `3 units Y`, and old exact checker marked it incorrect.

### Case D — correct answer is wrong or question is ambiguous

Action:

- mark the old question as not suitable for future active use;
- create a new `question_id` with corrected content;
- link old and new question through `question_version_links`;
- preserve historical attempts as they were;
- historical recalculation only after explicit approval and impact report.

History policy:

- `clone_for_future_keep_old_history`;
- possibly `requires_architect_approval_before_recalc`.

### Case E — typo / language issue without semantic change

Action:

- minor fix may be applied only if it does not change answer meaning;
- keep audit record;
- do not recalculate history.

History policy:

- `preserve_history_as_is`.

## 3. What not to do

Never do this on a question with history:

- silently change correct answer;
- silently rewrite an option so that old selected letters mean something else;
- delete old question rows;
- update old user answers manually;
- recalculate scores without an impact report;
- reuse the same `question_id` for a materially different question.

Changing option B from one meaning to another is dangerous because historical users who selected B selected the old B, not the new B.

## 4. Safe correction workflow

1. Select candidate questions.
2. Run answer distribution audit.
3. Check whether each wrong answer corresponds to a meaningful diagnostic interpretation.
4. Check history impact: practice only / tour / certificate / rating.
5. Classify decision:
   - `diagnostic_mapping_only`;
   - `future_evaluator_rule_only`;
   - `minor_text_fix_no_semantic_change`;
   - `retire_and_clone_new_version`;
   - `historical_recalculation_candidate`;
   - `manual_review_required`.
6. Store decision in `question_content_change_decisions`.
7. Apply only approved low-risk changes.
8. For high-risk changes, clone instead of rewriting.
9. Preserve old user history.

## 5. Tables/functions added

### `question_content_change_decisions`

Stores the decision and rationale before changing any question with history.

Key fields:

- `question_id`;
- `decision_type`;
- `risk_level`;
- `history_policy`;
- `rationale`;
- `proposed_change`;
- `evidence_snapshot`;
- `status`.

### `question_version_links`

Links old question IDs to replacement/new version question IDs.

Use it when a question is cloned instead of rewritten.

### `get_question_history_impact(bigint[])`

Internal helper to see:

- practice answer count;
- tour answer count;
- correct counts;
- existing decisions;
- whether the question has user history;
- recommended history policy.

## 6. First audit observations

Initial Economics candidates showed three different situations:

1. MCQ wrong options that are good diagnostic distractors.
   - Action: diagnostic mapping only.

2. MCQ weak distractor but scoring still valid.
   - Action: map broadly; clone only if future high-stakes use needs stronger distractors.

3. Input false-negative candidates.
   - Example: answer key `3`, user answers such as `3 units Y` were marked incorrect by exact input checking.
   - Action: future evaluator rule; historical recalculation only with explicit approval.

## Owner's 2026-11-20 Practice correction priority (scoped exception)

[Approved owner decision](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574#issuecomment-7039540376), registered in [Rules Inbox #570](https://github.com/jteshaboev1984-ops/iClub_APP/issues/570#issuecomment-7039548309), updates the older unconditional preservation guidance **for demonstrably wrong or ambiguous Practice questions**:

- **Do not keep a wrong question learner-facing just to preserve its answer history.** Fix the concrete issue, independently check its mathematical result, distractors, explanation, diagnostics, RU/UZ/EN, and release the verified correction promptly in small batches instead of waiting for an entire bank.
- The preferred route remains **retire the old version for future selection and activate a tested new version** (Case D), allowing issued sessions and previous results to remain valid wherever possible. Existing answers do **not** create a release block.
- Where the particular Practice correction genuinely requires removal of erroneous answer records, the owner has **expressly authorized deletion limited to answers tied to that specific wrong question**. Before applying it, identify only those answer rows, FK/dependency/parent-session consequences and existing aggregate statistics; use transactional guarded DML with recorded counts. Do not extrapolate to an all-learner Practice reset, user deletion, Tour answers, protected assessments, rankings, certificates or unaffected history.
- A fix is ready for publication when its specific answer contract, mathematics and multilingual source pass the applicable QA and publication is within the owner's approved scope. **Pending review of unrelated question revisions is not a reason to delay an independently complete confirmed correction.**
- No silent semantic rewrite of prior option letters on already-issued items; re-score/modify competitive results only under a separate explicit owner decision.

This rule is **Practice-specific** and later than the historical July 2026 default protocol. Other assessment types still follow their original protected-history procedures.

## 7. Final principle

For President Tech Award demo, use the diagnostic layer to prove intelligent feedback.

Do not risk the credibility of historical scores by silently editing old questions.

The safe product architecture is:

> old question history stays stable; future diagnostic quality improves through mapping, evaluator rules and cloned versions.
