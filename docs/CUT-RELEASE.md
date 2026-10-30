# Cut Orb v0.3.0

The release contains custom icons, extra mouse-button gestures and additional installed agents. Touch/tablet is reserved for v0.4.0; named wheels, transfers, work setups and split/swap are deferred further.

## Before pressing Publish

1. Owner acceptance of the candidate and disclosed native coverage gaps is recorded in `ACCEPTANCE.json`. Manual cases without detailed results remain pending; additional [desktop testing](DESKTOP-TEST.md) remains available and does not require Omadev.
2. Require green CI on the PR. Use **Create a merge commit**, not squash/rebase, so the accepted `input_commit` remains an ancestor of the final release. If you choose squash/rebase, reconcile evidence against the resulting main source before tagging; do not simply substitute a SHA.
3. Write your release notes. Update `docs/RELEASE-NOTES.md` before running the workflow, or replace the draft release notes on GitHub before publication. `RELEASE-SUMMARY.md` provides the feature and setup summary.
4. Keep `status: pending-live` while documented native cases remain unverified. The owner's recorded acceptance permits the explicit per-commit `allow_pending_live=true` path; it does not fabricate test passes.
5. Keep `VERSION` and `manifest.json` at `0.3.0`, and use the immutable `v0.3.0` tag.

The workflow rejects runtime/build changes made after the accepted source. Docs-only release-note changes may follow it. If code or build inputs change, rerun relevant checks and update source-bound evidence.

## Start the release workflow

Push the prepared branch and merge it before this step. Use **Actions → Release source → Run workflow** on **main** with:

| Input | Value |
| --- | --- |
| `tag` | `v0.3.0` |
| `expected_commit` | Full SHA of the accepted, final `main` commit |
| `allow_pending_live` | `true` — recorded owner acceptance of disclosed coverage gaps |

Equivalent CLI, after final main is fetched and checked:

```bash
git fetch origin main
release_sha=$(git rev-parse origin/main)
gh workflow run release.yml --ref main \
  -f tag=v0.3.0 \
  -f expected_commit="$release_sha" \
  -f allow_pending_live=true
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
