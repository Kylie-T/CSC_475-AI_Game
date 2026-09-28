"""Verify player/camera/ambient systems preserved alongside the new puzzle."""
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root / 'main.gd').read_text()
functions = {m.group(1): m.group(0) for m in re.finditer(
    r'^func (\w+)\([^\n]*\n.*?(?=^func |\Z)', source, re.M | re.S)}
expected = json.loads((root / 'tools/gameplay_fingerprints.json').read_text())
for name, digest in expected.items():
    body = functions[name]
    if name == '_physics_process':
        body = body.replace('\tif introduced:\n\t\t_update_trade(delta)\n', '')
    assert hashlib.sha256(body.encode()).hexdigest() == digest, name
print('PASS: player movement, fixed camera, shoppers, idle cues and NPC collisions unchanged')
