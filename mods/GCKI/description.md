This is **Gizmos Car Keys (continued)**, a fork of [Gizmos Car Keys (improved)](https://mods.factorio.com/mod/GCKI) by Pi-C. Its internal mod name and remote interface are `gcki-continued`.

The original mod and this fork cannot be enabled together.

Is your vehicle always where you are not, especially when you need it? Do you regularly waste time running to your vehicle because you need something from its trunk? Then *let it come to you* instead!

This mod is based on [Gizmos Car Keys](https://mods.factorio.com/mod/Gizmos_Car_Keys) by aodgizmo, since version 1.1.2 it supports spider-vehicles as well. It should work with most modded vehicles based on a car or spider-vehicle prototype. If you are the author of a mod that uses such prototypes for special purposes, you can blacklist your prototypes with GCKI.

# Usage #
The keys will be available as long as an unlock technology has been researched. Usually that will be Automobilism, but there may be others depending on the mods you are using (e.g. Ships if [Cargo Ships](https://mods.factorio.com/mod/cargo-ships) is active). Take the keys and click on a vehicle to claim it. Click *on the same vehicle* again to lock or unlock it. By using the keys *on another vehicle*, you replace your claimed vehicle on that planet when Space Age is enabled, or your single global vehicle without Space Age. (Hint: If you want to exchange vehicles, you should lock your old vehicle before giving it up! As of version 1.1.2, any unlocked vehicle without a player character inside can be claimed by *any* player. In other words, vehicles can be stolen by another force!)

If you use the keys on a free position where the vehicle can be placed, it will be summoned there if the position is within your reach. With Space Age enabled, this summons only the vehicle claimed on your current planet.

**A locked vehicle remains usable by its owner.** You can enter either seat, drive, and open its inventory without unlocking it, and locking while seated keeps you inside. Other players can ride in passenger seats, even when you are not inside, but cannot drive the vehicle or open its inventory window. If a non-owner enters the driver seat, they are moved to an available passenger seat or ejected if it is occupied. Switching seats cannot bypass the driver lock. The player who locked a vehicle retains access even after claiming a replacement. Locked vehicles must still be unlocked before anyone can mine them.

This mod supports vehicle grids and everything else a vehicle might contain. Without Space Age, the single globally claimed vehicle can also be summoned to another surface. Other players riding in the vehicle travel with it unless they have chosen to stay on the original surface through their per-player runtime setting.

Other than the original mod, this one should be safe to use in multiplayer games.

# Does it work with other mods? #
## Space Age ##
Space Age is detected automatically. Each player can claim **one vehicle per planet**, so you can keep a car on Nauvis, a tank on Vulcanus, and another vehicle on each of the other planets.

- Use the car-key shortcut to take out the keys, then click a vehicle to claim it. Click your claimed vehicle again to lock or unlock it.
- Click a free position within reach to summon the vehicle claimed on your current planet. **If you have no vehicle claimed there, nothing is summoned.** Vehicles on other planets stay where they are.
- Claiming another vehicle replaces only your assignment on that planet. Assignments on other planets are preserved. Lock your old vehicle before replacing it if you want it to remain locked afterward.
- Existing claims in a `gcki-continued` save are retained on the planet where the vehicle is located when the updated mod loads. Previously locked but unclaimed vehicles stay locked; they are not automatically assigned to planets.

**Space platforms:** the car-key shortcut is disabled on platforms. The keyboard shortcut and key tool also reject platform use, so you cannot summon a vehicle onto a platform. The shortcut becomes available again when you return to a supported surface and its unlock technology is researched.

Keys cannot be used while remotely viewing a different surface; return to your character's surface first. Custom planets are supported, and surfaces without an associated planet have their own separate assignments.

Without Space Age, each player has **one globally claimed vehicle**, retaining the original claiming, locking, and summoning behavior.

## Incompatible mods ##
There have been no reports yet that this mod would cause errors if used together with another mod, so I guess it's  safe to use.

## Supported mods ##
 **[Autodrive](https://mods.factorio.com/mod/autodrive)**
- If a vehicle controlled by Autodrive is locked, the dummy passenger will be removed (if present).
- Autodrive now recognizes whether a vehicle has been locked by this mod and will disable its GUI controls in this case.

**[Cargo Ships](https://mods.factorio.com/mod/cargo-ships)**
- If this mod is installed, the keys will also be unlocked by researching "Ships".

** [Uncle Shred's unminable vehicles](https://mods.factorio.com/mod/UnminableVehicles)**
- If that mod makes vehicles unminable, GCKI will respect this setting and keep vehicles unminable even if they are unlocked.

**[Vehicle Wagon 2](https://mods.factorio.com/mod/VehicleWagon2)**
- This mod is fully compatible with GCKI. If a player owned the vehicle before it was loaded, he will get it back when it is unloaded -- unless the player has claimed another vehicle in the meantime. Only the player who owns or who has locked a vehicle may load it onto a wagon and unload it again. Thanks to robot256 for cooperating on getting this done!

## Remote interface for use by other mods ##
As of version 0.17.14, other mods can check who has locked a vehicle or who is the owner of a vehicle.

**Usage:**

      remote.call("gcki-continued", "vehicle_locked_by", vehicle)
      remote.call("gcki-continued", "vehicle_owned_by", vehicle)

 In both cases, the argument `vehicle` must be a `LuaEntity` of type `"car"` or `"spider-vehicle"`. Both remote calls will return either a `LuaPlayer` or `nil`.

As of version 0.17.15/0.18.2, other mods can check whether a dummy character has been inserted into a vehicle.

**Usage:**

      remote.call("gcki-continued", "dummies_in_vehicle", vehicle)

The argument `vehicle` must be a `LuaEntity` of type `"car"` or `"spider-vehicle"`. This remote call will return either `nil` or a table of character entities with the fields `"driver"` and `"passenger"`.


## Commands ##

### Admin vehicle recovery ###

Server admins can recover griefed vehicles or vehicles left behind by players
who no longer play. This is an explicit console action; admin status does not
override normal car-key, locking, or passenger behavior.

- `/GCKI-clear-owner` or `/GCKI-clear-owner selected`: recover the vehicle under your cursor.
- `/GCKI-clear-owner vehicle 12345`: recover the vehicle with that unit number.
- `/GCKI-clear-owner player PlayerName`: recover vehicles claimed or locked by that player across all planets. Player indexes and quoted names such as `player "Player Name"` are also accepted.

Recovery clears both the lock and claim and ejects occupants, allowing another
player to claim the vehicle. The vehicle, its contents, equipment, custom name,
and color are preserved. Each recovered vehicle is recorded in the server log
with the administrator, vehicle ID, surface, and previous owner and lock holder.

The server console and RCON can use the same command with an explicit `vehicle`
or `player` target. An omitted or invalid target never recovers every vehicle.
Non-admin players cannot use the recovery command.

# Supported languages  #
- English
- German
- [Russian](https://mods.factorio.com/mod/MyRUS2) (Dragonling fetches and translates new/changed strings from other mods and includes them in his. I'll eventually integrate his changes, but you'll get new translations faster if you also have his translations-pack  mod installed!)

*If you can provide a localization for another language, I'd  be happy to include it! :-)*

# Uninstalling GCKI #
Before removing GCKI from a game, unlock or reset your vehicles so their mining protection is cleared. Likewise, if you are participating in a multiplayer game and intend to never join your current server again, unlock or reset all vehicles owned or locked by you so that other players can use them.

# Help needed #
I've spent quite some time on testing this mod to make sure it's safe to use in multiplayer mode. However, doing these tests locally may not be reliable. So I'm interested in any feedback on issues while playing multiplayer games!

# Credits  #
Credits go to

- [aodgizmo](https://mods.factorio.com/user/aodgizmo): for the original mod -- I used the code (and changed, added to, or removed parts of it) and the car-key graphics (which I also used for the mod thumbnail) in my mod.
- [Zahnfeechen](https://mods.factorio.com/user/Zahnfeechen): for [Gizmos Car Keys - Zahnfeechen Patch](https://mods.factorio.com/mod/Gizmos_Car_Keys_Z_Patch) (which updated aodgizmo's mod for Factorio 0.17) -- I happily played with this mod myself until I decided to make my own version. Because this mod shares a lot of code with mine, it is not only unnecessary to have both active at the same time, it could even lead to unforeseeable results because both mods act on the same events. I therefore decided to let my mod conflict with this one.
-  [Dragonling](https://mods.factorio.com/user/Dragonling): for the Russian localization -- thanks a lot!
