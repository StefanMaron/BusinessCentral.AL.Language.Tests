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
    if env:
        lines.append("### Environment this verdict is about")
        lines.append("")
        lines.append("| | |")
        lines.append("|---|---|")
        for k, v in env.items():
            lines.append(f"| {k} | {v} |")
        lines.append("")
    lines.append(f"**{len(passed)} passed, {len(failed)} failed, {len(skipped)} skipped, {len(tests)} total.**")
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

        lines.append("### Against issue #213's sandbox list")
        lines.append("")
        lines.append(f"- **{len(reproduced)}** of {len(b_by_key)} also fail here")
        lines.append(f"- **{len(not_reproduced)}** pass here (so they are properties of the sandbox, not of BC)")
        if missing:
            lines.append(f"- **{len(missing)}** did not run here at all")
        lines.append(f"- **{len(new)}** failures here that #213 did not list "
                     "(#213 is a partial list, so this is expected to be non-zero)")
        lines.append("")

        if reproduced:
            lines.append("#### Also fails on the Windows container")
            lines.append("")
            lines.append("| cu | test | group | message |")
            lines.append("|---|---|---|---|")
            for b, t in reproduced:
                msg = t["message"][:220].replace("|", "\\|")
                lines.append(f"| {b['codeunit']} | `{b['test']}` | {b.get('group','')} | {msg} |")
            lines.append("")

        if not_reproduced:
            lines.append("#### Passes here -- did NOT reproduce")
            lines.append("")
            lines.append("| cu | test | group | why #213 saw it fail |")
            lines.append("|---|---|---|---|")
            for b, t in not_reproduced:
                lines.append(f"| {b['codeunit']} | `{b['test']}` | {b.get('group','')} | "
                             f"{b.get('cause','').replace('|', chr(92)+'|')} |")
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
            lines.append("#### Listed in #213 but not executed here")
            lines.append("")
            for b in missing:
                lines.append(f"- {b['codeunit']} `{b['test']}`")
            lines.append("")

        if new:
            lines.append("#### Failing here, not listed in #213")
            lines.append("")
            lines.append("| cu | test | message |")
            lines.append("|---|---|---|")
            for t in new[:100]:
                msg = t["message"][:220].replace("|", "\\|")
                lines.append(f"| {t['codeunit']} | `{t['test']}` | {msg} |")
            if len(new) > 100:
                lines.append(f"| ... | _{len(new) - 100} more, see the artifact_ | |")
            lines.append("")

        with (outdir / "issue-213-comparison.md").open("w", encoding="utf-8") as fh:
            fh.write("\n".join(lines) + "\n")

    elif failed:
        lines.append("### Failures")
        lines.append("")
        lines.append("| cu | test | message |")
        lines.append("|---|---|---|")
        for t in failed[:100]:
            msg = t["message"][:220].replace("|", "\\|")
            lines.append(f"| {t['codeunit']} | `{t['test']}` | {msg} |")
        lines.append("")

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
