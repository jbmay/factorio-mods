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
and requires **Pi-C_lib >= 2.1.0**. Vehicle locks enforce entry and inventory-window
permissions through events and keep locked vehicles unminable. Owners can enter
either seat, drive, and open the vehicle interface while the lock stays active.
Other players may ride as passengers. Entering or switching to the driver seat
moves them to an available passenger seat, or ejects them if it is occupied;
the vehicle inventory window remains restricted to its owner or lock holder.
The lock holder retains access after claiming another vehicle. On upgrade,
existing locks are preserved and the old disabling flags are removed.
`ci.json` pins the engine and dependency used for smoke tests;
`portal.json` records the upstream identity and first-publication metadata.
See [shared development notes](../../docs/development.md) for credentials, coverage,
and the release workflow.

## Vehicle assignments with Space Age

When Space Age is enabled, each player can claim one vehicle per planet. The car
keys claim, lock/unlock, or summon the vehicle on the player's current planet;
claiming a replacement leaves assignments on other planets intact. Previously
locked vehicles stay locked when their claim is replaced. Custom planets are
supported, and surfaces without an associated planet have separate assignments.
Without Space Age, each player retains one global claimed vehicle.

The shortcut is disabled on space platforms, and both the keyboard shortcut and
key tool reject platform use. Keys also reject remote views of another surface;
returning to the character's surface restores the shortcut when its technology
is unlocked. Existing saves retain their claims without a storage migration.

The remote `owned_by_player` lookup returns the assignment for the player's
current planet with Space Age enabled. Administrative resets still affect all
of a player's vehicles. If another mod moves claimed vehicles onto the same
planet, reconciliation keeps the lowest unit number claimed and releases the
other claims while preserving their locks. The same rule applies when Space Age
is disabled and multiple claims must become one global claim.
