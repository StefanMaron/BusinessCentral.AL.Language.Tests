#!/usr/bin/env python3
"""Which test codeunits an .app contains, and whether every one of them reported a result.

Used by nightly-windows.yml. Reads the compiled .app itself (SymbolReference.json inside it),
so codeunits that a preprocessor symbol leaves out of a BC version are not expected there.

  ids   --app A.app [--other B.app ...]
        Prints JSON: {"tests": [...], "no_methods": [...], "foreign": [...]}.
        tests      = Subtype = Test codeunits with at least one [Test] method (expected to report)
        no_methods = Subtype = Test codeunits without a [Test] method (fixtures; not expected)
        foreign    = test codeunit ids of the --other apps (a range filter must not include them)

  check --app A.app --xunit results.xml --name al-language [--aborted 1,2] [--summary FILE]
        Compares the codeunits that reported in the XUnit file against the app. Prints the counts
        and the highest id that reported, appends a table to --summary, and exits 1 when fewer
        codeunits reported than the app contains.
"""
import argparse
import io
import json
import sys
import xml.etree.ElementTree as ET
import zipfile


def symbols(app_path):
    data = open(app_path, 'rb').read()
    start = data.find(b'PK\x03\x04')  # a .app is a NAVX header followed by a zip
    if start < 0:
        raise SystemExit(f'{app_path}: no zip payload')
    with zipfile.ZipFile(io.BytesIO(data[start:])) as z:
        return json.loads(z.read('SymbolReference.json').decode('utf-8-sig'))


def codeunits(node):
    yield from node.get('Codeunits') or []
    for ns in node.get('Namespaces') or []:
        yield from codeunits(ns)


def test_codeunits(app_path):
    tests, no_methods = [], []
    for cu in codeunits(symbols(app_path)):
        props = {p.get('Name'): p.get('Value') for p in cu.get('Properties') or []}
        if str(props.get('Subtype', '')).lower() != 'test':
            continue
        has_test = any(
            a.get('Name') == 'Test'
            for m in cu.get('Methods') or []
            for a in m.get('Attributes') or []
        )
        (tests if has_test else no_methods).append(int(cu['Id']))
    return sorted(tests), sorted(no_methods)


def reported_ids(xunit_path):
    try:
        root = ET.parse(xunit_path).getroot()
    except (OSError, ET.ParseError):
        return set()
    ids = set()
    for asm in root.iter('assembly'):
        head = (asm.get('name') or '').split(' ', 1)[0]
        if head.isdigit():
            ids.add(int(head))
    return ids


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('ids')
    p.add_argument('--app', required=True)
    p.add_argument('--other', action='append', default=[])
    c = sub.add_parser('check')
    c.add_argument('--app', required=True)
    c.add_argument('--xunit', required=True)
    c.add_argument('--name', required=True)
    c.add_argument('--aborted', default='')
    c.add_argument('--summary')
    a = ap.parse_args()

    if a.cmd == 'ids':
        tests, no_methods = test_codeunits(a.app)
        foreign = set()
        for o in a.other:
            t, n = test_codeunits(o)
            foreign.update(t)
            foreign.update(n)
        json.dump({'tests': tests, 'no_methods': no_methods, 'foreign': sorted(foreign)}, sys.stdout)
        return 0

    tests, no_methods = test_codeunits(a.app)
    got = reported_ids(a.xunit)
    missing = sorted(set(tests) - got)
    aborted = [int(x) for x in a.aborted.split(',') if x.strip()]
    top = max(got) if got else None
    lines = [
        f'{a.name}: {len(got & set(tests))} of {len(tests)} test codeunits reported '
        f'(highest id that reported: {top}; highest in the app: {tests[-1] if tests else None}; '
        f'{len(no_methods)} Subtype = Test codeunits without a [Test] method not counted)',
    ]
    if aborted:
        lines.append(f'{a.name}: the test runner aborted during codeunit(s) {", ".join(map(str, aborted))}')
    if missing:
        shown = ', '.join(map(str, missing[:40])) + (' ...' if len(missing) > 40 else '')
        lines.append(f'{a.name}: {len(missing)} test codeunit(s) did not report: {shown}')
    for line in lines:
        print(line)
    if a.summary:
        with open(a.summary, 'a', encoding='utf-8') as f:
            f.write('\n'.join(f'- {line}' for line in lines) + '\n')
    if missing:
        print(f'::error::{a.name}: {len(missing)} of {len(tests)} test codeunits reported no result')
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
