# Gizmos Car Keys (continued)

Imported from the extracted `GCKI_2.0.1` mod portal download. The imported source
declares Factorio 2.0 compatibility and requires `Pi-C_lib >= 2.0.3`.

- Upstream author: Pi-C
- Based on Gizmos Car Keys by aodgizmo
- Upstream mod portal: https://mods.factorio.com/mod/GCKI
- Fork internal name: `gcki-continued`
- Upstream homepage: https://forums.factorio.com/viewtopic.php?f=190&t=77332
- Imported mod version: 2.0.1
- Upstream release date: 2025-09-08 (from `changelog.txt`)

The original ZIP was deleted before repository setup, so its checksum was not
recorded. Existing source and assets were moved without modification. The
upstream `.bak` files remain on disk but are excluded by the root `.gitignore`.

## License and credits

The mod portal lists this mod under the MIT license. The extracted download
contains no standalone license file. Preserve upstream attribution and obtain
the applicable license notice for inclusion before redistribution; do not
substitute a new copyright notice for the upstream authors.

See `graphics/credits.txt` for artwork attribution and `description.md` for the
upstream portal description, usage instructions, and additional credits.

## Maintenance

The internal mod name is `gcki-continued`; its source directory remains
`mods/GCKI`. Packages use `gcki-continued_<version>.zip` and release tags use
`gcki-continued/v<version>`. Internal imports and localized mod metadata use the
fork's name, while existing prototype, setting, and command identifiers retain
their `GCKI` prefixes. The remote interface follows the new internal name.

The fork conflicts with upstream `GCKI` to prevent duplicate prototypes and
handlers. Automatic transfer of upstream save data is not implemented, and
integrations that look for the original mod name require separate review.
The maintained fork targets Factorio **2.1.24** or newer within the 2.1 series
and requires **Pi-C_lib >= 2.1.0**. Vehicle locking uses the 2.1 script-controlled
activation and mining flags. `ci.json` pins the engine and dependency used for smoke tests;
`portal.json` records the upstream identity and first-publication metadata.
See [shared development notes](../../docs/development.md) for credentials, coverage,
and the release workflow.
