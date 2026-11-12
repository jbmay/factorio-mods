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
| [mods/GCKI](mods/GCKI/) | Gizmos Car Keys (continued), internal name `gcki-continued` | 2.0.1 | 2.0 |

See [development documentation](docs/development.md) for local setup and release
automation, including the required GitHub and Factorio secrets. Release Please
creates independent release PRs; Renovate proposes engine and dependency updates.
Compatibility values above describe the imported source; they do
not indicate that it has been tested against a newer Factorio release.

## Licensing

Licensing and upstream attribution belong to each mod. This repository does not
apply a replacement license to imported code or assets. See each mod's README
and any included license and credits files.
