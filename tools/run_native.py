"""Boot installed game/PCK/Metro in a fresh local sandbox. Never opens real saves."""
import os, shutil, subprocess, json, re, sys, argparse
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--game-dir',type=Path,default=ROOT.parent.parent.parent)
parser.add_argument('--mods-dir',type=Path)
parser.add_argument('--reactive',action='store_true')
parser.add_argument('--furniture',action='store_true')
parser.add_argument('--hotkey',action='store_true')
args=parser.parse_args()
game=args.game_dir.resolve()
MODS=(args.mods_dir or game/'mods').resolve()
for name in ['RTV.exe','RTV.pck','modloader.gd']:
    if not (game/name).is_file():raise SystemExit('Missing game or Metro file: '+str(game/name))
fixture=ROOT/'validation/native';fixture.mkdir(parents=True,exist_ok=True)
for name in ['RTV.exe','RTV.pck','modloader.gd']:
    source=game/name
    dest=fixture/name
    if not dest.exists():
        if name=='RTV.pck':os.link(source,dest)
        else:shutil.copy2(source,dest)
shutil.copy2(ROOT/'project/tests/NativeMonitor.gd',fixture/'NativeMonitor.gd')
(fixture/'override.cfg').write_text('[autoload_prepend]\nModLoader="*res://modloader.gd"\nNativeRangeMonitor="*res://NativeMonitor.gd"\n')
archives=fixture/'mods';archives.mkdir(exist_ok=True)
for source in MODS.glob('*.vmz'):
    if source.name!='ShootingRange.vmz':shutil.copy2(source,archives/source.name)
shutil.copy2(ROOT/'release/ShootingRange-0.2.4.vmz',archives/'ShootingRange.vmz')
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    path=fixture/key.lower();path.mkdir(exist_ok=True);env[key]=str(path)
user=fixture/'appdata/Road to Vostok';user.mkdir(exist_ok=True)
paths=', '.join(json.dumps(str(p).replace('\\','/')) for p in sorted(archives.glob('*.vmz')))
state=user/'mod_pass_state.cfg'
text=state.read_text() if state.exists() else '[state]\nmodloader_version="3.4.1"\n'
text=re.sub(r'^archive_paths=.*\n?', '', text, flags=re.M)
text=re.sub(r'^restart_count=.*\n?', '', text, flags=re.M)
state.write_text(text+'\narchive_paths=PackedStringArray('+paths+')\nrestart_count=0\n')
(user/'mod_config.cfg').write_text('[settings]\nactive_profile="Default"\ndeveloper_mode=false\n')
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
with (fixture/'console.txt').open('w',encoding='utf-8') as output:
    cmd=[str(fixture/'RTV.exe'),'--rendering-method','forward_plus','--rendering-driver','d3d12','--resolution','1600x1000','--position','-10000,-10000','--audio-driver','Dummy','--log-file',str(fixture/'engine.log'),'--','--modloader-restart']
    if '--reactive' in sys.argv:cmd.append('--range-reactive-only')
    if '--furniture' in sys.argv:cmd.append('--range-furniture-only')
    if '--hotkey' in sys.argv:cmd.append('--range-hotkey-only')
    proc=subprocess.Popen(cmd,cwd=fixture,env=env,stdout=output,stderr=subprocess.STDOUT,startupinfo=startup)
    try:code=proc.wait(timeout=210)
    except subprocess.TimeoutExpired:proc.kill();proc.wait();code=-1
content=(fixture/'console.txt').read_text(encoding='utf-8',errors='replace')
errors=[line for line in content.splitlines() if re.match(r'(?:SCRIPT )?ERROR:',line) and 'root certificate store' not in line]
report={'exit_code':code,'complete':'NATIVE_RANGE_COMPLETE' in content,'errors':errors,'results':[line for line in content.splitlines() if line.startswith(('NATIVE_RANGE','[ShootingRange]'))]}
(fixture/('reactive-report.json' if '--reactive' in sys.argv else 'furniture-report.json' if '--furniture' in sys.argv else 'hotkey-report.json' if '--hotkey' in sys.argv else 'report.json')).write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
raise SystemExit(1 if code or errors or not report['complete'] else 0)
