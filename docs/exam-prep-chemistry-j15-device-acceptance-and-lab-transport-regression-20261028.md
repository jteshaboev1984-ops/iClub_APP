# iClub Chemistry 9701 — J-15 device acceptance, LAB transport hardening and compatibility hold
Date: 2026-10-28

**Verdict: protected preview only. Chemistry release NO GO.**

## Owner-reported J-14 acceptance
Owner opened the J-14 protected Preview and reported all five requested manual checks OK:
1. Main screen layout, text and menu.
2. Chemistry Exam Prep stays closed; no accessible Entry, Recheck, P1, P3, P5 or Tutor.
3. Russian, Uzbek and English text/switching.
4. Non-mutating navigation Chemistry ↔ Mathematics/Economics and back.
5. Mobile viewport/layout/buttons.
This is **owner-reported 5/5**, not an independently instrumented browser test. It does not certify authenticated exam completion, offline/data-loss/recovery, accessibility audit or 375/768/1280px metrics.

## J-15 scoped code hardening
Updated ONLY `exam-prep/exam-prep-chemistry-labs-native.js` on the isolated Chemistry branch:
- Paper 3 catalogue accepts precisely the distinct six `CHEM9701-LAB-01` through `-06` keys; Paper 5 precisely distinct `-07` through `-12`.
- Reject duplicate keys, foreign-paper keys, malformed/empty titles, wrong count, paper/level/locale mismatches and server-provided mastery credit.
- Lesson details reject empty/missing title and preserve existing Tutor/mastery/practical-exam prohibition.
- All mismatches fail closed; no localStorage, attempt history or actual learner account touched.
New reproducible synthetic QA `scripts/qa-chemistry-9701-j15-lab-response-boundary.cjs`: **19/19 PASS**, including valid P3/P5, duplicates, mixed paper, metadata mismatches, Tutor, invalid lesson text/title and practical exam replacement claims.
J-13 legacy synthetic LAB test re-run: **20/20 PASS**.

## Live database verification (read-only)
On 2026-10-28 re-ran J04 (32), J08 (39), J09 (36), J10 (41), J11 (42), J12 (64), J12 Tutor ACL (12), J13 (44): **310/310 PASS**.
Source version `chemistry9701_20261022_stageb_draft` remains 154 Theory + 12 LAB =166; 6 P3 AS and 6 P5 A cards; all 12 draft, complete EN/RU/UZ title/explanation and locale-specific Tutor objects. This is structural completeness, not content rights approval.
Live J12 release gate: owner GO false, rights review false, backup-restore test false, device QA formal signoff false, armed false, visible false, core/entry/recheck/p1 all OFF, `can_publish=false`, generic publisher incompatible. J13 P3/P5/Tutor global switches OFF, individual permissions zero, Chemistry remains inaccessible.
Previously observed Math/Practice baselines 1,979/4,816; no deletion/reset performed.

## Contemporary main compatibility risks
Immediately before J15 changes branch was ahead **127**, behind **56** vs production `main` SHA `1435b323d7d58d08a03d9088f57d98aa95d3a1a2`. Main continues to change independently, and later production deployment was seen READY at SHA `69ba26235249a12951d116b56267152a352de002`. Re-compare at integration time.
At this J15 checkpoint, exact shared source blob SHA matches main for `exam-prep-api.js`, `exam-prep-live.js`, `exam-prep-economics-native.js`, `exam-prep-economics-native.css`, and multisubject shell JSON. Differences remain for Chemistry-extended `exam-prep-host.js`, CSS, and `index.html`. 56 newer main commits include Economics written, AI Practice, Core/answer-recovery changes and workflows. Do not blindly merge or replace common files.

## Separate protected J15 Preview
Deployment `dpl_8rjzpra7bzNS2HbgRUwhwY3HDAAL`
Pinned SHA `18e36e5e3d4f8ed4b2aa8d40f3ed8dcbbe943e65`
URL https://i-club-o8w0qubcf-jasurbeks-projects-c5451f97.vercel.app
Target not production, Vercel Authentication protection remains enabled. Status initially INITIALIZING; inspect final READY before claiming success.

## No owner GO / remaining launch blocks
Independent authenticated browser/device acceptance of real data flows remains outstanding. Full package academic content/rights safety review, production backup *restore* proof, composite publisher incompatibility resolution, separately approved release flags and entitlement policy must precede release.
No production merge, no Chemistry publish, no new beta learner access or user data mutation occurred.
