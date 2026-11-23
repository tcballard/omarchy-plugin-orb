# Orb architecture

`io.github.tcballard.orb` declares `menu` and `bar-widget`, mapping to the hosted `Item` in `Wheel.qml` and the optional `TouchWidget.qml` bar entry. There is no standalone Quickshell or external daemon, Rust helper, Python, network or privileged operation.

Sections below are by subsystem. Each states the owning files first; behaviour notes follow.

## File map

| Area | Files |
|---|---|
| Menu root and state | `Wheel.qml` (open/close, selection, submenus, launching, settings save flow, gesture glue) |
| Overlay surface | `OrbOverlay.qml` |
| Bindings | `BindingSetup.qml`, `BindingLifecycle.js`, `scripts/setup`, `scripts/mouse-binding.lua`, `desktop-click.lua` |
| Mouse-button gesture | `Gesture.js` (pure state machine); glue in `Wheel.qml` |
| Validation and geometry | `Model.js` (config, actions, merge, hit-testing, placement, helper paths) |
| Drawing | `WheelSurface.qml`, `LineIcon.qml`, `ActionIcon.qml`, `assets/` |
| Settings editor | `SettingsPanel.qml`, `ActionEditor.qml`, `ActionPicker.qml`, `WheelPreview.qml`, `ShortcutHistory.js`, `Editor*.qml` |
| App catalog | `AppLibraryCompat.qml` |
| Touch | `TouchModel.js`, `TouchBackend.qml`, `TouchHome.qml`, `TouchWheel.qml`, `TouchHandle.qml`, `TouchWidget.qml`, `TouchOptions.qml`, `TouchButton.qml`, `scripts/touch` |
| Launch helpers | `scripts/launch`, `scripts/agents`, `scripts/agent`, `scripts/files` |
| Release tooling (not runtime) | `scripts/check.mjs`, `scripts/archive.mjs`, `scripts/common.mjs` |

QML resolves every bundled helper through `Wheel.helper(name)`, which URL-decodes via `Model.localPath`; do not strip `file://` by hand.

## Menu host and overlay

The menu loader retains ownership of the shell facade. It exposes `open(payloadJson)`, `close()` and `opened`. `keepLoaded` avoids repeated construction and permits a 120ms launch handoff after unmapping. One keep-loaded menu owns the edge handle and bounded touch processes.

`OrbOverlay.qml`, built on Quickshell's `PanelWindow`, owns the focused-monitor surface and scale readiness. It retains the screen for each opening and waits for fullscreen geometry and matching output scale before revealing content. This avoids importing `qs.Ui.OverlayWindow`, which is absent in Omarchy 4.0.6.

The desktop wheel uses exclusive keyboard focus while open. Settings and the touch home use on-demand focus and respect reserved space so a hosted keyboard can retain its target. Cancellation clears pointer sampling and pending launches, unmaps the layer and lets Hyprland restore focus. Completed actions hide before launching. Repeated summon resets one surface; toggle cancels it.

## Placement, selection and appearance

`hyprctl -j cursorpos` runs once per summon; failure falls back to monitor centre. `Model.js` clamps logical coordinates against reserved edges and tests radial hit regions. Placement reserves the scaled footer height when keeping Orb inside the monitor. Selection starts neutral; sectors run clockwise from Browser at the top. `PointerMoveGate` prevents stationary pointer events replacing keyboard selection.

Five to eight top-level actions are supported, with six as the default. Radial placement and hit-testing use the current count, with narrower labels above six. Sectors contain centred icons at every wheel diameter; there are no in-sector labels or size breakpoint. The footer displays the full selected action label for both pointer and keyboard selection, including submenus. Its text, padding and pagination controls scale proportionally above the default 280px rendered diameter, retaining a readable minimum at smaller sizes.

The compact wheel defaults to 240 theme units. Small, Medium and Large select 240, 360 and 480; they stage the existing `diameter` setting, so custom values and the fine-adjustment slider share its validation, concurrent-edit protection and save/cancel flow.

`WheelSurface.qml` draws the shared circle/polygon outline and sectors for the live wheel and draft preview. Polygon vertices align with the visible actions; `Model.edgeRadius` supplies the same boundary for drawing and pointer/drag hit-testing. The hub is always circular. Submenu pages use their own visible count; pages with one or two entries retain a circular outline. The optional `shape` setting defaults to `circle` for existing configurations and follows the normal appearance draft/merge flow.

