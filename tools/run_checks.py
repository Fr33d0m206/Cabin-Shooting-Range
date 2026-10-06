"""Isolated regressions/rendering with no access to the player's save directory."""
import argparse, os, subprocess, json, re, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', required=True, type=Path)
parser.add_argument('--render', action='store_true')
parser.add_argument('--scores', action='store_true')
parser.add_argument('--reactive', action='store_true')
parser.add_argument('--renderer', default='gl_compatibility', choices=['gl_compatibility','forward_plus'])
args = parser.parse_args()
case = ROOT/'validation'/('render-'+args.renderer if args.render else 'reactive' if args.reactive else 'scores' if args.scores else 'checks')
case.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
runtime=Path(tempfile.mkdtemp(prefix='range-render-')) if args.render else case
for name in ['APPDATA','LOCALAPPDATA']:
    path=runtime/name.lower(); path.mkdir(exist_ok=True)
    env[name]=str(path)
cmd=[str(args.godot.resolve()), '--path', str(ROOT/'project'), '--audio-driver','Dummy', '--fixed-fps','60']
if args.render:
    cmd += ['--rendering-method',args.renderer,'--resolution','1600x1000','--position','-10000,-10000','--script','res://tests/RenderReview.gd']
    if args.renderer=='forward_plus':cmd += ['--rendering-driver','d3d12']
else:
    cmd += ['--headless','--script','res://tests/ReactiveTests.gd' if args.reactive else 'res://tests/ScoreTests.gd' if args.scores else 'res://tests/RangeTests.gd']
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
with (case/'engine.log').open('w',encoding='utf-8') as log:
    proc=subprocess.Popen(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup)
    try: code=proc.wait(timeout=150)
    except subprocess.TimeoutExpired: proc.kill();proc.wait();code=-1
content=(case/'engine.log').read_text(encoding='utf-8',errors='replace')
errors=[line for line in content.splitlines() if re.match(r'(?:SCRIPT )?ERROR:',line) and 'root certificate store' not in line]
done='RANGE_RENDER_COMPLETE' if args.render else 'REACTIVE_TESTS_COMPLETE' if args.reactive else 'SCORE_TESTS_COMPLETE' if args.scores else 'RANGE_TESTS_COMPLETE'
report={'exit_code':code,'complete':done in content,'errors':errors,'results':[line for line in content.splitlines() if line.startswith(('CHECK','RANGE_','SCORE_','REACTIVE_'))]}
(case/'report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
raise SystemExit(1 if code or errors or done not in content or 'CHECK FAIL' in content else 0)
