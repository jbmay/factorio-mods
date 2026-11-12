# Mod automation

[`mod_ci.py`](mod_ci.py) provides the shared CLI used by GitHub Actions for mod
validation, packaging, engine testing, and portal publication. It uses Python
3.13+ and the standard library. Lua syntax checking uses the external `luac5.2`
executable, with `LUAC` available as an override. Engine tests run on Linux.

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
| `publish MOD --archive ZIP --tag TAG` | Verifies and uploads a release package. | Creates a portal listing or adds a release to an existing listing. |

Examples of local discovery, validation, and packaging:

```sh
python tools/mod_ci.py list
python tools/mod_ci.py check GCKI
python tools/mod_ci.py package GCKI
```

### Configuration validation

`check`, `package`, `engine`, `publish`, and each selected entry in
`release-matrix` use `validate(mod)`. It checks:

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

`run_engine(mod, work)` creates the work directory if needed and requires it to
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

The function does not run engine tests, check whether the GitHub Release exists,
or attach GitHub assets itself. Those steps belong to `publish.yml`, which runs
engine tests before invoking this command. The CLI's `publish` command performs
a real upload when its checks pass.

## Supporting functions

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
python -m unittest discover -s tools/tests -v
```

[Development and releases](../docs/development.md) describes how these commands
fit into the GitHub workflows and repository configuration.
