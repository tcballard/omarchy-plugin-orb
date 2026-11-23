# Orb v0.4.0 release

v0.4.0 adds touch and tablet navigation, Omarchy's agent marks and fixes for
current Omarchy and Hyprland on top of the published v0.3.0.

[Current acceptance](ACCEPTANCE.json) records the tested source and remaining
gates. [v0.3.0 evidence](history/v0.3.0-ACCEPTANCE.json) is historical and does not
establish acceptance for this candidate. Portable checks, QML parsing and Qt
input tests with host stubs do not establish layer-shell focus, physical touch,
real provider compatibility or iPad support.

Before tagging, run the native editor, gesture, upgrade, right-click and
lifecycle checks on an idle desktop (`ORB_LIVE_HOST=1`) or in an owned Omadev
nest, then the [touch QA handoff](TOUCH.md#native-qa-handoff)
on target hardware. Record source SHA, shell/compositor versions, provider
versions, architecture and display/scale/rotation details. Update acceptance
only with observed results. Runtime changes invalidate earlier acceptance.
After the recorded checks pass on the tree being accepted, record its exact
runtime files with `node scripts/runtime-hashes.mjs --write`; without `--write`
it lists stale entries. Never refresh the hashes without re-running the checks.

The inspected Omarchy lock screen has no on-screen keyboard. Secure login and
unlock, suspend/resume, touch mapping and output selection must work before
claiming a complete keyboard-free tablet session or proposing Orb as the
official tablet default. Do not bypass authentication with a normal overlay.

`scripts/archive.mjs` requires source-bound acceptance with current runtime
hashes, a matching annotated tag and a clean checkout. Its existing pending-live override additionally requires
explicit per-candidate release authorization recorded in `ACCEPTANCE.json`.
Release through **Actions → Release source** on `main` with `tag`, the exact
`expected_commit` and `allow_pending_live=true`, as in the
[v0.3.0 cut](history/v0.3.0-CUT-RELEASE.md); it creates the tag and a draft.
Do not tag or update the marketplace snapshot from portable evidence alone.

[Release notes](RELEASE-NOTES.md) are the draft body for the GitHub release.
Published records for [v0.3.0](history/v0.3.0-RELEASE.md) and
[v0.1.1](history/v0.1.1-RELEASE.md) are retained separately.
