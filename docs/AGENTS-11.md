# Expanded Agents menu

Issue: https://github.com/tcballard/omarchy-plugin-orb/issues/11

Contract reviewed on 24 October 2026 against Omarchy's `quattro` development commit `4e46082b289e34d99313fcdd7a6507ea7450e429`, after upstream PR #14040. This is not a claim that the expanded roster has shipped to stable.

Entry points follow [omarchy-agent](https://github.com/omacom/omarchy/blob/4e46082b289e34d99313fcdd7a6507ea7450e429/bin/omarchy-agent), with Orb's existing policy of no added permission-bypass flags, prompts or tasks:

| Agent | Interactive entry point |
| --- | --- |
| Qwen Code | `qwen` |
| DeepSeek Harness | `dsh web` |
| MiniMax Code | `mcode` |
| Kiro CLI | `kiro-cli chat` |
| Freebuff | `freebuff` |
| Kilo | `kilo` |
| Devin CLI | `devin` |
| Amp | `amp` |
| Command Code | `commandcode` |

DeepSeek Harness opens its browser interface; Orb's terminal hosts the web process. Orb does not set `DSH_PERMISSION_MODE` or override the agent's own settings. Kiro enters chat explicitly. Other agents retain their own startup, authentication and permission behaviour.

Discovery reads executable candidates and an offline installed-mise inventory. It checks both mise installation layouts, PATH and `~/.local/bin`, follows real executable symlinks, and rejects installer wrappers and shim targets. It never runs an agent to discover it. The existing fifteen entries and account handling remain intact; no default-agent setting is written.

## Verification

Passed in a Linux portable environment: `./tests/run` and `git diff --check`. Six new regression groups cover all 24 entries, absent agents without mise, both mise layouts, active version selection, off-PATH user installs, real symlinks, installer wrappers in every location, shim aliases, non-executables, literal executable paths containing spaces, launch argv, ignored unsolicited arguments, removed/unknown agents and an unchanged default-agent file.

No live Omarchy version was tested in this environment: Omarchy, Hyprland and Quickshell are unavailable. The upstream source review and stub-executable tests do not establish real CLI or desktop acceptance. Existing release acceptance records are unchanged.

Remaining acceptance on an owned Omarchy development session containing #14040: record `omarchy-version` and the source commit; run `./tests/native`; open Orb's Agents submenu and launch each installed new agent; verify `dsh` opens its web interface, Kiro opens chat, default-agent configuration is unchanged and no prompt is sent. Repeat discovery on a supported stable installation where the new agents are absent. Record actual installed CLI versions and any launch failures before closing issue #11.
