# Orb v0.3.0 touch interface

## Agreed scope

Extend the existing v0.3.0 development branch with a keyboard-free navigation
surface: a reachable edge button, labelled radial favourites, an app grid,
window switching and management, quick controls, touch settings and explicit
Desktop / Touch / Automatic modes. Preserve existing desktop gestures and
configuration. This is one hosted plugin, not a replacement compositor.

Orb owns navigation and its configuration. One enabled Tablet Mode provider
owns folding, rotation and hardware input changes. An enabled on-screen keyboard
owns typing. Orb does not change monitor rules, disable input devices, install
dependencies, or intercept global touchscreen gestures.

## Contracts inspected

- Orb base: `8558b8447fb42b3fa6a2551925da6ae28dcbb888`.
- Omarchy: `573b518be16ec47547d50fe6197bc7f53e982340`, including the scoped
  plugin shell API, plugin discovery, dispatcher syntax and brightness command.
- Tablet Mode: `76c7833f5f96a189ee9d8975084b4607138f8cd3`, documented CLI
  `status`, `lock`, `rotate`, and `keyboard`. Only an enabled provider with
  `hasFoldSensor: true` and `folded: true` activates Automatic mode.
- OmaTouch 1.1.1: hosted overlay keyboard, no keyboard focus, masked floating
  card. Orb must remap it above an open Orb surface and provide typing space.

## Release acceptance

Portable tests and CI parsing are necessary, but do not establish physical touch,
layer-shell focus, provider compatibility, or ARM64 / iPad support. Required host
checks: launch and cancel by tap and drag; edit a shortcut with the keyboard;
switch, maximise, move and close windows; connect to Wi-Fi; rotate while open;
suspend, wake and unlock; switch back to Desktop; reload, disable and remove;
repeat with mixed scaling and an external display. Authenticate through the
existing secure lock surface. A normal plugin keyboard cannot bypass the lock.

Touch unlock is a separate core integration requirement: the inspected lock view
does not expose an on-screen keyboard. Orb must never weaken authentication or
pretend that launching a desktop keyboard solves secure unlock.

Global edge swipes, arbitrary device drivers and official-default adoption are
outside this plugin patch. An iPad needs a working graphical Linux session and
touch driver before the same interface can be tested there.

## Try the development branch

On Omarchy Quattro, install a committed checkout through the native manager:

```bash
git clone --branch v0.3.0 https://github.com/tcballard/omarchy-plugin-orb.git
cd omarchy-plugin-orb
omarchy plugin add "$PWD" --enable --yes
```

The local-source installer may normalize this repository’s Git origin for future
normal updates. Keep this checkout and reinstall it after `git pull` when testing
the branch; the public update command tracks the stable source. Do not overwrite
a modified installed checkout. Existing `orb.json` is retained.

Open Orb, select the centre for Settings, then **Touch → Touch → Save**. Choose
the tablet display explicitly if more than one output could match. Move the edge
button vertically by dragging it. Choose Left hand or Right hand and Edge fan or
Full wheel. To restore desktop behaviour, select **Desktop → Save**. Keyboard and
mouse opening bindings remain available.

Add Orb through Omarchy’s bar configuration for a reachable launcher before
enabling persistent Touch mode. Its button selects the bar’s display. The
equivalent diagnostic commands are:

```bash
omarchy-shell shell summon io.github.tcballard.orb '{"touch":true,"output":"eDP-1"}'
omarchy-shell io.github.tcballard.orb status
omarchy-shell shell hide io.github.tcballard.orb
```

Replace `eDP-1` with the actual output from `hyprctl -j monitors`. Omitting the new
fields from an existing configuration retains Desktop mode. Saved actions are
never reset. See `config.example.json` for validated touch settings.

## Providers

| Capability | Requirement | Without it |
| --- | --- | --- |
| Persistent navigation | Enabled Orb and a chosen output | Desktop wheel available |
| Automatic switching | Enabled Tablet Mode, real fold sensor, definite folded state | Choose Touch manually |
| Rotation | Enabled Tablet Mode CLI | Controls disabled |
| Keyboard | Enabled OmaTouch plus `wtype`, or a Tablet Mode keyboard | Visible error and Retry |
| Network | Omarchy Network panel enabled in the bar | Control disabled |
| Audio / media | `wpctl` / `playerctl` | Respective controls disabled |
| Brightness | `omarchy-brightness-display` and a supported display | Reports unavailable |
| Secure unlock | Input inside the secure lock surface | Physical keyboard or another working secure method required |

