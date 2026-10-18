#!/usr/bin/env bash
# Run alc and refuse to call the build clean unless all four checks hold.
#
# Usage: scripts/check-alc-output.sh <alc command and arguments>
#   e.g. scripts/check-alc-output.sh alc /project:. /packagecachepath:pkgs /out:out.app
#
# Why four checks (corpus issue 234). Each one catches a different way a broken build looked
# clean through `alc ... | grep ': error'`:
#   1. "Compilation started" present  - with an empty package cache alc can fail (AL1018)
#      and print no diagnostics at all.
#   2. "Compilation ended" present    - alc can stop before it finishes.
#   3. exit code 0                    - alc can print errors and still be the only signal.
#   4. no error line in EITHER shape  - "file(line,col): error ALnnnn" and the bare
#      column-0 form "error ALnnnn: ...", which a grep for ': error' does not see.
set -u
[ "$#" -ge 1 ] || { echo "usage: $0 <alc command and arguments>" >&2; exit 2; }
log=$(mktemp)
trap 'rm -f "$log"' EXIT
"$@" >"$log" 2>&1
code=$?
cat "$log"
fail=0
grep -q 'Compilation started' "$log" || { echo "CHECK FAILED: no 'Compilation started' line" >&2; fail=1; }
grep -q 'Compilation ended' "$log" || { echo "CHECK FAILED: no 'Compilation ended' line" >&2; fail=1; }
[ "$code" -eq 0 ] || { echo "CHECK FAILED: alc exited with $code" >&2; fail=1; }
if grep -Eq '(^|[^[:alnum:]])error AL[0-9]+' "$log"; then
  echo "CHECK FAILED: alc reported errors:" >&2
  grep -E '(^|[^[:alnum:]])error AL[0-9]+' "$log" >&2
  fail=1
fi
[ "$fail" -eq 0 ] && echo "alc output is clean: started, ended, exit 0, no errors."
exit "$fail"
