<h1 align="center">Orb</h1>

<p align="center">A shortcut wheel for Omarchy.</p>

<p align="center"><a href="https://github.com/tcballard/omarchy-badges"><img alt="Built for Omarchy: Plugin" height="20" src="https://raw.githubusercontent.com/tcballard/omarchy-badges/75975e5b5bf75e7ede3764bcd2950046f7abfe2c/badges/v1/omarchy-plugin.svg"></a></p>

Launch apps, switch themes and open your installed coding agents from a wheel near your pointer. Press **Super+Alt+O**, then click an icon or select it with the keyboard and press Enter. Choose five to eight shortcuts in Orb’s settings; the wheel follows your Omarchy shell theme.

**For Omarchy Quattro.** This development branch prepares v0.3.0; the normal install command tracks `main`. The new mouse gesture still needs live Omarchy acceptance. [Install and update](#install) · [Previous release evidence](docs/ACCEPTANCE.json).

![Orb with a five-section polygon and a circular centre](preview.png)

Native capture with five shortcuts in Polygon mode; six and Circle remain the defaults. [Capture details](docs/PREVIEW.json).

Inspired by **Tangerine for Mac**. Original implementation built from Tom Ballard’s [Omarchy plugin starter](https://github.com/tcballard/build-omarchy-plugins). [Credits](CREDITS.md).

## Install

```bash
omarchy plugin add https://github.com/tcballard/omarchy-plugin-orb.git --enable
```

Installs from `main`. Orb creates its settings on first enable and registers **Super+Alt+O** while enabled. No separate installer or source checkout is needed. Existing settings are retained. A conflicting shortcut opens an in-app error with a retry button and leaves the existing binding alone.

Update:

```bash
omarchy plugin update io.github.tcballard.orb
```

Remove:

```bash
omarchy plugin remove io.github.tcballard.orb
```

For an existing v0.1.0 install that tracks a local source checkout, remove and add Orb once through the normal plugin manager to switch it to this public repository; saved settings are retained.

Disabling or removing Orb releases its runtime bindings; your Orb settings remain. The old installer’s unmodified binding module is migrated automatically, with backups. User-modified legacy modules are preserved and reported for review.

Requires Quattro with `PointerMoveGate`, the normal Omarchy launchers, Bash, Git, jq and libnotify. Orb includes compatibility for the Omarchy 4.0.6 shell's missing overlay, animation helper and menu app-library service. Node and a compiler are only development dependencies. The tested source and package scope is recorded in [acceptance evidence](docs/ACCEPTANCE.json).

## Use and configure

- Optional **right-click on empty desktop** also opens Orb. This is enabled on this XPS; applications retain their context menus. Super+Alt+O remains available.
- Hover a sector and left-click to launch. The centre logo glows on hover; click it to open Orb’s compact settings panel. In a submenu, the centre goes back.
- Arrow keys or Tab/Shift+Tab cycle; 1–8 select an available slot; Enter launches. Home selects the centre button; Enter opens Orb settings (or goes back in a submenu).
- **Shortcuts** shows your layout as a wheel. Drag an icon to another sector to move it, or use the arrow buttons / Alt+Left and Alt+Right. **Browse actions** opens a searchable picker beside the wheel: drag an app, shortcut or submenu onto any slot. Click a slot and choose an action, or use the picker's arrow keys and Enter, for the same assignment. Changes stay in the draft until **Save**. **Back to shortcuts** returns to the slot list; click a sector or row to edit it. Arrow keys select rows; Enter edits. **Add shortcut** expands up to eight; **Remove** or Delete removes the selected shortcut down to five.
- The action editor offers **Apps & shortcuts**, **Custom command**, and **Submenu**. Custom commands have a name, icon, program and separate argument fields; spaces stay inside the argument and shell punctuation is passed literally. Submenus contain up to twelve app, shortcut or custom-command actions, with controls to add, edit, reorder and remove them. Submenus cannot contain another submenu. **Use command / Use submenu** stages the change; Back/Escape discards that editor's draft.
- **Undo** or Ctrl+Z on Shortcuts restores the last shortcut addition, removal, replacement or reorder. It keeps your Appearance and Opening drafts. Text fields retain their own Undo. History lasts until Save or Cancel; up to forty shortcut edits can be restored. The header shows the installed Orb version.
- **Opening** changes the Super shortcut, optional desktop right-click, and optional extra mouse button. Enable the button and choose its code (275–511); the default is 277. Tap to open Orb at the pointer, or hold the button, move to a sector and release to launch. Release in the centre or outside the wheel to cancel. A submenu opens for a second selection. Tap again to dismiss. The chosen extra button is consumed in applications while enabled. Left, right and middle click remain available. Button codes vary by device; `wev`, if installed, can show them. Conflicts appear before saving and preserve existing bindings.
- **Appearance** offers **Circle** or **Polygon** outlines. Polygon follows the shortcut count: five makes a pentagon, six a hexagon, and so on; the centre always stays circular. The Shortcuts preview follows your draft shape. Choose **Small**, **Medium** or **Large** wheel sizes, with a slider for fine adjustment and a separate opening-animation toggle. Existing custom sizes are retained. **Save** or Ctrl+S applies all staged settings; **Cancel/Escape** discards them. Tab moves between controls. Settings opens centred in the screen’s usable area and keeps its opening size across tabs and action editors, scrolling longer content inside the panel.
- Escape/Left/Backspace or the centre button returns from a submenu. Escape on the wheel, outside click, or the summon shortcut again dismisses.
- Sectors show centred icons at every wheel size. The full hovered or keyboard-selected action name appears beneath Orb, including in submenus. Its text and pill grow with the wheel, retaining a readable minimum at small sizes.
- The wheel and keyboard hint stay clear of monitor edges and reserved bar space.
- Submenus with more than six actions use footer arrows, scrolling or Page Up/Down.
- **Files** opens a submenu for **Home, Recent, Starred, Downloads, Documents, Pictures, Music, Videos and Trash**. Pick a location to open it in Files; scroll or use the footer arrows for the second page. The centre button or Escape returns to the main wheel. Standard folders follow your XDG directory settings. Existing default Files shortcuts gain this menu automatically; custom file commands and app entries keep their configured behaviour.
- **Make something cool** is an optional slot: search for it in Apps & shortcuts to add a circular **New theme / New plugin / New app** menu. Selecting a starter opens your default Omarchy agent with the same prompt used by the native Agents panel.
- Opening animates for 190ms; newer shells' reduced-motion setting is respected. Appearance also offers an explicit animation toggle.

![Orb settings with a draggable polygon preview, Undo and the installed version](docs/v0.2.0-settings.png)

![Browse actions beside the wheel and assign them directly to slots](docs/v0.2.0-browser.png)

Previous native captures and checks: [v0.2.0 acceptance evidence](docs/ACCEPTANCE.json). The v0.3.0 mouse gesture has not yet had live Omarchy acceptance. Earlier editor checks: [Catalog and size presets](docs/CATALOG-ACCEPTANCE.json) · [Settings](docs/SETTINGS-ACCEPTANCE.json).

Settings remain in `~/.config/omarchy/orb.json`, and can still be edited directly. See [the example](config.example.json). Five to eight top-level actions, one submenu level, the installed-agent menu (`"menu": "agents"`), Files locations (`"menu": "files"`), shape (`"circle"` or `"polygon"`), size, animation, shortcut, desktop activation and an optional extra mouse button are supported. The mouse button defaults to code 277 and stays off until enabled. The default diameter is 240 theme units. App choices store a `desktopId` and launch through Quattro’s app library; icons follow the installed application. Custom commands run as argument arrays without shell-string evaluation. Orb preserves unrelated settings and metadata on moved or edited actions, and rejects conflicting external edits. Invalid configuration retains the last valid actions and shows an error hint.

Desktop right-click uses Hyprland’s auto-consuming binding: app, panel and widget clicks pass through. It replaces the wallpaper’s right-double-click theme gesture; Themes remains available as a shortcut. Conservative panel bounds, including the dock’s transparent area, are excluded. The optional extra mouse button is a separate global binding.

```bash
omarchy-shell shell toggle io.github.tcballard.orb
omarchy-shell shell hide io.github.tcballard.orb
omarchy-shell io.github.tcballard.orb status
```

## Verification and limits

Developed on a Dell XPS 9320. [Acceptance evidence](docs/ACCEPTANCE.json) separates portable checks, native tests in owned Omadev sessions and historical owner reports. It records the exact Omarchy source, display and installed package scope. [Development](docs/DEVELOPMENT.md) · [Architecture](ARCHITECTURE.md) · [Demo and recording](docs/DEMO.md).

Five to eight configurable top-level entries with one submenu level. Agent discovery filters out first-run installer wrappers, requires a real installed executable, and does not alter the default agent. The new extra-button and gesture paths need live testing, including over applications. Multiple physical monitors, hotplug and fractional scaling need further live testing. Screenshot verification covers opening and cancelling the capture UI, not saving a capture. Historical theme checks use real shell palette-change IPC and restore it; full desktop/app retinting is not exercised. Historical physical-key and launcher checks remain separately recorded; nested tests do not recreate a complete historical Omarchy package installation.

Codex, Claude and Grok use the product marks bundled with Omarchy’s agents panel, with contrasting variants for light and dark themes. [Asset provenance](CREDITS.md#agent-marks).

The published v0.1.1 owner acceptance is retained in [the historical record](docs/history/v0.1.1-ACCEPTANCE.json). Marketplace snapshot updates require maintainer approval.

Orb itself makes no network requests and requires no authentication. Applications and agents you launch can use their own network connections and accounts. Agent discovery reads installed executables and, when present, the local mise inventory; it does not install agents. Runtime helpers require the normal Omarchy launchers, Bash, jq and standard system utilities. The plugin reads the pointer position with `hyprctl` and starts the selected application or agent after dismissing the wheel.

Installation writes the plugin checkout through Omarchy and creates `~/.config/omarchy/orb.json` only if missing, plus an Orb setup lock. Fresh installations do not write Hyprland configuration files. Migration of the old installer removes only its unchanged module and exact owned include, with backups. The plugin manager records enablement in shell configuration. Removal retains Orb settings and migration backups. Runtime bindings are recreated after Hyprland reload; restarting the shell recovers them after a shell crash. Custom command arguments in `orb.json` are trusted local configuration.

Report problems through [GitHub issues](https://github.com/tcballard/omarchy-plugin-orb/issues), including your Omarchy version and reproduction steps. See [security reporting](SECURITY.md) for sensitive reports and [release evidence](docs/RELEASE.md) for release gates.

## Licence

[MIT](LICENSE). Third-party software and media retain their own licences.
