# Develop and verify Orb

Portable checks (Node 22+, Bash, jq, Lua 5.4 or texlua; no npm dependencies):

```bash
./tests/run
```

This retains the starter identity/CI checks and adds geometry/config tests. On Omarchy, `./tests/native` also runs the installed manifest validator and Qt's QML parser. Parsing is not runtime verification.

`node --test tests/surface.test.mjs` checks the handlers and readiness expressions in `OrbOverlay.qml`, including output selection, focus changes, scale readiness, deferred reveal and screen removal. These fixtures do not instantiate QML or exercise layer-shell mapping. The original issue #10 still needs confirmation on the reporter's full historical package stack and live multi-monitor/fractional-scale checks.

Install from main with `omarchy plugin add https://github.com/tcballard/omarchy-plugin-orb.git --enable`. For a committed development checkout, use the supported local Git URL with `omarchy plugin add "$PWD" --enable --yes`. Normal updates use `omarchy plugin update io.github.tcballard.orb`; remove with `omarchy plugin remove io.github.tcballard.orb`. The compatibility `./install` and `./uninstall` wrappers only forward to the native manager. No post-install terminal command is needed.

The current settings acceptance harness runs **only in an owned omadev nest**:

```bash
omadev ensure 4 --owner orb-settings --plugin "$PWD"
# Run these in a visible terminal in that nest:
./tests/native
./tests/build-pointer
node tests/editor-live.cjs
```

The harness refuses the host desktop. It saves/restores the nest's Orb config, uses real Wayland pointer/drag and keyboard input, and exercises size presets, direct catalog-to-wheel assignment, cancelled drops, draft/cancel/save/reopen, metadata retention, keyboard reordering, opening controls and live binding updates, shortcut conflicts, custom command arguments, submenu edits and launches, six-to-eight shortcuts and screen edges. Appearance checks open six/eight-slot Settings at all corners and both side edges, verify the entire panel is centred within reserved screen space, and retain the opening frame through tab changes, presets and full slider drags. Commands launch only a local argv-recording fixture. Captures and JSON results stay under ignored `artifacts/`. `--appearance-only` checks that placement and sizing; `--catalog-only` also checks presets and direct assignment; `--submenu-only` narrows a failed submenu check. No video is recorded.

For the v0.3.0 extra-button gesture, use an owned, single-monitor, scale-1 unrotated nest linked to this checkout:

```bash
./tests/build-pointer
node tests/gesture-live.cjs
```

The script selects an unused extra-button code, temporarily replaces only the nest's Orb settings, launches a private recording fixture, and restores the settings and pointer in cleanup. It checks tap/dismiss, directional launch, centre cancellation, submenu opening and removing both bindings. It does not test a physical mouse, multiple monitors or a button pressed over a real application. Also test those manually on the target desktop, including a conflicting binding, application input, keyboard use, shell/compositor reload, disable/removal and monitor edges. This test has not yet been run for v0.3.0.

Every editor run also checks the installed version label and shortcut Undo: removal, keyboard/pointer reorder, additions, submenu edits and catalog assignments, retained origin identities, native text Undo, and preservation of appearance/opening drafts. Use `--undo-only` for that focused check.

After committing a clean candidate, `node tests/release-live.cjs` runs only in an owned nest initially linked to this checkout. It installs the published v0.1.1 source from a private local Git origin, advances that origin to the candidate, and upgrades through the real plugin manager. It verifies byte-preserved legacy settings, eight slots, metadata, disable/enable/reload and owned bindings, removal, then a fresh Git installation with no existing Orb config. It restores the nest's original link, Orb config and shell settings in cleanup. It never uninstalls the host's Orb. Tests use the nest's selected Omarchy source with this machine's installed compositor and Quickshell; testing a 4.0.6 source checkout does not recreate the reporter's entire historical OS package set.

`node tests/app-library-live.cjs` selects the installed Ghostty app from the catalog, saves its desktop ID, then verifies a real new window appears after Orb dismisses. It restores Orb configuration and closes only its new window. Run on both selected shell sources to exercise the native service and the 4.0.6 fallback. Application directories are read only.

`node tests/files-live.cjs` also requires an owned nest. It exercises the legacy Files shortcut, both radial pages, pointer/keyboard navigation and back behaviour, then opens all nine locations in native Nautilus windows. It checks each actual location through FileManager1 D-Bus properties, including Recent, Starred and Trash, and uses private XDG folders containing spaces. Before writing user-directory fixtures, it replaces any shared configuration symlink with a private file, restoring the original link afterward. It closes only the windows it created and restores the nest’s Orb and user-directory configuration. Portable `tests/files.test.cjs` checks command arguments, folder resolution, missing locations, menu validation and compatibility without launching a real file manager.

