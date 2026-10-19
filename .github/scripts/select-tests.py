#!/usr/bin/env python3
"""Pick the test codeunits that a change can affect, so that CI runs those instead of the whole suite.

    select-tests.py --base REV [--head REV] [--merge-base] [--repo DIR] [--json FILE] [--github]
    select-tests.py --full-reason TEXT [--head REV] [--repo DIR] [--json FILE] [--github]

The change is the tree diff BASE..HEAD (two dots: the merge commit's first parent for a pull request, the branch the
batch was built on for a dispatched run). Both trees are read from git objects, so no checkout of either is needed.

What is selected, per test job of .github/workflows/ci.yml:
  * every test codeunit (Subtype = Test, at least one [Test] procedure) declared in a changed file, and
  * every test codeunit that references a changed object, directly or through other objects: an object that names a
    changed object by name or id is itself treated as changed, until nothing new is found. An extension object
    (tableextension, pageextension, enumextension, ...) also counts as a change of the object it extends.
  * every job also runs one small test codeunit outside any #if (the sentinel): the reusable workflow fails a leg that
    ran no test at all, and a selected codeunit can be compiled out on an older BC version. The leg still compiles and
    publishes every app.
Only codeunits inside the job's own codeunit_range are selected, so a codeunit the full run leaves out stays out.

A change to ci.yml that edits nothing but the values of codeunit_range lines (a "CI range edit") is no reason for a
full run: the selection is made as usual, plus every test codeunit the edit brings into its job's range.

A full run is chosen instead when the change touches something a reference scan cannot follow (the rules are in
FULL_RULES below and in CONTRIBUTING.md, "Test selection in CI"). Any error in this script also means a full run.

Output: the step summary (--github: $GITHUB_STEP_SUMMARY), and the job output `subset` ($GITHUB_OUTPUT): a JSON object
{test app dir: "id,id,..."}; {} means a full run. ci.yml passes the value as codeunit_range, or the job's full range
when its key is missing. --json FILE writes the whole result (mode, reasons, per app selection with the why).
"""
import argparse
import json
import os
import re
import subprocess
import sys

CI_YML = '.github/workflows/ci.yml'
MAX_FILES = 50

# Paths outside the CI apps that no CI leg reads. A change to anything else outside the CI apps means a full run.
IGNORED_OUTSIDE_APPS = (
    re.compile(r'^docs/'), re.compile(r'^scripts/'), re.compile(r'^\.claude/'), re.compile(r'^tests/must-not-compile/'),
    re.compile(r'^[^/]+\.md$'), re.compile(r'^tests/[^/]+\.md$'), re.compile(r'^tests/al-surface(-inscope)?\.json$'),
    re.compile(r'^(tests/)?v2-classification\.json$'), re.compile(r'^\.gitignore$'),
)
# Files inside a CI app that the compile does not read.
IGNORED_INSIDE_APP = re.compile(r'(\.md|\.py|/bc-full-results\.json|/\.dev/.*)$')

KINDS = ('codeunit', 'table', 'tableextension', 'page', 'pageextension', 'pagecustomization', 'report', 'reportextension',
         'query', 'xmlport', 'enum', 'enumextension', 'permissionset', 'permissionsetextension', 'interface',
         'controladdin', 'profile', 'entitlement')
EXTENSION_KINDS = {'tableextension', 'pageextension', 'pagecustomization', 'reportextension', 'enumextension',
                   'permissionsetextension'}
PERMISSION_KINDS = {'permissionset', 'permissionsetextension', 'entitlement'}

# One pass over the source: comments (dropped), strings, quoted identifiers, braces, everything else.
LEX = re.compile(r"//[^\n]*|/\*.*?\*/|'(?:[^']|'')*'|\"[^\"\n]*\"|[{}]|[^/'\"{}]+|/", re.S)
WORD = re.compile(r'[A-Za-z_][A-Za-z0-9_]*|\d+')
NAME = r'(?:"[^"\n]*"|[A-Za-z_][A-Za-z0-9_]*)'
QUALIFIED = r'(?:(?:%s)\s*\.\s*)*%s' % (NAME, NAME)
HEADER = re.compile(r'\b(%s)\b(?:\s+(\d+))?\s+(%s)(?:\s+(?:extends|customizes)\s+(%s))?' % ('|'.join(KINDS), NAME, QUALIFIED),
                    re.I | re.S)
