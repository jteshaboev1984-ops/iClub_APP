# Exam Prep repeat-content recovery — academic release gate (20 Sep 2026)

**STATUS: unresolved release blocker; design and audit only.** This document is not permission to publish questions, change grades, alter correction thresholds, install SQL, enroll learners or deploy PR #121. Related #112, #113, #124.

## Verified live facts, SELECT only on 20 Sep

- Mathematics canonical map: 45 P1 skills and 36 P5 skills. All 81 have exactly one published learning assessment and none has a second vetted, published learning assessment.
- One P1 learner has ten finalized learning sessions across two distinct assessments: nine for P1-CIR-01, one for P1-COO-02. Eight sessions represent re-exposure to an assessment that learner already finalized. This count is a time-stamped observation, not a fixed user-data baseline or a judgment of any answer's correctness.
- The previously documented P1-CIR-01 correction did not meet the existing three independently correct objective answers plus saved written response. Retain its actual state and all nine saved attempts; never mark it corrected because a learner has worked hard or because a week advanced.
- A separate in-flight written response in #112 must remain resumable; do not use that real session to test content fixes.

## Single learner journey required before a release

1. Resume any ACTIVE session and its first unanswered question ahead of every new assignment. Preserve the exact saved response and assessment version; never restart or replace an ongoing written answer.
2. On each genuinely finalized attempt, show verified machine score where its feedback policy permits, the status of the written artifact (**saved, not independently verified**), and whether the correction actually passed. Distinguish `session saved`, `weekly goal fulfilled`, and `syllabus coverage/mastery`.
3. Never launch an assessment already finalized by the same learner as a *fresh* four-question attempt. A blocked fresh start must create no session, evidence or false completion. Display a precise RU/UZ/EN reason, offer other verified current goals and a return to the existing weekly plan, without silently regenerating that plan.
4. The academic recovery is **privately authored new iClub originals** for this exact skill, not reused diagnostic/retest/mixed/timed reserve and not copied Cambridge or textbook questions. Begin with P1-CIR-01, followed by the next exposed/blocked skills, and replenish all 81 using an approved rolling release schedule. Merely offering one replacement pack once does not resolve repeated learning failures: define sustainable replenishment and a non-credit teaching path separately.
5. Optional review of already seen material, if later approved, must be explicitly called *review*, use `academic_credit=false`, remain distinguishable in historical counters and never satisfy fresh correction evidence, delayed retest, mastery, coverage or readiness. **No review lane is yet built or approved.** Until then, show honest availability/waiting and other eligible tasks, not an invented alternative.
6. A newly governed original learning assessment can be selected only after the academic content-release contract exists. The current Core authorizer selects the first published assessment, not the first unseen alternative; publishing new rows alone is insufficient and unsafe. Upgrade selection transactionally and test consumption, user/component/version identity and genuine exposure BEFORE any activation.
7. After actually achieving the existing remediation conditions, schedule a separate delayed **fresh retest** according to existing Core rules. Only that legitimate result may resolve the correction. P1 work never credits P5.

## Content-editor acceptance for every replacement assessment

- New content version + entirely new stable question/task keys and IDs. Do not change history-bearing public question rows, assessment items, old answer keys or content hashes in place.
- Skill boundaries checked against canonical syllabus/source map. For P1-CIR-01 this is degree/radian conversion and radians as natural angular measure, NOT automatically arc length or sector area.
- At least three independent, mathematically verified original objective analogues plus a written reasoning task; maintain distinct routine/transfer opportunities and the separate long-term mastery requirements from the canonical map. Explanations and plausible distractors independently validated against arithmetic.
- Complete, mathematically equivalent original English, Russian and Uzbek Latin wording; verify units, options, decimal format, scripts and natural grammar. No learner-visible engine jargon.
- Provenance and originality attestation; copyright, syllabus scope, math, linguistic, technical and written-rubric QA all marked **pending** until a responsible academic reviewer signs off. The draft must not contain unreleased questions/solutions in a public GitHub issue, CI log, client JS or learner response.
- Every question's exposure role is **learning**, never diagnostic/retest/unseen/mixed/timed/paper. Maintain at least 20% truly unseen protected retest/mixed/unseen stock by component and at least two weeks of approved content ahead (four weeks target). Existing 70-question Practice and 20-question Tours are not automatically eligible.
- Publishing and serving require separate owner-authorized release; default OFF. Disabled draft material cannot be fetched by learners, even through old REST/RPC paths.

## Isolated end-to-end acceptance, not just row counts

Use synthetic users, isolated PostgreSQL and a loaded Chromium Exam Prep screen; block production network. Prove: original pack complete but 2/3+written -> correction remains open -> repeat start denied without new auth/session/evidence -> P5 unchanged -> new private QA-approved alternative receives distinct item IDs after transactional selection -> 3/3+written genuinely completes remediation -> delayed retest not early -> fresh protected retest pass/fail changes correction only under existing Core rule. Include retry, crash, two-device race and re-entry after week rollover; verify all history preserved and legacy Practice/Tour/certificate/rating counts unchanged.

**Current verdict:** technical weekly-route draft may be checked in isolation, but no real-learner release/expansion until content and exposure governance above passes. Do not treat 81 existing initial packs as a sustainable correction bank.
