#!/usr/bin/env python3
"""Self-test for check-cross-pr-object-ids.py, run in CI alongside it.

The cross-PR check can only exercise its interesting path when two open pull
requests actually collide, which is rare and cannot be arranged on demand. Left
untested it would sit in CI for months reporting "no collisions" whether or not
it still worked -- the shape of a check that has quietly stopped checking.

So this builds a throwaway git repository with a known collision and asserts
the real detection code reports it, plus the three ways it must NOT fire.
No network, no token, about a second.
"""
import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "xpr", HERE / "check-cross-pr-object-ids.py")
xpr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(xpr)

APP_JSON = '{"id":"a","name":"T","publisher":"p","version":"1.0.0.0",' \
           '"idRanges":[{"from":60000,"to":62000}]}'


def git(*a, cwd):
    p = subprocess.run(("git",) + a, cwd=cwd, capture_output=True, text=True)
    if p.returncode:
        sys.exit(f"setup failed: git {' '.join(a)}\n{p.stderr}")
    return p.stdout


def obj(kind, oid, name):
    return f'{kind} {oid} "{name}"\n{{\n}}\n'


def build(root: Path):
    """master + three branches: A, B (collides with A), C (same number, other type)."""
    git("init", "-q", "-b", "master", cwd=root)
    git("config", "user.email", "t@t", cwd=root)
    git("config", "user.name", "t", cwd=root)
    (root / "app.json").write_text(APP_JSON)
    # An id that master already owns. Both PRs will also contain it, inherited --
    # it must NOT count as a claim by either.
    (root / "Inherited.al").write_text(obj("codeunit", 60001, "Inherited"))
    git("add", "-A", cwd=root)
    git("commit", "-qm", "master", cwd=root)

    for branch, files in {
        "A": {"A1.al": obj("codeunit", 61500, "Collide A"),
              "A2.al": obj("codeunit", 61501, "Unique A")},
        "B": {"B1.al": obj("codeunit", 61500, "Collide B")},
        # Same NUMBER as A's codeunit but a different object type. AL namespaces
        # ids per type, so this is legal and must not be reported.
        "C": {"C1.al": obj("page", 61500, "Page Not A Clash")},
    }.items():
        git("checkout", "-q", "-B", branch, "master", cwd=root)
        for name, body in files.items():
            (root / name).write_text(body)
        git("add", "-A", cwd=root)
        git("commit", "-qm", branch, cwd=root)
    git("checkout", "-q", "master", cwd=root)


def run_check(root: Path, refs: dict, pr_number: str) -> int:
    """Invoke the real main() with the GitHub API and fetch stubbed out."""
    prs = [{"number": n, "sha": "0" * 40, "title": f"branch {r}",
            "author": "t", "draft": False, "ref": r} for n, r in refs.items()]
    saved_open, saved_fetch = xpr.open_prs, xpr.fetch_pr
    xpr.open_prs = lambda repo: prs
    xpr.fetch_pr = lambda repo, number, sha: refs[number]
    cwd = os.getcwd()
    try:
        os.chdir(root)
        os.environ["GITHUB_REPOSITORY"] = "o/r"
        os.environ["BASE_REF"] = "master"
        os.environ["PR_NUMBER"] = pr_number
        return xpr.main()
    finally:
        os.chdir(cwd)
        xpr.open_prs, xpr.fetch_pr = saved_open, saved_fetch


def main() -> int:
    failures = []
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        build(root)

        cases = [
            # label,                                  refs,                    PR_NUMBER, expected
            ("collision is reported on the PR's own run",
             {1: "A", 2: "B"}, "1", 1),
            ("collision is reported from the other side too",
             {1: "A", 2: "B"}, "2", 1),
            ("collision is reported by the pairwise sweep",
             {1: "A", 2: "B"}, "", 1),
            ("same number, different object type is NOT a collision",
             {1: "A", 2: "C"}, "1", 0),
            ("an id inherited from master is NOT a claim",
             {1: "B", 2: "C"}, "1", 0),
            ("a lone open PR has nothing to collide with",
             {1: "A"}, "1", 0),
        ]
        for label, refs, pr, expected in cases:
            print(f"\n--- {label} (expect exit {expected}) ---")
            got = run_check(root, refs, pr)
            if got != expected:
                failures.append(f"{label}: expected exit {expected}, got {got}")

    print("\n" + "=" * 78)
    if failures:
        for f in failures:
            print(f"::error::self-test FAILED — {f}")
        return 1
    print(f"self-test OK — {len(cases)} cases, detection and all three "
          f"must-not-fire cases behave as specified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