DOTNET_HEADER = re.compile(r'\bdotnet\s*$', re.I)
DOTNET_ALIAS = re.compile(r'\btype\s*\(\s*"[^"]*"\s*;\s*(%s)\s*\)' % NAME, re.I)
SUBTYPE = re.compile(r'\bSubtype\s*=\s*(\w+)\s*;', re.I)
TEST_ATTR = re.compile(r'\[\s*Test\s*\]', re.I)
HANDLER_ATTR = re.compile(r'\[\s*HandlerFunctions\s*\(', re.I)
SUBSCRIBER_ATTR = re.compile(r'\[\s*EventSubscriber\s*\(', re.I)
PREPROCESSOR_IF = re.compile(r'^\s*#if\b', re.I | re.M)


def has_code(text):
    """False for a file of comments and blank lines only."""
    return any(not (t.startswith('//') or t.startswith('/*') or t.isspace()) for t in (m.group(0) for m in LEX.finditer(text)))


def unquote(name):
    name = name.strip()
    if name.startswith('"') and name.endswith('"'):
        name = name[1:-1]
    return name.lower()


class Obj:
    __slots__ = ('path', 'kind', 'id', 'name', 'display', 'target', 'subtype', 'tests', 'handlers', 'subscriber', 'size',
                 'tokens', 'aliases', 'conditional')

    def keys(self):
        """What other objects use to name this one."""
        k = {self.name} if self.name else set()
        if self.id:
            k.add(self.id)
        if self.target:
            k.add(self.target)
        k.update(self.aliases)
        return k

    def label(self):
        return ' '.join(x for x in (self.kind, self.id, '"%s"' % self.display if self.display else None) if x)


def parse_al(path, text):
    """The top-level objects of one .al file. An object's tokens are the identifiers, quoted identifiers, numbers and
    string literals of its header and body, lower-cased, comments left out."""
    objs = []
    depth = 0
    header = []
    body = []
    conditional = bool(PREPROCESSOR_IF.search(text))
    for m in LEX.finditer(text):
        t = m.group(0)
        if t.startswith('//') or t.startswith('/*'):
            continue
        if depth == 0:
            if t == '{':
                depth = 1
                body = []
                head_tokens = header
                head_text = ''.join(header)
                header = []
                hm = None
                for hm in HEADER.finditer(head_text):
                    pass
                o = Obj()
                o.path, o.aliases, o.conditional = path, set(), conditional
                if hm is not None:
                    o.kind, o.id, o.name = hm.group(1).lower(), hm.group(2), unquote(hm.group(3))
                    o.display = hm.group(3).strip().strip('"')
                    target = hm.group(4)
                    o.target = unquote(re.split(r'\s*\.\s*(?=[^.]*$)', target)[-1]) if target else None
                    if o.kind not in EXTENSION_KINDS:
                        o.target = None
                elif DOTNET_HEADER.search(head_text):
                    o.kind, o.id, o.name, o.display, o.target = 'dotnet', None, None, None, None
                else:
                    o.kind = None  # not an object we can read: the caller decides
                    o.id = o.name = o.display = o.target = None
                o.tokens = head_tokens
                objs.append(o)
            else:
                header.append(t)
            continue
        if t == '{':
            depth += 1
        elif t == '}':
            depth -= 1
            if depth == 0:
                finish(objs[-1], body)
                continue
        body.append(t)
    return objs


def finish(o, body):
    text = ''.join(body)
    tokens = set()
    for part in o.tokens + body:
        if part.startswith("'"):
            tokens.add(part[1:-1].replace("''", "'").lower())
        elif part.startswith('"'):
            tokens.add(part[1:-1].lower())
        else:
            tokens.update(w.lower() for w in WORD.findall(part))
    o.tokens = tokens
    sm = SUBTYPE.search(text)
    o.subtype = sm.group(1).lower() if (sm and o.kind == 'codeunit') else None
    o.tests = len(TEST_ATTR.findall(text)) if o.subtype == 'test' else 0
    o.handlers = bool(HANDLER_ATTR.search(text))
    o.subscriber = bool(SUBSCRIBER_ATTR.search(text))
    o.size = len(text)
    if o.kind == 'dotnet':
        o.aliases = {unquote(a) for a in DOTNET_ALIAS.findall(text)}