Theme, typography, spacing and reduced-motion tokens are live bindings. Animation durations use the newer `Style.duration` when available and the configured duration otherwise. Canvas redraws on palette/selection changes. `LineIcon.qml` draws original vector paths. `ActionIcon.qml` renders agent marks from the installed Omarchy's Agents panel (`$OMARCHY_PATH/shell/plugins/agents/assets`), so newly supported agents pick up Omarchy's icon without an Orb change. Like that panel, light menu backgrounds try the `<id>-light.svg` twin first. `scripts/agents` names each agent's mark in its catalogue; `Model.agentMarks` lists the accepted ids, which stay out of the icon picker. Bundled Codex/Claude/Grok copies cover shells without those assets, and the generic icon covers agents with no mark or a failed load. Selected captions use the shell menu text colour; selected drawn shortcut icons remain white. Installed app icons retain native colours, and wheel selection surfaces use the shell menu palette. The main hub uses a theme-accent glow on hover or Home-key selection.

## Configuration and launching

`~/.config/omarchy/orb.json` owns durable configuration, watched by FileView. Five to eight bounded top-level actions are validated, with one optional submenu level or a dynamic built-in menu (`agents`, `files`). All displayed labels are plain text. IPC payloads cannot provide commands or file paths. The status IPC is read-only and includes editor control bounds for real-input acceptance tests.

Configuration is trusted local code: `scripts/launch` executes argv without eval and notifies on missing/failed commands. Apps run independently of the shell's lifetime. No new shell-string execution is introduced anywhere in the editor.

## Bindings and lifecycle

Normal `omarchy plugin add ... --enable` loads the keep-loaded menu. `BindingSetup.qml` owns registration: it creates a per-instance owner token, re-runs `scripts/setup` (debounced) only when `Model.bindingSignature` changes or Hyprland reloads its config, reports bounded errors, and on unload passes `BindingLifecycle.cleanup(owner)` directly to `hyprctl eval`, independent of the deleted checkout. Errors surface in Orb settings with Retry; a failed setup summons Orb so the error is reachable.

`scripts/setup` creates missing settings with a no-clobber hard link, then registers session-only Hyprland Lua binds. Tombstones reject a late apply after teardown; generation ordering rejects stale instances. Unchanged keyboard, desktop and mouse-button handles are retained when adopting a new owner or changing activation settings. Only changed bindings are created and superseded handles removed. Older Hyprland removed all bindings for the same key when removing a handle, so this prevents a repeated setup from deleting its own replacement; Hyprland 0.57.1 removes only the given handle, and both behaviours are tested. No standalone service or persistent binding config is needed. A hard shell crash can leave runtime handles until the shell restarts or Hyprland reloads.

Opening settings are normalized/validated by `Model.js` using the same key grammar as `scripts/setup`. Before writing activation changes, the menu reads live `hyprctl binds -j` and rejects conflicting keyboard, desktop or mouse-button bindings. The setup helper repeats that check before registration.

The old installer's exact unmodified module/include migrates with backups and reload/error rollback. Modified modules remain untouched. Local-source Git origins are changed only when that source's own origin is this exact public repository, allowing later normal plugin updates. Config and unrelated desktop settings are preserved. Contracts checked against Omarchy `81fd2d23ca6e3462183a4dc8360de3113fa8d80c` and Hyprland `12f242511a9c0fe8a884a9d90511bbbbe044f067`.

## Mouse-button gesture

The opt-in extra-button gesture owns a press/release pair through the same Hyprland Lua binding registry as the shortcut. Primary, secondary and middle mouse buttons are excluded; button codes 275–511 are explicit local settings. Conflicts across modifiers fail before registration. The two handles are retained and removed as one unit; removal calls `remove()` on both press and release, because Hyprland 0.57.1 no longer clears the release binding when the press is removed. Failed release registration removes the staged press and leaves the previous key intact. An old development-only mouse binding on the same key requires a shell restart for migration.

Hyprland emits owner-scoped custom socket events carrying pointer coordinates on press, movement and release. A single compositor timer samples only while held and stops on release, removal, owner change or a six-second timeout. This avoids relying on the overlay receiving a Wayland mouse release from another surface. `Gesture.js` validates each event and decides the outcome; `Wheel.qml` retains the press position for placement and uses the captured release position for the same radial hit test as clicking. A quick stationary tap opens the wheel; a longer stationary hold, centre or outside release cancels. A released submenu remains open. The menu's watchdog clears an incomplete interaction. Live acceptance is still required: the Lua API contract was checked against Hyprland `efb50993780079460b0cbed1363e2166a2de1d9f`; portable fixtures do not establish real compositor or pointer behaviour.

