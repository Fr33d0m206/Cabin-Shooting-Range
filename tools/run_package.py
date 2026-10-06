"""Mount the release in an empty project: no loose runtime or imported textures."""
import argparse, json, os, re, shutil, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--godot',required=True,type=Path)
args=parser.parse_args()
fixture=ROOT/'validation/package-smoke';fixture.mkdir(parents=True,exist_ok=True)
(fixture/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Range Package Smoke"\n[debug]\nfile_logging/enable_file_logging=false\n')
shutil.copy2(ROOT/'project/tests/PackageSmoke.gd',fixture/'PackageSmoke.gd')
# Metro mounts VMZ as ZIP. Use that same representation without loose files.
shutil.copy2(ROOT/'release/ShootingRange-0.2.5.vmz',fixture/'Range.zip')
env=os.environ.copy()
for name in ['APPDATA','LOCALAPPDATA']:
    path=fixture/name.lower();path.mkdir(exist_ok=True);env[name]=str(path)
cmd=[str(args.godot.resolve()),'--headless','--path',str(fixture),'--script','res://PackageSmoke.gd','--',str(fixture/'Range.zip')]
with (fixture/'engine.log').open('w',encoding='utf-8') as output:
    result=subprocess.run(cmd,env=env,stdout=output,stderr=subprocess.STDOUT,timeout=90)
content=(fixture/'engine.log').read_text(encoding='utf-8',errors='replace')
errors=[line for line in content.splitlines() if re.match(r'(?:SCRIPT )?ERROR:',line) and 'root certificate store' not in line]
report={'exit_code':result.returncode,'complete':'RANGE_PACKAGE_SMOKE_COMPLETE' in content,'errors':errors}
(fixture/'report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
raise SystemExit(1 if result.returncode or errors or not report['complete'] else 0)