# ---------- git ----------

class Git:
    def __init__(self, repo):
        self.repo = repo

    def run(self, *args, binary=False):
        p = subprocess.run(['git', '-C', self.repo] + list(args), capture_output=True)
        if p.returncode != 0:
            raise RuntimeError('git %s: %s' % (' '.join(args), p.stderr.decode(errors='replace').strip()))
        return p.stdout if binary else p.stdout.decode('utf-8', errors='replace')

    def rev(self, rev):
        return self.run('rev-parse', '--verify', rev + '^{commit}').strip()

    def changed(self, base, head):
        out = self.run('diff', '--name-only', '--no-renames', '-z', base, head)
        return sorted(f for f in out.split('\0') if f)

    def files(self, rev):
        return [f for f in self.run('ls-tree', '-r', '-z', '--name-only', rev).split('\0') if f]

    def read(self, rev, paths):
        """{path: text} for the paths that exist in rev."""
        paths = list(paths)
        if not paths:
            return {}
        out = {}
        data = subprocess.run(['git', '-C', self.repo, 'cat-file', '--batch'], capture_output=True,
                              input=''.join('%s:%s\n' % (rev, p) for p in paths).encode()).stdout
        pos = 0
        for p in paths:
            nl = data.index(b'\n', pos)
            head = data[pos:nl].decode(errors='replace').split(' ')
            pos = nl + 1
            if len(head) == 2 and head[1] == 'missing':
                continue
            size = int(head[2])
            out[p] = data[pos:pos + size].decode('utf-8-sig', errors='replace')
            pos += size + 1
        return out


# ---------- ci.yml ----------

RANGE_EXPR = re.compile(r"^\$\{\{\s*fromJson\(needs\.prepare\.outputs\.subset\)\[\s*'([^']+)'\s*\]\s*\|\|\s*'([^']*)'\s*\}\}$")


def parse_ci(text):
    """The jobs of ci.yml that call the BC test workflow: [{job, app_dirs, test_app_dirs, range, key}]. `key` is the
    subset key the job's codeunit_range reads, or None when the job always runs its full range."""
    jobs, cur, in_jobs = [], None, False
    lines = text.split('\n')
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.match(r'^jobs:\s*$', line):
            in_jobs = True
        elif in_jobs and re.match(r'^  ([A-Za-z0-9_-]+):\s*$', line):
            cur = {'job': line.strip()[:-1], 'with': {}}
            jobs.append(cur)
        elif cur is not None:
            m = re.match(r'^      ([a-z_]+):\s*(.*?)\s*$', line)
            if m and lines_in_with(lines, i):
                key, val = m.group(1), m.group(2)
                if val in ('|', '|-', '>'):
                    vals = []
                    while i + 1 < len(lines) and (lines[i + 1].startswith('        ') or not lines[i + 1].strip()):
                        i += 1
                        if lines[i].strip():
                            vals.append(lines[i].strip())
                    val = '\n'.join(vals)
                elif len(val) >= 2 and val[0] == val[-1] and val[0] in '"\'':
                    val = val[1:-1]
                cur['with'][key] = val
        i += 1
    out = []
    for j in jobs:
        w = j['with']
        if 'test_app_dirs' not in w or 'codeunit_range' not in w:
            continue
        rng, key = w['codeunit_range'], None
        m = RANGE_EXPR.match(rng)
        if m:
            key, rng = m.group(1), m.group(2)
        out.append({'job': j['job'], 'app_dirs': [d for d in w.get('app_dirs', '').split('\n') if d],
                    'test_app_dirs': [d for d in w['test_app_dirs'].split('\n') if d], 'range': rng, 'key': key})
    return out


