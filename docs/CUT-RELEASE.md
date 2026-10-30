# Cut Orb v0.3.0

The release contains custom icons, extra mouse-button gestures and additional installed agents. Touch/tablet is reserved for v0.4.0; named wheels, transfers, work setups and split/swap are deferred further.

## Before pressing Publish

1. Complete [desktop testing](DESKTOP-TEST.md). Record the tested commit, machine/display scope, pass/fail outcomes and untested cases in `ACCEPTANCE.json`. Owner-reported desktop results are valid evidence. No Omadev requirement applies to manual testing.
2. Pass the portable/native validation and Qt checks, including the currently blocked archive fixture. Get green CI for the final source. Resolve core failures; keep narrower hardware/agent limitations explicit.
3. Finalize `RELEASE-NOTES.md`: remove its draft/pending wording only after acceptance. Keep the release scope and any remaining limitations accurate.
4. Merge the prepared release branch to `main` through your normal PR process. If squash/rebase changes the tested commit identity, reconcile evidence against the resulting `main` source: the tested `input_commit` must be an ancestor of the release commit, with only docs/README/CREDITS changes afterward. Run final checks on that source and commit the evidence as a docs-only change. Never substitute a SHA without verifying the source.
5. In `ACCEPTANCE.json`, use `status: passed` only when the required acceptance is actually complete. Preserve results and documented limitations; clear completed items from `pending`. No waiver is pre-authorized. Keep `VERSION`, `manifest.json` and the release tag at `0.3.0` / `v0.3.0`.

The workflow refuses stale acceptance when runtime, tests or build/workflow inputs changed after the accepted commit. A docs-only evidence commit can follow it. Do not squash away the accepted source commit after recording evidence.

## Start the release workflow

Push the prepared branch and merge it before this step. Use **Actions → Release source → Run workflow** on **main** with:

| Input | Value |
| --- | --- |
| `tag` | `v0.3.0` |
| `expected_commit` | Full SHA of the accepted, final `main` commit |
| `allow_pending_live` | `false` |

Equivalent CLI, after final main is fetched and checked:

```bash
git fetch origin main
release_sha=$(git rev-parse origin/main)
gh workflow run release.yml --ref main \
  -f tag=v0.3.0 \
  -f expected_commit="$release_sha" \
  -f allow_pending_live=false
```

This is a manual workflow, not a tag-push or release-created trigger. Use it before publishing through GitHub's Releases screen; you do not need to create the tag yourself. It also accepts an existing annotated tag only if it points to the exact authorized commit. Never move an existing published tag.

The workflow runs tests and Qt checks, prepares a local annotated tag, validates source-bound acceptance, creates source assets and checksums, and only then pushes the tag and creates a **draft** release. It downloads the draft assets and verifies their checksums against the generated manifest. A failure before tag push leaves no new remote tag; a failure afterward leaves an unpublished draft/tag to inspect, not a published release.

## Review and publish the draft

Wait for the workflow to finish successfully. Check the draft title, notes and source commit. Its assets should be:

- `omarchy-plugin-orb-v0.3.0-source.tar.gz`
- `SOURCE-MANIFEST.json`
- `RELEASE-MANIFEST.json`
- `SBOM.spdx.json`
- `SHA256SUMS`

The archive is complete source, not a binary installer. Normal installation and update use public `main`; merging accepted source to `main` is what makes it available to the plugin manager.

You can independently download and verify the draft:

```bash
release_download=$(mktemp -d)
gh release download v0.3.0 --dir "$release_download"
(cd "$release_download" && sha256sum --check SHA256SUMS)
```

Then press **Publish release**, or explicitly publish it with:

```bash
gh release edit v0.3.0 --draft=false
```

Finally verify the public tag, assets and notes, and test a normal plugin update from public `main`. Marketplace listing changes are a separate submission; this workflow does not post an issue or claim marketplace approval.
