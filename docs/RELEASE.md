# Orb v0.3.0 — accepted for merge

The owner accepted the candidate and disclosed coverage gaps on 2026-10-30 and requested PR #16 ready for merge. The owner will merge, write the release notes and publish; no merge, tag or release is performed automatically.

The release includes custom icons with a file chooser, optional extra mouse-button gestures, expanded installed-agent discovery and desktop overlay fixes. Touch/tablet belongs to v0.4.0; named wheels, transfers, saved work setups and split/swap controls are deferred further.

`docs/ACCEPTANCE.json` records the source identity, CI evidence and exact owner acceptance. Native cases without supplied results remain pending rather than being called passed. Manual host-desktop testing is valid; Omadev applies only to the guarded automated harnesses.

Merge PR #16 using **Create a merge commit** to retain the accepted source in history. The release workflow supports the recorded owner acceptance through **allow_pending_live=true**, tied to the exact final main commit. It validates the archive before pushing a tag, creates a draft and verifies downloaded assets. The owner reviews and publishes that draft.

- [Feature and user setup summary](RELEASE-SUMMARY.md)
- [Cut the release](CUT-RELEASE.md)
- [Optional additional desktop testing and rollback](DESKTOP-TEST.md)

The existing local v0.4.0 checkout remains separate. The release-notes file is still a draft for the owner to replace.