The older `settings-live.cjs`, `slots-live.cjs` and `expanded-slots-live.cjs` harnesses record the v0.1 panel's keyboard paths. Use `editor-live.cjs` for the new settings UI. The remaining opt-in live harnesses below control the actual desktop; they are not part of the portable suite and should be run only with the desktop idle or adapted to a nest.

The opt-in live harness controls the actual desktop. It saves/restores workspace, focused window and pointer, uses an empty named workspace, launches real actions and closes only newly created test windows:

```bash
./tests/build-pointer
ORB_POINTER="$PWD/artifacts/input/pointer" node tests/live.cjs --actions --theme --agents
```

The pointer is a test-only C Wayland client, never a runtime dependency. Building it needs wayland-scanner, wayland-client, pkg-config and a C compiler. Keyboard input uses wtype. This XPS harness requires scale 1 and no rotation; unit tests cover logical geometry independently. The theme option applies another palette through real shell IPC and restores it in cleanup without changing theme/app files. The actions option exercises six real launchers. A browser can reuse an existing window; the harness never closes that existing window or its tabs.

Results and captures stay under ignored `artifacts/`. Review before sharing; personal wallpapers may be visible. Acceptance records identify the tested source. The Workbench companion remains optional and does not grant trust automatically.

Final physical-key check: Super+Alt+O, Right, Enter; then repeat with Escape and an outside click. On other hardware verify additional monitors, scale changes and hotplug. Do not infer those from a single-panel XPS result.

The optional `--agents` check uses real pointer clicks to open Agents and launch Codex, verifies the default-agent file is unchanged, closes only its new test terminal and captures still images. It sends no prompt or task. No video recording is performed.

Focused circular-menu check: `ORB_POINTER="$PWD/artifacts/input/pointer" node tests/live.cjs --menus-only --agents --settings`. The harness paces keyboard input and waits after surface mapping for compositor focus delivery.

Historical v0.1 check: `node tests/settings-live.cjs` exercised the old native settings panel. It changes size and animation through the UI, verifies Cancel and Save, restores the original values, checks screen bounds and verifies that no configuration editor opens. It assumes the XPS scale-1 layout used by the main live harness.

Historical v0.1 check: `node tests/slots-live.cjs` exercised all six slot drafts, cancellation, an installed Files app save/launch, Postcard save/reopen/launch, and panel bounds. It restores the configuration it started with; `--apply-postcard` deliberately retains Postcard in slot four on success. Keep the desktop idle during this input-driven check. It captures stills only. The older full-action harness assumes the default six-slot layout; use focused checks when you have customized it.

`./tests/native` also uses Lua to check desktop hit-testing and passthrough. `node tests/rightclick-live.cjs` checks real desktop right-click, left-click, the retained Super+right-click resize binding, and a Files context menu in a temporary workspace, then restores workspace/focus/pointer. Native binding contract: https://wiki.hypr.land/configuring/core/binds/#auto-consuming-binds-and-return--ok--false- .

Historical v0.1 check: `node tests/expanded-slots-live.cjs` starts with a six-slot configuration, verifies cancel/add/save/reopen for seven and eight slots, all eight pointer hit regions, the eighth action launch, and removal back to six. It restores the starting configuration and captures stills only.

`node tests/extras-live.cjs` checks a saved layout containing Make something cool: all pointer sectors, last-slot keyboard selection, its circular submenu and back navigation, and removal/Cancel without saving. It compares the starter prompts against the installed Agents panel and deliberately does not execute them.

`node tests/compact-live.cjs` checks 280px, 467px and 700px layouts on this XPS, growing pointer/keyboard captions, submenu captions and screen-edge clearance, then restores the original diameter without overwriting slot changes.

`node tests/preview-live.cjs` captures a real still on an empty workspace and restores workspace, pointer and focus. It rejects an intervening workspace change or visible application window; visually inspect the result before publishing. It does not record video.

`node tests/lifecycle-live.cjs` explicitly removes and reinstalls Orb on the live desktop. It backs up relevant configuration under ignored `artifacts/`, refuses a modified installed checkout, checks unload/owned-binding removal, compares configuration and unrelated settings, then tests a fresh Git reinstall and repeated install. It checks saved slots/appearance, three summon/Escape cycles and focus restoration. If removal starts but a check fails before reinstall finishes, it attempts reinstall in cleanup. It leaves Orb installed and retains backups. Physical key presses and action launches are separate checks.

`node tests/shapes-live.cjs` runs only in an owned nest. It checks Circle/Polygon draft, Cancel and save/reopen; removal down to five slots; polygon preview dragging; real pointer sectors and empty corners for five through eight entries; the circular centre; and three/two-entry submenus with back navigation. Captures and runtime hashes stay under ignored `artifacts/`. `tests/shapes.test.cjs` checks legacy defaults, shape persistence and validation, slot limits, and polygon hits against an independent convex-polygon check.
