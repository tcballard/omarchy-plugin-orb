Orb v0.4.0 brings touch and tablet navigation to Omarchy, shows every installed coding agent with its own icon, and fixes Orb on current Omarchy and Hyprland.

**Touch and tablet**

- Open a touch home from a movable edge button or your bar. Tap labelled favourites, open Oma-Cast search and manage windows from the same surface.
- Choose a left/right fan or full wheel, larger targets and optional drag selection. Hold a favourite to edit it. Compact screens keep a scrollable grid of large targets.
- Control brightness, sound, playback and network. Connect an enabled keyboard and Tablet Mode for typing, rotation and sensor-backed switching.
- Choose Desktop, Touch or Automatic. Existing settings keep their desktop behaviour; iPads and tablets without a fold sensor use Touch.
- The shortcut and action editors use larger, touch-sized controls.

**Agents**

- Each installed agent shows its own mark from Omarchy's Agents panel: Antigravity, OpenCode, Qwen Code, Copilot, Cursor, Kimi, DeepSeek, MiniMax and more.
- npm-installed agents such as OpenCode, Qwen Code, Kimi and Kilo now appear in the Agents menu.

**Fixes**

- Desktop right-click opens Orb again under current Omarchy's bar, including on named workspaces.
- The extra mouse button keeps working after Orb reloads or updates on Hyprland 0.57.1.
- Shortcuts and agents launch when Orb is installed under a path containing spaces.

**Known issues**

- If Orb's bar entry and an older menu entry are both in your shell settings, Disable leaves Orb loaded. Run `omarchy plugin disable io.github.tcballard.orb` a second time until Omarchy fixes this.
- Physical touch, ARM64/iPad hardware and secure keyboard-free unlock are not yet verified. This release does not make Orb an official Omarchy default.

Named wheels, import/export, saved work setups and split/swap controls are still deferred; existing saved data is kept. Hardware and keyboard integrations use the existing Tablet Mode and OmaTouch projects.

[Touch setup and QA](https://github.com/tcballard/omarchy-plugin-orb/blob/v0.4.0/docs/TOUCH.md) · [Acceptance evidence](https://github.com/tcballard/omarchy-plugin-orb/blob/v0.4.0/docs/ACCEPTANCE.json) · [Changelog](https://github.com/tcballard/omarchy-plugin-orb/blob/v0.4.0/CHANGELOG.md)
