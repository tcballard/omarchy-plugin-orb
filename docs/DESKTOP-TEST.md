# Test the v0.3.0 candidate on your desktop

Use your normal Omarchy session. No Omadev is required. The automated `*-live.cjs` harnesses have separate nest guards; leave those guards intact and use this manual checklist instead.

The installed copy checked on 2026-10-30 was `db10153`, the older development build. Its `0.3.0` version label does not prove it is this release candidate. Verify the commit below.

## 1. Back up and install the candidate

Run this block in a terminal. It refuses modified or linked checkouts, backs up your installed Orb and settings, then uses the normal plugin **update** command against the local release checkout. It restores the original Git remote afterward. It does not install from public `main`.

```bash
bash <<'BASH'
set -euo pipefail
source=/home/tcballard/omarchy-plugin-orb-release
installed="$HOME/.config/omarchy/plugins/io.github.tcballard.orb"
config="$HOME/.config/omarchy/orb.json"
id=io.github.tcballard.orb
[[ $(git -C "$source" branch --show-current) == release/v0.3.0 ]]
[[ -z $(git -C "$source" status --porcelain) ]]
[[ $(cat "$source/VERSION") == 0.3.0 ]]
[[ -d "$installed/.git" && ! -L "$installed" ]]
[[ -z $(git -C "$installed" status --porcelain --untracked-files=all) ]]
candidate=$(git -C "$source" rev-parse HEAD)
original_origin=$(git -C "$installed" remote get-url origin)
backup=$(mktemp -d "$HOME/orb-release-test.XXXXXX")
cp -a "$installed" "$backup/plugin"
if [[ -f $config ]]; then cp -a "$config" "$backup/orb.json"; else touch "$backup/no-original-config"; fi
omarchy plugin list --json > "$backup/plugins-before.json"
printf '%s\n' "$candidate" > "$backup/candidate-sha.txt"
printf '%s\n' "$original_origin" > "$backup/origin.txt"
printf 'BACKUP AND TEST RECORD: %s\n' "$backup"
trap 'git -C "$installed" remote set-url origin "$original_origin"' EXIT
omarchy plugin disable "$id"
git -C "$installed" remote set-url origin "$source"
omarchy plugin update "$id" --yes
[[ $(git -C "$installed" rev-parse HEAD) == "$candidate" ]]
omarchy plugin enable "$id"
omarchy-shell shell rescanPlugins
printf 'Installed candidate: %s\n' "$candidate"
omarchy version > "$backup/omarchy-version.txt"
hyprctl version > "$backup/hyprland-version.txt"
hyprctl monitors -j > "$backup/monitors.json"
BASH
```

Keep the printed backup path. If a check fails, stop and keep the terminal output; the rollback section restores the previous copy. The original remote is restored even if the update fails.

Open Orb with **Super+Alt+O**. Settings should have **Shortcuts, Appearance and Opening**, with no Touch or Wheels tabs. Your existing shortcuts should still be there. The v0.4.0 source checkout is untouched.

## 2. Check the user-facing features

Record pass/fail and any reproduction steps. A single-monitor result only establishes that display/scale scope.

| Area | What to do | Expected result |
| --- | --- | --- |
| Open and close | Open by keyboard; use arrows/Enter; close with Escape and outside click. Repeat near each screen edge. | No clipping or stuck overlay; focus returns to the previous app. |
| Existing actions | Launch an installed app and a Files location. Open and return from a submenu. | Correct app/location opens after Orb disappears. |
| Settings | Change a slot and appearance, Cancel, then repeat and Save. Reopen. Try Undo. | Cancel preserves the old state; saved edits and Undo work. |
| Custom icons | Edit a harmless custom command (for example `notify-send` with a separate argument `Orb test`). Use **Choose image…** for a local SVG/PNG. Save, reopen and launch it. Repeat for a submenu. | Chosen image renders and persists; command arguments are preserved. Canceling the chooser leaves the icon unchanged. |
| Missing image | Use a disposable copy of an image, save it, then rename that copy. | Orb remains usable and falls back to a generic icon. Restore or reselect the image afterward. |
| Mouse gesture | In Opening, enable an unused extra button. Tap twice. Hold, point to a shortcut and release. Release in the centre and outside. Try a submenu. | Tap opens/dismisses; directional release launches once; centre/outside cancel; submenu opens without launching a child. |
| Application input | Repeat the gesture over a normal app. Test normal left/right/middle clicks, keyboard activation and your existing desktop right-click option. | Only the configured extra button is consumed. Existing controls remain usable. |
| Conflicts | Try a button already assigned by your desktop, if one exists. Cancel afterward. | Orb reports the conflict and leaves that binding and the saved configuration intact. Do not create a conflicting system binding just for this check. |
| Agents | Open Agents. Launch the installed agents you actually use, including any newly supported one. Exit without submitting a prompt. Compare your default agent before/after. | Installed agents launch interactively; absent agents are not offered or installed; the default is unchanged. List exactly which agents you tested. |
| Lifecycle | Disable and enable Orb, then restart the shell using `omarchy restart shell`. Reopen and repeat one launch/gesture. | No duplicate bindings, lost settings or stuck mouse button. |

