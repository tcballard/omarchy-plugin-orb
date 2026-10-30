# Credits and provenance

**Interaction inspiration: Tangerine for Mac**, as specified by the user. Orb's QML implementation and general-purpose line icons are original; the agent marks below are third-party branding. No Tangerine code, artwork or branding is included.

Size presets and direct assignment from an action picker also take interaction inspiration from [Logitech Actions Ring](https://support.logi.com/hc/en-gb/articles/17844647906967-Actions-Ring), suggested by the user. Orb implements these interactions independently in Omarchy's hosted QML.

The optional extra mouse-button support starts with [Michal Mazurek's contribution](https://github.com/tcballard/omarchy-plugin-orb/compare/main...MichalMazurek:optional-mouse-button), shared in [issue #13](https://github.com/tcballard/omarchy-plugin-orb/issues/13). The v0.3.0 branch builds the hold-and-release interaction on that work.

The Omarchy 4.0.6 compatibility fix follows [sanjithdoescode's diagnosis and PanelWindow proposal](https://github.com/sanjithdoescode/omarchy-plugin-orb/pull/1), reported in [issue #10](https://github.com/tcballard/omarchy-plugin-orb/issues/10). `OrbOverlay.qml` adapts Omarchy's [OverlayWindow at 57e4d3d1294e02dd3866a066e2f7276bd86c9938](https://github.com/tcballard/omarchy/blob/57e4d3d1294e02dd3866a066e2f7276bd86c9938/shell/Ui/OverlayWindow.qml), retaining screen selection, scale readiness and monitor-removal handling without importing that newer shell component. The MIT notice is retained in [assets/agents/LICENSE.omarchy](assets/agents/LICENSE.omarchy).

Template authorship: Tom Ballard, 2026, MIT. Project author: Tom Ballard.
- Plugin conventions: [Build Omarchy Plugins](https://github.com/tcballard/build-omarchy-plugins).
- Community badge: [omarchy-badges](https://github.com/tcballard/omarchy-badges), pinned to 75975e5b5bf75e7ede3764bcd2950046f7abfe2c.
- Test-only virtual pointer protocol: copyright 2019 Josef Gajdusek, MIT. Full licence remains in tests/virtual-pointer.xml. [Upstream protocol](https://gitlab.freedesktop.org/wlroots/wlr-protocols/-/blob/master/unstable/wlr-virtual-pointer-unstable-v1.xml).

`preview.png` is a real cropped Orb capture in an owned Omadev session on the XPS, including a portion of the active wallpaper. Tom Ballard confirmed on 2026-10-19 that he made the wallpaper and owns or has permission to submit the plugin and preview assets. It is a product screenshot, not a separately distributed wallpaper asset. Unpublished local test captures remain under ignored `artifacts/`. The current Settings captures use the default six shortcuts in Polygon mode; dimensions and hashes are recorded in [the acceptance evidence](docs/ACCEPTANCE.json). Earlier editor images retain their separate [capture record](docs/CATALOG-ACCEPTANCE.json).

## Agent marks

The unmodified SVG files in `assets/agents/` are copied from Omarchy’s agents panel at [27d215832cfb74d252d4cfed8519f645c76d8d9c](https://github.com/tcballard/omarchy/tree/27d215832cfb74d252d4cfed8519f645c76d8d9c/shell/plugins/agents/assets). The upstream MIT notice is retained in `assets/agents/LICENSE.omarchy`.

- Codex mark: OpenAI; white and dark variants. [Brand information](https://openai.com/brand/).
- Claude mark: Anthropic; original orange colour. [Claude](https://claude.com/).
- Grok mark: xAI; white and dark variants. [Brand information](https://x.ai/legal/brand-guidelines).

These marks identify the corresponding installed agent clients. They remain their owners’ trademarks and do not imply endorsement. They are not original Orb artwork. No assets are fetched at runtime.

## Omarchy centre mark

`assets/omarchy-logo.svg` is the unmodified official SVG downloaded from [Omarchy’s brand assets](https://omarchy.org/brand/omarchy-logo.svg) on 2026-10-18. The wheel renders it in the active menu text colour using Quattro’s existing Qt Quick colourization pattern. Omarchy branding belongs to its respective owners; its use identifies the desktop integration and does not imply endorsement.

## Make something cool

The three theme/plugin/app starter prompts are reused from [Omarchy’s Agents panel](https://github.com/tcballard/omarchy/blob/301ea47016e28df527825cbd417e084fdd612405/shell/plugins/agents/Panel.qml), as installed locally when implemented. Omarchy’s MIT notice is retained in [assets/agents/LICENSE.omarchy](assets/agents/LICENSE.omarchy). Orb supplies its own circular presentation and calls the native `omarchy agent prompt` launcher.