Automatic keyboard selection prefers OmaTouch. An explicitly selected provider
is honoured. Orb shows a keyboard on its own focused fields; it does not monitor
text focus in arbitrary apps. Show the keyboard before leaving Orb when needed
in another app. Hide keys dismisses the selected provider. Reserved typing space
records Orb’s own request, not a global visibility subscription. If the provider
is closed elsewhere, use Hide keys to clear it.

## Native QA handoff

Test a clean, committed candidate in an owned Omadev nest first. Record the SHA,
Omarchy source, Quickshell/Hyprland versions, architecture, outputs, scale,
rotation, provider versions and evidence path. Theme/UI stubs do not establish
Omarchy integration. Repeat touch-specific checks on physical hardware.

1. Run `./tests/native`, the editor and gesture harnesses, and the upgrade/fresh
   install harness from `DEVELOPMENT.md`. Verify old settings and metadata survive;
   check Cancel, Save and a conflicting concurrent edit.
2. Add Orb to the bar. Open it on each display while the mouse is elsewhere.
   Enable Touch, move the handle, reopen and restart the shell. Check all three
   modes and missing/disabled providers. Unknown fold state must not activate
   Automatic. A hand-written fold-state file is not hardware acceptance.
3. With actual touch, tap every favourite, cancel drags, long-press to edit, enter
   a submenu, change page, use Back and dismiss. Check both hands, ring/fan,
   5–8 favourites, large targets, portrait/landscape and the compact grid.
4. With OmaTouch and then the Tablet Mode keyboard, open Oma-Cast Search and launch an app;
   edit a command and submenu using the image chooser; Save/Cancel/reopen.
   Confirm the keyboard stays above Orb after changing panels, text reaches the
   intended field and controls remain reachable. Repeat after provider loss and
   restoration. Try app text entry and a Wi-Fi password in the native panel.
   Report core/provider limitations separately.
5. Switch windows and workspaces; restore a minimised window to the chosen
   display; maximise, move and close a disposable window. Stale windows and
   disconnected displays must not affect another target. Cancel a close
   confirmation and verify the window remains.
6. Check brightness on one output, sound, playback, rotation and rotation lock.
   Rotate during a press; selection must cancel. Check fractional scaling,
   dock/bar reservations, hotplug, selected-output loss, shell reload, disable
   and removal. No orphan handle, polling process or owned binding may remain.
   Preserve unrelated windows and settings.
7. On the tablet, remove the physical keyboard and test a complete session:
   first boot/login, apps, networking, suspend, wake and secure unlock.
   **Record a failure if secure touch input is unavailable.** The inspected core
   lock screen has no keyboard. This is an external blocker for a complete
   keyboard-free tablet claim, not a passed Orb test.

For Tom’s iPad mini 4, a Linux shell over USB is insufficient for acceptance.
Graphics, a Quattro session, touch mapping and a keyboard provider must work on
the device. ARM64/iPad acceptance remains pending until tested there.

## Becoming Omarchy’s tablet default

This release supplies hosted navigation and explicit activation. Official
adoption needs an upstream decision after native acceptance. Proposed policy:

| Device profile | Initial choice | Return to desktop |
| --- | --- | --- |
| Dedicated tablet / iPad with working touch | Touch on the verified internal display | User selects Desktop |
| Convertible with verified fold sensor | Automatic through one Tablet Mode owner | Unfolding restores Desktop |
| Touch laptop without reliable fold sensor | Offer Touch during setup | User-controlled mode |
| Multiple/unidentified touch outputs | Ask for display selection | Preserve explicit choice |
| Desktop without touch | Desktop | No change |

Upstream setup would enable Orb and one keyboard provider, preserve existing
settings and expose the choice during setup. It must not infer folding from a
touchscreen or a disconnected mouse. Gate rollout on secure login/unlock,
suspend/resume, accessible input, output mapping, provider recovery, battery/idle
observations and a documented route back to Desktop. This plugin release does
not change the upstream installer or global default.

Named wheels, saved setups, import/export and touch window pairs have a separate [operation and acceptance checklist](WHEELS.md).
