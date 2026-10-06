"""Create an upload ZIP from the verified VMZ and public release documents."""
from pathlib import Path
from io import BytesIO
import hashlib
import json
import re
import zipfile
import argparse

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'project'
RELEASE = ROOT / 'release'
parser = argparse.ArgumentParser()
parser.add_argument('--mods-dir',type=Path,default=ROOT.parent.parent)
args = parser.parse_args()
version = re.search(r'^version="([\d.]+)"$', (PROJECT / 'mod.txt').read_text(), re.M).group(1)
vmz_path = RELEASE / f'ShootingRange-{version}.vmz'
vmz = vmz_path.read_bytes()
digest = lambda data: hashlib.sha256(data).hexdigest()

# Require an exact source match, including the native resource bundles.
sources = [PROJECT / 'mod.txt',
           *sorted((PROJECT / 'mods/ShootingRange').rglob('*.gd')),
           *sorted((PROJECT / 'mods/ShootingRange/assets').glob('*.png')),
           *sorted((PROJECT / 'Assets/ShootingRange').glob('*.tscn')),
           *sorted((PROJECT / 'Assets/ShootingRange').glob('*.tres'))]
with zipfile.ZipFile(BytesIO(vmz)) as archive:
    assert archive.testzip() is None
    assert set(archive.namelist()) == {p.relative_to(PROJECT).as_posix() for p in sources}
    assert len(archive.namelist()) == len(sources)
    for source in sources:
        assert archive.read(source.relative_to(PROJECT).as_posix()) == source.read_bytes()

checks = {}
for name in ['checks', 'reactive', 'scores', 'native', 'package-smoke', 'render-forward_plus']:
    report = json.loads((ROOT / 'validation' / name / 'report.json').read_text())
    assert report['complete'] and report['exit_code'] == 0 and not report['errors'], name
    assert not any('FAIL ' in line for line in report.get('results', [])), name
    checks[name] = 'passed'
native = ROOT / 'validation/native'
assert (native / 'mods/ShootingRange.vmz').read_bytes() == vmz
assert any(f'[ShootingRange] {version} ready' in line
           for line in json.loads((native / 'report.json').read_text())['results'])
assert (ROOT / 'validation/package-smoke/Range.zip').read_bytes() == vmz

contents = {'ShootingRange.vmz': vmz}
for name in ['README.md', 'CHANGELOG.md', 'MOD_DESCRIPTION.md']:
    contents[name] = (RELEASE / 'docs' / name).read_bytes()
    assert '\u2014' not in contents[name].decode('utf-8'), name
assert f'Cabin Shooting Range {version}' in contents['README.md'].decode('utf-8')
contents['SHA256SUMS.txt'] = ''.join(
    f'{digest(data)}  {name}\n' for name, data in contents.items()).encode('utf-8')

output = RELEASE / f'ShootingRange-v{version}.zip'
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=7) as archive:
    for name, data in contents.items():
        entry = zipfile.ZipInfo(name, date_time=(2026, 10, 6, 0, 0, 0))
        entry.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(entry, data)
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert archive.namelist() == list(contents)
    for name, data in contents.items():
        assert archive.read(name) == data

installed = args.mods_dir / 'ShootingRange.vmz'
report = {'version': version, 'zip': str(output), 'bytes': output.stat().st_size,
          'zip_sha256': digest(output.read_bytes()), 'vmz_sha256': digest(vmz),
          'source_identical': True, 'entries': list(contents), 'checks': checks,
          'installed_identical': installed.is_file() and installed.read_bytes() == vmz}
(ROOT / 'validation/release.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
