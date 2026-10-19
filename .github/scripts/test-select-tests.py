#!/usr/bin/env python3
"""Self-test for select-tests.py: builds small git repos and checks which test codeunits it selects and when it falls
back to a full run. Also checks that the real ci.yml wires every test job to the selection."""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('select_tests', HERE / 'select-tests.py')
st = importlib.util.module_from_spec(spec)
spec.loader.exec_module(st)

CI = """name: t
on: [pull_request]
jobs:
  prepare:
    runs-on: ubuntu-latest
  test:
    name: BC ${{ matrix.bc_version }}
    uses: x/y/.github/workflows/bc-test-from-source.yml@master
    with:
      app_dirs:             "tests/fixture"
      test_app_dirs:        "tests/main"
      codeunit_range:       ${{ fromJson(needs.prepare.outputs.subset)['tests/main'] || '50000..50099|50200..50299' }}
  test-onprem:
    name: BC OnPrem ${{ matrix.bc_version }}
    uses: x/y/.github/workflows/bc-test-from-source.yml@master
    with:
      app_dirs: |
        tests/fixture
        tests/main
      test_app_dirs:        "tests/onprem"
      codeunit_range:       ${{ fromJson(needs.prepare.outputs.subset)['tests/onprem'] || '60000..60099' }}
"""

BASE_FILES = {
    '.github/workflows/ci.yml': CI,
    'README.md': '# corpus\n',
    'tests/fixture/app.json': '{}',
    'tests/fixture/Fix.al': 'codeunit 70000 "Fix Helper"\n{\n}\n',
    'tests/main/app.json': json.dumps({'resourceFolders': ['res']}),
    'tests/main/res/a.txt': 'hello',
    'tests/main/Assert.al': 'codeunit 50000 Assert\n{\n    procedure IsTrue(b: Boolean) begin end;\n}\n',
    'tests/main/Probe.Table.al': 'table 50001 "Probe Rec"\n{\n    fields { field(1; "No."; Integer) { } }\n}\n',
    'tests/main/Helper.al': ('codeunit 50002 "Probe Helper"\n{\n    procedure Make()\n    var R: Record "Probe Rec";\n'
                             '    begin R.Insert(); end;\n}\n'),
    'tests/main/T1.al': ('codeunit 50010 "Uses Table"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                         '    var R: Record "Probe Rec";\n    begin end;\n}\n'),
    'tests/main/T2.al': ('codeunit 50011 "Uses Helper"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                         '    var H: Codeunit "Probe Helper";\n    begin H.Make(); end;\n}\n'),
    'tests/main/T3.al': ('// mentions [EventSubscriber( only in a comment; "Probe Rec" too\n'
                         'codeunit 50012 Unrelated\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n    begin\n'
                         "        Message('{ not a brace }');\n    end;\n    [Test]\n    procedure B() begin end;\n}\n"),
    'tests/main/NoTests.al': 'codeunit 50013 "Fixture Only"\n{\n    Subtype = Test;\n    var R: Record "Probe Rec";\n}\n',
    'tests/main/OutOfRange.al': ('codeunit 50150 "Out Of Range"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                                 '    var R: Record "Probe Rec";\n    begin end;\n}\n'),
    'tests/main/Cust.al': ('codeunit 50014 "Uses Customer"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                           '    var C: Record Customer;\n    begin end;\n}\n'),
    'tests/main/CustExt.al': ('namespace Corpus.Ext;\nusing Microsoft.Sales.Customer;\n'
                              'tableextension 50003 "Cust Ext" extends Microsoft.Sales.Customer.Customer\n{\n}\n'),
    'tests/main/Rep.al': ("report 50004 \"Probe Report\"\n{\n    RDLCLayout = 'Layout.rdlc';\n}\n"
                          'codeunit 50015 "Runs Report"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                          '    begin Report.Run(Report::"Probe Report"); end;\n}\n'),
    'tests/main/Layout.rdlc': '<Report/>',
    'tests/main/Orphan.al': 'codeunit 50005 "Nobody Calls Me"\n{\n}\n',
    'tests/onprem/app.json': '{}',
    'tests/onprem/O1.al': ('codeunit 60010 "OnPrem Uses Table"\n{\n    Subtype = Test;\n    [Test]\n    procedure A()\n'
                           '    var R: Record "Probe Rec";\n    begin end;\n}\n'),
    'tests/onprem/O2.al': 'codeunit 60011 "OnPrem Other"\n{\n    Subtype = Test;\n    [Test]\n    procedure A() begin end;\n}\n',
}


def git(repo, *a):
    return subprocess.run(['git', '-C', repo, '-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false']
                          + list(a), check=True, capture_output=True, text=True).stdout.strip()


def make(changes, base_files=None):
    """A repo with BASE_FILES committed, then `changes` ({path: text or None to delete}) committed on top."""
    repo = tempfile.mkdtemp(prefix='repo-', dir=ROOT)
    git(repo, 'init', '-q', '-b', 'main')
    for p, t in (base_files or BASE_FILES).items():
        f = Path(repo, p)
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '-m', 'base')
    base = git(repo, 'rev-parse', 'HEAD')
    for p, t in changes.items():
        f = Path(repo, p)
        if t is None:
            f.unlink()
        else:
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text(t)
    git(repo, 'add', '-A')
    git(repo, 'commit', '-q', '--allow-empty', '-m', 'change')
    return st.select(st.Git(repo), base, 'HEAD')


