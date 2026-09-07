#!/usr/bin/env python3
"""Self-test for bc-test-results.py, run in CI alongside it.

WHY THIS EXISTS. The nightly's summary is read by humans as the answer to "what
failed on the Windows tier". Issue #249 recorded what happens when it is not: the
"Passes here" table replayed the SaaS baseline's own `cause` strings in a column
shaped exactly like the live `message` column of the table directly above it. A
17-row table of failure messages was read as the run's failure list when only 8 of
its rows were failures, and two issues (#244, #246) were filed on tests that had
PASSED. Both were withdrawn. The run's totals said "2988 passed, 8 failed" in the
same log throughout.

Nothing about that defect was detectable by running the script -- it produced
well-formed markdown from correct data. Only the RENDERING misled. So the assertions
below are about the rendering, and they are written to fail against the layout that
shipped before this file existed:

  * test_failure_list_precedes_any_baseline_history  -- old layout put the #213
    comparison first.
  * test_passing_test_cause_is_marked_as_the_sandboxs -- old layout printed the raw
    cause with no in-cell marker.
  * test_passing_row_states_it_passed                 -- old layout had no "result
    here" column at all.
  * test_no_baseline_error_text_above_the_historical_rule -- old layout had no rule.
  * test_headline_failure_count_matches_the_failure_table -- the arithmetic a reader
    would have had to do by hand to catch #249.

No network, no BC, about a second.
"""
import importlib.util
import io
import contextlib
import json
import sys
import tempfile
from pathlib import Path

# Loading the target by file path would otherwise drop a __pycache__ beside it in the
# checkout. Harmless, but a self-test should not dirty the tree it is testing.
sys.dont_write_bytecode = True

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("btr", HERE / "bc-test-results.py")
btr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(btr)

FAILURES = 0


def check(cond, label):
    global FAILURES
    if cond:
        print(f"  ok   {label}")
    else:
        FAILURES += 1
        print(f"  FAIL {label}")


def locate(md, needle, label):
    """md.index that reports a MISSING structural marker as a failed check rather
    than raising. Without this the suite crashes on the first absent heading when
    run against a rendering that lacks it, and a traceback proves far less than a
    named list of which properties are absent -- which is the whole point of
    running it against the old layout."""
    global FAILURES
    try:
        return md.index(needle)
    except ValueError:
        FAILURES += 1
        print(f"  FAIL {label} (marker {needle!r} is absent from the report)")
        return None


# The distinctive strings each fixture uses. They are deliberately unlike each other
# so an assertion cannot pass by matching the wrong one.
SANDBOX_CAUSE = "expected LOCAL, got Country-region-specific func."
LIVE_MESSAGE = "LIVEMSG assertion failed on the Windows container"


def xunit(tests):
    """tests: list of (codeunit, cu_name, method, result, message)."""
    by_cu = {}
    for cu, cuname, method, result, message in tests:
        by_cu.setdefault((cu, cuname), []).append((method, result, message))
    out = ['<?xml version="1.0" encoding="UTF-8"?>', "<assemblies>"]
    for (cu, cuname), rows in by_cu.items():
        out.append(f'  <assembly name="{cu} {cuname}">')
        out.append("    <collection>")
        for method, result, message in rows:
            out.append(f'      <test name="{cu} {cuname}:{method}" method="{method}" '
                       f'result="{result}" time="0.01">')
            if message:
                out.append(f"        <failure><message>{message}</message></failure>")
            out.append("      </test>")
        out.append("    </collection>")
        out.append("  </assembly>")
    out.append("</assemblies>")
    return "\n".join(out)


def run(tmp, tests, baseline_failures):
    """Run the generator over a fixture and return the summary markdown."""
    xml = Path(tmp) / "xunit-fixture.xml"
    xml.write_text(xunit(tests), encoding="utf-8")
    base = Path(tmp) / "baseline.json"
    base.write_text(json.dumps({
        "source": "https://example.invalid/213",
        "measured_on": "MS SaaS sandbox, US Business Central 28.4",
        "failures": baseline_failures,
    }), encoding="utf-8")
    outdir = Path(tmp) / "out"
    argv = sys.argv
    sys.argv = ["bc-test-results.py", "--xunit", str(xml),
                "--baseline", str(base), "--outdir", str(outdir)]
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            rc = btr.main()
    finally:
        sys.argv = argv
    assert rc == 0, f"generator exited {rc}"
    return (outdir / "summary.md").read_text(encoding="utf-8")


# ---------------------------------------------------------------------------------
# THE #249 FIXTURE. One baseline entry that PASSES here and carries a `cause`, one
# baseline entry that genuinely fails here, and one unrelated pass. This is #249 in
# miniature: the passing test's baseline cause must never render as a result.
# ---------------------------------------------------------------------------------
PASSES_BUT_IN_BASELINE = (60290, "Metadata Tests",
                          "MetadataPermissionSet_CaptionlessRole_NameFallsBackToRoleId",
                          "Pass", "")
REALLY_FAILS = (60130, "Media Tests",
                "Media_ExportStream_ValidPng_SameByteLengthAsImported",
                "Failure", LIVE_MESSAGE)
UNRELATED_PASS = (60378, "Isolated Storage Tests",
                  "IsolatedStorage_Delete_RemovesTheEntry", "Pass", "")

BASELINE = [
    {"codeunit": 60290,
     "test": "MetadataPermissionSet_CaptionlessRole_NameFallsBackToRoleId",
     "group": "divergence", "cause": SANDBOX_CAUSE},
    {"codeunit": 60130,
     "test": "Media_ExportStream_ValidPng_SameByteLengthAsImported",
     "group": "divergence", "cause": "ExportStream returned 99 bytes, imported 68"},
]


