#!/usr/bin/env python3
"""Turn BC XUnit result files into a diffable per-test list, and compare against issue #213.

The point of the nightly Windows run is COMPARISON: it exists to say which of the
14 failures reported on a SaaS sandbox in issue #213 also fail on an official
Microsoft BC container, and which do not. So the output is shaped for diffing --
one line per test, sorted, with the codeunit id and the error message on it.

Usage:
    bc-test-results.py --xunit results.xml [--xunit more.xml ...] \
                       --baseline .github/expected-failures/issue-213-saas-sandbox.json \
                       --outdir test-results

Exit status is 0 whenever the results were PARSED. Test failures are reported,
not fatal: this workflow is an authority signal for humans, not a merge gate.
The one thing that does fail the step is parsing zero tests, because "0 failures"
out of an empty file reads exactly like a green run.

THE REPORT'S ONE INVARIANT (#249): a reader must not be able to mistake baseline
history for a result of this run. The report opens with this run's complete failure
list, whose row count equals the headline failure count; everything about the #213
baseline sits below a horizontal rule under a "Historical" heading, and every
replayed baseline string is prefixed `sandbox saw:` in the cell so it still says
whose measurement it is when copied out. Tests in test-bc-test-results.py hold that.
"""

import argparse
import json
import os
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

# "60013 CalcFields Ext FlowField Tests" -> (60013, "CalcFields Ext FlowField Tests")
ASSEMBLY_RE = re.compile(r"^\s*(\d+)\s+(.*?)\s*$")


def parse_xunit(path):
    """Yield one dict per <test>. Defensive about layout: BcContainerHelper has
    emitted <assembly><collection><test> and <assembly><test> at different times,
    so walk the whole assembly subtree rather than a fixed path."""
    tests = []
    root = ET.parse(path).getroot()
    assemblies = list(root.iter("assembly")) or [root]
    for assembly in assemblies:
        raw = assembly.get("name", "") or ""
        m = ASSEMBLY_RE.match(raw)
        codeunit = int(m.group(1)) if m else 0
        codeunit_name = m.group(2) if m else raw

        for test in assembly.iter("test"):
            method = test.get("method") or ""
            name = test.get("name") or ""
            # name is usually "<id> <Codeunit Name>:<Method>"; prefer the explicit
            # method attribute, fall back to the tail of name.
            if not method:
                method = name.rsplit(":", 1)[-1].strip()

            result = (test.get("result") or "").strip() or "Unknown"

            message = ""
            failure = test.find("failure")
            if failure is not None:
                msg = failure.find("message")
                if msg is not None and msg.text:
                    message = msg.text
                else:
                    message = "".join(failure.itertext())
            message = " ".join(message.split())

            tests.append(
                {
                    "codeunit": codeunit,
                    "codeunit_name": codeunit_name,
                    "test": method,
                    "result": result,
                    "time": test.get("time") or "",
                    "message": message,
                    "source": os.path.basename(path),
                }
            )
    return tests


