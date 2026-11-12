#!/usr/bin/env python3
"""Container entrypoint for the existing unit, mod, and engine checks."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


class UnitResult(unittest.TextTestResult):
    """Keep the individual unit outcomes for the combined test summary."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.cases = []

    def record(self, test, status, detail=None):
        name = test.id().rsplit(".", 1)[-1].removeprefix("test_").replace("_", " ")
        case = {"name": f"Automation: {name}", "status": status}
        if detail:
            case["detail"] = detail
        self.cases.append(case)

    def addSuccess(self, test):
        super().addSuccess(test)
        self.record(test, "passed")

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.record(test, "failed")

    def addError(self, test, err):
        super().addError(test, err)
        self.record(test, "failed")

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self.record(test, "skipped", reason)

    def addExpectedFailure(self, test, err):
        super().addExpectedFailure(test, err)
        self.record(test, "skipped", "expected failure")

    def addUnexpectedSuccess(self, test):
        super().addUnexpectedSuccess(test)
        self.record(test, "failed", "unexpected success")


def run_check(tool, command, mod, cases, extra=()):
    """Run a CLI operation and collect only the checks it actually completed."""
    with tempfile.TemporaryDirectory(prefix="mod-report-") as tmp:
        report = Path(tmp) / "checks.json"
        result = subprocess.run([sys.executable, str(tool), command, mod, *extra, "--report", str(report)])
        completed = json.loads(report.read_text()) if report.exists() else []
        cases.extend(completed)
        if result.returncode:
            if not any(case["status"] == "failed" for case in completed):
                cases.append({"name": f"{mod}: {command}", "status": "failed"})
            raise subprocess.CalledProcessError(result.returncode, result.args)


def print_summary(cases, successful):
    print("\nTest results", flush=True)
    labels = {"passed": "PASS", "failed": "FAIL", "skipped": "SKIP"}
    for case in cases:
        detail = f" ({case['detail']})" if case.get("detail") else ""
        print(f"[{labels[case['status']]}] {case['name']}{detail}", flush=True)
    counts = {status: sum(case["status"] == status for case in cases) for status in labels}
    if successful:
        print(f"All executed checks passed: {counts['passed']} passed, {counts['skipped']} skipped.", flush=True)
    else:
        print(f"Tests failed: {counts['passed']} passed, {counts['failed']} failed, "
              f"{counts['skipped']} skipped. Remaining checks were not run.", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mod", default="", help="Directory under mods/; empty selects all mods")
    parser.add_argument("--static-only", action="store_true", help="Skip real Factorio engine tests")
    parser.add_argument("--results", type=Path, default=Path("/results"), help="Engine work directory parent")
    args = parser.parse_args()
    root = Path.cwd()
    tool = root / "tools/mod_ci.py"
    if not tool.is_file():
        parser.error("Mount the repository at /workspace and use it as the working directory")

    discovered = json.loads(subprocess.check_output([sys.executable, str(tool), "list"], text=True))
    mods = [args.mod] if args.mod else discovered
    if not mods:
        parser.error("No mods were discovered")
    for mod in mods:
        if not re.fullmatch(r"[A-Za-z0-9_-]+", mod) or mod not in discovered:
            parser.error(f"Unknown mod directory: {mod}")

    if not args.static_only:
        for key in ("FACTORIO_USERNAME", "FACTORIO_TOKEN"):
            if not os.environ.get(key):
                parser.error(f"Set {key} for dependency downloads, or use --static-only")
        args.results.mkdir(parents=True, exist_ok=True)

    cases = []
    successful = False
    try:
        suite = unittest.defaultTestLoader.discover("tools/tests")
        result = unittest.TextTestRunner(verbosity=2, buffer=True, resultclass=UnitResult).run(suite)
        cases.extend(result.cases)
        if not result.wasSuccessful():
            raise subprocess.CalledProcessError(1, "automation unit tests")
        for mod in mods:
            print(f"\nChecking {mod}", flush=True)
            run_check(tool, "check", mod, cases)
            if args.static_only:
                run_check(tool, "package", mod, cases)
                cases.append({"name": f"{mod}: Factorio engine", "status": "skipped", "detail": "static-only mode"})
            else:
                work = tempfile.mkdtemp(prefix=f"{mod}-", dir=args.results)
                print(f"Engine save and logs will be retained in {work}", flush=True)
                run_check(tool, "engine", mod, cases, ["--work", work])
        successful = True
    finally:
        print_summary(cases, successful)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        raise SystemExit(exc.returncode) from None
