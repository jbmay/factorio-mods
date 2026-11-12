# Development and releases

## Repository configuration

The repository's automation targets `main` as the default branch. GitHub Actions
handles checks, release preparation, packaging, and portal publication. The
intended branch protection requires the `All mod checks` status before merging.

Dependency maintenance uses the hosted
[Mend Renovate GitHub App](https://github.com/apps/renovate), with its behavior
defined in `renovate.json`. Renovate runs through the app rather than a repository
workflow. Release Please runs through GitHub Actions and uses bot credentials to
create release pull requests and GitHub Releases.

The workflows expect the following repository Actions secrets. App installation,
repository permissions, branch protection, and secret values are managed in
GitHub separately from the files in this repository.

| Secret | Purpose |
| --- | --- |
| `RELEASE_PLEASE_TOKEN` | Bot PAT with Contents, Issues, and Pull requests write permissions. Its PRs trigger CI, unlike PRs created with `GITHUB_TOKEN`. |
| `FACTORIO_USERNAME` | Factorio account username for dependency downloads. |
| `FACTORIO_TOKEN` | Account download/service token from Factorio profile/player data, distinct from the portal API key. |
| `FACTORIO_API_KEY` | Portal key with **Upload Mods** and **Publish Mods** permissions for subsequent releases and first-time listings. |

The download account must have access to the dependency mods. Publishing rights
apply to the new fork's listing. The publisher refuses to use the original name
recorded in `portal.json.upstream_name`.

## Checks and coverage

`check.yml` uses `maru run list-mods` to discover every `mods/*/info.json`, then
calls `test-mod.yml` separately for each mod. That reusable workflow invokes
`maru run test` for trusted runs or `maru run test-static` for fork PRs. Each
selected task runs the automation unit tests and mod checks inside the same
Docker image used locally. The workflow runs on PRs and main pushes; publishing
also reruns the checks for each release. Checks cover metadata and
release-version consistency, Lua 5.2 syntax, deterministic packaging, and a
pinned headless Factorio new-map test followed by loading the save and
benchmarking 600 ticks.

Fork PRs receive metadata, syntax, and packaging checks without credentials.
Engine tests run on same-repository PRs, trusted branch runs, and every publishing
run. Missing credentials fail engine tests. Pre-merge engine testing of a fork
contribution takes place on a trusted repository branch after code review.

The `gcki-continued` fork under `mods/GCKI` targets Factorio 2.1 and pins engine
**2.1.24** and **Pi-C_lib 2.1.0**. The current checks cover startup, save loading,
and tick execution. They do not cover locking, summoning, multiplayer, or save
upgrades. The scenario and save-fixture lists are empty; the smoke-test save is
generated automatically in the work directory.

`ci.json.dependencies` pins all external mods used by the tests, including
transitive requirements and optional integrations. The runner verifies portal
checksums, dependency constraints/conflicts, and matching Factorio series. Only
the configured dependency combination is tested. Expansion mods are not supplied
by the free headless download; this runner supports base-game combinations.

## Behavior and upgrade fixtures

For Factorio >= 2.1.24, test scenarios live under
`tests/<mod-directory>/scenarios/<scenario>/`, with their names recorded in
`ci.json.scenarios`. The runner stages them into a temporary installed mod and
excludes them from published ZIPs. Scenarios report their outcome through
`script.finish_test(true)` or `script.finish_test(false)`. Assertion errors and
process timeouts also fail the test run.

Upgrade fixtures live under `tests/<mod-directory>/saves/`, with their ZIP
filenames recorded in `ci.json.saves`. Each saved scenario contains assertions
that verify migrated state, followed by test completion logic. A plain save
without that logic times out. The runner avoids `--test-ticks`, which can exit
successfully without tests finishing. These fixtures are separate from the
original player saves used to create them.

## Release Please

Each package in `release-please-config.json` releases independently. The initial
version is recorded in `.release-please-manifest.json`. Release Please uses
Conventional Commit messages, such as `fix(GCKI): preserve vehicle lock state`,
to determine version increments and generate release notes for changes that
touch each mod.

1. Release Please opens one release PR per affected mod, updating its
   `version.txt`, `info.json.version`, Markdown changelog, and manifest entry.
2. Merging a reviewed release PR with passing checks causes Release Please to
   create a component tag such as `gcki-continued/v2.0.2` and a GitHub Release.
3. The same workflow directly invokes `publish.yml` for each released mod.
   Publishing does not depend on a second workflow being triggered by a bot tag.
4. Publishing checks out the exact tag, reruns checks and engine tests, uploads
   the tested ZIP to the portal, and attaches it to the GitHub Release.

The **Publish one mod** workflow supports retries using a mod directory name and
an existing release tag. An existing portal release is accepted only when its
bytes match the tested package; portal releases are never replaced. A GitHub
Release can exist even if subsequent testing or uploading fails, so its presence
alone does not confirm portal publication. Shared-tooling changes alone do not
release every mod automatically.

## Renovate

The GitHub Actions manager updates action versions and pins digests. Custom
regex managers and datasources track:

- Stable headless releases from the official Factorio API: `ci.json.factorio`.
- That release's major/minor series: `info.json.factorio_version`.
- Maru runner releases from GitHub: `.maru-version`, used by the CI installer.
- Portal releases: exact dependency pins in `ci.json` and `>=` constraints in
  `info.json`. The `base` floor stays unchanged because it describes the oldest
  supported patch, independently of the engine version used for testing.

Factorio and portal dependencies are grouped into one compatibility PR so a new
engine series and matching library can be proposed together. Updates never
automerge. Dependency candidates include all portal releases; incompatible
proposals fail engine checks and need review. Unversioned constraints and
operators other than `>=` require manual updates. A version PR may require Lua
API changes before it passes; metadata updates alone do not port a mod.

## Mod organization

Each mod occupies a stable `mods/<directory>/`, retaining its own licensing,
credits, and migrations. The root README provides an index of the maintained
mods. CI and Renovate discover mod directories automatically, while Release
Please uses explicit package registrations.

| File or configuration | Role |
| --- | --- |
| `info.json` | Defines the internal mod name, version, Factorio series, and dependency constraints. |
| `ci.json` | Pins the test engine and external dependencies, including transitives, and identifies test fixtures. The engine pin matches the declared Factorio series. |
| `portal.json` | Records the portal license ID, category, and original `upstream_name` for forks. |
| `description.md` | Supplies the portal description for first publication. Subsequent release uploads leave portal prose unchanged. |
| `version.txt` | Tracks the Release Please version and matches `info.json.version`. |
| Root release configuration and manifest | Register each mod's path, unique release component, and current release version. The extra-file updater keeps `info.json.version` synchronized. |

Forks use distinct internal names. Imports, remote interfaces, locale metadata,
and save migration behavior can depend on those names, so a renamed fork's
compatibility depends on more than its metadata.

Packages use `info.json.name`, independently of the source directory and release
component. An explicit allowlist in `tools/mod_ci.py` determines which runtime
directories and asset types enter each package. New runtime file types or
directories require a corresponding allowlist change.

## Local container tests

Local test execution uses the root `Dockerfile` and Maru 0.6-compatible
`tasks.yaml`. The host needs Docker daemon access and Maru; the container supplies
Python 3.13, Lua 5.2, CA certificates, and the Linux C++ runtime. Its Linux amd64
platform matches the Factorio headless executable downloaded by the engine
runner. Other host architectures require Docker's amd64 emulation support.

| Maru task | Behavior |
| --- | --- |
| `build-test-image` | Builds `local/factorio-mod-tests:latest` from the Dockerfile. |
| `test-static` | Builds the image, runs the automation unit tests once, then checks metadata/Lua syntax and packages each selected mod. No Factorio download credentials are needed. |
| `test` | Builds the image, runs unit and mod checks, then creates and loads a Factorio save for each selected mod. |
| `default` | Runs the full `test` task. |
| `list-mods` | Builds the image and writes the discovered directory selectors to `dist/mods.json` for the CI matrix. |
| `release-matrix` | Builds the image, reads Release Please JSON from `RELEASE_OUTPUTS`, and writes selected mods and tags to `dist/releases.json`. |
| `publish` | Builds the image and uploads the single tested ZIP in `dist/` with the selected `MOD` and `TAG`, using `FACTORIO_API_KEY`. This task makes real portal changes. |

The `MOD` variable selects a directory under `mods/`; its empty default selects
all discovered mods for the test tasks. Publication requires an explicit `MOD`
and release `TAG`. `TEST_IMAGE` controls the local image tag. Examples from
the repository root:

```sh
maru run build-test-image
maru run test-static
maru run test --set MOD=GCKI
```

Full engine tests use the exported `FACTORIO_USERNAME` and `FACTORIO_TOKEN`
environment variables for dependency downloads. Tasks pass their names to
Docker rather than interpolating secret values into command text. The build
context contains only the Dockerfile and container entrypoint; mod source and
credentials are not baked into the image. Factorio and its pinned dependencies
are downloaded at test time. The `test` and `test-static` tasks never publish;
portal changes are confined to the separate `publish` task.

The repository is mounted read-only at `/workspace`, with a writable `dist/`
mount for packages. Full tests also mount `.test-results/` at `/results`. Each
engine run gets a new directory named after the mod, containing `smoke.zip`,
`data/factorio-current.log`, and the downloaded engine/dependencies. Results remain
available after success or failure and are ignored by Git. The container runs
with the invoking user's UID/GID so generated files retain user ownership.

The entrypoint, `tools/run_container_tests.py`, orchestrates the existing Python
checks. Its final `Test results` summary lists each automation unit test and
each completed mod check with `[PASS]`, `[FAIL]`, or `[SKIP]`, followed by totals.
Engine checks name the configured Factorio version and tick count; scenario and
save fixtures are listed individually when configured. Empty fixture lists are
explicitly skipped. A failed run retains completed results and stops before
later checks; only successful runs print `All executed checks passed`.

GitHub workflows use these same Maru tasks for discovery, testing, release
selection, and portal publication. The local `setup-maru` composite action
installs the version pinned in `.maru-version` and verifies the downloaded binary
against the upstream release checksum. The initial pin is v0.6.0, matching the
local task format. CI no longer installs host Python or Lua for those operations.
Engine logs are uploaded from `.test-results/**/data/factorio-current.log`.

Release Please's GitHub action and GitHub Release/artifact operations remain
workflow orchestration around the tasks. Renovate tracks the image's Python base,
the Maru version, action dependencies, and mod dependencies.

## Interactive development

Interactive development uses a source directory linked into Factorio's mods
directory under the internal name, with dependencies installed separately.
[Local tool commands](../tools/README.md) cover validation, packaging, and engine
test execution outside GitHub Actions.

References: [Factorio CLI](https://wiki.factorio.com/Command_line_parameters),
[upload API](https://wiki.factorio.com/Mod_upload_API),
[first publication API](https://wiki.factorio.com/Mod_publish_API),
[Release Please manifests](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md),
and [Renovate custom datasources](https://docs.renovatebot.com/modules/datasource/custom/).