def lines_in_with(lines, i):
    """True when line i sits under a `    with:` key of its job."""
    for k in range(i - 1, -1, -1):
        s = lines[k]
        if re.match(r'^    [a-z_-]+:', s):
            return s.strip() == 'with:'
        if re.match(r'^  \S', s):
            return False
    return False


RANGE_LINE = re.compile(r'^      codeunit_range:\s*(.*?)\s*$')


def range_line_key(lines, i):
    """For a codeunit_range line of a test job: ('key', subset key or None). None when line i is not one."""
    m = RANGE_LINE.match(lines[i])
    if not m or not lines_in_with(lines, i):
        return None
    k = RANGE_EXPR.match(m.group(1))
    return ('key', k.group(1) if k else None)


def ci_range_edit(base_text, head_text):
    """True when ci.yml changed, but only in the values of codeunit_range lines (a "CI range edit"): same lines
    otherwise, and every changed codeunit_range line still reads the same subset key (or still none)."""
    b, h = base_text.split('\n'), head_text.split('\n')
    if len(b) != len(h):
        return False
    diff = [i for i, (x, y) in enumerate(zip(b, h)) if x != y]
    return bool(diff) and all(range_line_key(b, i) is not None and range_line_key(b, i) == range_line_key(h, i)
                              for i in diff)


def spans(expr):
    out = []
    for part in expr.replace('|', ',').split(','):
        part = part.strip()
        if not part:
            continue
        lo, _, hi = part.partition('..')
        try:
            out.append((int(lo), int(hi or lo)))
        except ValueError:
            pass
    return out


def in_spans(sp, cid):
    return any(lo <= cid <= hi for lo, hi in sp)


# ---------- the selection ----------

def app_of(path, app_dirs):
    for d in app_dirs:
        if path.startswith(d.rstrip('/') + '/'):
            return d
    return None


