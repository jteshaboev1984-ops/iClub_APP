# iClub AI v2.1 — CI-only verification branch

QA-to-QA draft PR, no merge to main, no deployment, no production secrets, no live DB. The only purpose of this branch is to trigger the existing full offline Node/Chromium/Deno/PostgreSQL/Math parity workflow and inspect actual job steps. Deployment permission remains NO-GO.

Re-run requested after fixing the exact two source QA tests observed in workflow #203. No product release or protected app modifications.