The added agent entries are Qwen Code, DeepSeek Harness, MiniMax Code, Kiro CLI, Freebuff, Kilo, Devin CLI, Amp and Command Code. You do not need to install agents just to test Orb; record unavailable ones as untested.

## 3. Removal and fresh-install check

The first step already exercises the plugin manager's upgrade path. For fresh-install/removal acceptance, finish the feature checks first and keep the backup from step 1. This removes only the installed Orb plugin and temporarily sets aside its settings.

Run in a terminal, replacing the backup path:

```bash
bash <<'BASH'
set -euo pipefail
backup="$HOME/orb-release-test.REPLACE_ME"
source=/home/tcballard/omarchy-plugin-orb-release
config="$HOME/.config/omarchy/orb.json"
id=io.github.tcballard.orb
[[ -f "$backup/candidate-sha.txt" && -d "$backup/plugin" ]]
[[ ! -e "$backup/before-fresh-orb.json" ]]
[[ $(git -C "$source" rev-parse HEAD) == $(cat "$backup/candidate-sha.txt") ]]
[[ -z $(git -C "$source" status --porcelain) ]]
[[ -z $(git -C "$HOME/.config/omarchy/plugins/$id" status --porcelain --untracked-files=all) ]]
cp -a "$config" "$backup/before-fresh-orb.json"
omarchy plugin remove "$id" --yes
cmp "$config" "$backup/before-fresh-orb.json"
printf 'Removal retained Orb settings. Confirm the Orb shortcut no longer opens it.\n'
read -r -p 'Press Enter after checking removal: ' </dev/tty
mv "$config" "$backup/retained-orb.json"
omarchy plugin add "$source" --enable --yes
[[ $(git -C "$HOME/.config/omarchy/plugins/$id" rev-parse HEAD) == $(cat "$backup/candidate-sha.txt") ]]
printf 'Test fresh defaults, open/close, and one app launch now.\n'
read -r -p 'Press Enter to restore your pre-fresh-test Orb settings: ' </dev/tty
omarchy-shell shell hide "$id"
cp -a "$config" "$backup/fresh-generated-orb.json"
cp -a "$backup/before-fresh-orb.json" "$config"
git -C "$HOME/.config/omarchy/plugins/$id" remote set-url origin "$(cat "$backup/origin.txt")"
omarchy-shell shell rescanPlugins
BASH
```

Confirm unrelated desktop shortcuts/configuration still work. If interrupted, use the rollback below; all original data remains in the backup.

## 4. Record the result

Send the candidate SHA and your pass/fail notes, including agents tested, display/scale, and any skipped checks. Logs can be captured with `omarchy-shell io.github.tcballard.orb status` and the version/display files in the backup. Do not mark skipped checks as passed. These are valid owner-reported native results; they do not need an automated nest run.

Afterward run `./tests/native` from the release checkout in your terminal and the Qt command in `docs/DEVELOPMENT.md`. The archive test has encountered a child-process `EPERM` in the agent environment; keep any failure output from your terminal rather than assuming it passes there.

## Roll back to your original Orb

Use this only to undo the candidate test. It retains the tested plugin and settings in the backup before restoring the original copy. Replace the backup path. Do not use it after making unrelated edits to the installed plugin.

```bash
bash <<'BASH'
set -euo pipefail
backup="$HOME/orb-release-test.REPLACE_ME"
id=io.github.tcballard.orb
installed="$HOME/.config/omarchy/plugins/$id"
config="$HOME/.config/omarchy/orb.json"
[[ -d "$backup/plugin/.git" && -f "$backup/plugins-before.json" ]]
[[ ! -e "$backup/tested-plugin" && ! -e "$backup/tested-orb.json" ]]
if [[ -e $installed ]]; then
  [[ ! -L $installed && -d "$installed/.git" ]]
  [[ -z $(git -C "$installed" status --porcelain --untracked-files=all) ]]
  current=$(git -C "$installed" rev-parse HEAD)
  [[ $current == $(cat "$backup/candidate-sha.txt") || $current == $(git -C "$backup/plugin" rev-parse HEAD) ]]
  omarchy plugin disable "$id"
  mv "$installed" "$backup/tested-plugin"
fi
cp -a "$backup/plugin" "$installed"
if [[ -f $config ]]; then mv "$config" "$backup/tested-orb.json"; fi
if [[ -f "$backup/orb.json" ]]; then cp -a "$backup/orb.json" "$config"; fi
omarchy-shell shell rescanPlugins
if jq -e --arg id "$id" 'any(.[]; .id == $id and .enabled)' "$backup/plugins-before.json" >/dev/null; then
  omarchy plugin enable "$id"
else
  omarchy plugin disable "$id"
fi
BASH
```