def key(codeunit, test):
    return (int(codeunit), test.strip())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--xunit", action="append", required=True)
    ap.add_argument("--baseline")
    ap.add_argument("--outdir", default="test-results")
    ap.add_argument("--environment", help="JSON file describing the tier this ran on")
    args = ap.parse_args()

    tests = []
    for path in args.xunit:
        p = pathlib.Path(path)
        if not p.exists():
            print(f"::warning::no XUnit file at {path} -- the test step may not have reached it")
            continue
        try:
            found = parse_xunit(p)
        except ET.ParseError as exc:
            print(f"::error::{path} is not parseable XML: {exc}")
            return 2
        print(f"{path}: {len(found)} tests")
        tests.extend(found)

    if not tests:
        print("::error::parsed 0 tests from the supplied XUnit files. "
              "That is not a green run -- it means the tests never executed, or "
              "the result file never got written. Refusing to report a verdict.")
        return 2

    outdir = pathlib.Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    tests.sort(key=lambda t: (t["codeunit"], t["test"]))
    failed = [t for t in tests if t["result"].lower() not in ("pass", "success", "skip", "skipped")]
    passed = [t for t in tests if t["result"].lower() in ("pass", "success")]
    skipped = [t for t in tests if t["result"].lower() in ("skip", "skipped")]

    # ---- full per-test list, one line each, sorted: this is the diffable artifact
    with (outdir / "all-tests.tsv").open("w", encoding="utf-8") as fh:
        fh.write("result\tcodeunit\tcodeunit_name\ttest\tmessage\n")
        for t in tests:
            fh.write(f"{t['result']}\t{t['codeunit']}\t{t['codeunit_name']}\t{t['test']}\t{t['message']}\n")

    with (outdir / "failures.tsv").open("w", encoding="utf-8") as fh:
        fh.write("codeunit\ttest\tmessage\n")
        for t in failed:
            fh.write(f"{t['codeunit']}\t{t['test']}\t{t['message']}\n")

    with (outdir / "results.json").open("w", encoding="utf-8") as fh:
        json.dump({"total": len(tests), "passed": len(passed), "failed": len(failed),
                   "skipped": len(skipped), "tests": tests}, fh, indent=2)

    lines = []
    env = {}
    if args.environment and pathlib.Path(args.environment).exists():
        env = json.loads(pathlib.Path(args.environment).read_text(encoding="utf-8"))

    lines.append("## Nightly Windows container run")
    lines.append("")
    lines.append(f"**{len(passed)} passed, {len(failed)} failed, {len(skipped)} skipped, {len(tests)} total.**")
    lines.append("")

    # ---------------------------------------------------------------------------------
    # WHAT FAILED HERE, FIRST AND COMPLETE (#249).
    #
    # This block is the answer to "what failed on this run", and nothing else in this
    # report is. It is printed before the baseline comparison, is derived only from THIS
    # run's XUnit, and its row count equals the failure count on the line above -- so a
    # reader who checks nothing else still gets the right answer.
    #
    # The defect this ordering fixes: the report used to open with the #213 comparison,
    # whose "Passes here" table replayed the SaaS baseline's `cause` strings in a column
    # that looked exactly like the live `message` column of the table above it. A reader
    # took a 17-row table of failure messages as this run's failure list when only 8 rows
    # were failures, and filed two issues on tests that had passed (#244, #246, both
    # withdrawn). The run's own totals said "2988 passed, 8 failed" in the same log.
    # ---------------------------------------------------------------------------------
    lines.append("### Failed on THIS run")
    lines.append("")
    if failed:
        lines.append(f"All {len(failed)} of them, measured here. Every message below is from this run.")
        lines.append("")
        lines.append("| cu | test | message (measured here) |")
        lines.append("|---|---|---|")
        for t in failed[:100]:
            msg = t["message"][:220].replace("|", "\\|")
            lines.append(f"| {t['codeunit']} | `{t['test']}` | {msg} |")
        if len(failed) > 100:
            lines.append(f"| ... | _{len(failed) - 100} more, see `failures.tsv` in the artifact_ | |")
    else:
        lines.append("Nothing failed on this run.")
    lines.append("")

    if env:
        lines.append("### Environment this verdict is about")
        lines.append("")
        lines.append("| | |")
        lines.append("|---|---|")
        for k, v in env.items():
            lines.append(f"| {k} | {v} |")
        lines.append("")

    exit_code = 0

    if args.baseline and pathlib.Path(args.baseline).exists():
        baseline = json.loads(pathlib.Path(args.baseline).read_text(encoding="utf-8"))
        b_by_key = {key(f["codeunit"], f["test"]): f for f in baseline["failures"]}
        failed_keys = {key(t["codeunit"], t["test"]): t for t in failed}
        all_keys = {key(t["codeunit"], t["test"]): t for t in tests}

        reproduced, not_reproduced, missing, new = [], [], [], []
        for k, b in sorted(b_by_key.items()):
            if k in failed_keys:
                reproduced.append((b, failed_keys[k]))
            elif k in all_keys:
                not_reproduced.append((b, all_keys[k]))
            else:
                missing.append(b)
        for k, t in sorted(failed_keys.items()):
            if k not in b_by_key:
                new.append(t)

        measured_on = baseline.get("measured_on", "the MS SaaS sandbox")

        # -----------------------------------------------------------------------------
        # HISTORICAL SECTION. Everything from here down is about the #213 BASELINE, not
        # about this run, and it must not be readable as a failure list.
        #
        # Three separable devices carry that, because any one alone has already been shown
        # to be insufficient (the old layout labelled its column `why #213 saw it fail`
        # and was still misread):
        #   1. `reproduced` and `not_reproduced` are no longer adjacent tables of the same
        #      shape. The one that IS a live result carries no baseline text at all; the
        #      one that is NOT a live result carries no live-shaped column at all.
        #   2. Every replayed baseline string is prefixed IN THE CELL with `sandbox saw:`,
        #      so a cell copied out of the table still says whose measurement it is.
        #   3. Rows that passed here say so, in their own column, in words.
        # -----------------------------------------------------------------------------
        lines.append("---")
        lines.append("")
        lines.append("## Historical: against issue #213's sandbox list")
        lines.append("")
        lines.append(f"> Everything below this line is about the **{measured_on}** baseline "
                     "recorded in `.github/expected-failures/issue-213-saas-sandbox.json`. "
                     "**No error text below was produced by this run.** "
                     f"This run's own failures are the {len(failed)} listed above.")
        lines.append("")
        def ent(n):
            return "entry" if n == 1 else "entries"

        lines.append(f"- **{len(reproduced)}** of {len(b_by_key)} baseline {ent(len(b_by_key))} "
                     "also failed here")
        lines.append(f"- **{len(not_reproduced)}** baseline {ent(len(not_reproduced))} "
                     "**passed here** (so they are properties of the sandbox, not of BC)")
        if missing:
            was = "was" if len(missing) == 1 else "were"
            them = "it" if len(missing) == 1 else "them"
            lines.append(f"- **{len(missing)}** baseline {ent(len(missing))} {was} **not "
                         f"executed here** — neither a pass nor a failure; nothing was "
                         f"measured for {them}")
        lines.append(f"- **{len(new)}** of this run's failures are not in the baseline "
                     "(#213 is a partial list, so this is expected to be non-zero)")
        lines.append("")

        if reproduced:
            lines.append("### Baseline entries that also failed here")
            lines.append("")
            lines.append("These rows ARE among the failures listed at the top. "
                         "The message is this run's.")
            lines.append("")
            lines.append("| cu | test | group | message (measured here) |")
            lines.append("|---|---|---|---|")
            for b, t in reproduced:
                msg = t["message"][:220].replace("|", "\\|")
                lines.append(f"| {b['codeunit']} | `{b['test']}` | {b.get('group','')} | {msg} |")
            lines.append("")

        if not_reproduced:
            lines.append("### Baseline entries that PASSED here — did not reproduce")
            lines.append("")
            lines.append("**None of these is a failure on this run.** Each one passed. "
                         "The last column is the sandbox's own recorded reason from the "
                         "baseline file, kept so the entry can be understood — it is not a "
                         "result and describes an event that did not happen here.")
            lines.append("")
            lines.append("| cu | test | group | result here | sandbox's recorded reason (NOT this run) |")
            lines.append("|---|---|---|---|---|")
            for b, t in not_reproduced:
                cause = b.get("cause", "").replace("|", chr(92) + "|")
                cause = f"sandbox saw: {cause}" if cause else "_(no cause recorded)_"
                lines.append(f"| {b['codeunit']} | `{b['test']}` | {b.get('group','')} | "
                             f"**passed** | {cause} |")
            lines.append("")
            groups = {b.get("group") for b, _ in not_reproduced}
            if "permissions" in groups:
                lines.append("> **A pass in the `permissions` group proves nothing.** Codeunits 60013 "
                             "and 60827 declare `TestPermissions = Disabled` and no `Permissions` "
                             "property, so their writes fall through to whatever the license grants. "
                             "A dev-licensed container **masks** that defect rather than resolving it "
                             "-- the same masking that hid it until a SaaS run exposed it. "
                             "See issue #213.")
                lines.append("")

        if missing:
            # The `missing` bucket is neither a pass nor a failure, and after a corpus test
            # is deleted (cu 60878, PR #250) it is the EXPECTED state for that entry rather
            # than a problem. The old wording, "Listed in #213 but not executed here", sat
            # under a run of failure tables and read as one more thing that went wrong.
            lines.append("### Baseline entries with no result here — nothing was measured")
            lines.append("")
            lines.append("**Not failures.** These baseline entries had no matching test in this "
                         "run's output, so this run says nothing about them either way. The usual "
                         "reason is that the corpus test was deleted or renamed since the baseline "
                         "was recorded; a stale baseline entry is the thing to fix, not a test.")
            lines.append("")
            lines.append("| cu | test | group | result here | sandbox's recorded reason (NOT this run) |")
            lines.append("|---|---|---|---|---|")
            for b in missing:
                cause = b.get("cause", "").replace("|", chr(92) + "|")
                cause = f"sandbox saw: {cause}" if cause else "_(no cause recorded)_"
                lines.append(f"| {b['codeunit']} | `{b['test']}` | {b.get('group','')} | "
                             f"_not run_ | {cause} |")
            lines.append("")

        if new:
            lines.append("### This run's failures that the baseline does not list")
            lines.append("")
            lines.append("These rows ARE among the failures listed at the top; they are broken out "
                         "only to show which of them #213 had not seen.")
            lines.append("")
            lines.append("| cu | test | message (measured here) |")
            lines.append("|---|---|---|")
            for t in new[:100]:
                msg = t["message"][:220].replace("|", "\\|")
                lines.append(f"| {t['codeunit']} | `{t['test']}` | {msg} |")
            if len(new) > 100:
                lines.append(f"| ... | _{len(new) - 100} more, see the artifact_ | |")
            lines.append("")

        with (outdir / "issue-213-comparison.md").open("w", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n")

    # No `elif failed:` fallback here any more. The failure table is now printed
    # unconditionally near the top, so a second one at the bottom of a baseline-less run
    # would list the same failures twice -- and a report where the same test appears in two
    # differently-worded tables is exactly the ambiguity #249 was about.

    report = "\n".join(lines) + "\n"
    (outdir / "summary.md").write_text(report, encoding="utf-8")
    print(report)

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(report)

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
