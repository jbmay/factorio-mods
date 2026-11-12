import importlib.util
import io
import json
from pathlib import Path
import tempfile
import tarfile
import unittest
from unittest.mock import patch
import zipfile

SPEC = importlib.util.spec_from_file_location("mod_ci", Path(__file__).parents[1] / "mod_ci.py")
ci = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ci)


class ModCITests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.patch = patch.object(ci, "ROOT", self.root)
        self.patch.start()
        self.addCleanup(self.patch.stop)
        self.mod = self.root / "mods/Demo"
        self.mod.mkdir(parents=True)
        self.info = {"name": "Demo", "version": "1.0.0", "factorio_version": "2.0",
                     "title": "Demo", "author": "Example", "dependencies": ["base >= 2.0.26"]}
        self.write("info.json", self.info)
        self.write("ci.json", {"factorio": "2.0.77", "dependencies": {}, "scenarios": [],
                               "saves": [], "benchmark_ticks": 10})
        self.write("portal.json", {"license": "default_mit", "category": "content"})
        (self.mod / "version.txt").write_text("1.0.0\n")
        (self.mod / "changelog.txt").write_text("-" * 99 + "\nVersion: 1.0.0\n\n  Changes:\n    - Imported.\n")
        (self.mod / "control.lua").write_text("local x = 1\n")
        (self.mod / "description.md").write_text("Demo mod")
        (self.root / ".release-please-manifest.json").write_text(json.dumps({"mods/Demo": "1.0.0"}))
        (self.root / "release-please-config.json").write_text(json.dumps({"packages": {"mods/Demo": {"component": "Demo"}}}))

    def write(self, name, data):
        (self.mod / name).write_text(json.dumps(data))

    def test_report_retains_passes_and_marks_failure_without_claiming_success(self):
        path = self.root / "report.json"
        report = ci.TestReport(path)
        with report.case("successful check"):
            pass
        with self.assertRaisesRegex(ValueError, "deliberate failure"):
            with report.case("failing check"):
                raise ValueError("deliberate failure")
        report.record("optional fixture", "skipped", "none configured")
        self.assertEqual(ci.read_json(path), [
            {"name": "successful check", "status": "passed"},
            {"name": "failing check", "status": "failed"},
            {"name": "optional fixture", "status": "skipped", "detail": "none configured"},
        ])

    def test_package_is_reproducible_and_excludes_development_files(self):
        (self.mod / "control.lua.bak").write_text("backup")
        (self.mod / "README.md").write_text("development")
        (self.mod / "graphics").mkdir()
        (self.mod / "graphics/icon.png").write_bytes(b"image")
        (self.mod / "graphics/icon.xcf").write_bytes(b"source")
        first = ci.package("Demo").read_bytes()
        (self.mod / "control.lua").touch()
        self.assertEqual(first, ci.package("Demo").read_bytes())
        with zipfile.ZipFile(io.BytesIO(first)) as z:
            self.assertEqual(set(z.namelist()), {"Demo_1.0.0/info.json", "Demo_1.0.0/control.lua",
                                               "Demo_1.0.0/changelog.txt", "Demo_1.0.0/graphics/icon.png"})

    def test_new_version_converts_release_notes_preserving_history(self):
        (self.mod / "CHANGELOG.md").write_text(
            "# Changelog\n\n## [1.0.1](https://example.com) (2026-11-11)\n\n"
            "### Bug Fixes\n\n* **Demo:** Fix lock ([abc](https://example.com))\n\n"
            "## 1.0.0 (2025-01-01)\n* Old\n")
        result = ci.changelog(self.mod, "1.0.1").decode()
        self.assertIn("Version: 1.0.1\nDate: 2026-11-11", result)
        self.assertIn("    - Demo: Fix lock (abc)", result)
        self.assertEqual(result.count("Version: 1.0.0"), 1)
        self.assertNotIn("    - Old", result)

    def test_missing_release_notes_fail(self):
        with self.assertRaisesRegex(ValueError, "no Release Please"):
            ci.changelog(self.mod, "1.0.1")

    def test_changelog_includes_all_fork_releases_without_future_or_duplicate_entries(self):
        (self.mod / "CHANGELOG.md").write_text(
            "# Changelog\n\n## [1.2.0](https://example.com) (2026-11-14)\n* Future\n\n"
            "## [1.1.1](https://example.com) (2026-11-13)\n* Current patch\n\n"
            "## [1.1.0](https://example.com) (2026-11-12)\n* Space Age\n\n"
            "## [1.0.1](https://example.com) (2026-11-11)\n* Initial fork\n\n"
            "## [1.0.0](https://example.com) (2025-01-01)\n* Duplicate upstream\n")
        result = ci.changelog(self.mod, "1.1.1").decode()
        self.assertEqual(ci.re.findall(r"^Version: (.*)$", result, ci.re.MULTILINE),
                         ["1.1.1", "1.1.0", "1.0.1", "1.0.0"])
        for entry in ("Current patch", "Space Age", "Initial fork", "Imported."):
            self.assertIn(entry, result)
        self.assertNotIn("Future", result)
        self.assertNotIn("Duplicate upstream", result)

    def test_changelog_backfills_history_when_current_version_already_exists_in_text(self):
        old = (self.mod / "changelog.txt").read_text()
        (self.mod / "changelog.txt").write_text(
            "-" * 99 + "\nVersion: 1.1.0\nDate: 2026-11-12\n\n  Changes:\n    - Existing current.\n\n" + old)
        (self.mod / "CHANGELOG.md").write_text(
            "## 1.1.0 (2026-11-12)\n* Replacement text\n\n"
            "## 1.0.1 (2026-11-11)\n* Missing fork release\n")
        result = ci.changelog(self.mod, "1.1.0").decode()
        self.assertEqual(ci.re.findall(r"^Version: (.*)$", result, ci.re.MULTILINE),
                         ["1.1.0", "1.0.1", "1.0.0"])
        self.assertIn("Existing current.", result)
        self.assertIn("Missing fork release", result)
        self.assertNotIn("Replacement text", result)

    def test_engine_and_compatibility_metadata_must_agree(self):
        self.info["factorio_version"] = "2.1"
        self.write("info.json", self.info)
        with self.assertRaisesRegex(ValueError, "disagree"):
            ci.validate("Demo")

    def test_release_versions_must_agree(self):
        (self.mod / "version.txt").write_text("1.0.1")
        with self.assertRaisesRegex(ValueError, "version.txt"):
            ci.validate("Demo")

    def test_dependency_constraints_conflicts_and_missing_transitives(self):
        infos = {"Demo": self.info, "base": {"name": "base", "version": "2.0.77", "dependencies": []}}
        ci.check_dependencies(infos)
        self.info["dependencies"] += ["? absent >= 1.0.0", "+ recommended", "! conflict"]
        ci.check_dependencies(infos)
        self.info["dependencies"] += ["library >= 2.0.0"]
        with self.assertRaisesRegex(ValueError, "Pin required"):
            ci.check_dependencies(infos)
        infos["library"] = {"name": "library", "version": "1.9.9", "dependencies": []}
        with self.assertRaisesRegex(ValueError, "Unsatisfied"):
            ci.check_dependencies(infos)
        self.info["dependencies"] = ["! base"]
        with self.assertRaisesRegex(ValueError, "Conflicting"):
            ci.check_dependencies(infos)

    def test_release_matrix_maps_paths_to_independent_tags(self):
        outputs = {"paths_released": '["mods/Demo"]', "mods/Demo--tag_name": "Demo/v1.0.0"}
        self.assertEqual(ci.release_matrix(outputs), [{"mod": "Demo", "tag": "Demo/v1.0.0"}])
        outputs["mods/Demo--tag_name"] = "Other/v1.0.0"
        with self.assertRaisesRegex(ValueError, "does not match"):
            ci.release_matrix(outputs)
        self.assertEqual(ci.release_matrix({}), [])

    def test_tag_matrix_selects_only_registered_mods_with_matching_versions(self):
        self.assertEqual(ci.tag_matrix("Demo/v1.0.0"), [{"mod": "Demo", "tag": "Demo/v1.0.0"}])
        for tag in ("Other/v1.0.0", "Demo-v1.0.0", "main", "refs/tags/Demo/v1.0.0"):
            with self.assertRaisesRegex(ValueError, "exactly one registered mod"):
                ci.tag_matrix(tag)
        for tag in ("Demo/v1.0.1", "Demo/v1.0.0-extra"):
            with self.assertRaisesRegex(ValueError, "does not match"):
                ci.tag_matrix(tag)

    def test_unsafe_selectors_and_symlinks_are_rejected(self):
        for name in ("../Demo", "Demo/foo", "$(whoami)"):
            with self.assertRaises(ValueError):
                ci.mod_path(name)
        (self.mod / "alias.lua").symlink_to(self.mod / "control.lua")
        with self.assertRaisesRegex(ValueError, "Symlinks"):
            ci.package("Demo")

    def engine_tar(self, version, bundled=None):
        buffer = io.BytesIO()
        files = {
            "factorio/bin/x64/factorio": b"test executable",
            "factorio/data/base/info.json": json.dumps({"name": "base", "version": version,
                                                       "dependencies": ["core"]}).encode(),
            "factorio/data/core/info.json": json.dumps({"name": "core", "version": "0.0.0",
                                                       "dependencies": []}).encode(),
        }
        for name, dependencies in (bundled or {}).items():
            files[f"factorio/data/{name}/info.json"] = json.dumps({
                "name": name, "version": version, "dependencies": dependencies,
            }).encode()
        with tarfile.open(fileobj=buffer, mode="w:xz") as tar:
            for name, data in files.items():
                member = tarfile.TarInfo(name)
                member.size = len(data)
                tar.addfile(member, io.BytesIO(data))
        return buffer.getvalue()

    @patch.object(ci.subprocess, "run")
    @patch.object(ci, "request")
    def test_space_age_checks_base_then_expansion_with_bundled_dependencies(self, request, run):
        config = ci.read_json(self.mod / "ci.json")
        config["space_age"] = True
        self.write("ci.json", config)
        request.return_value = self.engine_tar("2.0.77", {
            "space-age": ["base", "elevated-rails", "+ quality", "recycler"],
            "elevated-rails": ["base"], "quality": ["base"], "recycler": ["base"],
        })
        combinations = []
        disabled = []
        work = self.root / "expansion"
        def capture(*args, **kwargs):
            combinations.append({m["name"] for m in ci.read_json(work / "mods/mod-list.json")["mods"] if m["enabled"]})
            disabled.append({m["name"] for m in ci.read_json(work / "mods/mod-list.json")["mods"] if not m["enabled"]})
        run.side_effect = capture
        ci.run_engine("Demo", work)
        self.assertEqual(combinations[:2], [{"base", "Demo"}] * 2)
        self.assertEqual(disabled[:2], [{"space-age", "elevated-rails", "quality", "recycler"}] * 2)
        self.assertEqual(combinations[2:], [{"base", "Demo", "space-age", "elevated-rails", "quality", "recycler"}] * 2)
        commands = [call.args[0] for call in run.call_args_list]
        self.assertIn(str(work / "space-age-smoke.zip"), commands[2])
        self.assertIn(str(work / "space-age-smoke.zip"), commands[3])
        request.assert_called_once()

    def test_space_age_configuration_requires_boolean(self):
        config = ci.read_json(self.mod / "ci.json")
        config["space_age"] = "true"
        self.write("ci.json", config)
        with self.assertRaisesRegex(ValueError, "space_age must be a boolean"):
            ci.validate("Demo")

    @patch.object(ci.subprocess, "run")
    def test_runtime_suites_are_temporary_and_report_individual_engine_cases(self, run):
        fixture = self.root / "tests/Demo/engine/vehicles.lua"
        fixture.parent.mkdir(parents=True)
        fixture.write_text("return function(context) script.finish_test(true) end")
        archive = ci.package("Demo")
        original = archive.read_bytes()
        work = self.root / "runtime"
        mods = work / "mods"
        mods.mkdir(parents=True)
        ci.shutil.copy2(archive, mods)
        config = {"runtime_tests": ["vehicles"], "factorio": "2.1.24"}
        report = ci.TestReport()
        def simulate(args, **kwargs):
            mode = args[-1].rsplit(":", 1)[-1]
            output = work / "data/script-output" / f"mod-ci-vehicles-{mode}.json"
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(json.dumps([{"name": "claims survive reload", "status": "passed"}]))
        run.side_effect = simulate
        for mode in ("base-game", "space-age"):
            ci.run_runtime_tests("Demo", config, archive, mods, ["factorio"], work / "smoke.zip", work, mode, report)
        control = (mods / archive.stem / "control.lua").read_text()
        self.assertEqual(control.count("-- mod-ci runtime test loader"), 1)
        self.assertTrue((mods / archive.stem / "ci-runtime/vehicles.lua").exists())
        self.assertEqual(archive.read_bytes(), original)
        with zipfile.ZipFile(archive) as z:
            self.assertFalse(any("ci-runtime" in name for name in z.namelist()))
            self.assertNotIn(b"mod-ci runtime test loader", z.read("Demo_1.0.0/control.lua"))
        self.assertEqual(report.cases[0], {"name": "Demo: base-game: claims survive reload", "status": "passed"})
        self.assertEqual(run.call_args_list[0].args[0][-2:], ["--test-arg", "mod-ci:vehicles:base-game"])

    @patch.object(ci.subprocess, "run")
    def test_runtime_failure_keeps_completed_assertions_and_never_passes_suite(self, run):
        fixture = self.root / "tests/Demo/engine/vehicles.lua"
        fixture.parent.mkdir(parents=True)
        fixture.write_text("return function(context) end")
        archive = ci.package("Demo")
        work = self.root / "runtime"
        mods = work / "mods"
        mods.mkdir(parents=True)
        ci.shutil.copy2(archive, mods)
        output = work / "data/script-output/mod-ci-vehicles-space-age.json"
        output.parent.mkdir(parents=True)
        # A stale report must not turn an engine run with no assertions into a pass.
        output.write_text('[{"name":"stale","status":"passed"}]')
        report = ci.TestReport()
        config = {"runtime_tests": ["vehicles"], "factorio": "2.1.24"}
        with self.assertRaisesRegex(ValueError, "did not report successful assertions"):
            ci.run_runtime_tests("Demo", config, archive, mods, ["factorio"], work / "smoke.zip", work, "space-age", report)
        def fail(args, **kwargs):
            output.write_text(json.dumps([{"name": "claim car", "status": "passed"},
                                          {"name": "cross-planet summon", "status": "failed"}]))
            raise ci.subprocess.CalledProcessError(1, args)
        run.side_effect = fail
        report = ci.TestReport()
        with self.assertRaises(ci.subprocess.CalledProcessError):
            ci.run_runtime_tests("Demo", config, archive, mods, ["factorio"], work / "smoke.zip", work, "space-age", report)
        self.assertEqual([case["status"] for case in report.cases], ["passed", "failed", "failed"])

    def test_runtime_suites_require_safe_unique_names_and_supported_engine(self):
        config = ci.read_json(self.mod / "ci.json")
        for names in (["../vehicles"], ["vehicles", "vehicles"], ["vehicles"]):
            config["runtime_tests"] = names
            self.write("ci.json", config)
            with self.assertRaises(ValueError):
                ci.validate("Demo")

    @patch.object(ci.subprocess, "run")
    @patch.object(ci, "request")
    def test_failed_engine_load_is_reported_without_passing_tick_or_fixture_tests(self, request, run):
        request.return_value = self.engine_tar("2.0.77")
        run.side_effect = [None, ci.subprocess.CalledProcessError(1, "factorio --benchmark")]
        report = ci.TestReport(self.root / "engine-report.json")
        with self.assertRaises(ci.subprocess.CalledProcessError):
            ci.run_engine("Demo", self.root / "work", report)
        self.assertEqual(report.cases[-2:], [
            {"name": "Demo: Factorio 2.0.77 mod initialization and new save creation", "status": "passed"},
            {"name": "Demo: reload generated save and run 10 ticks", "status": "failed"},
        ])
        self.assertFalse(any("fixture" in case["name"] for case in report.cases))

    @patch.dict("os.environ", {"FACTORIO_USERNAME": "example", "FACTORIO_TOKEN": "test-token"})
    @patch.object(ci.subprocess, "run")
    @patch.object(ci, "api")
    @patch.object(ci, "request")
    def test_engine_installs_verified_pins_and_runs_create_and_benchmark(self, request, api, run):
        config = ci.read_json(self.mod / "ci.json")
        config["dependencies"] = {"Library": "1.0.0"}
        self.write("ci.json", config)
        self.info["dependencies"].append("Library >= 1.0.0")
        self.write("info.json", self.info)
        dependency = io.BytesIO()
        with zipfile.ZipFile(dependency, "w") as z:
            z.writestr("Library_1.0.0/info.json", json.dumps({"name": "Library", "version": "1.0.0",
                                                           "dependencies": ["base >= 2.0.0"]}))
        dep = dependency.getvalue()
        api.return_value = {"releases": [{"version": "1.0.0", "info_json": {"factorio_version": "2.0"},
                                         "download_url": "/download/library", "sha1": ci.hashlib.sha1(dep).hexdigest()}]}
        request.side_effect = [self.engine_tar("2.0.77"), dep]
        work = self.root / "work"
        ci.run_engine("Demo", work)
        commands = [c.args[0] for c in run.call_args_list]
        self.assertEqual(len(commands), 2)
        self.assertIn("--create", commands[0])
        self.assertIn("--benchmark", commands[1])
        self.assertIn(str(work / "config.ini"), commands[0])
        self.assertTrue((work / "mods/Library_1.0.0.zip").exists())
        enabled = ci.read_json(work / "mods/mod-list.json")["mods"]
        self.assertEqual({m["name"] for m in enabled}, {"base", "Demo", "Library"})

    @patch.object(ci.subprocess, "run")
    @patch.object(ci, "request")
    def test_native_scenario_is_staged_but_not_published(self, request, run):
        self.info["factorio_version"] = "2.1"
        self.write("info.json", self.info)
        config = ci.read_json(self.mod / "ci.json")
        config.update({"factorio": "2.1.24", "scenarios": ["smoke"]})
        self.write("ci.json", config)
        fixture = self.root / "tests/Demo/scenarios/smoke"
        fixture.mkdir(parents=True)
        (fixture / "control.lua").write_text("script.finish_test(true)")
        request.return_value = self.engine_tar("2.1.24")
        work = self.root / "native"
        ci.run_engine("Demo", work)
        commands = [c.args[0] for c in run.call_args_list]
        self.assertIn("--test-scenario", commands[2])
        self.assertIn("Demo/smoke", commands[2])
        self.assertNotIn("--test-ticks", commands[2])
        self.assertTrue((work / "mods/Demo_1.0.0/scenarios/smoke/control.lua").exists())
        with zipfile.ZipFile(ci.package("Demo")) as z:
            self.assertFalse(any("scenarios/smoke" in name for name in z.namelist()))

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "test-key"})
    def test_publish_rejects_wrong_tag_or_modified_artifact(self):
        archive = ci.package("Demo")
        with self.assertRaisesRegex(ValueError, "tag/version"):
            ci.publish("Demo", archive, "Demo/v2.0.0")
        archive.write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "differs"):
            ci.publish("Demo", archive, "Demo/v1.0.0")

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "test-key"})
    def test_fork_cannot_publish_using_upstream_identity(self):
        self.write("portal.json", {"license": "default_mit", "category": "content", "upstream_name": "Demo"})
        with self.assertRaisesRegex(ValueError, "distinct fork"):
            ci.publish("Demo", ci.package("Demo"), "Demo/v1.0.0")
        with self.assertRaisesRegex(ValueError, "distinct fork"):
            ci.update_description("Demo")

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "test-key"})
    @patch.object(ci, "api")
    @patch.object(ci, "request")
    def test_first_release_uses_publish_api_and_declared_license(self, request, api):
        request.side_effect = ValueError("HTTP request failed (status 404)")
        api.side_effect = [{"upload_url": "https://mods.factorio.com/upload/one"}, {"success": True}]
        ci.publish("Demo", ci.package("Demo"), "Demo/v1.0.0")
        self.assertTrue(api.call_args_list[0].args[0].endswith("/init_publish"))
        self.assertEqual(api.call_args_list[1].kwargs["fields"]["license"], "default_mit")

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "test-key"})
    @patch.object(ci, "api")
    @patch.object(ci, "request")
    def test_upload_is_idempotent_only_for_identical_existing_release(self, request, api):
        archive = ci.package("Demo")
        prior = {"version": "1.0.0", "sha1": ci.hashlib.sha1(archive.read_bytes()).hexdigest()}
        request.return_value = json.dumps({"releases": [prior]}).encode()
        api.return_value = {"success": True}
        ci.publish("Demo", archive, "Demo/v1.0.0")
        api.assert_called_once_with("https://mods.factorio.com/api/v2/mods/edit_details",
                                    fields={"mod": "Demo", "description": "Demo mod"}, token="test-key")
        api.reset_mock()
        prior["sha1"] = "different"
        request.return_value = json.dumps({"releases": [prior]}).encode()
        with self.assertRaisesRegex(ValueError, "different bytes"):
            ci.publish("Demo", archive, "Demo/v1.0.0")
        api.assert_not_called()

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "test-key"})
    @patch.object(ci, "api")
    @patch.object(ci, "request")
    def test_existing_release_upload_refreshes_description_after_successful_upload(self, request, api):
        request.return_value = json.dumps({"releases": []}).encode()
        api.side_effect = [{"upload_url": "https://uploads.example.com/release"}, {"success": True}, {"success": True}]
        description = "# Space Age\n\nOne vehicle per planet.\n"
        (self.mod / "description.md").write_text(description)
        archive = ci.package("Demo")
        ci.publish("Demo", archive, "Demo/v1.0.0")
        self.assertTrue(api.call_args_list[0].args[0].endswith("releases/init_upload"))
        self.assertEqual(api.call_args_list[1].args[0], "https://uploads.example.com/release")
        self.assertNotIn("token", api.call_args_list[1].kwargs)
        self.assertEqual(api.call_args_list[2].args[0], "https://mods.factorio.com/api/v2/mods/edit_details")
        self.assertEqual(api.call_args_list[2].kwargs["fields"], {"mod": "Demo", "description": description})

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "test-key"})
    @patch.object(ci, "api")
    @patch.object(ci, "request")
    def test_failed_release_upload_does_not_change_portal_description(self, request, api):
        request.return_value = json.dumps({"releases": []}).encode()
        api.side_effect = [{"upload_url": "https://uploads.example.com/release"}, {"success": False}]
        with self.assertRaisesRegex(ValueError, "successful upload"):
            ci.publish("Demo", ci.package("Demo"), "Demo/v1.0.0")
        self.assertEqual(api.call_count, 2)

    @patch.dict("os.environ", {"FACTORIO_API_KEY": "edit-only-key"})
    @patch.object(ci, "api")
    def test_update_description_needs_no_release_archive_and_fails_without_confirmation(self, api):
        api.return_value = {"success": True}
        ci.update_description("Demo")
        api.assert_called_once_with("https://mods.factorio.com/api/v2/mods/edit_details",
                                    fields={"mod": "Demo", "description": "Demo mod"}, token="edit-only-key")
        self.assertFalse((self.root / "dist").exists())
        api.return_value = {}
        with self.assertRaisesRegex(ValueError, "successful description update"):
            ci.update_description("Demo")

    @patch.dict("os.environ", {}, clear=True)
    @patch.object(ci, "api")
    def test_update_description_requires_edit_credentials_before_contacting_portal(self, api):
        with self.assertRaisesRegex(ValueError, "Edit Mods"):
            ci.update_description("Demo")
        api.assert_not_called()

    @patch.object(ci.urllib.request, "urlopen")
    def test_details_request_uses_authenticated_multipart_without_a_file(self, urlopen):
        urlopen.return_value.__enter__.return_value.read.return_value = b'{"success":true}'
        description = "# Space Age\n\nPlanet claims & passenger access — updated.\n"
        ci.request("https://mods.factorio.com/api/v2/mods/edit_details",
                   fields={"mod": "Demo", "description": description}, token="test-key")
        request = urlopen.call_args.args[0]
        self.assertEqual(request.get_method(), "POST")
        self.assertEqual(request.get_header("Authorization"), "Bearer test-key")
        self.assertTrue(request.get_header("Content-type").startswith("multipart/form-data; boundary="))
        self.assertIn(description.encode(), request.data)
        self.assertIn(b'name="mod"\r\n\r\nDemo\r\n', request.data)
        self.assertNotIn(b'filename=', request.data)
        self.assertNotIn(b'test-key', request.data)


if __name__ == "__main__":
    unittest.main()
