"""Run GCKI's Lua behavior regressions in the same container as static checks."""

import os
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPACE_AGE_CASES = (
    "claims_are_independent_per_planet",
    "reclaim_replaces_only_same_planet_and_preserves_locks",
    "old_save_claim_needs_no_migration",
    "summon_uses_current_planet_without_moving_other_vehicle",
    "unclaimed_planet_does_not_summon_another_planets_vehicle",
    "platform_blocks_shortcut_hotkey_and_existing_keys",
    "remote_view_from_platform_cannot_bypass_guard",
    "removing_one_claim_preserves_other_planets",
    "reset_player_removes_all_planet_claims",
    "claims_stay_separate_between_players",
    "locking_and_unlocking_are_independent_per_planet",
    "reset_all_visits_all_planets_and_players",
    "invalid_vehicles_and_deleted_surfaces_are_ignored",
    "custom_planets_and_nonplanet_surfaces_have_separate_claims",
    "disabling_space_age_reconciles_to_one_global_claim",
    "moved_vehicle_cannot_create_two_claims_on_one_planet",
)


BASE_GAME_CASES = (
    "base_game_keeps_single_global_claim",
    "base_game_claim_lock_unlock_and_summon",
    "base_game_replacing_claim_preserves_old_lock",
    "claims_stay_separate_between_players",
    "invalid_vehicles_and_deleted_surfaces_are_ignored",
)


LOCK_CASES = (
    "lock_owner_can_enter_drive_and_open_inventory_without_unlocking",
    "lock_allows_other_passengers_but_rejects_other_drivers",
    "locking_occupied_vehicle_keeps_owner_and_closes_other_inventory",
    "lock_allows_unattended_passenger_but_rejects_switching_to_driver",
    "lock_redirects_other_driver_to_an_available_passenger_seat",
    "lock_rejects_other_inventory_but_unlock_restores_public_access",
    "lock_holder_keeps_access_after_claiming_a_replacement",
)
BASE_GAME_CASES += LOCK_CASES
SPACE_AGE_CASES += LOCK_CASES


class GCKIBaseGameTests(unittest.TestCase):
    pass


class GCKISpaceAgeTests(unittest.TestCase):
    pass


def runtime_case(name, mode):
    def test(self):
        lua = os.environ.get("LUA") or shutil.which("lua5.2") or shutil.which("lua")
        self.assertTrue(lua, "Lua is required; run through Maru or set LUA to a Lua 5.2 interpreter")
        result = subprocess.run([lua, "tests/GCKI/runtime.lua", name, mode], cwd=ROOT,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    return test


for name in BASE_GAME_CASES:
    setattr(GCKIBaseGameTests, "test_gcki_base_game_" + name.removeprefix("base_game_"),
            runtime_case(name, "base-game"))
for name in SPACE_AGE_CASES:
    setattr(GCKISpaceAgeTests, "test_gcki_space_age_" + name, runtime_case(name, "space-age"))
