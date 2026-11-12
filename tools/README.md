# Mod automation

[`mod_ci.py`](mod_ci.py) provides the shared CLI used by GitHub Actions for mod
validation, packaging, engine testing, and portal publication. It uses Python
3.13+ and the standard library. Lua syntax checking uses the external `luac5.2`
executable, with `LUAC` available as an override. Engine tests run on Linux.

For local use without host Python or Lua, the root Dockerfile and Maru tasks run
these same checks in a container. CI invokes the same tasks and image.
`maru run test-static` runs unit, syntax, and
packaging checks; `maru run test --set MOD=GCKI` includes engine tests. Omitting
`MOD` selects all mods. [Local container tests](../docs/development.md#local-container-tests)
describes credentials, mounts, and retained saves/logs.

The `list-mods`, `release-matrix`, `tag-matrix`, and `publish` tasks also run their corresponding
CLI commands in that image. Discovery and release selection write JSON under
`dist/` so workflow outputs do not mix with Maru build/progress messages. CI's
Maru installation is pinned in `.maru-version`.

The repository root is resolved from the script's location. A command's mod
argument selects a directory under `mods/`: `GCKI` selects `mods/GCKI`, whose
internal Factorio name is `gcki-continued`. Package filenames use the internal
name; release tags use the component in `release-please-config.json`.

## Commands

| Command | Purpose | Output or side effects |
| --- | --- | --- |
| `list` | Discovers `mods/*/info.json`. | Prints a sorted JSON array of directory selectors for the CI matrix. |
| `check MOD` | Validates configuration and checks every `.lua` file with `luac5.2 -p`. | Prints a success message or exits with an error; does not run Factorio. |
| `package MOD` | Validates configuration and builds the release ZIP. | Writes `dist/<name>_<version>.zip` and prints its path. |
| `engine MOD --work DIRECTORY` | Installs an isolated test environment and runs the real Factorio engine. | Downloads files, builds a package in `dist/`, and retains test files and engine logs under the work directory. |
| `release-matrix` | Converts Release Please outputs into per-mod publishing jobs. | Reads `RELEASE_OUTPUTS` and prints a JSON array of objects containing `mod` and `tag`. |
| `tag-matrix --tag TAG` | Selects the registered mod for a version tag and checks its version. | Prints the single-entry publishing matrix; rejects unknown components and mismatched versions. |
| `publish MOD --archive ZIP --tag TAG` | Verifies and uploads a release package. | Creates a portal listing or adds a release to an existing listing. |

Examples of local discovery, validation, and packaging:

```sh
python tools/mod_ci.py list
python tools/mod_ci.py check GCKI
python tools/mod_ci.py package GCKI
```

### Configuration validation

`check`, `package`, `engine`, `publish`, and each selected entry in
`release-matrix` and `tag-matrix` use `validate(mod)`. It checks:

- Required `info.json` fields, portal name syntax, version syntax, and Factorio's
  numeric version limits.
- An exact engine pin in `ci.json` matching `info.json.factorio_version`.
- Agreement between `info.json.version`, `version.txt`, and the Release Please
  manifest, plus registration in the release configuration.
- Dependency pin names and versions, dependency expression syntax, portal
  license/category presence, fixture names, and a positive benchmark tick count.

This validates configuration structure and consistency. Actual dependency
availability and compatibility are checked during engine testing.

### Packaging and changelogs

`package(mod, output=None)` writes a ZIP containing a single
`<name>_<version>/` directory. Its optional Python argument `output` changes the
destination directory; the CLI always uses `dist/`.

`packaged_files(path)` selects files using `ROOT_FILES`, `RUNTIME_DIRS`, and
`ASSET_SUFFIXES`. Root Lua files and recognized metadata are included, along with
supported files inside runtime directories. Hidden paths, development metadata,
backups, and artwork source formats are excluded. Symlinks cause packaging to
fail. New runtime directories or asset types require an allowlist change.

Files are sorted and written with fixed timestamps and permissions so repeated
builds with the same source and toolchain produce identical ZIPs. Packaging
overwrites the existing archive for that name and version.

`changelog(path, version)` supplies the packaged `changelog.txt`. If the source
changelog already contains the version, its text is used. Otherwise, the function
extracts that version's dated entry from Release Please's `CHANGELOG.md`, converts
its bullet points into Factorio's text format, and prepends them to the original
history. Missing or empty release notes fail packaging. The source changelog is
not rewritten.

### Engine testing

`run_engine(mod, work, report=None)` creates the work directory if needed and requires it to
be empty. It downloads the pinned Linux headless Factorio release, installs a
freshly built mod package, and downloads each external dependency pinned in
`ci.json.dependencies`.

Dependency downloads require `FACTORIO_USERNAME` and `FACTORIO_TOKEN`. The runner
checks each release's Factorio series, verifies its portal SHA-1 checksum, and
reads its actual `info.json` to confirm the name, version, and dependencies.
`check_dependencies(infos)` then checks the entire installed combination,
including transitive requirements, version constraints, and conflicts. Missing
required dependencies fail with a request for an explicit pin; the runner does
not automatically resolve or download unpinned transitive dependencies.

A generated `mod-list.json` enables the candidate, its pinned dependencies, and
the base game. A separate Factorio configuration isolates both mods and writable
game data from the developer's installation. The engine creates a map with seed
`1`, then loads it for the configured number of benchmark ticks. Each engine
process has a 180-second timeout.

For Factorio >= 2.1.24, the runner also executes scenarios named in
`ci.json.scenarios` and save fixtures named in `ci.json.saves`. Scenarios are
staged from `tests/<mod>/scenarios/` into a temporary installed copy of the mod;
save fixtures come from `tests/<mod>/saves/`. These tests report completion through
`script.finish_test`. A test that never finishes times out. Test-only scenarios
are excluded from the release package.

```sh
python tools/mod_ci.py engine GCKI --work /tmp/gcki-engine-test
```

Without configured behavior fixtures, this command checks startup, save loading,
and tick execution. It does not establish coverage of player interactions or
every optional-mod combination.

### Release selection

`release_matrix(outputs)` reads Release Please's `paths_released` array and each
path's tag output. Every selected path must be registered in the release
configuration, pass metadata validation, and have a tag matching
`<component>/v<version>`. The result is the publishing matrix, for example:

```json
[{"mod": "GCKI", "tag": "gcki-continued/v2.0.2"}]
```

The CLI obtains `outputs` from the JSON object in `RELEASE_OUTPUTS`. With no
released paths, the result is an empty array.

`tag_matrix(tag)` finds the registered release component in a tag such as
`gcki-continued/v2.0.2`, then uses `release_matrix()` to validate the selected
mod and exact version. Tag-triggered CI calls this through the `tag-matrix` Maru
task, which writes `dist/releases.json`. It requires no Factorio credentials.

### Portal publication

`publish(mod, archive, tag)` requires `FACTORIO_API_KEY`, a matching release tag,
and a mod name different from `portal.json.upstream_name`. It rebuilds the package
in a temporary directory and compares both its filename and bytes with the input
archive. A mismatched artifact fails before any portal request.

The publisher queries the portal for the internal mod name. For a new listing,
it uses the first-publication API with `description.md` and the license/category
from `portal.json`. When `GITHUB_REPOSITORY` is available, it also supplies the
repository source URL. Existing listings use the release-upload API without
changing their portal descriptions.

If the version already exists, publication succeeds only when its portal
checksum matches the input archive. Different bytes for the same version fail;
the publisher never replaces an existing portal release. The API key is sent
only to the upload initialization endpoint, and the returned upload URL must
use HTTPS.

The function does not run engine tests, ensure a GitHub Release exists,
or attach GitHub assets itself. Those steps belong to `publish.yml`, whose
tag-only authenticated jobs run in the `trusted` environment. Main pushes run
authenticated engine tests without publishing, and all PRs run credential-free
checks. The CLI's `publish` command performs
a real upload when its checks pass.

## Supporting functions

`TestReport` records individual checks. Its `case(name)` context manager prints
`[RUN]`, then records `[PASS]` only after the operation succeeds. Exceptions
record `[FAIL]` before propagating. `record(name, status, detail=None)` also
supports `[SKIP]` for unconfigured fixtures. Check, package, and engine commands
accept `--report FILE` to write these outcomes as JSON; progress messages go to
stderr so JSON output and package paths on stdout remain usable by callers.

| Function | Responsibility |
| --- | --- |
| `read_json(path)` | Reads a UTF-8 JSON file into Python objects. |
| `mod_path(mod)` | Validates the directory selector and resolves it under `mods/`, rejecting unknown directories and symlinked mod roots. |
| `version_tuple(value)` | Converts dotted version components into integers for numeric comparison. |
| `satisfies(actual, op, expected)` | Evaluates `>=`, `<=`, `=`, `>`, or `<`, padding two-component versions with a zero patch number. |
| `request(url, fields=None, token=None, file=None)` | Performs HTTP requests, including form submissions and multipart file uploads, with a 180-second timeout. Network errors omit URLs because dependency URLs contain credentials. |
| `api(url, **kwargs)` | Decodes a JSON HTTP response and rejects portal responses containing an `error` field. |
| `main()` | Parses the CLI arguments and dispatches to the selected operation. Discovery and Lua syntax checking are implemented directly in this dispatcher. |

## Automation tests

[`tests/test_mod_ci.py`](tests/test_mod_ci.py) exercises configuration failures,
dependency constraints, deterministic packaging, changelog conversion, release
selection, engine staging, and publication safeguards. Engine processes and
network calls are mocked in those unit tests; running them does not download
Factorio or publish a mod.

```sh
python -m unittest discover -s tools/tests -v -b
```

[`run_container_tests.py`](run_container_tests.py) is the image entrypoint. It
discovers mods, runs the unit suite once in-process, and invokes `mod_ci.py check` for each
selected mod. In static-only mode it then invokes `package`; in full mode it
creates a fresh results directory and invokes `engine`, which builds the package
as part of preparing the game environment. It forwards failures as a nonzero
container exit status.

The entrypoint's `UnitResult` records each unit test's actual outcome. Unit output
is buffered so successful mocks do not print misleading engine or upload success
messages. `run_check()` collects JSON reports from each CLI command, including
partial results on failure. `print_summary()` ends the run with a named list of
passed, failed, and skipped checks plus totals. A failing check stops the run;
later checks are not reported as passed. Static-only mode explicitly marks the
engine as skipped, and empty scenario/save lists are reported as unconfigured.

[Development and releases](../docs/development.md) describes how these commands
fit into the GitHub workflows and repository configuration.
