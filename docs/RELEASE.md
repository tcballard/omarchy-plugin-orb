# Orb v0.3.0 release candidate

This candidate contains custom icons with a local file chooser, optional extra mouse-button gestures, expanded installed-agent discovery and desktop overlay fixes. It exposes only the desktop menu. Touch/tablet navigation belongs to v0.4.0; named wheels, transfers, saved work setups and split/swap controls are deferred further.

The candidate is prepared on `release/v0.3.0`. The existing `v0.4.0` working checkout is preserved separately. Public installation and updates still track `main` (v0.2.0 when checked on 2026-10-30). No v0.3.0 tag or published release has been created by this preparation.

## Prepared evidence

Runtime candidate: `188c502a8a16df6b95fcaf91889819e0b39f60c6`. Model/editor tests, eight Node test files, Qt custom-icon checks (5 passes), QML parsing, manifest validation and clean static release preflight pass. `docs/ACCEPTANCE.json` binds these results to the candidate.

The archive fixture is blocked by a child-process `EPERM`; direct desktop acceptance is still unrecorded; shell Git cannot resolve GitHub for a push or CI run. These gates remain open. No release assets or version tag have been published.

## Before publication

- Pass `./tests/native`, Qt editor tests, strict plugin validation and release preflight on the exact committed candidate.
- Complete the [direct desktop test guide](DESKTOP-TEST.md) on your normal Omarchy desktop. Omadev is optional; only the existing automated `*-live.cjs` harnesses require an owned nest. Record manual results for icons, gestures, focus, binding conflicts, reload and settings persistence.
- Verify fresh installation, upgrade and removal preserve settings and unrelated configuration. Test real installed-agent launches without submitting a prompt or changing the default.
- Record source SHA, shell/compositor versions and display/architecture scope in `ACCEPTANCE.json`. Previous candidate evidence is historical, not acceptance for this release.
- Require green CI and accepted source on `main`, then follow [Cut v0.3.0](CUT-RELEASE.md). The workflow validates the archive before pushing the immutable annotated tag, creates a draft, then downloads and checks its assets. You publish the verified draft.

The archive builder requires source-bound acceptance and a clean tagged checkout. There is no authorization to waive pending native checks. Historical v0.2.0 acceptance remains in `history/v0.2.0-ACCEPTANCE.json`.

For the copy-paste installation and rollback commands, use [Desktop testing](DESKTOP-TEST.md). For acceptance recording, merging, workflow inputs and publication, use [Cut v0.3.0](CUT-RELEASE.md).
