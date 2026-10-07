# iClub Free / Plus / Pro — product capability audit v1

Date: 2026-10-06  
Scope: learner-facing plan presentation only.  
Production status: read-only audit; no production entitlement or learner-state mutation.

## Production evidence checked before plan UI QA

Current active subject catalog:
- Biology — active main subject
- Chemistry — active main subject
- Mathematics — active main subject
- Informatics — active main subject
- Economics — active main subject
- English A1/A2/B1, SAT and IELTS exist in the catalog but are inactive.

Current production content/activity evidence:
- 5 active books total, one for each active main subject.
- 47 lesson rows total.
- 3,741 recommendation rows.
- 901 Practice attempts.
- 365 Tour attempts.
- 157 certificates.
- Mathematics Exam Prep remains controlled beta.
- Current Exam Prep live entitlements: 3 Core, 3 AI, 0 Mentor Care.

## What is already a real app capability

### Subject learning
The app already has subject selection and subject-specific Study surfaces for the five active main subjects.

### Practice
Practice is a real learner flow. It includes attempts, results, review, recommendations and saved history.

### Tours / ratings / certificates / archive
These are existing product surfaces. Competitive mode is already a distinct user-subject mode and the current product rule caps it at two subjects.

### Recommendations
Recommendations are real and persisted. The current app does **not** yet have separate Free/Plus/Pro recommendation algorithms.

### Books / video lessons
Books and lesson/video infrastructure are real app capabilities. Books are subject-linked. Current active books: 5. Lesson/video infrastructure is also present.

### Mathematics Exam Prep
The governed Mathematics P1/P5 Exam Prep contains real diagnostic/placement, weekly-plan, learning/correction, delayed retest, mixed practice, timed work and readiness flows. It is still controlled-beta access, not a general commercial entitlement yet.

### AI explanations
Practice AI and governed Mathematics Exam Prep AI infrastructure already exist. Global iClub AI is being added as a separate dormant layer and is not production-activated.

### Support
The standard support flow is real. A separate priority-support queue is **not** implemented yet.

## Product promises intentionally removed from the current plan screen

The first plan-screen draft contained several attractive but not-yet-implemented promises. They are removed from learner-facing comparison until a real implementation exists:

- “extended history” as a Pro-only analysis capability;
- “deeper personalized recommendations” as a Pro-only recommendation engine;
- “early access after QA” as a live learner entitlement;
- “priority support” as a live support-routing capability;
- a Free Exam Prep preview/first diagnostic, because the commercial Free preview gate does not exist yet;
- future Exam Prep modules as an included Pro promise.

The server policy may retain dormant capability fields for future work, but learner-facing copy must not sell them before implementation.

## Launch-safe comparison target

| Capability | Free | Plus | Pro | Current implementation note |
|---|---|---|---|---|
| Study subjects | 1 | Up to 3 | All active available | Subject-slot enforcement still pending |
| Competitive subjects | 1 | 2 | 2 | Current app already supports max 2; Free cap still pending |
| Practice | Included for connected subjects | Included | Included | Real |
| Tours / ratings / certificates | For eligible Competitive subjects | Included | Included | Real |
| Practice error review | Basic review | Basic + AI explanation where supported | Basic + AI explanation where supported | Real base; Global AI integration pending |
| Recommendations/history | Included | Included | Included | Real; no tiered algorithm yet |
| Books/video/materials | Connected subjects | Connected subjects | All connected/available subjects | Real content surfaces |
| Mathematics Exam Prep P1+P5 | Not included in commercial Free v1 | Full after commercial entitlement integration | Full after commercial entitlement integration | Real module; tariff mapping pending |
| iClub AI | 3 prepared answers / 5h | Higher usage / 5h | Highest usage / 5h | Server accounting foundation built; activation pending |
| Free-form AI questions | No | Yes | Yes | Global generation provider still pending |
| Standard support | Included | Included | Included | Real |

## Commercial distinction that remains honest

Plus is the lower-cost paid entry:
- up to 3 study subjects;
- full paid Global AI capability once generation is connected;
- commercial Mathematics Exam Prep entitlement once tariff mapping is implemented.

Pro is the intentionally better-value option:
- all active available study subjects;
- highest Global AI usage allowance;
- all otherwise available learner content without the Plus three-subject cap.

At 35,000 UZS vs 50,000 UZS, the 15,000 UZS step-up is justified by breadth (all subjects) and heavier AI usage without inventing Pro-only academic truth.

## Activation blockers

Do not enable the plan screen for real learners until all are true:
1. existing-user grandfather/cutover is explicitly approved;
2. subject-slot enforcement is non-destructive and tested;
3. Plus/Pro Mathematics Exam Prep entitlement mapping is implemented;
4. Global generated AI is approved and cost-protected;
5. subscription lifecycle exists;
6. payment/checkout provider exists, or checkout remains clearly unavailable;
7. downgrade never deletes Practice, Tours, recommendations, certificates, Exam Prep evidence or local progress;
8. commercial copy matches implemented capabilities at the time of activation.