def main():
    with tempfile.TemporaryDirectory() as tmp:
        md = run(tmp, [PASSES_BUT_IN_BASELINE, REALLY_FAILS, UNRELATED_PASS], BASELINE)

        print("== a passing test's baseline cause must not read as a result ==")

        # 1. The run's own failure list comes before any baseline history. In the old
        #    layout the #213 comparison was the first section after the totals.
        rule = locate(md, "\n---\n", "the report has a rule separating live from historical")
        failed_heading = locate(md, "### Failed on THIS run",
                                "the report has a 'Failed on THIS run' section")
        check(rule is not None and failed_heading is not None and failed_heading < rule,
              "this run's failure list precedes the historical rule")
        hist = locate(md, "Historical", "the report labels the baseline section 'Historical'")
        check(rule is not None and hist is not None and hist > rule,
              "the '#213' comparison sits below the historical rule")
        # From here on, treat an absent rule as "everything is above it": that is
        # literally true of a report with no rule, and it is the condition that made
        # the old layout misleading.
        rule = len(md) if rule is None else rule
        failed_heading = 0 if failed_heading is None else failed_heading

        # 2. No baseline error text appears anywhere above that rule. This is the
        #    property #249 is actually about: everything a skimmer sees first is a
        #    measurement of this run.
        check(SANDBOX_CAUSE not in md[:rule],
              "no baseline cause text appears above the historical rule")
        check(LIVE_MESSAGE in md[:rule],
              "this run's own failure message DOES appear above the rule")

        # 3. Where the baseline cause is printed, it is marked in the cell -- not only
        #    in a column header, which is what the old layout relied on and what was
        #    misread. A cell copied out of context must still say whose measurement
        #    it is.
        idx = locate(md, SANDBOX_CAUSE,
                     "the baseline cause is rendered somewhere (it should be, below the rule)")
        if idx is not None:
            cell_start = md.rindex("|", 0, idx)
            check("sandbox saw:" in md[cell_start:idx],
                  "the baseline cause is prefixed 'sandbox saw:' inside its own cell")

            # 4. The row for a test that passed says so, in its own column.
            row_start = md.rindex("\n", 0, idx) + 1
            row = md[row_start:md.index("\n", idx)]
            check("**passed**" in row,
                  "the row for a passing baseline entry states that it passed")
            check("MetadataPermissionSet_CaptionlessRole_NameFallsBackToRoleId" in row,
                  "...and that row is the one for the passing test")

        # 5. The headline count and the failure table agree. #249 was caught only by
        #    someone doing this arithmetic by hand against the log.
        check("**2 passed, 1 failed, 0 skipped, 3 total.**" in md,
              "the headline totals are correct")
        table = md[failed_heading:rule]
        rows = [l for l in table.splitlines()
                if l.startswith("| 6")]
        check(len(rows) == 1,
              f"the failure table has exactly 1 row for 1 failure (got {len(rows)})")
        check("Media_ExportStream_ValidPng_SameByteLengthAsImported" in table,
              "the failing test is the one in the failure table")
        check("MetadataPermissionSet" not in table,
              "the PASSING test is not in the failure table")

        # 6. The failure list is complete on its own -- a reader who reads only it
        #    has every failure. Guards against a future split that keeps some
        #    failures only in the baseline sections.
        for cu, _, method, result, _ in [PASSES_BUT_IN_BASELINE, REALLY_FAILS, UNRELATED_PASS]:
            if result == "Failure":
                check(method in table, f"failure {method} is in the top failure list")

        print("== the 'missing' bucket must not read as a failure either ==")
        # A baseline entry whose test no longer exists -- live since cu 60878 was
        # deleted in PR #250.
        md2 = run(tmp, [REALLY_FAILS], BASELINE + [
            {"codeunit": 60878, "test": "SaveAsPdf_RdlcLayout_ReturnsFalseWithLastErrorTextOnLinux",
             "group": "image-limitation-asserted-as-bc",
             "cause": "asserts RDLC rendering is UNAVAILABLE"}])
        rule2 = locate(md2, "\n---\n", "the missing-bucket report has a historical rule")
        rule2 = len(md2) if rule2 is None else rule2
        check("SaveAsPdf_RdlcLayout" not in md2[:rule2],
              "a deleted baseline test does not appear in this run's failure list")
        check("nothing was measured" in md2,
              "the missing bucket says nothing was measured for those entries")
        m_idx = locate(md2, "SaveAsPdf_RdlcLayout", "the missing entry is listed at all")
        m_row = "" if m_idx is None else md2[md2.rindex("\n", 0, m_idx) + 1:md2.index("\n", m_idx)]
        check("_not run_" in m_row,
              "the missing row's result column reads '_not run_', not a failure")
        check("Not failures" in md2,
              "the missing section states outright that these are not failures")
        check("**1 passed, 1 failed" not in md2 and "0 passed, 1 failed, 0 skipped, 1 total" in md2,
              "the headline count ignores the missing baseline entry")

        print("== a clean run must not imply the baseline reproduced ==")
        md3 = run(tmp, [UNRELATED_PASS], BASELINE)
        check("Nothing failed on this run." in md3,
              "a run with no failures says so explicitly")
        rule3 = locate(md3, "\n---\n", "the clean-run report has a historical rule")
        rule3 = len(md3) if rule3 is None else rule3
        check(SANDBOX_CAUSE not in md3[:rule3],
              "...and still prints no baseline error text above the rule")

    if FAILURES:
        print(f"\n{FAILURES} check(s) FAILED")
        return 1
    print("\nall checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