def select(git, base, head, merge_base=False, ci_text=None):
    head = git.rev(head)
    base = git.rev(base)
    if merge_base:
        base = git.run('merge-base', base, head).strip()
    result = {'base': base, 'head': head, 'mode': 'subset', 'reasons': [], 'changed_files': [], 'apps': {}}
    ci = parse_ci(ci_text if ci_text is not None else git.read(head, [CI_YML]).get(CI_YML, ''))
    if not ci:
        return full(result, 'could not read the test jobs of %s' % CI_YML)
    unwired = [j['job'] for j in ci if not j['key']]
    if len(unwired) == len(ci):
        return full(result, 'no test job of %s reads the selection' % CI_YML)
    test_apps = {}
    for j in ci:
        for d in j['test_app_dirs']:
            test_apps.setdefault(d, []).append(j)
    ci_apps = sorted({d for j in ci for d in j['app_dirs'] + j['test_app_dirs']}, key=len, reverse=True)
    dependency_only = sorted(set(ci_apps) - set(test_apps))

    changed = git.changed(base, head)
    result['changed_files'] = changed
    if not changed:
        return full(result, 'no changed files between %s and %s' % (base[:10], head[:10]))

    all_files = git.files(head)
    ci_texts = git.read(base, [CI_YML]), git.read(head, [CI_YML])
    range_edit = CI_YML in changed and ci_range_edit(ci_texts[0].get(CI_YML, ''), ci_texts[1].get(CI_YML, ''))
    app_resources = resource_dirs(git, head, ci_apps)
    relevant, ignored = [], []
    reasons = []
    for f in changed:
        app = app_of(f, ci_apps)
        if f == CI_YML and range_edit:
            result['ci_range_edit'] = [f]  # only codeunit_range values changed: select as usual
        elif f.startswith('.github/'):
            reasons.append('CI configuration changed: %s' % f)
        elif app is None:
            if any(p.search(f) for p in IGNORED_OUTSIDE_APPS) or test_app_outside_ci(f, all_files, ci_apps):
                ignored.append(f)
            else:
                reasons.append('file outside the test apps that CI may read: %s' % f)
        elif app in dependency_only:
            reasons.append('dependency app changed: %s' % f)
        elif f == app + '/app.json' or f.startswith(app + '/.alpackages/'):
            reasons.append('app manifest or symbols changed: %s' % f)
        elif any(f.startswith(r + '/') for r in app_resources.get(app, ())):
            reasons.append('app resource changed (NavApp.ListResources sees every resource): %s' % f)
        elif IGNORED_INSIDE_APP.search(f) and not f.endswith('.al'):
            ignored.append(f)
        else:
            relevant.append(f)
    result['ignored_files'] = ignored
    if len(relevant) > MAX_FILES:
        reasons.append('%d changed files in the test apps (more than %d)' % (len(relevant), MAX_FILES))
    if reasons:
        return full(result, *reasons)
    if not relevant:
        return full(result, 'no changed file in the test apps, so nothing to select')

    al_files = [f for f in all_files if f.endswith('.al') and app_of(f, ci_apps)]
    texts = git.read(head, al_files)
    objs = []
    for f in al_files:
        objs.extend(parse_al(f, texts[f]))
    index = {}
    for n, o in enumerate(objs):
        for t in o.tokens:
            index.setdefault(t, []).append(n)
    by_path = {}
    for n, o in enumerate(objs):
        by_path.setdefault(o.path, []).append(n)

    # seeds: objects of the changed files (head and base versions), objects that name a changed non-AL file
    base_texts = git.read(base, [f for f in relevant if f.endswith('.al')])
    seeds = []  # (description, keys, head object indices, needs_coverage)
    for f in relevant:
        if f.endswith('.al'):
            versions = [(objs[n], 'head') for n in by_path.get(f, [])]
            if f in base_texts:
                versions += [(o, 'base') for o in parse_al(f, base_texts[f])]
            if f in texts and not by_path.get(f) and has_code(texts[f]):
                reasons.append('no AL object found in %s' % f)
            for o, side in versions:
                if o.kind is None:
                    reasons.append('an object in %s could not be read' % f)
                elif o.subscriber:
                    reasons.append('event subscriber in %s (%s): it can run in any test' % (f, o.label()))
                elif o.subtype in ('install', 'upgrade', 'testrunner'):
                    reasons.append('Subtype = %s codeunit in %s' % (o.subtype.capitalize(), f))
                elif o.kind in PERMISSION_KINDS:
                    reasons.append('%s in %s' % (o.kind, f))
            here = by_path.get(f, [])
            if f in texts and here:
                seeds.append(('changed: %s' % f, set(), here, True))
            gone = {o.name for o, side in versions if side == 'base'} - {objs[n].name for n in here}
            if gone:
                # deleted or renamed objects: the compile proves nothing else names them; follow their names anyway
                keys = set().union(*[o.keys() for o, side in versions if side == 'base' and o.name in gone])
                seeds.append(('object removed from %s' % f, keys, [], False))
        else:
            base_name = f.rsplit('/', 1)[-1].lower()
            app = app_of(f, ci_apps)
            users = [n for n, o in enumerate(objs) if o.path.startswith(app + '/') and base_name in texts[o.path].lower()]
            users = sorted({n for n in users})
            if not users and f in all_files:
                reasons.append('no AL object names the changed file %s' % f)
            seeds.append(('changed: %s (named in %s)' % (f, ', '.join(sorted({objs[n].path for n in users})) or 'nothing'),
                          set(), users, f in all_files))
    if reasons:
        return full(result, *reasons)

    def runnable(n):
        o = objs[n]
        if o.subtype != 'test' or not o.tests or not o.id:
            return None
        app = app_of(o.path, list(test_apps))
        if app is None:
            return None
        if not any(in_spans(spans(j['range']), int(o.id)) for j in test_apps[app]):
            return None
        return app

    why = {}
    for desc, keys, here, needs_cover in seeds:  # a test codeunit in a changed file: that is the reason to give
        for n in here:
            if runnable(n):
                why[n] = desc
    for desc, keys, here, needs_cover in seeds:
        reached = closure(objs, index, keys, here)
        tests = {n: v for n, v in reached.items() if runnable(n)}
        if needs_cover and not tests:
            reasons.append('nothing in a test codeunit uses what %s declares, so its effect is unknown' % desc.split(': ', 1)[-1])
        for n, v in tests.items():
            if n not in why:
                why[n] = describe(objs, v, desc)
    if reasons:
        return full(result, *reasons)
    if range_edit:
        # a test codeunit the CI range edit brings into its job's range has never run in CI: run it too
        base_ranges = {}
        for j in parse_ci(ci_texts[0].get(CI_YML, '')):
            for d in j['test_app_dirs']:
                base_ranges.setdefault(d, []).extend(spans(j['range']))
        for n in range(len(objs)):
            app = runnable(n)
            if app and n not in why and not in_spans(base_ranges.get(app, []), int(objs[n].id)):
                why[n] = 'brought into codeunit_range by the CI range edit in %s' % CI_YML
    if not why:
        return full(result, 'nothing selected')

    for app, jobs in sorted(test_apps.items()):
        if not any(j['key'] for j in jobs):
            continue
        picked = sorted((n for n in why if runnable(n) == app), key=lambda n: int(objs[n].id))
        entry = {'codeunits': [{'id': int(objs[n].id), 'name': objs[n].display, 'file': objs[n].path, 'why': why[n]}
                               for n in picked],
                 'test_codeunits_in_app': sum(1 for n in range(len(objs)) if runnable(n) == app)}
        # One test codeunit outside any #if always runs too: the test workflow fails a leg that runs no codeunit, and a
        # selected codeunit can be compiled out on an older BC version.
        s = sentinel(objs, [n for n in range(len(objs)) if runnable(n) == app and not objs[n].conditional])
        if s is None:
            return full(result, 'no test codeunit without #if in %s to keep its leg running' % app)
        if s not in picked:
            entry['codeunits'].append({'id': int(objs[s].id), 'name': objs[s].display, 'file': objs[s].path,
                                       'why': 'sentinel: one small codeunit every leg runs, so that no leg runs zero codeunits',
                                       'sentinel': True})
        entry['sentinel'] = not picked
        result['apps'][app] = entry
    result['unwired_jobs'] = unwired
    return result


