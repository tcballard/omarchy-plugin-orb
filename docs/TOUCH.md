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
