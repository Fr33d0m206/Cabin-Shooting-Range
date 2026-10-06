"""Deterministic source-identical Metro archive. Only this mod is installed."""
from pathlib import Path
import argparse, hashlib, json, zipfile, shutil
ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT/'project'
parser=argparse.ArgumentParser()
parser.add_argument('--install',action='store_true')
parser.add_argument('--mods-dir',type=Path,default=ROOT.parent.parent,help='Game mods folder for --install')
args=parser.parse_args()
files=[PROJECT/'mod.txt',*sorted((PROJECT/'mods/ShootingRange').rglob('*.gd')),*sorted((PROJECT/'mods/ShootingRange/assets').glob('*.png')),*sorted((PROJECT/'Assets/ShootingRange').glob('*.tscn')),*sorted((PROJECT/'Assets/ShootingRange').glob('*.tres'))]
release=ROOT/'release';release.mkdir(exist_ok=True)
archive_path=release/'ShootingRange-0.2.5.vmz'
with zipfile.ZipFile(archive_path,'w',zipfile.ZIP_DEFLATED,compresslevel=7) as archive:
    for source in files:
        name=source.relative_to(PROJECT).as_posix()
        info=zipfile.ZipInfo(name,date_time=(2026,10,6,0,0,0))
        info.compress_type=zipfile.ZIP_DEFLATED
        archive.writestr(info,source.read_bytes())
with zipfile.ZipFile(archive_path) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist())==len(files)
    for source in files:assert archive.read(source.relative_to(PROJECT).as_posix())==source.read_bytes()
digest=hashlib.sha256(archive_path.read_bytes()).hexdigest()
if args.install:
    destination=args.mods_dir.resolve()/'ShootingRange.vmz'
    if not destination.parent.is_dir():raise SystemExit('The game mods folder does not exist: '+str(destination.parent))
    if destination.exists() and destination.read_bytes()!=archive_path.read_bytes():
        backup=release/('previous-'+hashlib.sha256(destination.read_bytes()).hexdigest()[:16]+'.vmz')
        if not backup.exists():shutil.copy2(destination,backup)
    shutil.copy2(archive_path,destination)
    assert hashlib.sha256(destination.read_bytes()).hexdigest()==digest
report={'sha256':digest,'archive':str(archive_path),'bytes':archive_path.stat().st_size,'files':len(files),'source_identical':True,'installed':args.install}
(ROOT/'validation').mkdir(exist_ok=True)
(ROOT/'validation/package.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