def ids(result, app):
    return [c['id'] for c in result['apps'][app]['codeunits'] if not c.get('sentinel')]


def sentinels(result, app):
    return [c['id'] for c in result['apps'][app]['codeunits'] if c.get('sentinel')]


FAILED = []
ROOT = tempfile.mkdtemp(prefix='select-tests-')


def check(name, cond, detail=''):
    print('%s %s%s' % ('ok  ' if cond else 'FAIL', name, '' if cond else ': %s' % detail))
    if not cond:
        FAILED.append(name)


def touch(path):
    return {path: BASE_FILES[path] + '\n// changed\n'}


def main():
    r = make(touch('tests/main/T1.al'))
    check('changed test codeunit runs alone', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010], r)
    check('app with nothing selected runs only its sentinel', r['apps']['tests/onprem'].get('sentinel')
          and ids(r, 'tests/onprem') == [] and sentinels(r, 'tests/onprem') == [60011], r['apps'].get('tests/onprem'))
    check('every app also runs one sentinel: the smallest codeunit with one test and no #if',
          sentinels(r, 'tests/main') == [50014], r['apps']['tests/main'])
    check('subset output is {app: "ids"}', st.subset_output(r) == {'tests/main': '50010,50014', 'tests/onprem': '60011'},
          st.subset_output(r))

    with_if = dict(BASE_FILES)
    with_if['tests/main/Tiny.al'] = '#if BC29PLUS\ncodeunit 50016 Tiny\n{\n    Subtype = Test;\n    [Test]\n    procedure A() begin end;\n}\n#endif\n'
    r = make(touch('tests/main/T1.al'), with_if)
    check('a codeunit in #if is never the sentinel', sentinels(r, 'tests/main') == [50014], r['apps']['tests/main'])

    comment_only = dict(BASE_FILES)
    comment_only['tests/main/Notes.al'] = '// placeholder, no object yet\n'
    r = make({'tests/main/Notes.al': '// placeholder, still no object\n', 'tests/main/T1.al': BASE_FILES['tests/main/T1.al'] + '\n'},
             comment_only)
    check('a file with only comments selects nothing and is no reason for a full run', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010], r['reasons'])

    r = make(touch('tests/main/Probe.Table.al'))
    check('changed table: users, users through a helper, other apps; not out of range, not without [Test], '
          'not a mention in a comment', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010, 50011]
          and ids(r, 'tests/onprem') == [60010], r)

    r = make(touch('tests/main/CustExt.al'))
    check('table extension: tests that use the extended table', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50014], r)

    r = make(touch('tests/main/Layout.rdlc'))
    check('layout file: tests that use the report that names it', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50015], r)

    r = make({'tests/main/Orphan.al': None, 'tests/main/T1.al': BASE_FILES['tests/main/T1.al'] + '\n'})
    check('removed object does not force a full run', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010], r)

    r = make({'tests/main/T3.al': BASE_FILES['tests/main/T3.al'] + '\n'})
    check('[EventSubscriber( in a comment is not a subscriber', r['mode'] == 'subset', r['reasons'])

    sub = ('codeunit 50020 "Subs"\n{\n    [EventSubscriber(ObjectType::Table, Database::"Probe Rec", \'OnAfterInsertEvent\','
           " '', false, false)]\n    local procedure X() begin end;\n}\n")
    fulls = {
        'event subscriber': ({'tests/main/Subs.al': sub}, 'event subscriber'),
        'install codeunit': ({'tests/main/I.al': 'codeunit 50021 Inst\n{\n    Subtype = Install;\n}\n'}, 'Subtype = Install'),
        'permission set': ({'tests/main/P.al': 'permissionset 50022 "PS"\n{\n}\n'}, 'permissionset'),
        'app.json': ({'tests/main/app.json': '{"x": 1}'}, 'manifest'),
        'resource': ({'tests/main/res/a.txt': 'changed'}, 'resource'),
        'CI file': ({'.github/scripts/x.py': 'print(1)'}, 'CI configuration'),
        'dependency app': (touch('tests/fixture/Fix.al'), 'dependency app'),
        'unknown file outside the apps': ({'tools/x.sh': 'echo'}, 'outside the test apps'),
        'docs only': ({'README.md': '# changed\n', 'docs/a.md': 'x'}, 'no changed file in the test apps'),
        'empty diff': ({}, 'no changed files'),
        'orphan object': (touch('tests/main/Orphan.al'), 'effect is unknown'),
        'more than MAX_FILES': ({'tests/main/gen/T%d.al' % i: 'codeunit %d "G%d"\n{\n}\n' % (50100 + i, i)
                                 for i in range(st.MAX_FILES + 1)}, 'more than'),
    }
    for name, (changes, needle) in fulls.items():
        r = make(changes)
        check('full run: %s' % name, r['mode'] == 'full' and any(needle in x for x in r['reasons']), r['reasons'])
    with_upgrade = dict(BASE_FILES)
    with_upgrade['tests/main/U.al'] = 'codeunit 50023 Upg\n{\n    Subtype = Upgrade;\n}\n'
    r = make({'tests/main/U.al': None}, with_upgrade)
    check('full run: upgrade codeunit removed', r['mode'] == 'full'
          and any('Subtype = Upgrade' in x for x in r['reasons']), r['reasons'])

    # a job whose codeunit_range is a plain string keeps its full range and is listed as such
    plain = dict(BASE_FILES)
    plain['.github/workflows/ci.yml'] = CI.replace(
        "${{ fromJson(needs.prepare.outputs.subset)['tests/onprem'] || '60000..60099' }}", '"60000..60099"')
    r = make(touch('tests/main/T1.al'), plain)
    check('unwired job runs its full range', r['mode'] == 'subset' and 'tests/onprem' not in r['apps']
          and r['unwired_jobs'] == ['test-onprem'], r)

    # a ci.yml change that only edits codeunit_range values (a "CI range edit") is selected as usual, not a full run
    wider = CI.replace("'50000..50099|50200..50299'", "'50000..50099|50200..50299|50300..50399'")
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': wider}))
    check('CI range edit: selected as usual', r['mode'] == 'subset' and ids(r, 'tests/main') == [50010]
          and r.get('ci_range_edit') == ['.github/workflows/ci.yml'], r)
    into_range = CI.replace("'50000..50099|50200..50299'", "'50000..50199|50200..50299'")
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': into_range}))
    check('CI range edit: a test codeunit the edit brings into the range runs too', r['mode'] == 'subset'
          and ids(r, 'tests/main') == [50010, 50150], r)
    r = make({'.github/workflows/ci.yml': wider})
    check('CI range edit alone: full run (nothing in the test apps changed)', r['mode'] == 'full'
          and any('no changed file in the test apps' in x for x in r['reasons']), r['reasons'])
    more = wider.replace('  test-onprem:\n', '  # a comment\n  test-onprem:\n')
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': more}))
    check('ci.yml edit beyond codeunit_range lines: full run', r['mode'] == 'full'
          and any('CI configuration' in x for x in r['reasons']), r['reasons'])
    rewired = CI.replace("['tests/onprem'] || '60000..60099'", "['tests/main'] || '60000..60099'")
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': rewired}))
    check('codeunit_range edit that changes the subset key: full run', r['mode'] == 'full'
          and any('CI configuration' in x for x in r['reasons']), r['reasons'])
    other_key = CI.replace('      test_app_dirs:        "tests/onprem"', '      test_app_dirs:        "tests/other"')
    r = make(dict(touch('tests/main/T1.al'), **{'.github/workflows/ci.yml': other_key}))
    check('ci.yml edit of another with: key: full run', r['mode'] == 'full'
          and any('CI configuration' in x for x in r['reasons']), r['reasons'])

    # the parser: several objects per file, braces in strings, quoted and namespaced names
    objs = st.parse_al('x.al', BASE_FILES['tests/main/Rep.al'] + BASE_FILES['tests/main/CustExt.al'])
    check('parse_al reads every object', [(o.kind, o.id, o.name, o.target) for o in objs] == [
        ('report', '50004', 'probe report', None), ('codeunit', '50015', 'runs report', None),
        ('tableextension', '50003', 'cust ext', 'customer')], [(o.kind, o.id, o.name, o.target) for o in objs])
    t3 = st.parse_al('t3.al', BASE_FILES['tests/main/T3.al'])
    check('comments are not tokens, strings are', len(t3) == 1 and 'probe rec' not in t3[0].tokens
          and '{ not a brace }' in t3[0].tokens and t3[0].tests == 2, [(o.name, sorted(o.tokens)) for o in t3])

    # the real ci.yml: every job that runs BC tests reads the selection under its own test app dir
    real = st.parse_ci((HERE.parent / 'workflows' / 'ci.yml').read_text())
    check('real ci.yml has test jobs', len(real) >= 3, real)
    for j in real:
        check('real ci.yml job %s reads the selection for its test app' % j['job'],
              j['key'] is not None and j['test_app_dirs'] == [j['key']] and st.spans(j['range']), j)
    # test-testlibraries (the job that installs Tests-TestLibraries and Data Archive) keeps its own id block as full range
    tl = [j for j in real if j['job'] == 'test-testlibraries']
    check('real ci.yml job test-testlibraries runs 81550..81649 in full', len(tl) == 1
          and tl[0]['key'] == 'tests/al-language-testlibraries' and st.spans(tl[0]['range']) == [(81550, 81649)], tl)

    if FAILED:
        print('%d failed: %s' % (len(FAILED), ', '.join(FAILED)))
        return 1
    print('all passed')
    return 0


if __name__ == '__main__':
    try:
        code = main()
    finally:
        shutil.rmtree(ROOT, ignore_errors=True)
    sys.exit(code)
