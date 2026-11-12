This is **Gizmos Car Keys (continued)**, a fork of [Gizmos Car Keys (improved)](https://mods.factorio.com/mod/GCKI) by Pi-C. Its internal mod name and remote interface are `gcki-continued`.

The original mod and this fork cannot be enabled together.

Is your vehicle always where you are not, especially when you need it? Do you regularly waste time running to your vehicle because you need something from its trunk? Then *let it come to you* instead!

This mod is based on [Gizmos Car Keys](https://mods.factorio.com/mod/Gizmos_Car_Keys) by aodgizmo, since version 1.1.2 it supports spider-vehicles as well. It should work with most modded vehicles based on a car or spider-vehicle prototype. If you are the author of a mod that uses such prototypes for special purposes, you can blacklist your prototypes with GCKI.

# Usage #
The keys will be available as long as an unlock technology has been researched. Usually that will be Automobilism, but there may be others depending on the mods you are using (e.g. Ships if [Cargo Ships](https://mods.factorio.com/mod/cargo-ships) is active). Take the keys and click on a vehicle to claim it. Click *on the same vehicle* again to lock or unlock it. By using the keys *on another vehicle*, you replace your claimed vehicle on that planet when Space Age is enabled, or your single global vehicle without Space Age. (Hint: If you want to exchange vehicles, you should lock your old vehicle before giving it up! As of version 1.1.2, any unlocked vehicle without a player character inside can be claimed by *any* player. In other words, vehicles can be stolen by another force!)

If you use the keys on a free position where the vehicle can be placed, it will be summoned there if the position is within your reach.
(Hint:

In contrast to the original mod, this one also supports vehicle grids and everything else a vehicle might contain. It also is possible to summon vehicles to another surface; driver and player will be teleported along  with  the vehicle unless they have chosen to be left on the original surface via a per-player runtime setting.

Other than the original mod, this one should be safe to use in multiplayer games.

# Does it work with other mods? #
## Space Age ##
With Space Age enabled, each player can claim one vehicle per planet. Clicking a vehicle with the keys claims it or toggles its lock; clicking an empty position summons the vehicle claimed on the current planet. Claims on other planets are preserved, and vehicles cannot be summoned between planets. Custom planets are supported; non-planet surfaces have independent assignments.

The shortcut and keyboard input cannot be used on space platforms. Keys also cannot be used while remotely viewing another surface; return to your character's surface first. Without Space Age, the original single global vehicle behavior remains.

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



# Supported languages  #
- English
- German
- [Russian](https://mods.factorio.com/mod/MyRUS2) (Dragonling fetches and translates new/changed strings from other mods and includes them in his. I'll eventually integrate his changes, but you'll get new translations faster if you also have his translations-pack  mod installed!)

*If you can provide a localization for another language, I'd  be happy to include it! :-)*

# Uninstalling GCKI #
If you want to remove GCKI from a game, you should make sure that there are no locked vehicles left behind! Otherwise, you won't be able to drive them, mine them, or open their inventory. Likewise, if you are participating in a multiplayer game and intend to never join your current server again, you should unlock or reset all vehicles owned or locked by you so that other players can use them.

# Help needed #
I've spent quite some time on testing this mod to make sure it's safe to use in multiplayer mode. However, doing these tests locally may not be reliable. So I'm interested in any feedback on issues while playing multiplayer games!

# Credits  #
Credits go to

- [aodgizmo](https://mods.factorio.com/user/aodgizmo): for the original mod -- I used the code (and changed, added to, or removed parts of it) and the car-key graphics (which I also used for the mod thumbnail) in my mod.
- [Zahnfeechen](https://mods.factorio.com/user/Zahnfeechen): for [Gizmos Car Keys - Zahnfeechen Patch](https://mods.factorio.com/mod/Gizmos_Car_Keys_Z_Patch) (which updated aodgizmo's mod for Factorio 0.17) -- I happily played with this mod myself until I decided to make my own version. Because this mod shares a lot of code with mine, it is not only unnecessary to have both active at the same time, it could even lead to unforeseeable results because both mods act on the same events. I therefore decided to let my mod conflict with this one.
-  [Dragonling](https://mods.factorio.com/user/Dragonling): for the Russian localization -- thanks a lot!