def closure(objs, index, keys, start):
    """{object index: (key, from)} for every object that names one of keys or a key of start, directly or through
    other objects; from is the object the key belongs to (None for a key of a removed object)."""
    reached = {n: None for n in start}
    todo = [(k, None) for k in keys] + [(k, n) for n in start for k in objs[n].keys()]
    seen = set()
    while todo:
        k, src = todo.pop()
        if k in seen:
            continue
        seen.add(k)
        for n in index.get(k, ()):
            if n in reached:
                continue
            reached[n] = (k, src)
            todo.extend((k2, n) for k2 in objs[n].keys())
    return reached


def describe(objs, via, seed):
    if via is None:
        return seed
    key, src = via
    if src is None:
        return 'uses "%s"; %s' % (key, seed)
    o = objs[src]
    if o.target and key == o.target:
        return 'uses "%s", which %s extends; %s' % (key, o.label(), seed)
    return 'uses %s; %s' % (o.label(), seed)


def sentinel(objs, candidates):
    """The cheapest-looking test codeunit: no handler functions, fewest tests, least code, lowest id."""
    if not candidates:
        return None
    return min(candidates, key=lambda n: (objs[n].handlers, objs[n].tests, objs[n].size, int(objs[n].id)))


def resource_dirs(git, head, apps):
    out = {}
    texts = git.read(head, [a + '/app.json' for a in apps])
    for a in apps:
        try:
            manifest = json.loads(texts.get(a + '/app.json', '{}'))
        except ValueError:
            continue
        out[a] = [a + '/' + r.strip('/') for r in manifest.get('resourceFolders', [])]
    return out


def test_app_outside_ci(f, all_files, ci_apps):
    """A file of an app under tests/ that no CI job builds (for example the isolation probe app)."""
    parts = f.split('/')
    return len(parts) > 2 and parts[0] == 'tests' and ('tests/%s/app.json' % parts[1]) in all_files \
        and ('tests/' + parts[1]) not in ci_apps


def full(result, *reasons):
    result['mode'] = 'full'
    result['reasons'] = list(dict.fromkeys(reasons))
    result['apps'] = {}
    return result


# ---------- output ----------

