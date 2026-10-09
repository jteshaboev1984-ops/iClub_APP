# Economics 9708 — Priority Gaps & Legacy Tier QA v1

**2026-10-09 | Stage 1 | READ-ONLY search of the 809 Economics question records**
Primary authority: [Cambridge Economics 9708 2026–2028, v2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf). Secondary: supplied Economics 4e and seven-tour map.

## Exact keyword triage methodology
For selected high-risk official subpoints, a case-insensitive regular-expression search was performed on existing Economics `public.questions` (`topic`, `subtopic`, English stem) across **all 809 question records**, including questions outside the original 490 active Practice pool links. Aggregate totals below were calculated by live Supabase SELECT and manually sampled where noted.

**Limits:** keywords are only a **discovery heuristic**. Zero hits do not prove an absent concept; positive hits do not prove a valid answer key, source alignment, teacher-ready learning outcome, or question-level explanation. Accessing the database during audit is not permission to expose or feed locked Tour solutions to learners.

| Search concept | Total keyword hits | Active keyword hits | What this means for the academic map |
|---|---:|---:|---|
| Pareto | 0 | 0 | No explicit Pareto term found; 7.3.3 evidence unresolved |
| Moral hazard | 0 | 0 | No explicit phrase; 7.4.6 evidence unresolved |
| Economic rent / transfer earnings | 0 | 0 | No explicit phrase; 8.3.10 evidence unresolved |
| Liquidity preference / demand for money | 1 | 1 | Q6225 is actually **liquidity trap**, insufficient to claim full liquidity preference theory 9.4.7 |
| Loanable funds / interest rate determination | 1 | 1 | Q6167: loanable funds mechanism in **Season 2 Tour 3**, not evidence of safe AS-syllabus placement; official A Level 9.4.8 |
| Phillips curve | 2 | 2 | Q2541 (Practice Tour 2) and Q6222 (Season 2 Tour 6) both emphasise *short-run* concept. No evidence yet of expectations-augmented long-run 10.2.5 |
| IMF / International Monetary Fund | 1 | 1 | Q6244, Season 2 Tour 7, evaluates IMF conditionality; useful 11.5.6 candidate **subject to archive/scope restrictions** |
| World Bank | 0 | 0 | No direct phrase found; 11.5.7 remains unresolved |
| Kuznets | 0 | 0 | No direct phrase found; 11.3.3 component still unresolved |
| MEW / Measure of Economic Welfare | 0 | 0 | No direct phrase found; 11.3.3 component still unresolved |
| MPI / Multidimensional poverty | 0 | 0 | No direct phrase found; 11.3.3 component still unresolved |
| Deadweight / welfare loss | 0 | 0 | No explicit keyword found; 7.4.5 may still be covered by graph-based items |
| Gini coefficient + calculate wording | 5 | 5 | Keyword query matched Gini questions but examples Q2503, Q2547, Q4401/Q5152 concern **interpretation**, not automatically A Level Gini calculation 11.4.2. **Do not treat these five as verified calculations.** |
| Multiplier | 11 | 10 | Q2459, Q2533, Q2543 appear in **AS Tour 2 / nearby legacy sets**, despite multiplier being excluded at AS 4.2.2; A Level 9.1.1 needs proper separate mapping |
| Price discrimination | 1 | 1 | Q3983, classified Ch35 but official main topic 7.8.3 Ch37; source relationship requires governed cross-link |
| Government failure | 1 | 1 | Q4437 possible A Level 8.1.2 candidate; full causes/consequences still missing |
| Terms of trade | 4 | 4 | Q2536 (AS Tour 2, concept belongs AS Tour 3 6.1.3); Q5406/Q5439 in A Level Ch52 tag, plus Tour 7 example; verify actual scope |

## Additional confirmed high-risk historical placements
- **Q2459** AS Tour 2 legacy has a direct MPC/multiplier calculation, besides Q2533 and Q2543. Official AS **4.2.2 excludes multiplier**; assess effects of this history without changing past grades, pools or keys.
- **Q2541** AS Tour 2 legacy asks about Phillips curve, whose official A Level context is **10.2.5**.
- **Q6167** Season 2 Tour 3 explicitly tests loanable-funds crowding out. The main official theory of interest-rate determination is A Level 9.4.8; its question also touches wider fiscal/macroeconomic concepts and should be reviewed by an academic assessor.
- **Q6225** 'liquidity trap' is **not synonymous** with defining/explaining the liquidity-preference theory. Do not count precise 9.4.7 mapping from the shared word.
- **Q6244** IMF question is a *possible* 11.5.6 candidate but comes from Season 2 Tour 7; AI must never use it to hint during active/closed review.

## Decisions for safe next work
1. Preserve all questions, answer keys, historical attempts, learner outcomes, public and private lesson metadata. **No destructive repair**.
2. Mark any unsupported skill candidate `needs_further_evidence` rather than assigning false QA/PASS. Evidence must distinguish `full_stem_verified`, `answer_logic_verified`, `tier_approved`, `source_approved`; none of these are claimed in the base CSV register.
3. Create original trilingual content only after each atomic skill's official scope has passed academic review, with versioned source, independently verified RU/UZ/EN and no source copying.
4. Keep active assessment material private. Runtime AI use limited to approved Practice post-submit or approved archived Tour review after separate activation, never at active Tour.

## Cost/safety
No Vercel API calls, builds or deployments for this report; no model generation, no AI flags, no learner data or production source-card modifications.