## Desktop right-click

Optional `desktopRightClick` registers the callback from `desktop-click.lua` for the enabled menu's lifetime. The unmodified right-button binding checks the pointer against windows on the active workspace and non-background layers. It uses the documented `auto_consuming` callback result so clicks over applications pass through. Background renderers (including Wallpaper Engine) count as desktop. Special workspaces and unknown geometry fail closed. There is no input daemon or additional surface for right-click handling. Existing unmodified right-click bindings block installation rather than being overwritten.

## Submenus and built-in menus

Submenus reuse the same circular geometry, position and diameter; their centre button returns to the main wheel. They page in groups of six using footer arrows, scrolling or Page Up/Down. Escape/Left/Backspace returns to the wheel; outside click closes the entire interaction. Submenu hubs navigate back.

Agents: `scripts/agents` performs one read-only mise inventory query plus executable checks, excluding auto-install stubs. `scripts/agent` launches an installed client in Omarchy's agent terminal with the selected account, without changing the default agent or submitting a prompt.

Files: `"menu": "files"` uses the same submenu/paging behaviour. `Model.fileActions` supplies nine fixed locations with distinct vector icons. `scripts/files` resolves Home and XDG user directories at activation time, then launches Nautilus with one literal path or Recent/Starred/Trash URI, using Omarchy's setsid/uwsm-app handoff. Unknown locations and unavailable directories fail without launching. Validation normalizes only the original top-level Files command into this menu, without rewriting its saved document; app entries, custom paths, renamed commands and leaf commands inside user submenus remain unchanged.

Make something cool: the optional catalog entry contains the same three starter prompts as Omarchy's Agents panel. It uses normal one-level children and the supported `omarchy agent prompt` CLI, so the default agent/account and existing terminal launch behaviour stay with Omarchy.

Search hands off to `typecraft.oma-cast` after dismissal. Postcard uses its installed manifest ID `tahayvr.postcard` with an empty summon payload to open the editor.

## App catalog

The menu-scoped `shell.appLibrary` supplies installed entries, labels and icon sources. Picker choices persist desktop IDs rather than guessed Exec strings, and `appLibrary.launch` runs after the same 120ms unmap handoff.

`AppLibraryCompat.qml` delegates to that service when present. Omarchy 4.0.6's panel model can pass QVariantList kinds to a host check that requires a JavaScript array, omitting the service for menus. In that case Orb uses Quickshell's desktop-entry index, the shell's configured/desktop hide lists and icon lookup, and launches through the literal `setsid uwsm-app -- gtk-launch <id>.desktop` path after dismissal. Application-list changes update an open picker without discarding its search or the settings draft.

## Settings editor

Activating the main hub opens a compact `SettingsPanel.qml` inside the same overlay, centred in the focused screen's usable area with a margin beyond reserved bar space, independent of the pointer and wheel position. The header reads the installed manifest version.

Drafts and saving: slot choices, appearance and activation settings stay in a draft until Save; Cancel discards it. Draft origin arrays track each top-level action and submenu child, so moving/editing canonical fields retains unknown metadata. On Save the latest configuration is re-read and `Model.mergeSettings` performs a three-way merge: only edited fields and slots are merged, preserving custom metadata and concurrent edits to untouched slots; external edits to changed slots, structural changes and opening/appearance fields are rejected. FileView writes atomically with success/failure handling. An unchanged save finishes explicitly because FileView does not emit `saved` for identical text; a watchdog recovers failed saves.

Slots: all slots share the same picker, while menu shortcuts retain their submenus. The panel can append a seventh/eighth slot and remove entries down to five; the slot list scrolls to keep the panel compact. `WheelPreview.qml` supports pointer drag/release and click editing; `SettingsPanel.qml` also offers keyboard and button reordering. `ActionEditor.qml` edits commands as separate argv fields and lazily loads a child editor for submenu leaves.

Catalog: `ActionPicker.qml` supplies the shared searchable catalog for the action editor and the browser beside the wheel. Browser drags remain inside the hosted overlay: pointer coordinates map to `WheelPreview.qml` and use its radial hit regions. The target sector highlights before release; dropping in the centre or outside cancels. Click, keyboard and drag assignment use the same path, updating the draft and its child origins while retaining the slot's original metadata identity. Search has a separate focus target; leaving it restores keyboard navigation to the slot panel. The compact layout keeps the picker and wheel beside each other when space permits, with separate scrolling inside the catalog.

