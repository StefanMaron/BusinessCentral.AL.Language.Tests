#!/usr/bin/env python3
"""Self-test for isolation-probe-results.py (AL Runner #4826). No network, no BC.

What it holds:
  * every fixture test gets a row, with its failure message, in every run;
  * the fixture's test list is read from the real .al file, so a renamed or added test
    cannot silently drop out of the summary;
  * the three ways a run can fail to measure -- no file, zero tests, a fixture test with
    no row -- each print NO VERDICT and exit 3, never 0.
"""
import contextlib
import importlib.util
import io
import os
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
FIXTURE = ROOT / "tests/al-language-isolation-probe/src/IsolProbeFixture.Codeunit.al"
spec = importlib.util.spec_from_file_location("ipr", HERE / "isolation-probe-results.py")
ipr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ipr)

FAILURES = 0
CU = (61302, "Isol Probe Fixture")
OBSERVED = "expected 4826, observed 0"


def check(cond, label):
    global FAILURES
    print(f"  {'ok  ' if cond else 'FAIL'} {label}")
    if not cond:
        FAILURES += 1


def xunit(rows):
    out = ['<?xml version="1.0" encoding="UTF-8"?>', "<assemblies>",
           f'  <assembly name="{CU[0]} {CU[1]}">', "    <collection>"]
    for method, result, message in rows:
        out.append(f'      <test name="{CU[0]} {CU[1]}:{method}" method="{method}" result="{result}" time="0.01">')
        if message:
            out.append(f"        <failure><message>{message}</message></failure>")
        out.append("      </test>")
    out += ["    </collection>", "  </assembly>", "</assemblies>"]
    return "\n".join(out)


def run(tmp, runs):
    argv = sys.argv
    sys.argv = ["isolation-probe-results.py", "--fixture", str(FIXTURE), "--outdir", str(Path(tmp) / "out")]
    for label, path in runs:
        sys.argv += ["--run", f"{label}={path}"]
    saved = os.environ.pop("GITHUB_STEP_SUMMARY", None)
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            rc = ipr.main()
    finally:
        sys.argv = argv
        if saved is not None:
            os.environ["GITHUB_STEP_SUMMARY"] = saved
    return rc, (Path(tmp) / "out" / "isolation-probe.md").read_text(encoding="utf-8")


def main():
    names = ipr.fixture_tests(FIXTURE)
    print("== the fixture list comes from the .al file ==")
    check(len(names) >= 5 and names[0].startswith("T1_"), f"fixture tests read from source: {names}")

    with tempfile.TemporaryDirectory() as tmp:
        full = Path(tmp) / "full.xml"
        full.write_text(xunit([(n, "Fail" if n.startswith("T2_") else "Pass", OBSERVED if n.startswith("T2_") else "")
                               for n in names]), encoding="utf-8")
        print("== a complete run renders every test with its message ==")
        rc, md = run(tmp, [("Function (61300)", full)])
        check(rc == 0, f"complete run exits 0 (got {rc})")
        check(all(f"| {n} |" in md for n in names), "every fixture test has a row")
        check(OBSERVED in md, "the failure message (the observed value) is in the row")
        check("NO VERDICT" not in md, "a complete run is not reported as NO VERDICT")

        print("== a label containing '=' still finds its file (nightly run 36727084058) ==")
        rc, md = run(tmp, [("TestIsolation = Function (runner 61300)", full)])
        check(rc == 0, f"label with '=' exits 0 (got {rc})")
        check("#### TestIsolation = Function (runner 61300)" in md, "the whole label is the heading")

        print("== no file is NO VERDICT, exit 3 ==")
        rc, md = run(tmp, [("Function (61300)", full), ("Codeunit (61301)", Path(tmp) / "absent.xml")])
        check(rc == 3, f"missing file exits 3 (got {rc})")
        check("NO VERDICT" in md and "does not exist" in md, "missing file says NO VERDICT and why")

        print("== zero tests is NO VERDICT, exit 3 ==")
        empty = Path(tmp) / "empty.xml"
        empty.write_text('<?xml version="1.0"?><assemblies></assemblies>', encoding="utf-8")
        rc, md = run(tmp, [("Function (61300)", empty)])
        check(rc == 3, f"zero tests exits 3 (got {rc})")
        check("parsed to 0 tests" in md, "zero tests says so")

        print("== a fixture test with no row is NO VERDICT, exit 3 ==")
        partial = Path(tmp) / "partial.xml"
        partial.write_text(xunit([(n, "Pass", "") for n in names[:-1]]), encoding="utf-8")
        rc, md = run(tmp, [("Function (61300)", partial)])
        check(rc == 3, f"missing row exits 3 (got {rc})")
        check(f"| {names[-1]} | **NOT RUN** |" in md, "the missing test is named as NOT RUN")

    if FAILURES:
        print(f"\n{FAILURES} check(s) FAILED")
        return 1
    print("\nall checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
