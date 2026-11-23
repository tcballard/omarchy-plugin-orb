# Real desktop demo

## v0.2.0 still captures

The current preview is a native `grim` crop in an owned Omadev session using the Omarchy 4.0.6 source. It shows five shortcuts in Polygon mode at diameter 360 theme units, with Browser selected and a circular centre. The six-slot Circle view, Files submenu, Settings, action browser and Appearance captures are `docs/v0.2.0-browser.png`, `docs/v0.2.0-settings.png` and `docs/history/v0.2.0-*.png`. [PREVIEW.json](PREVIEW.json) and [ACCEPTANCE.json](ACCEPTANCE.json) record their dimensions, hashes and tested runtime.

To reproduce, use an owned nest and an empty workspace. Keep the host config untouched. Start from `config.example.json` in the nest's `orb.json`; use diameter 360 and disable animation for stills. For the pentagon, remove Screenshot to leave Browser, Terminal, Files, Settings and Agents, then select Polygon. Open Orb and press 1 to show Browser's caption. Crop the wheel and footer, with an eight-pixel margin. For Settings captures, use the default six actions with Polygon, open the centre, and capture the panel bounds reported by the read-only status IPC. Restore the nest's original configuration afterward. These images were inspected directly; no image generation or composition was used.

## Historical recording notes

Recording is on hold at the user’s request while the visual design is being refined. The recording harness predates the compact-menu revision; recheck it before a future recording.

On an empty workspace, move the pointer near the centre, press Super+Alt+O, hover Browser → Terminal → Files, and click Terminal. Summon again and press Escape. One real launch plus cancellation makes a useful 15-second clip.

```bash
omarchy screenrecord --status
omarchy screenrecord --fullscreen
# Demonstrate the wheel.
omarchy screenrecord --stop-recording
```

The stop command prints the path. No audio is requested. Do not interrupt an existing recording. Set OMARCHY_SCREENRECORD_DIR when starting to choose an output directory.

`demo/record.cjs` automates a real pointer demonstration after the native test pointer is built. It uses an empty workspace, clicks Terminal, cancels another summon and restores the user's workspace/pointer/focus. Recordings remain under ignored artifacts until reviewed.

X-thread drafts, based on observed prototype behaviour:

1. “Orb is running inside Quattro on the XPS: six default slots, expandable to eight, with native icons and action names below the wheel.”
2. “Pointer and keyboard selection, circular agent menus, cancellation and focus restoration are working. The caption now scales with Orb, with live checks at 280, 467 and 700px.”
3. “The working feature branch is on GitHub. Preparing v0.1.0 with release notes, source checksums and a real desktop preview; final lifecycle acceptance and tagging are still ahead.”

Nothing is posted automatically.
