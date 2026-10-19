#!/usr/bin/env python3
"""Fail the build when a codeunit with Subtype = Install or Upgrade is added to the corpus apps.

Why: an install or upgrade trigger runs when the app is published. One that raises (a per-company table written from OnInstallAppPerDatabase: "You must choose a
company before you can access the ... table.") makes the publish fail, and then the app does not install on ANY BC version: the whole matrix is red before a single test
runs. A probe must never live in an install trigger; read the effect from a test instead. The files below are the install codeunits that existed when this check was added;
a new one needs a conscious change of this list, after the batch was published to a local container that starts from an empty database.
"""
import re
import sys
from pathlib import Path

ALLOWED = {
    'tests/al-language/_fixtures/ALTInstallProbe.al',
    'tests/al-language/_fixtures/ALTQuotedInstallProbe.al',
    'tests/al-language/install/TestInstallSeeder.al',
    'tests/al-language/record/TestCodeunitMetadataVirtualTable.al',
    'tests/al-language/record/TestAllObjVirtualTable.al',
    'tests/al-language/types/TestBlankEnumInitInstaller.Codeunit.al',
    'tests/al-language/install/TestInstallStartSessionProbe.al',
    'tests/al-language/events/lt-trigger-pins/PUpgradeTriggers.al',
}
PATTERN = re.compile(r'^\s*Subtype\s*=\s*(Install|Upgrade)\s*;', re.M | re.I)


def find(root: Path, allowed):
    bad = []
    for al in sorted(root.rglob('*.al')):
        rel = al.relative_to(root).as_posix()
        if '.git' in al.parts or rel in allowed:
            continue
        if PATTERN.search(al.read_text(encoding='utf-8-sig', errors='replace')):
            bad.append(rel)
    return bad


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')
    bad = find(root, ALLOWED)
    for rel in bad:
        print('::error file=%s::codeunit with Subtype = Install/Upgrade: it runs at publish and one failure breaks the app on every BC version. See .github/scripts/check-install-triggers.py' % rel)
    if bad:
        return 1
    print('OK: no new install or upgrade codeunit')
    return 0


if __name__ == '__main__':
    sys.exit(main())
