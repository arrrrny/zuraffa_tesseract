# Publish Configuration for `zuraffa_tesseract`

<!-- Managed with the publish-manager skill. Edit if the workflow changes. -->

## Package Manager

- **Type**: `pub.dev`
- **Packages** (in publish order — the app package first; the platform core
  and the federated adapters declare their in-family dependencies hosted):
1. `zuraffa_tesseract`
2. `zuraffa_tesseract_platform`
3. `zuraffa_tesseract_darwin`
4. `zuraffa_tesseract_android`
5. `zuraffa_tesseract_web`
6. `zuraffa_tesseract_linux`
- **All packages are public**

## Scripts

- **Pre-publish**: `./scripts/prepare_for_publish.sh <version>` — creates a
  `publish-<version>` branch, bumps all package versions and in-family
  constraints, propagates the root CHANGELOG entry into each package, commits
- **Publish**: `./scripts/publish.sh` — dry-run then publish per package in
  order, waiting for pub.dev propagation (needs flutter/dart on PATH)
- **Post-publish**: `./scripts/push_to_master.sh -f` — merges the publish
  branch to master, tags, pushes, deletes the branch

## Workflow

1. Write the release notes as a `## <version>` entry at the TOP of the root
   `CHANGELOG.md`
2. `./scripts/prepare_for_publish.sh <version>`
3. `git push origin publish-<version>`
4. `bash scripts/publish.sh` (allow 10-30 min: propagation waits between
   packages)
5. `bash scripts/push_to_master.sh -f`

## Notes

- The workspace resolves the in-family packages from this checkout; each
  `pubspec.yaml` still carries the hosted `^<version>` constraint, which is
  what ships. No `dependency_overrides` are committed, so there is nothing to
  strip before publishing.
- Sibling packages fail `dart pub publish --dry-run` until their hosted
  in-family dependencies exist on pub.dev — publish in order and each dry-run
  goes green in turn.

---

**Mono version policy:** every package in the zuraffa fleet shares one version
number, currently **7.4.2** (matching `zuraffa`, `zuraffa_ocr` and the rest of
the fleet). Bump the whole fleet with `../zuraffa/scripts/update_fleet.sh
<version>`. Whenever a version is updated, the install guide in this repo's
README.md MUST be updated to that release version in the same change — no old
version constraints may linger in README install snippets. Dependency
constraints on `zuraffa` itself must move to `^<version>` in the same bump.
