# J-21 — Chemistry integrated preview green after latest main synchronization

Date: 2026-10-28.

## Verified
- Git integration SHA `fe0d1dd8d23c7e47d88cb45d38cef8fb7be1ef90` includes current main `bf2f17e639b883cce2ab883b96851892fafd1ab0` without overwriting its new Practice AI scripts, using a two-parent merge.
- GitHub Actions on this exact integrated SHA: **39/39 SUCCESS**, 0 pending, 0 failing.
- Protected standalone Vercel preview: `dpl_4AZ2vCuNHwYpinD3jJva4JK2MBLe`, URL https://i-club-45hfe5spi-jasurbeks-projects-c5451f97.vercel.app, **READY**, `target:null`. Production deployment untouched.
- Read-only live Supabase re-run of 8 Chemistry safety suites: J04 32/32, J08 39/39, J09 36/36, J10 41/41, J11 42/42, J12 64/64, J12 Tutor 12/12, J13 44/44: **310/310 PASS**.
- Live counts during verification: Mathematics private exam responses 1,979; Practice answers 4,856; Practice attempts 506. No reset, deletion or test attempts created. Counts may grow naturally with learners.
- Chemistry publish gate `can_publish=false`, `armed=false`, `currently_hidden=true`, P3/P5/Tutor OFF, zero A/Tutor individual approvals.
- Owner previously accepted the earlier visually identical client journey 3/3; owner academic and rights attestation separately documented in J18. This exact new preview has not been manually verified by owner, but is covered by GitHub isolated CI.

## Blockers not assumed resolved
- `backup_restore_tested=false` remains the live authoritative flag. Source code checkpoint `safety/pre-chemistry-code-merge-main-20261028` is not a database backup or restore rehearsal.
- A real non-destructive isolated Supabase restore rehearsal has not been performed. Do not call `restore_project` against production, assume an RPO/RTO, or set the flag without evidence.
- Chemistry learning still requires separate explicit owner GO and controlled entitlement activation. This work authorizes only protected technical preview preparation, not content publication.
- PR #388 should stay draft pending database recovery plan and final code-merge decision; never auto-merge when production safety is unproven.
