Orb v0.3.0 adds custom icons, extra mouse-button gestures and nine more coding agents.

## What's new

- **Your own icons.** Choose a local SVG, PNG, JPEG or WebP image for a custom command or submenu under Settings → Shortcuts → Choose image…. Apply the action and save. Keep the image at its saved location; missing images fall back to a generic icon.
- **Launch with an extra mouse button.** Tap to open or dismiss Orb, or hold, point and release to launch. Centre and outside releases cancel; submenus stay open for another selection. Enable the gesture under Settings → Opening and choose your mouse's button code (default: 277). Orb checks for binding conflicts. The selected extra button is consumed across applications while enabled; left, right and middle clicks remain available.
- **Nine more agents.** Qwen Code, DeepSeek Harness, MiniMax Code, Kiro CLI, Freebuff, Kilo, Devin CLI, Amp and Command Code join the installed-agent menu. Install and authenticate them separately, then reopen the menu. Discovery stays offline and preserves your default agent.
- **Desktop reliability.** Existing keyboard and desktop right-click activation, shortcut layouts and saved settings are retained, with expanded overlay and regression coverage. No settings migration is needed.

Thanks to **Michal Mazurek** for the original extra mouse-button contribution.

## Install or update

New installation:

```bash
omarchy plugin add https://github.com/tcballard/omarchy-plugin-orb.git --enable
```

Existing installation:

```bash
omarchy plugin update io.github.tcballard.orb
```

Open Orb with **Super+Alt+O**, then click its centre to open Settings.

## Validation and scope

PR CI passed, including portable/archive tests, QML parsing and Qt icon-editor checks. Owner acceptance of the candidate and disclosed native coverage gaps is recorded in [ACCEPTANCE.json](https://github.com/tcballard/omarchy-plugin-orb/blob/v0.3.0/docs/ACCEPTANCE.json). Unverified native cases remain pending; owner acceptance does not mark them as passed.

Touch/tablet support is planned for v0.4.0. Named wheels, transfers, saved work setups and split/swap controls are deferred further.

Release assets contain source and verification manifests, not a binary installer. Normal plugin installation and updates track main.
