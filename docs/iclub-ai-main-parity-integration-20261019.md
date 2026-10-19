# iClub AI v2.1 — current main compatibility, October 19 2026
**QA only. No production deploy, merge, migrations, or student records.**

The original QA branch predates production Economics Gen2. Current main has changes to its academic engine and shell, Practice results tabs, translations and Economics data/assets. A conventional merge could overwrite existing features. Main stays authoritative for Mathematics, Economics and the real application shell.

The new CI-only Preview exports the exact immutable origin/main Git commit into an empty disposable archive. Twelve key host, Economics, Global AI and Math files must match the Git blobs from that commit. The QA builder then copies all public application assets from that archive and replaces ONLY the emitted Global AI UI with the independently prepared QA-only design. The original main files are not modified. Synthetic Auth, local help candidates and original Practice demo remain isolated with a restrictive offline CSP and no paid provider.

Browser/Node regression checks real Home and Study, quiz blackouts, Practice error demo, approved AI mark, source file hashes, latest Practice result tabs and intact Mathematics files.

This **does not** grant independent source publication or new user access. Live JWT owner-current-screen checks, article/locale approval, entitlement, assessment locks, and safe learner delivery still require a separate verified production service and owner signoff. Typed local Help is not published Knowledge First content. Global AI release remains NO_GO.

Next: evaluate browser parity results and then connect independent editorial-approved free source returns to the current screen authority, without modifying the existing Math Tutor or academic data.
