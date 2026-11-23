# Deferred beyond v0.4.0

Named wheels and switching, wheel import/export, saved app/workspace setups, and split-window ratios/swapping are deferred to a future release. They are absent from v0.4.0 controls and helpers.

v0.4.0 keeps custom icons, extra mouse-button gestures, additional installed agents, and touch/tablet navigation, including ordinary window focus, restore, maximise, move and close controls.

Existing `wheels`, `activeWheel` and `setups` settings are preserved unchanged. The top-level `actions` projection remains the active shortcut layout. Editing it does not update archived wheel data. Previously saved Work setups menu slots show a deferred-feature message and can be replaced in Settings.

The implementation remains recoverable from commit `db10153` (branch `dev/0.3-wheels`). Reintroduction will need fresh design review, configuration reconciliation and native tests, especially the previously failing window-pair dispatches. No future version or delivery date is assigned.

Runtime placeholders for this deferred work are marked `DEFERRED(wheels-setups)`; `grep -rn "DEFERRED(wheels-setups)"` lists every site to revisit.