def subset_output(result):
    if result['mode'] != 'subset':
        return {}
    return {app: ','.join(str(c['id']) for c in e['codeunits']) for app, e in result['apps'].items()}


def summary(result):
    out = []
    if result['mode'] == 'full':
        out.append('## Test selection: full run\n')
        out.append('Every test codeunit in every job runs. Why:\n')
        out.extend('- %s' % r for r in result['reasons'])
    else:
        n = sum(1 for e in result['apps'].values() for c in e['codeunits'] if not c.get('sentinel'))
        out.append('## Test selection: %d test codeunit%s\n' % (n, '' if n == 1 else 's'))
        out.append('Only the test codeunits that the change can affect run. Every app is still compiled and published. '
                   'Rules: CONTRIBUTING.md, "Test selection in CI". Add the label `full-run` to a pull request and '
                   're-run all jobs to run everything.\n')
        for app, e in result['apps'].items():
            own = sum(1 for c in e['codeunits'] if not c.get('sentinel'))
            label = 'nothing affected, sentinel only' if e.get('sentinel') else '%d of %d' % (own, e['test_codeunits_in_app'])
            out.append('- `%s`: %s' % (app, label))
        if result.get('ci_range_edit'):
            out.append('- `%s`: only `codeunit_range` values changed (CI range edit), so no full run' % CI_YML)
        if result.get('unwired_jobs'):
            out.append('- jobs that always run their full range: %s' % ', '.join(result['unwired_jobs']))
        out.append('\n| App | Codeunit | Name | Why |\n|---|---|---|---|')
        for app, e in result['apps'].items():
            for c in e['codeunits']:
                out.append('| `%s` | %d | %s | %s |' % (app, c['id'], c['name'].replace('|', '\\|'), c['why'].replace('|', '\\|')))
    if result.get('base'):
        out.append('\nDiff: `%s..%s`, %d changed file%s%s.' % (
            result['base'][:10], (result.get('head') or '')[:10], len(result.get('changed_files', [])),
            '' if len(result.get('changed_files', [])) == 1 else 's',
            ', %d of them not read by CI' % len(result['ignored_files']) if result.get('ignored_files') else ''))
    return '\n'.join(out) + '\n'


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--base')
    ap.add_argument('--head', default='HEAD')
    ap.add_argument('--repo', default='.')
    ap.add_argument('--merge-base', action='store_true',
                    help='diff from the merge base of BASE and HEAD (what a branch changed since it left BASE)')
    ap.add_argument('--ci-yml', help='read the test jobs from this file instead of HEAD:%s (local measurements)' % CI_YML)
    ap.add_argument('--full-reason')
    ap.add_argument('--json')
    ap.add_argument('--github', action='store_true', help='write $GITHUB_STEP_SUMMARY and $GITHUB_OUTPUT')
    a = ap.parse_args(argv)
    if not a.full_reason and not a.base:
        ap.error('--base or --full-reason is required')
    git = Git(a.repo)
    if a.full_reason:
        result = full({'base': None, 'head': None, 'mode': 'full', 'reasons': [], 'apps': {}}, a.full_reason)
    else:
        try:
            result = select(git, a.base, a.head, a.merge_base, open(a.ci_yml).read() if a.ci_yml else None)
        except Exception as e:  # never block CI on this script: run everything
            result = full({'base': None, 'head': None, 'mode': 'full', 'reasons': [], 'apps': {}},
                          'the selection script failed (%s: %s)' % (type(e).__name__, e))
    text = summary(result)
    print(text)
    if a.json:
        with open(a.json, 'w') as f:
            json.dump(result, f, indent=1)
    if a.github:
        if os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as f:
                f.write(text)
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                f.write('subset=%s\n' % json.dumps(subset_output(result), separators=(',', ':')))
        n = sum(1 for e in result['apps'].values() for c in e['codeunits'] if not c.get('sentinel'))
        print('::notice title=Test selection::%s' % (
            'full run: ' + '; '.join(result['reasons'])[:900] if result['mode'] == 'full'
            else '%d test codeunit(s) selected; the prepare job summary says which and why' % n))
    return 0


if __name__ == '__main__':
    sys.exit(main())
