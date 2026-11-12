# GCKI test coverage

`maru run test --set MOD=GCKI` runs the Lua regressions and the real Factorio
engine suites. CI uses the same task. `maru run test-static --set MOD=GCKI` runs
the Lua regressions, syntax checks and packaging without engine downloads.

| Suite | Coverage |
| --- | --- |
| Base game | One global claimed vehicle, lock/unlock, replacing a claim without unlocking the old car, local summoning, and summoning across non-planet surfaces. |
| Space Age | Separate claims on Nauvis, Vulcanus, Fulgora, Gleba and Aquilo; independent locking, unlocking and summoning; no cross-planet fallback without a local claim; replacement on one planet preserves the others. |
| Platform guards | The shortcut, keyboard input and existing key tool cannot summon onto a platform. Returning to the character restores shortcut availability. |
| Persistence | Both engine suites run Factorio's `game.reload_mods()` and verify the stored vehicle references, unit numbers, surfaces, positions, owners and lockers. Claimed cars remain summonable after reloading. |

The Python tests in `tools/tests/test_gcki_runtime.py` group the fast Lua cases
in `runtime.lua` into base-game and Space Age suites. These use small substitutes
for Factorio APIs and also cover old save records, multiple players, custom
planets, invalid entities, resets and reconciliation.

The engine fixture in `engine/vehicles.lua` uses real players, cars and planet
surfaces and calls the production key handlers. Each scripted click resets the
input cooldown because the fixture executes several interactions in one tick;
reach, collision and ownership checks remain active. Test areas are cleared and
given flat ground, so these tests do not establish vehicle suitability for every
planet's natural terrain or weather.

`ci.json.runtime_tests` selects the engine fixture. The runner installs the
fixture and its loader into a temporary copy of the mod. The release ZIP remains
unchanged and contains neither. Lua assertions write individual results that
appear in the combined test summary, including completed cases before a failure.

Each engine mode explicitly enables its selected mods and disables other bundled
mods. It creates a smoke-test ZIP, reloads it for 600 ticks, then runs the behavior
fixture with a native test player. Persistence checks use Factorio's mod save/load
lifecycle through `reload_mods()` because the native test runner does not write
requested autosaves. This is not a populated save ZIP round trip or an upgrade
test from an older released mod version.
