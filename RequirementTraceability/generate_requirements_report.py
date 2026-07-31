#!/usr/bin/env python3
"""Runs every already-built F' native unit-test binary with GTest's
--gtest_output=xml flag, then parses the resulting JUnit-style reports into
one combined requirements-traceability table -- and separately reports every
module under Components/ and lib/fprime-scales/scales/scalesSvc/ that has no
unit tests at all, so a module that was never built with --ut isn't just
silently absent from the report.

Test-result coverage is limited to the shared native UT build tree
(build-fprime-automatic-native-ut/bin/Linux/*_ut_exe) -- both
lib/fprime-scales/scales/scalesSvc/* and Components/* land here, since both
are registered into the same root project.cmake. A module only shows real
test results once it has actually been built: run 'fprime-util build --ut' in
that module's own directory first. The "missing unit tests" section below is
different: it's derived by scanning each module's own CMakeLists.txt for an
active (non-commented) register_fprime_ut() call, so it catches a module that
has never been built with --ut at all, not just one that's out of date.

Each test in this codebase tags itself with RecordProperty("requirement", "ID")
(one ID, or a comma-separated list for a test that verifies more than one).
GTest never writes that out on its own -- it only appears in a report when a
binary is invoked with --gtest_output=xml:<path>. This script is the thing
that actually asks for it, for every built module at once, and turns the
result into one readable table.

Self-replacing: every run fully regenerates requirements-traceability.md from
scratch (no appending, no stale leftovers) -- rerun this any time you've
built more UT targets, added tests to a previously-untested module, or
changed test code, and the file in this directory is overwritten with the
current state.
"""

import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = REPO_ROOT / "build-fprime-automatic-native-ut"
OUT_DIR = Path(__file__).resolve().parent
REPORT_PATH = OUT_DIR / "requirements-traceability.md"

# Each source root that can hold a testable module, paired with the binary
# name prefix CMake derives for modules under it (see the "Module names are
# derived from the path..." comment repeated in every component's
# CMakeLists.txt). Add an entry here if another module root shows up.
MODULE_ROOTS = [
    (REPO_ROOT / "Components", "Components_"),
    (REPO_ROOT / "lib" / "fprime-scales" / "scales" / "scalesSvc", "scales_scalesSvc_"),
]

_ACTIVE_REGISTER_UT_RE = re.compile(r"^\s*register_fprime_ut\s*\(", re.MULTILINE)


def find_ut_binaries() -> list[Path]:
    bin_dir = BUILD_DIR / "bin" / "Linux"
    return sorted(bin_dir.glob("*_ut_exe")) if bin_dir.is_dir() else []


def module_name_from_binary(binary_name: str) -> str:
    # e.g. scales_scalesSvc_JetsonManager_ut_exe -> JetsonManager
    #      Components_MLComponent_ut_exe         -> MLComponent
    name = binary_name
    for prefix in ("scales_scalesSvc_", "scales_", "Components_"):
        if name.startswith(prefix):
            name = name[len(prefix):]
            break
    return name[: -len("_ut_exe")] if name.endswith("_ut_exe") else name


def discover_modules() -> list[dict]:
    """Scans every module directory under MODULE_ROOTS (built or not) and
    checks its own CMakeLists.txt for an active register_fprime_ut() call.
    This is what lets a module that has never been built with --ut still
    show up in the report as missing, instead of just not appearing."""
    modules = []
    for root, prefix in MODULE_ROOTS:
        if not root.is_dir():
            continue
        for module_dir in sorted(p for p in root.iterdir() if p.is_dir()):
            cmakelists = module_dir / "CMakeLists.txt"
            if not cmakelists.is_file():
                continue
            text = cmakelists.read_text()
            # Strip full-line '#' comments before matching, so a commented-out
            # register_fprime_ut() (e.g. "# register_fprime_ut()") never
            # counts as active -- exactly the pattern several modules in this
            # repo were left in before their real test suites were written.
            active_lines = "\n".join(
                line for line in text.splitlines() if not line.strip().startswith("#")
            )
            modules.append({
                "name": module_dir.name,
                "path": module_dir.relative_to(REPO_ROOT),
                "binary_name": f"{prefix}{module_dir.name}_ut_exe",
                "ut_registered": bool(_ACTIVE_REGISTER_UT_RE.search(active_lines)),
            })
    return modules


def run_and_parse(binary: Path, tmp_dir: Path, rows: list[dict]) -> tuple[int, int, bool]:
    """Runs one UT binary, parses its report, returns (tests, failed, ran_ok)."""
    module = module_name_from_binary(binary.name)
    xml_out = tmp_dir / f"{binary.name}.xml"
    result = subprocess.run(
        [str(binary), f"--gtest_output=xml:{xml_out}"],
        capture_output=True,
        text=True,
    )
    if not xml_out.exists():
        print(f"[ERROR] {binary.name} did not produce a report (crashed before finishing?)")
        if result.stderr:
            print(result.stderr[-2000:])
        return 0, 0, False

    tree = ET.parse(xml_out)
    total = 0
    failed = 0
    for testcase in tree.getroot().iter("testcase"):
        total += 1
        status = "FAIL" if testcase.find("failure") is not None else "PASS"
        if status == "FAIL":
            failed += 1
        name = f'{testcase.get("classname", "")}.{testcase.get("name", "")}'
        req_ids = [
            p.strip()
            for prop in testcase.findall("./properties/property")
            if prop.get("name") == "requirement"
            for p in prop.get("value", "").split(",")
            if p.strip()
        ] or ["(untagged)"]
        for req_id in req_ids:
            rows.append({"requirement": req_id, "module": module, "test": name, "status": status})

    status_str = "ok" if failed == 0 else f"{failed} FAILED"
    print(f"{binary.name}: {total} tests, {status_str}")
    return total, failed, True


