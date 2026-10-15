#!/usr/bin/env python3
import importlib.util, sys, tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location('chk', Path(__file__).with_name('check-install-triggers.py'))
chk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(chk)

with tempfile.TemporaryDirectory() as d:
    root = Path(d)
    (root / 'a.al').write_text('codeunit 1 "A"\n{\n    Subtype = Install;\n}\n')
    (root / 'b.al').write_text('codeunit 2 "B"\n{\n    Subtype = Test;\n}\n')
    (root / 'c.al').write_text('codeunit 3 "C"\n{\n    subtype = upgrade;\n}\n')
    assert chk.find(root, set()) == ['a.al', 'c.al'], chk.find(root, set())
    assert chk.find(root, {'a.al'}) == ['c.al']
print('self-test OK')
