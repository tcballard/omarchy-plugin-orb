# Deferred work

Named wheels and switching, wheel import/export, saved app/workspace setups and split/swap controls are deferred beyond v0.4.0. They are not part of the v0.3.0 desktop release or the planned v0.4.0 touch/tablet scope.

Existing library/setup data is preserved. The top-level `actions` layout remains usable; editing it does not rewrite archived wheel data. Development-only Work setups slots open Settings with a message so they can be replaced without launching a setup.

The earlier implementation remains in Git at `db10153` for later design review and native testing.
