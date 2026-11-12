#!/usr/bin/env python3
"""Monorepo checks, deterministic packages, engine tests, and portal uploads.

Python standard library only. Network commands never print credential-bearing URLs.
"""

import argparse
from contextlib import contextmanager
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = r"\d+\.\d+\.\d+"
NAME = r"[A-Za-z0-9_-]{4,49}"
DEPENDENCY = re.compile(
    r"\s*(?P<prefix>\(\?\)|[?!~+])?\s*(?P<name>[\w-]+)"
    r"(?:\s*(?P<op>>=|<=|=|>|<)\s*(?P<version>\d+\.\d+(?:\.\d+)?))?\s*"
)
RUNTIME_DIRS = {"scripts", "prototypes", "migrations", "libs", "locale", "graphics",
                "sound", "sounds", "music", "scenarios", "campaigns", "tutorials"}
ASSET_SUFFIXES = {".lua", ".json", ".cfg", ".png", ".jpg", ".jpeg", ".ogg",
                  ".wav", ".flac", ".ttf", ".otf", ".txt"}
ROOT_FILES = {"info.json", "changelog.txt", "thumbnail.png", "LICENSE", "LICENSE.txt",
              "LICENSE.md", "COPYING", "credits.txt"}


class TestReport:
    """Record completed checks, optionally sharing their results with a caller."""

    def __init__(self, path=None):
        self.path = Path(path) if path else None
        self.cases = []

    def record(self, name, status, detail=None):
        case = {"name": name, "status": status}
        if detail:
            case["detail"] = detail
        self.cases.append(case)
        if self.path:
            self.path.write_text(json.dumps(self.cases, indent=2) + "\n")
        suffix = f" ({detail})" if detail else ""
        label = {"passed": "PASS", "failed": "FAIL", "skipped": "SKIP"}[status]
        print(f"[{label}] {name}{suffix}", file=sys.stderr, flush=True)

    @contextmanager
    def case(self, name):
        print(f"[RUN] {name}", file=sys.stderr, flush=True)
        try:
            yield
        except Exception:
            self.record(name, "failed")
            raise
        else:
            self.record(name, "passed")


