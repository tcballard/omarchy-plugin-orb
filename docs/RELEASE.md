# Orb v0.3.0 development branch

The release branch combines touch navigation, provider integration, custom icons
and the extra-button mouse gesture. The normal install command tracks `main`.
The version is not tagged or published.

[Current acceptance](ACCEPTANCE.json) records the tested source and remaining
gates. [v0.2.0 evidence](history/v0.2.0-ACCEPTANCE.json) is historical and does not
establish acceptance for this candidate. Portable checks, QML parsing and Qt
input tests with host stubs do not establish layer-shell focus, physical touch,
real provider compatibility or iPad support.

Before tagging, run the native editor, gesture, upgrade and app-library checks
in an owned Omadev nest, then the [touch QA handoff](TOUCH.md#native-qa-handoff)
on target hardware. Record source SHA, shell/compositor versions, provider
versions, architecture and display/scale/rotation details. Update acceptance
only with observed results. Runtime changes invalidate earlier acceptance.

The inspected Omarchy lock screen has no on-screen keyboard. Secure login and
unlock, suspend/resume, touch mapping and output selection must work before
claiming a complete keyboard-free tablet session or proposing Orb as the
official tablet default. Do not bypass authentication with a normal overlay.

`scripts/archive.mjs` requires source-bound acceptance, a matching annotated tag
and a clean checkout. Its existing pending-live override additionally requires
explicit per-candidate release authorization; none is recorded for this work.
Do not tag or update the marketplace snapshot from portable evidence alone.

[Release notes](RELEASE-NOTES.md) remain a draft. The original published
[v0.1.1 release record](history/v0.1.1-RELEASE.md) is retained separately.
