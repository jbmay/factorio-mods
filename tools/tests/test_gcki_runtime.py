"""Run GCKI's Lua behavior regressions in the same container as static checks."""

import os
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[2]
CASES = (
    "claims_are_independent_per_planet",
    "reclaim_replaces_only_same_planet_and_preserves_locks",
    "old_save_claim_needs_no_migration",
    "base_game_keeps_single_global_claim",
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


class GCKIRuntimeTests(unittest.TestCase):
    pass


def runtime_case(name):
    def test(self):
        lua = os.environ.get("LUA") or shutil.which("lua5.2") or shutil.which("lua")
        self.assertTrue(lua, "Lua is required; run through Maru or set LUA to a Lua 5.2 interpreter")
        result = subprocess.run([lua, "tests/GCKI/runtime.lua", name], cwd=ROOT,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    return test


for name in CASES:
    setattr(GCKIRuntimeTests, "test_gcki_" + name, runtime_case(name))
