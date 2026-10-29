Draft for Orb v0.3.0. Available on the development branch; not tagged or released.

Orb gains a touch home, named wheels and saved work setups for Omarchy.

- Switch between named wheels with fixed shortcut positions; create, rename and manage them in Settings → Wheels.
- Save app/workspace setups with normal tiling or equal columns, and split two touch-selected windows with ratios and side swapping.
- Export/import wheels with bundled custom icons and an explicit command review. Search opens Oma-Cast.
- Discover nine additional installed agents, retaining offline discovery and the existing default agent.
- Cover overlay output selection, deferred reveal, close races, reserved geometry and hotplug with regression tests.


- Open it from a movable edge button or your bar. Tap labelled favourites, open Oma-Cast search and manage windows from the same surface.
- Choose a left/right fan or full wheel, larger targets and optional drag selection. Hold a favourite to edit it. Compact screens keep a scrollable grid of large targets.
- Control brightness, sound, playback and network. Connect an enabled keyboard and Tablet Mode for typing, rotation and sensor-backed switching.
- Choose Desktop, Touch or Automatic. Existing settings keep their desktop behaviour; iPads and tablets without a fold sensor use Touch.
- Pick a custom icon from a local image, and use the larger shortcut editor controls. The optional extra mouse button supports tap-to-open or hold, point and release.

Thanks to Michal Mazurek for the original extra-button contribution. Hardware and keyboard integrations use the existing Tablet Mode and OmaTouch projects.

Physical touch, provider layering, ARM64/iPad hardware and the new mouse gesture still need native acceptance. Secure keyboard-free unlock needs support inside Omarchy’s lock screen. This release does not yet make Orb an official Omarchy default.

[Wheels and setups](WHEELS.md) · [Setup and QA](TOUCH.md) · [Acceptance evidence](ACCEPTANCE.json)
