### Repository URL

https://github.com/tcballard/omarchy-plugin-orb

### Category

Desktop

### Tags

Launcher, Quickshell, Hyprland

### Suggest a missing tag

_No response_

### Maintainer notes

Orb is a Quattro shortcut wheel with six to eight configurable slots, circular Settings/Agents menus, and mouse and keyboard activation. Plugin ID: `io.github.tcballard.orb`; version: `0.1.1`.

Native installation is `omarchy plugin add https://github.com/tcballard/omarchy-plugin-orb.git --enable`, from the default `main` branch. Standard plugin update/remove commands are supported. No separate installer is required. Orb initializes missing settings and registers runtime bindings while enabled; optional desktop right-click remains off by default. Unmodified v0.1.0 installer files migrate with backups. User-modified legacy files and conflicting shortcuts remain untouched.

Portable lifecycle fixtures and QML parsing pass. Tom has now tested the published v0.1.1 on his XPS and confirmed that it works; this is owner-reported acceptance, with no new instrumented lifecycle logs supplied. This is a request to review the new released snapshot and its native installation path; previous approval of the legacy snapshot does not establish approval of this update.

Requires current Quattro APIs, the normal Omarchy launchers, Bash, Git, jq and libnotify. No compiled helper or package installation. Orb itself makes no network or authentication requests. It reads local pointer/configuration/agent inventory and launches user-selected applications or agents. Optional agents use their own accounts; their default selection is unchanged.

Historical live evidence covers a Dell XPS 9320 at 1920×1200, scale 1; exact source identities and limitations are in `docs/ACCEPTANCE.json`. Multi-monitor, hotplug, fractional scaling and other architectures remain unverified. The root `preview.png` is a real XPS screenshot; third-party mark and screenshot provenance is in `CREDITS.md`.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
