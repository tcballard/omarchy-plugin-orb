# Orb v0.3.0 — feature and setup summary

This is background for the owner's release notes, not the final announcement.

## What was built

- **Custom icons:** choose a local SVG, PNG, JPEG or WebP image for custom commands and submenus through the image chooser, or use the expanded built-in icon set. Missing local images fall back to a generic icon.
- **Extra mouse-button gestures:** tap an optional extra button to open/dismiss Orb; hold, point and release to launch once. Centre/outside releases cancel; submenus remain open for a second selection. Conflict checks protect existing bindings.
- **More installed coding agents:** adds Qwen Code, DeepSeek Harness, MiniMax Code, Kiro CLI, Freebuff, Kilo, Devin CLI, Amp and Command Code. Discovery is offline, ignores installer wrappers, and does not install agents or change the default agent.
- **Desktop reliability:** retains keyboard and desktop right-click activation, saved settings and existing shortcut layouts, with overlay/output lifecycle regression coverage.

Credit Michal Mazurek for the original extra mouse-button contribution.

Touch/tablet support is reserved for v0.4.0. Named wheels, wheel transfers, saved work setups and split/swap controls are deferred beyond that. Existing data is retained.

## User setup after the PR is merged

New installation:

```bash
omarchy plugin add https://github.com/tcballard/omarchy-plugin-orb.git --enable
```

Existing installation:

```bash
omarchy plugin update io.github.tcballard.orb
```

Normal installation/update tracks `main`. A modified or divergent development checkout may need reconciliation before a normal update; do not discard local changes.

1. Open Orb with **Super+Alt+O**, then click its centre to open Settings.
2. For a custom icon, edit a custom command or submenu under **Shortcuts**, choose **Choose image…**, select a local image, apply the edited action and **Save**. Keep that image at the saved path.
3. For the optional gesture, open **Opening**, enable the extra mouse button, choose its button code and **Save**. The default code is **277**; the actual code depends on the mouse (`wev`, if installed, can identify it). The chosen extra button is consumed across applications while enabled; left/right/middle clicks remain available.
4. For agents, install and authenticate the agent using its own setup instructions first, then reopen Orb's Agents menu. Orb only discovers existing installations; no default-agent change or extra Orb configuration is required.

Existing users do not need a settings migration or to enable the new mouse gesture. No touch/tablet setup applies to this release.

## Owner release steps

Use **Create a merge commit** for PR #16 so the accepted source remains in ancestry. Write the release notes yourself, either by updating `docs/RELEASE-NOTES.md` before running the release workflow or by replacing the draft's notes before publication. Run **Release source** on `main` with tag `v0.3.0`, the exact final main SHA and **allow_pending_live=true** for the owner-accepted coverage gaps. Check the successful workflow and draft assets, then publish the draft. See `CUT-RELEASE.md` for details.
