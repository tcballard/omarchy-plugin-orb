# Orb v0.3.0 development branch

The `v0.3.0` branch prepares extra-button activation and a hold-and-release gesture. It is not a released version. The normal plugin install command still tracks `main`.

The [v0.2.0 acceptance record](ACCEPTANCE.json) describes the previous candidate and does not establish acceptance of the new input path. Before release, run the portable suite, installed Omarchy manifest and QML checks, the isolated gesture test documented in [DEVELOPMENT.md](DEVELOPMENT.md), and real hardware checks including application focus, button conflicts, cancellation, submenu selection, monitor edges, reload and removal. Record the tested source SHA, shell/compositor versions and limitations.

Physical multi-monitor, hotplug, fractional scaling and other architectures remain unverified. Do not publish a tag or update the marketplace snapshot on the basis of portable tests alone.

Release notes are a [draft](RELEASE-NOTES.md). The previous release's [acceptance](history/v0.1.1-ACCEPTANCE.json), [release record](history/v0.1.1-RELEASE.md) and [notes](history/v0.1.1-RELEASE-NOTES.md) remain separately recorded.