def read_json(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def mod_path(mod):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", mod):
        raise ValueError("Mod selector must be a directory name under mods/")
    path = ROOT / "mods" / mod
    if not path.is_dir() or path.is_symlink():
        raise ValueError(f"Unknown mod directory: {mod}")
    return path


def version_tuple(value):
    return tuple(int(x) for x in value.split("."))


def satisfies(actual, op, expected):
    a = version_tuple(actual)
    b = version_tuple(expected)
    a, b = a + (0,) * (3 - len(a)), b + (0,) * (3 - len(b))
    return {">=": a >= b, "<=": a <= b, "=": a == b, ">": a > b, "<": a < b}[op]


def validate(mod):
    path = mod_path(mod)
    info, ci = read_json(path / "info.json"), read_json(path / "ci.json")
    for field in ("name", "version", "title", "author", "factorio_version"):
        if not isinstance(info.get(field), str) or not info[field]:
            raise ValueError(f"{mod}: missing metadata {field}")
    if not re.fullmatch(NAME, info["name"]) or not re.fullmatch(VERSION, info["version"]):
        raise ValueError(f"{mod}: invalid portal name or version")
    if any(int(x) > 65535 for x in info["version"].split(".")):
        raise ValueError(f"{mod}: version exceeds Factorio limits")
    if not re.fullmatch(VERSION, ci["factorio"]):
        raise ValueError(f"{mod}: pin an exact engine version")
    if ".".join(ci["factorio"].split(".")[:2]) != info["factorio_version"]:
        raise ValueError(f"{mod}: engine pin and factorio_version disagree")
    if (path / "version.txt").read_text().strip() != info["version"]:
        raise ValueError(f"{mod}: Release Please version.txt and info.json disagree")
    manifest = read_json(ROOT / ".release-please-manifest.json")
    packages = read_json(ROOT / "release-please-config.json")["packages"]
    key = f"mods/{mod}"
    if manifest.get(key) != info["version"] or key not in packages:
        raise ValueError(f"{mod}: release manifest/configuration disagree with metadata")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", packages[key]["component"]):
        raise ValueError(f"{mod}: unsafe release component")
    if not isinstance(ci.get("dependencies"), dict):
        raise ValueError(f"{mod}: ci.json needs pinned dependencies")
    for name, version in ci["dependencies"].items():
        if not re.fullmatch(NAME, name) or not re.fullmatch(VERSION, version):
            raise ValueError(f"{mod}: invalid dependency pin")
    portal = read_json(path / "portal.json")
    if not portal.get("license") or not portal.get("category"):
        raise ValueError(f"{mod}: portal.json must specify license and category")
    for dep in info.get("dependencies", ["base"]):
        if not isinstance(dep, str) or not DEPENDENCY.fullmatch(dep):
            raise ValueError(f"{mod}: unsupported dependency {dep!r}")
    for key in ("scenarios", "saves", "runtime_tests"):
        items = ci.get(key, []) if key == "runtime_tests" else ci.get(key)
        if not isinstance(items, list):
            raise ValueError(f"{mod}: ci.json needs a {key} list")
        for item in items:
            if not re.fullmatch(r"[A-Za-z0-9_.-]+", item) or item in (".", ".."):
                raise ValueError(f"{mod}: unsafe test fixture name")
        if len(items) != len(set(items)):
            raise ValueError(f"{mod}: duplicate {key} fixture")
    if ci.get("runtime_tests") and version_tuple(ci["factorio"]) < (2, 1, 24):
        raise ValueError("Runtime behavior tests require Factorio >= 2.1.24")
    if not isinstance(ci.get("benchmark_ticks"), int) or ci["benchmark_ticks"] < 1:
        raise ValueError(f"{mod}: benchmark_ticks must be positive")
    if not isinstance(ci.get("space_age", False), bool):
        raise ValueError(f"{mod}: space_age must be a boolean")
    return path, info, ci


def packaged_files(path):
    for file in sorted(path.rglob("*")):
        if file.is_symlink():
            raise ValueError(f"Symlinks are not allowed in mod sources: {file}")
        if not file.is_file():
            continue
        rel = file.relative_to(path)
        if any(part.startswith(".") for part in rel.parts):
            continue
        if len(rel.parts) == 1:
            include = rel.name in ROOT_FILES or file.suffix == ".lua"
        else:
            include = rel.parts[0] in RUNTIME_DIRS and file.suffix.lower() in ASSET_SUFFIXES
        if include:
            yield file, rel


def changelog(path, version):
    original = (path / "changelog.txt").read_text(encoding="utf-8")
    if re.search(rf"^Version: {re.escape(version)}\s*$", original, re.MULTILINE):
        return original.encode()
    # Release Please generates Markdown; the portal requires Factorio's text format.
    markdown = path / "CHANGELOG.md"
    if not markdown.exists():
        raise ValueError("New version has no Release Please CHANGELOG.md entry")
    text = markdown.read_text()
    match = re.search(
        rf"^## \[?{re.escape(version)}\]?(?:[^\n]*)\((\d{{4}}-\d{{2}}-\d{{2}})\)\s*\n(.*?)(?=^## |\Z)",
        text, re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError("Cannot find dated release notes for the package version")
    notes = []
    for line in match[2].splitlines():
        if line.startswith("* ") or line.startswith("- "):
            line = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", line[2:])
            notes.append("    - " + line.replace("**", ""))
    if not notes:
        raise ValueError("Release changelog has no entries")
    entry = "-" * 99 + f"\nVersion: {version}\nDate: {match[1]}\n\n  Changes:\n"
    return (entry + "\n".join(notes) + "\n\n" + original).encode()


def package(mod, output=None):
    path, info, _ = validate(mod)
    output = Path(output) if output else ROOT / "dist"
    output.mkdir(parents=True, exist_ok=True)
    stem = f"{info['name']}_{info['version']}"
    archive = output / f"{stem}.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as z:
        for file, rel in packaged_files(path):
            data = changelog(path, info["version"]) if str(rel) == "changelog.txt" else file.read_bytes()
            entry = zipfile.ZipInfo(f"{stem}/{rel.as_posix()}", (1980, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            z.writestr(entry, data)
    return archive


def request(url, *, fields=None, token=None, file=None):
    headers = {"User-Agent": "factorio-mods-ci"}
    data = None
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if fields is not None:
        if file:
            boundary = uuid.uuid4().hex
            parts = []
            for key, value in fields.items():
                parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode())
            parts.extend([
                f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{file.name}"\r\nContent-Type: application/zip\r\n\r\n'.encode(),
                file.read_bytes(), f"\r\n--{boundary}--\r\n".encode(),
            ])
            data = b"".join(parts)
            headers["Content-Type"] = f"multipart/form-data; boundary={boundary}"
        else:
            data = urllib.parse.urlencode(fields).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(url, data=data, headers=headers), timeout=180) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        raise ValueError(f"HTTP request failed (status {exc.code}); check access and release metadata") from None
    except (urllib.error.URLError, TimeoutError):
        raise ValueError("Network request failed; check connectivity and credentials") from None


def api(url, **kwargs):
    result = json.loads(request(url, **kwargs))
    if result.get("error"):
        raise ValueError(f"Portal API rejected request: {result['error']}")
    return result


def check_dependencies(infos):
    for info in infos.values():
        for dep in info.get("dependencies", ["base"]):
            match = DEPENDENCY.fullmatch(dep)
            if not match:
                raise ValueError(f"Unsupported dependency: {dep}")
            prefix, name, op, expected = match.group("prefix", "name", "op", "version")
            if prefix == "!":
                if name in infos:
                    raise ValueError(f"Conflicting dependency: {name}")
                continue
            if name not in infos:
                if prefix in ("?", "(?)", "+"):
                    continue
                raise ValueError(f"Pin required dependency {name} in ci.json (including transitive dependencies)")
            if op and not satisfies(infos[name]["version"], op, expected):
                raise ValueError(f"Unsatisfied dependency: {info['name']} requires {dep}")


def run_runtime_tests(mod, ci, package_zip, mods, common, save, work, mode, report):
    """Stage test-only scripts and exercise real handlers plus mod save/load."""
    suites = ci.get("runtime_tests", [])
    if not suites:
        return
    installed = mods / package_zip.stem
    if (mods / package_zip.name).exists():
        with zipfile.ZipFile(package_zip) as archive:
            archive.extractall(mods)
        (mods / package_zip.name).unlink()
    target = installed / "ci-runtime"
    target.mkdir(exist_ok=True)
    for suite in suites:
        shutil.copy2(ROOT / "tests" / mod / "engine" / f"{suite}.lua", target / f"{suite}.lua")
    control = installed / "control.lua"
    marker = "-- mod-ci runtime test loader (temporary installed copy only)"
    source = control.read_text()
    if marker not in source:
        control.write_text(source + '\n' + marker + '''
local ci_suite, ci_mode = (script.test_arg or ""):match(
  "^mod%-ci:([%w_.-]+):([%a-]+)$")
if ci_suite then
  require("ci-runtime/" .. ci_suite){suite = ci_suite, mode = ci_mode}
end
''')
    for suite in suites:
        results = work / "data/script-output" / f"mod-ci-{suite}-{mode}.json"
        results.unlink(missing_ok=True)
        completed = []
        with report.case(f"{mod}: {mode} {suite} behavior and save/load in Factorio {ci['factorio']}"):
            # Preserve completed Lua case results even when a later assertion fails.
            try:
                subprocess.run(common + ["--test-save", str(save), "--test-arg",
                                         f"mod-ci:{suite}:{mode}"], check=True, timeout=180)
            finally:
                if results.exists():
                    completed = read_json(results)
                    for case in completed:
                        if not isinstance(case.get("name"), str) or case.get("status") not in ("passed", "failed"):
                            raise ValueError("Invalid runtime test result")
                        report.record(f"{mod}: {mode}: {case['name']}", case["status"])
            if not completed or any(case["status"] != "passed" for case in completed):
                raise ValueError("Runtime suite did not report successful assertions")


def run_engine(mod, work, report=None):
    report = report if report is not None else TestReport()
    with report.case(f"{mod}: engine configuration"):
        path, info, ci = validate(mod)
    work = Path(work).resolve()
    work.mkdir(parents=True, exist_ok=True)
    if any(work.iterdir()):
        raise ValueError("Engine work directory must be empty")
    archive = work / "engine.tar.xz"
    archive.write_bytes(request(f"https://factorio.com/get-download/{ci['factorio']}/headless/linux64"))
    with tarfile.open(archive) as tar:
        tar.extractall(work, filter="data")
    engine = work / "factorio/bin/x64/factorio"
    mods = work / "mods"
    mods.mkdir()
    with report.case(f"{mod}: release ZIP packaging"):
        package_zip = package(mod)
    shutil.copy2(package_zip, mods)
    infos = {info["name"]: info}
    base = read_json(work / "factorio/data/base/info.json")
    infos["base"] = base
    infos["core"] = read_json(work / "factorio/data/core/info.json")
    with report.case(f"{mod}: pinned dependency versions, checksums, and constraints"):
        for name, version in ci["dependencies"].items():
            if name in infos:
                raise ValueError(f"Duplicate/bundled dependency pin: {name}")
            releases = api(f"https://mods.factorio.com/api/mods/{name}/full")["releases"]
            release = next((r for r in releases if r["version"] == version), None)
            if release is None or release["info_json"]["factorio_version"] != info["factorio_version"]:
                raise ValueError(f"{name} {version} does not target Factorio {info['factorio_version']}")
            username, token = os.getenv("FACTORIO_USERNAME"), os.getenv("FACTORIO_TOKEN")
            if not username or not token:
                raise ValueError("Dependency downloads require FACTORIO_USERNAME and FACTORIO_TOKEN")
            download_url = urllib.parse.urljoin("https://mods.factorio.com", release["download_url"])
            if urllib.parse.urlparse(download_url).netloc != "mods.factorio.com":
                raise ValueError("Unexpected dependency download host")
            data = request(download_url + "?" + urllib.parse.urlencode({"username": username, "token": token}))
            if hashlib.sha1(data).hexdigest() != release["sha1"]:
                raise ValueError(f"Checksum mismatch for {name}")
            with zipfile.ZipFile(io.BytesIO(data)) as z:
                metadata = [n for n in z.namelist() if n.count("/") == 1 and n.endswith("/info.json")]
                if len(metadata) != 1:
                    raise ValueError(f"Invalid dependency archive: {name}")
                dep_info = json.loads(z.read(metadata[0]))
            if dep_info["name"] != name or dep_info["version"] != version:
                raise ValueError(f"Dependency metadata mismatch: {name}")
            infos[name] = dep_info
            (mods / f"{name}_{version}.zip").write_bytes(data)
        check_dependencies(infos)
    # Unlisted bundled mods can default to enabled. Explicitly disable every
    # bundled mod outside the selected combination so the baseline is truly base.
    bundled_names = {read_json(file)["name"] for file in (work / "factorio/data").glob("*/info.json")}
    def write_mod_list():
        (mods / "mod-list.json").write_text(json.dumps({"mods": [
            {"name": name, "enabled": name in infos}
            for name in sorted((bundled_names | infos.keys()) - {"core"})
        ]}))
    write_mod_list()
    # Isolate write-data as well as mods; never touch a developer's installed game.
    config = work / "config.ini"
    (work / "data").mkdir()
    config.write_text(f"[path]\nread-data={work}/factorio/data\nwrite-data={work}/data\n")
    common = [str(engine), "--config", str(config), "--mod-directory", str(mods)]
    save = work / "smoke.zip"
    with report.case(f"{mod}: Factorio {ci['factorio']} mod initialization and new save creation"):
        subprocess.run(common + ["--create", str(save), "--map-gen-seed", "1"], check=True, timeout=180)
    with report.case(f"{mod}: reload generated save and run {ci['benchmark_ticks']} ticks"):
        subprocess.run(common + ["--benchmark", str(save), "--benchmark-ticks", str(ci["benchmark_ticks"]),
                                 "--benchmark-runs", "1"], check=True, timeout=180)
    if ci["scenarios"] or ci["saves"]:
        if version_tuple(ci["factorio"]) < (2, 1, 24):
            raise ValueError("Native test scenarios/saves require Factorio >= 2.1.24")
        test_root = ROOT / "tests" / mod
        if ci["scenarios"]:
            # Extract only our own generated archive, then add test-only scenarios.
            with zipfile.ZipFile(package_zip) as z:
                z.extractall(mods)
            (mods / package_zip.name).unlink()
            target = mods / package_zip.stem / "scenarios"
            target.mkdir(exist_ok=True)
            for scenario in ci["scenarios"]:
                shutil.copytree(test_root / "scenarios" / scenario, target / scenario)
                with report.case(f"{mod}: scenario {scenario}"):
                    subprocess.run(common + ["--test-scenario", f"{info['name']}/{scenario}"], check=True, timeout=180)
        for fixture in ci["saves"]:
            with report.case(f"{mod}: save fixture {fixture}"):
                subprocess.run(common + ["--test-save", str(test_root / "saves" / fixture)], check=True, timeout=180)
    if not ci["scenarios"]:
        report.record(f"{mod}: scenario fixtures", "skipped", "none configured")
    if not ci["saves"]:
        report.record(f"{mod}: save fixtures", "skipped", "none configured")
    run_runtime_tests(mod, ci, package_zip, mods, common, save, work, "base-game", report)
    if ci.get("space_age", False):
        with report.case(f"{mod}: bundled Space Age dependencies and constraints"):
            def enable_bundled(name):
                if name in infos:
                    return
                bundled = read_json(work / "factorio/data" / name / "info.json")
                infos[name] = bundled
                for dependency in bundled.get("dependencies", []):
                    dep = DEPENDENCY.fullmatch(dependency)
                    if dep and dep["prefix"] not in ("?", "(?)", "!"):
                        enable_bundled(dep["name"])

            enable_bundled("space-age")
            check_dependencies(infos)
            write_mod_list()
        space_save = work / "space-age-smoke.zip"
        with report.case(f"{mod}: Space Age initialization and new save creation"):
            subprocess.run(common + ["--create", str(space_save), "--map-gen-seed", "1"],
                           check=True, timeout=180)
        with report.case(f"{mod}: reload Space Age save and run {ci['benchmark_ticks']} ticks"):
            subprocess.run(common + ["--benchmark", str(space_save), "--benchmark-ticks", str(ci["benchmark_ticks"]),
                                     "--benchmark-runs", "1"], check=True, timeout=180)
        run_runtime_tests(mod, ci, package_zip, mods, common, space_save, work, "space-age", report)


def release_matrix(outputs):
    result = []
    packages = read_json(ROOT / "release-please-config.json")["packages"]
    for path in json.loads(outputs.get("paths_released", "[]")):
        if path not in packages:
            raise ValueError(f"Unknown released path: {path}")
        tag = outputs[f"{path}--tag_name"]
        mod = path.removeprefix("mods/")
        _, info, _ = validate(mod)
        expected = f"{packages[path]['component']}/v{info['version']}"
        if tag != expected:
            raise ValueError(f"Release tag {tag} does not match {expected}")
        result.append({"mod": mod, "tag": tag})
    return result


def tag_matrix(tag):
    """Select a registered mod from a component/version tag and validate its version."""
    packages = read_json(ROOT / "release-please-config.json")["packages"]
    paths = [path for path, config in packages.items()
             if tag.startswith(f"{config['component']}/v")]
    if len(paths) != 1:
        raise ValueError("Tag must select exactly one registered mod: <component>/v<version>")
    path = paths[0]
    return release_matrix({"paths_released": json.dumps(paths), f"{path}--tag_name": tag})


def publish(mod, archive, tag):
    path, info, _ = validate(mod)
    component = read_json(ROOT / "release-please-config.json")["packages"][f"mods/{mod}"]["component"]
    if tag != f"{component}/v{info['version']}":
        raise ValueError("Release tag/version mismatch")
    token = os.getenv("FACTORIO_API_KEY")
    if not token:
        raise ValueError("Set FACTORIO_API_KEY with portal Upload Mods and Publish Mods permissions")
    portal_config = read_json(path / "portal.json")
    if info["name"] == portal_config.get("upstream_name"):
        raise ValueError("Choose a distinct fork name in info.json and update internal imports before publishing")
    archive = Path(archive)
    with tempfile.TemporaryDirectory() as tmp:
        expected = package(mod, tmp)
        if archive.name != expected.name or archive.read_bytes() != expected.read_bytes():
            raise ValueError("Publish artifact differs from the tested source package")
    portal = "https://mods.factorio.com"
    try:
        existing = json.loads(request(f"{portal}/api/mods/{info['name']}"))
    except ValueError as exc:
        if "status 404" not in str(exc):
            raise
        existing = None
    if existing:
        prior = next((r for r in existing["releases"] if r["version"] == info["version"]), None)
        if prior:
            if prior["sha1"] != hashlib.sha1(archive.read_bytes()).hexdigest():
                raise ValueError("Portal already has different bytes for this version")
            print("Identical release is already published")
            return
    endpoint = "releases/init_upload" if existing else "init_publish"
    response = api(f"{portal}/api/v2/mods/{endpoint}", fields={"mod": info["name"]}, token=token)
    upload = response["upload_url"]
    parsed = urllib.parse.urlparse(upload)
    # The authenticated portal response selects the upload service; it may use a CDN.
    # The API key is only sent to init_upload/init_publish, not to this URL.
    if parsed.scheme != "https" or not parsed.hostname:
        raise ValueError("Portal returned an invalid upload URL")
    fields = {}
    if not existing:
        fields = {"description": (path / "description.md").read_text()}
        # Each mod must explicitly declare its own portal license/category.
        fields.update({"license": portal_config["license"], "category": portal_config["category"]})
        repository = os.getenv("GITHUB_REPOSITORY")
        if repository:
            fields["source_url"] = f"https://github.com/{repository}/tree/main/mods/{mod}"
    result = api(upload, fields=fields, file=archive)
    if result.get("success") is not True:
        raise ValueError("Portal did not confirm a successful upload")
    print(f"Published {info['name']} {info['version']}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["list", "check", "package", "engine", "release-matrix", "tag-matrix", "publish"])
    parser.add_argument("mod", nargs="?")
    parser.add_argument("--work")
    parser.add_argument("--archive")
    parser.add_argument("--tag")
    parser.add_argument("--report", help="Write completed check results as JSON (check, package, engine)")
    args = parser.parse_args()
    report = TestReport(args.report)
    if args.command == "list":
        print(json.dumps([p.parent.name for p in sorted((ROOT / "mods").glob("*/info.json"))]))
    elif args.command == "release-matrix":
        print(json.dumps(release_matrix(json.loads(os.environ["RELEASE_OUTPUTS"]))))
    elif args.command == "tag-matrix":
        if not args.tag:
            parser.error("tag-matrix requires --tag")
        print(json.dumps(tag_matrix(args.tag)))
    elif args.command == "check":
        with report.case(f"{args.mod}: metadata and release version consistency"):
            path, _, ci = validate(args.mod)
        files = sorted(path.rglob("*.lua"))
        files += [ROOT / "tests" / args.mod / "engine" / f"{suite}.lua"
                  for suite in ci.get("runtime_tests", [])]
        with report.case(f"{args.mod}: Lua 5.2 syntax ({len(files)} files)"):
            for file in files:
                subprocess.run([os.getenv("LUAC", "luac5.2"), "-p", str(file)], check=True)
    elif args.command == "package":
        with report.case(f"{args.mod}: release ZIP packaging"):
            archive = package(args.mod)
        print(archive)
    elif args.command == "engine":
        if not args.work:
            parser.error("engine requires --work")
        run_engine(args.mod, args.work, report)
    elif args.command == "publish":
        if not args.archive or not args.tag:
            parser.error("publish requires --archive and --tag")
        publish(args.mod, args.archive, args.tag)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.SubprocessError, zipfile.BadZipFile, tarfile.TarError) as exc:
        raise SystemExit(str(exc)) from None
