# iClub APP — Demo AI v1.2 — final release record

Date: 2026-07-14
Specification: `iClub_APP_ТЗ_разработка_демо_AI_тарифов_v1.2`
Release branch: `demo-ai-v12-final-candidate`
Immutable checkpoint branch: `demo-ai-v12-final-2026-07-14`
Final release SHA: `cbf87a2e5438a9326e7ee9275f68dad53ddbbfdb`
Validated source SHA: `026d71340bdf5d3e12b1ac31d8c315c28b6f705a`
Rollback SHA: `8f3bbf8e5f6a4d8d6c1c1970ca5c784ca8b350ca`
Main base SHA left unchanged: `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`

## Final Gate 8 completion

Gate 8 is completed against the required exit criteria:

- iClub AI mark and main-app shell are present;
- 360 / 390 / 430 px and desktop layouts were exercised;
- RU / UZ / EN routes were exercised;
- ten full Playwright browser rehearsals completed successfully;
- browser videos and traces were saved as GitHub Actions artifacts;
- reserve presentation videos are included in the rehearsal artifact;
- Active Tour 5 exact, paraphrase, confirmation, option-elimination, prompt-injection and theory-only routes were exercised;
- verified, generated, cached, fallback and no-source routes were exercised;
- dynamic Pro evidence and trajectory changes were regression-tested;
- the final Vercel deployment for the release SHA completed successfully;
- a frozen release checkpoint branch was created.

## Browser rehearsal evidence

GitHub Actions run ID: `29308278260`
Artifact name: `demo-ai-v12-browser-rehearsals`
Artifact ID: `8301101153`
Artifact digest: `sha256:f79613e6a19d0915260c291b46995869b333a037e4a0b6231bc471bb38bd93e3`
Artifact expiry: `2026-07-28`

Coverage included:

- RU, UZ and EN;
- 360 px, 390 px, 430 px and desktop;
- full presentation route;
- videos and Playwright traces.

## Release isolation

- Pull request 8 was merged only into `demo-ai-v12-final-candidate`.
- `main` was not the PR base and was not modified.
- Production Supabase scripts are not loaded by the demo.
- The demo endpoint has no production database access.
- Demo state remains limited to the `iclub_demo_v12.*` namespace.
- No production user, attempt, answer, rating, recommendation or certificate data was read or written.

## Rollback

For a visual or state regression, restore the route from:

`8f3bbf8e5f6a4d8d6c1c1970ca5c784ca8b350ca`

For a generated-AI provider problem, disable:

`DEMO_AI_GENERATED_ENABLED`

Verified answers, deterministic Pro analysis and fallback continue to work without the generated route.

## Final decision

P0: complete.
P1: complete with runtime provider health guard and degradation path.
P2: complete, including ten rehearsals and reserve videos.

Final verdict: `DEMO_AI_V1_2_RELEASE_READY`
