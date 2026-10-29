# Wheels, work setups and multitasking

In Settings → Wheels, duplicate the current wheel and name it Code, Everyday,
Media, Travel or anything you prefer. Each wheel keeps five to eight fixed
shortcut positions. Rename, import and remove wheels in the same draft, then
Save. Shortcut edits belong to the wheel that was active when Settings opened.
The wheel selector in desktop and touch views switches immediately and saves
that choice. Up to sixteen wheels are supported. Existing configurations become
Everyday in memory without rewriting unchanged settings.

Search opens the enabled **typecraft.oma-cast** plugin. Orb's Apps page remains
a browsable app grid; it does not introduce another universal search engine.
The settings picker still filters its own choices.

## Saved work setups

In Wheels, name a setup, choose workspace 1–9999, add up to eight installed apps
in opening order, and choose Normal tiling or Equal columns. Save, then run it
from touch Controls or add the Work setups submenu to a wheel. Up to sixteen
setups are supported. Remove and recreate a setup to change its app list/layout.

Orb checks every desktop entry and the selected display before launching. A
workspace already owned by another display is rejected. Normal tiling follows
Hyprland's layout; Equal columns applies floating position/size rules to newly
created windows. Existing windows are not closed. Single-instance apps may reuse
an existing window and ignore new-window rules. A successful launch request does
not prove that every app opened; later failures can leave earlier apps running.

## Touch window pairs

Open Windows, tap Pair on two windows, then Split. Choose a 30/70, 40/60, 50/50,
60/40 or 70/30 ratio, or Swap sides. The two windows become floating, leave
fullscreen and move onto the chosen display's active workspace. Placement accounts
for scale, rotation and reserved bars. Clear pair clears the selection, without
undoing placement. Window/display identities are checked again at execution;
compositor failures can leave a partial arrangement. Use normal tiling controls
to return these windows to the tiled layout.

## Sharing

Export writes an `.orb.json` file with the wheel's shortcut actions and bundled
custom icons. Import shows the exact command arguments and asks you to add the
reviewed wheel to the draft; Save makes it available. Import never executes a
shortcut or automatically selects the wheel. A changed file must be reviewed
again. Command paths and installed apps still need to exist on the receiving
machine; saved work setups are local and are not included in wheel exports.

PNG, JPEG, WebP and SVG icons are limited to 128 KiB each, with at most 32 images
and an 8 MiB package. Bundled images use checksum filenames in
`$XDG_DATA_HOME/omarchy/orb/icons` (normally `~/.local/share/omarchy/orb/icons`).
Uninstall preserves them. Unknown action metadata is not exported.

## Validation and native follow-up

Portable tests cover legacy settings, draft switching, metadata, concurrent
changes, import review/digests, image checksums, missing apps, stale windows,
scaled/rotated geometry, and Oma-Cast handoff. Qt tests exercise draft controls
and touch actions with host stubs. The compositor contracts were inspected in
Hyprland v0.56.2; they require native acceptance on the supported Omarchy session.

Before release, exercise wheel changes across shell restart, Save/Cancel, import
on another account, live Oma-Cast focus/keyboard handoff, two real windows at
fractional scale and after rotation, and tiled/column setups including an app
that reuses its current window. Run the expanded agents acceptance in
[AGENTS-11.md](AGENTS-11.md) and the hardware checklist in [TOUCH.md](TOUCH.md).
