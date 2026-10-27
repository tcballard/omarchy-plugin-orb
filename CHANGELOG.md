# Changelog

## 0.3.0 — in development

- Use an optional extra mouse button to open Orb anywhere. Tap to keep the wheel open, or hold, move and release to launch a shortcut. Centre and outside releases cancel; submenus stay open for a second selection.
- Configure the button in Opening with conflict checks and without taking over left, right or middle click. Thanks to Michal Mazurek for the original mouse-button contribution.
- The gesture needs live Omarchy acceptance before release.

## 0.2.0 — 2026-10-23

- Open on Omarchy 4.0.6 without depending on the newer shell's overlay and animation helpers; keep the installed-app catalog available when that shell omits its app-library service.
- Undo shortcut additions, removals, replacements and reordering with Undo or Ctrl+Z, keeping appearance and opening drafts.
- Show the installed version in Settings.

- Choose circle or polygon outlines; polygon sides follow the shortcut count and the centre stays circular.
- Configure five to eight shortcuts, including a five-section pentagon.
- Open Files as a circular menu of Home, Recent, Starred and standard folders, including Trash; existing default Files slots gain the menu automatically.
- Choose Small, Medium or Large wheel sizes, with fine adjustment for custom sizes.
- Browse actions beside the wheel and drag apps, shortcuts or submenus directly onto slots; click and keyboard assignment remain available.
- Arrange shortcuts by dragging around a wheel preview, with keyboard and button alternatives.
- Change the opening shortcut and desktop right-click in Settings, with validation and conflict checks before saving.
- Create and edit custom commands, including separate arguments and an icon picker.
- Add, edit, reorder and remove submenu actions without editing JSON.
- Keep Settings at its opening size while switching tabs or editing shortcuts and submenus.
- Centre Settings in the current screen’s usable area, independent of Orb’s position near desktop edges.
- Give the Settings scrollbar its own gutter and hide it when the page fits.
- Retain custom action metadata through reordering and edits; preserve unrelated concurrent changes.
- Finish unchanged saves normally and keep shortcut bindings working across repeated setup and activation changes.

## 0.1.1 — 2026-10-19

- Install, update and remove through the normal Omarchy plugin commands against `main`.
- Create missing settings on enable while retaining existing layouts and custom metadata.
- Own shortcut and optional desktop bindings for the enabled plugin’s lifetime, including compositor reload and unload cleanup.
- Show setup failures and Retry inside Orb; preserve conflicting user shortcuts.
- Migrate unchanged v0.1.0 installer files with backups and rollback; preserve modified files.

Portable lifecycle and migration fixtures, Qt QML parsing and the upstream manifest validator pass. Tom subsequently tested v0.1.1 on his XPS and confirmed it works. This is owner-reported acceptance; the previous automated and v0.1.0 evidence remain separately recorded.

## 0.1.0 — 2026-10-19

Orb brings a pointer-centred shortcut wheel to Omarchy's Quattro shell.

- Six default slots, expandable to eight, with a native settings panel for choosing apps, plugins and shortcuts.
- Circular Settings and installed-agent submenus; an optional Make something cool menu starts the native theme, plugin or app creation prompt.
- Pointer and keyboard selection, click/Enter activation, Escape/outside-click dismissal, and focus restoration.
- Configurable Super+Alt+O shortcut and optional right-click activation on empty desktop, preserving application context menus.
- Live shell colours, native application icons, Codex/Claude/Grok marks, animated opening, and captions that grow with the wheel.
- Monitor-edge clamping, including reserved bar space and the caption below the wheel.
- Repository-based local installation and removal that retains the user's Orb configuration.
- Failed shortcut installation restores existing files and removes newly created binding files, including reload and configuration-query failures.
- Selected action captions use the shell theme's text colour for light and dark backgrounds.

Tested on a Dell XPS 9320 at 1920×1200, scale 1. This targets the Quattro development contract documented in the acceptance evidence; older Omarchy releases are not claimed compatible. Physical multi-monitor/fractional-scale testing remains outstanding. Theme testing covers live shell palette changes, not full desktop retinting. See [acceptance evidence](docs/ACCEPTANCE.json) for the precise scope and remaining gaps.

Owner acceptance completed on 2026-10-19. Marketplace listing remains subject to maintainer review.