def write_markdown_report(rows: list[dict], totals: dict, missing: list[dict]) -> None:
    lines = [
        "# Requirements Traceability Report",
        "",
        "Auto-generated by `generate_requirements_report.py` -- do not hand-edit, "
        "rerun the script instead (it overwrites this file completely each time).",
        "",
        f"{totals['binaries']} test binaries, {totals['tests']} tests, "
        f"{totals['failed']} failed, "
        f"{len(set(r['requirement'] for r in rows))} distinct requirement IDs covered, "
        f"{len(missing)} module(s) with no unit tests.",
        "",
    ]

    if missing:
        lines.append("## Modules Missing Unit Tests")
        lines.append("")
        lines.append(
            "Every module under `Components/` and `.../scalesSvc/` is scanned "
            "directly (not just already-built binaries), so a module that has "
            "never been built with `--ut` still shows up here instead of "
            "silently not appearing anywhere in this report."
        )
        lines.append("")
        lines.append("| Module | Path | Status |")
        lines.append("|---|---|---|")
        for m in sorted(missing, key=lambda m: m["name"]):
            if m["ut_registered"]:
                status = "Tests registered but not built -- run `fprime-util build --ut` in this module's directory"
            else:
                status = "No unit tests written (`register_fprime_ut()` not present/active in `CMakeLists.txt`)"
            lines.append(f'| {m["name"]} | `{m["path"]}` | {status} |')
        lines.append("")

    modules = sorted(set(r["module"] for r in rows))
    lines.append("## Modules With Unit Tests")
    lines.append("")
    for module in modules:
        lines.append(f"- [{module}](#{module.lower()})")
    lines.append("")

    def row_sort_key(row: dict) -> tuple:
        req = row["requirement"]
        return (req == "(untagged)", req, row["test"])

    for module in modules:
        module_rows = sorted((r for r in rows if r["module"] == module), key=row_sort_key)
        module_tests = len(module_rows)
        module_failed = sum(1 for r in module_rows if r["status"] == "FAIL")
        module_reqs = len(set(r["requirement"] for r in module_rows))

        lines.append(f"## {module}")
        lines.append("")
        lines.append(
            f"{module_tests} requirement mappings, {module_failed} failed, "
            f"{module_reqs} distinct requirement IDs."
        )
        lines.append("")
        lines.append("| Requirement | Test | Status |")
        lines.append("|---|---|---|")
        for row in module_rows:
            mark = "PASS" if row["status"] == "PASS" else "**FAIL**"
            lines.append(f'| {row["requirement"]} | `{row["test"]}` | {mark} |')
        lines.append("")

    REPORT_PATH.write_text("\n".join(lines) + "\n")


def main() -> int:
    modules = discover_modules()
    built_binary_names = {b.name for b in find_ut_binaries()}
    missing = [m for m in modules if m["binary_name"] not in built_binary_names]

    if missing:
        print(f"{len(missing)} module(s) with no unit-test results (see 'Modules Missing Unit Tests'):")
        for m in sorted(missing, key=lambda m: m["name"]):
            reason = "not built" if m["ut_registered"] else "no tests written"
            print(f"  - {m['name']} ({reason})")
        print()

    binaries = find_ut_binaries()
    if not binaries:
        print(f"No *_ut_exe binaries found under {BUILD_DIR}/bin/Linux.")
        print("Run 'fprime-util build --ut' in the module directories you want covered first.")
        write_markdown_report([], {"binaries": 0, "tests": 0, "failed": 0}, missing)
        print(f"Wrote {REPORT_PATH} (missing-tests list only -- no test results available).")
        return 1

    rows: list[dict] = []
    total_tests = 0
    total_failed = 0
    any_run_failure = False

    with tempfile.TemporaryDirectory(prefix="fprime-ut-reports-") as tmp:
        tmp_dir = Path(tmp)
        for binary in binaries:
            tests, failed, ran_ok = run_and_parse(binary, tmp_dir, rows)
            total_tests += tests
            total_failed += failed
            any_run_failure = any_run_failure or not ran_ok

    write_markdown_report(rows, {
        "binaries": len(binaries), "tests": total_tests, "failed": total_failed,
    }, missing)
    print(f"\nWrote {REPORT_PATH}")

    # Missing unit tests are reported (console + markdown) but do not fail
    # the run on their own -- this command stays usable as a status/progress
    # check even before every module has tests, same as it always has for
    # already-covered modules. Only an actual test failure or crash fails it.
    return 1 if (total_failed > 0 or any_run_failure) else 0


if __name__ == "__main__":
    sys.exit(main())