Undo: `ShortcutHistory.js` stores up to forty independent snapshots of shortcut actions, origin arrays and selection. Undo or Ctrl+Z restores the last shortcut edit, retaining appearance and activation drafts. Editor text fields keep their native Undo, and history clears when Settings begins a new draft.

Layout: Settings uses native tab-focusable buttons and fields; the scrollable body keeps focused controls visible and leaves Save/Cancel reachable. It captures its opening height after the initial Shortcuts layout settles; tabs, action editors, added rows and error messages keep that frame, with overflow scrolling inside it. The available monitor height still caps the panel when the display changes.

## Touch

`TouchModel.js` supplies mode selection, deterministic display choice, radial geometry and press/move/release state. Explicit output wins; otherwise a unique internal display or the only connected output is selected. Ambiguous outputs require a choice. Touch openings never sample the mouse position. A display disappearing closes the interaction. Layout changes cancel a pending selection; hold-to-edit cannot also launch. A scrollable grid retains target size when a fan or ring cannot fit.

`TouchHandle.qml` maps only while the configured touch mode is active and Orb is closed. It takes no keyboard focus and reserves no band. Its vertical position uses the existing three-way settings merge. `TouchWidget.qml` is an optional bar entry that opens the same menu on the bar's output. `TouchHome.qml` reuses favourites, submenus, app-library launching and the draft editor. Window closes require a second tap. Window targets are revalidated immediately before dispatch; minimised windows restore to the selected display's current workspace before focus and stacking.

`TouchBackend.qml` is the single process owner inside the keep-loaded menu; `Wheel.qml` passes it the resolved `scripts/touch` path. The view's generation rejects late completions; cancellation stops its action and window query. Helpers bound stdout, runtime and errors. Automatic mode polls at five seconds and watches the provider's fold-state file as a refresh hint, never as authorization. Window snapshots refresh at three seconds only while a touch view or settings is open. Actions are serialized, timeouts remain failures and a requested keyboard can queue behind an in-flight action.

`scripts/touch` accepts a closed set of typed operations. It validates window addresses, workspace IDs, connected monitor names and selected providers before constructing literal dispatcher arguments. Cross-plugin operations use `omarchy-shell shell listPlugins` and canonical CLI calls, never foreign shell service objects. Exit-zero `unknown`/dispatcher errors are failures. Tablet Mode owns folding, rotation and hardware input changes. OmaTouch or Tablet Mode owns the keyboard. Missing or disabled providers yield actionable errors, not automatic installation.

Touch text fields use `EditorField.qml`; editor and touch controls have at least 48px height. `ActionEditor.qml` opens a local image chooser while retaining the validated absolute-path input. The touch home reserves typing space because OmaTouch's floating keyboard does not advertise an exclusive zone. After an Orb surface is remapped, an already requested keyboard is hidden and summoned again above it. This is provider-specific desktop layering, not a lock-screen implementation.

Legacy configurations default to Desktop. Touch and Automatic are explicit saved choices. Automatic requires enabled Tablet Mode plus a real fold sensor and a boolean folded observation; missing/unknown state does not change input devices or activate touch mode. The inspected contracts and physical acceptance requirements are recorded in [TOUCH.md](docs/TOUCH.md). No architectural change here establishes iPad kernel, graphics, touch-driver or secure-unlock support.

## Deferred

- v0.4.0 uses one shortcut layout from the top-level `actions` field. Named-wheel libraries, transfers, saved work setups and window pairs are deferred ([WHEELS.md](docs/WHEELS.md)). The settings merge retains unknown wheel/setup fields unchanged, including during shortcut edits. Old setup-menu slots remain valid inert placeholders with an explanatory message and can be replaced in Settings; no setup or pair helper command is available. Placeholders are marked `DEFERRED(wheels-setups)` in code.
- Deeper submenu nesting.
- Physical multi-monitor acceptance.

## Provenance

The repository starts from the user's starter `0605227`; `.template/blueprint` is unchanged. Conventions were checked against installed Omarchy `5f7aaeb8c`, its active `dock-controls-desktop` checkout, and the upstream shell reference. Existing unrelated source edits were preserved.
