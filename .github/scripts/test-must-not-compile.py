#!/usr/bin/env python3
"""Self-test of check-must-not-compile.py: the header grammar, the diagnostic parser and the comparison. No compiler is run."""
import importlib.util, os, sys, tempfile

here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location('mnc', os.path.join(here, 'check-must-not-compile.py'))
mnc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mnc)

failures = []


def expect(cond, what):
    if not cond:
        failures.append(what)


h = mnc.parse_header("// @expect AL0161 | 'Hidden' is inaccessible\n// @target OnPrem\n// a note\n// @min-al 18\n// @appjson {\"a\": 1}\n\ntable 1 \"T\" {}\n// @expect AL9999 | after code\n")
expect(h['expect'] == [('AL0161', "'Hidden' is inaccessible")], 'expect line: %r' % h['expect'])
expect(h['target'] == 'OnPrem' and h['min-al'] == '18' and h['appjson'] == {'a': 1}, 'keys: %r' % h)

out = ("case.al(14,9): error AL0161: 'Hidden' is inaccessible due to its protection level [/tmp/x/app.json]\n"
       "warning AL0432: not an error\n"
       "app.json(5,3): error AL0124: The property 'x' cannot be used in this context\n"
       "error AL1009: Unrecognized option: '/foo'\n")
d = mnc.parse_diagnostics(out)
expect([c for c, _, _ in d] == ['AL0161', 'AL0124', 'AL1009'], 'codes: %r' % d)
expect(d[0][1] == "'Hidden' is inaccessible due to its protection level", 'message trimmed: %r' % d[0][1])

found = [('AL0161', "'Hidden' is inaccessible due to its protection level")]
expect(mnc.check([('AL0161', "'Hidden' is inaccessible")], found) == [], 'prefix match')
expect(mnc.check([('AL0161', 'other text')], found) != [], 'other text is a problem')
expect(mnc.check([('AL0440', '')], found) != [], 'missing code is a problem')
expect(mnc.check([], found) != [], 'extra diagnostic is a problem')
expect(mnc.check([('AL0161', '')], found) == [], 'empty text matches any')

expect(mnc.applies({'from': '28'}, 27, None) is False and mnc.applies({'until': '27'}, 28, None) is False, 'bc range')
expect(mnc.applies({'min-al': '18'}, 27, 16) is False and mnc.applies({'min-al': '18'}, 27, 18) is True, 'min-al')

cases = os.path.join(here, '..', '..', 'tests', 'must-not-compile', 'cases')
for f in sorted(os.listdir(cases)):
    if f.endswith('.al'):
        hh = mnc.parse_header(open(os.path.join(cases, f)).read())
        expect(hh['expect'] != [], '%s has no @expect line' % f)
        expect(all(c.startswith('AL') for c, _ in hh['expect']), '%s: bad code' % f)

if failures:
    print('FAIL:\n  ' + '\n  '.join(failures))
    sys.exit(1)
print('ok')
