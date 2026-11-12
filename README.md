# Factorio mods

A monorepo for maintaining Factorio mods. Each directory under `mods/` is an
independent mod with its own metadata, version, changelog, and licensing.

## Layout

```text
mods/                 Mod source, one stable directory per mod
tools/                Shared development and packaging tools
docs/                 Shared development documentation
.github/workflows/    GitHub Actions workflows
dist/                 Generated release ZIPs (ignored by Git)
```

## Mods

| Directory | Mod | Imported version | Declared Factorio version |
| --- | --- | --- | --- |
| [mods/GCKI](mods/GCKI/) | Gizmos Car Keys (continued), internal name `gcki-continued` | 2.0.1 | 2.1 |

See [development documentation](docs/development.md) for local setup and release
automation, including the required GitHub and Factorio secrets. Release Please
creates independent release PRs; Renovate proposes engine and dependency updates.
Compatibility values above describe the maintained source. Engine validation
uses the exact version pinned in each mod's `ci.json`.

## Local tests

Local tests use Docker and Maru, with Python, Lua, and the Factorio runtime
dependencies supplied by the [test image](Dockerfile). The [Maru tasks](tasks.yaml)
build the image automatically before running tests:

```sh
maru run test-static
maru run test --set MOD=GCKI
```

`test-static` runs unit tests, Lua/metadata checks, and packaging. `test` also
creates and reloads a Factorio save, requiring `FACTORIO_USERNAME` and
`FACTORIO_TOKEN` in the host environment for dependency downloads. Omitting
`--set MOD=GCKI` selects every mod. Saves and engine logs remain in
`.test-results/`; packages remain in `dist/`. See
[container test details](docs/development.md#local-container-tests).

GitHub CI calls the same Maru tasks and Docker image. Its Maru version is pinned
in `.maru-version`, and fork PRs use the credential-free `test-static` task.

## Licensing

Licensing and upstream attribution belong to each mod. This repository does not
apply a replacement license to imported code or assets. See each mod's README
and any included license and credits files.
