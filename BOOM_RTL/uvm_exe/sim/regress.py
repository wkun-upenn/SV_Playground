#!/usr/bin/env python3
"""
regress.py — run the test list in tests.yml through sim/Makefile in parallel
and print a pass/fail table (plus an optional junit xml for CI).

  ./regress.py                       # everything, 8 jobs, SIM from the environment (default vcs)
  ./regress.py --tag fp --tag ooo    # subsets
  ./regress.py --test t43_fp_all_random --seeds 20
  ./regress.py --dry-run             # just print the commands
  ./regress.py --cov                 # merge coverage (VCS: urg) at the end

A run passes when the log contains "TEST PASSED" and no UVM_ERROR/UVM_FATAL
lines, and the simulator exit code is 0.
"""
import argparse, os, re, subprocess, sys, time, concurrent.futures as cf, xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))

def load_tests(path):
    """tiny yaml reader for the fixed schema used here (no PyYAML dependency)"""
    tests, cur = [], None
    for line in open(path):
        s = line.strip()
        if s.startswith('- name:'):
            cur = {'name': s.split(':', 1)[1].strip(), 'tags': [], 'seeds': 1}
            tests.append(cur)
        elif cur and s.startswith('tags:'):
            cur['tags'] = [t.strip() for t in s.split('[', 1)[1].rstrip(']').split(',') if t.strip()]
        elif cur and s.startswith('seeds:'):
            cur['seeds'] = int(s.split(':', 1)[1])
    return tests

def run_one(sim, test, seed, plus, dry, cov):
    cmd = ['make', '-s', '-C', HERE, 'run', f'SIM={sim}', f'TEST={test}', f'SEED={seed}', f'PLUS={plus}', f'COV={1 if cov else 0}']
    if dry:
        print(' '.join(cmd)); return (test, seed, 'DRY', 0.0, '')
    t0 = time.time()
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    log = os.path.join(HERE, 'run', f'{test}_{seed}', 'sim.log')
    txt = open(log).read() if os.path.exists(log) else p.stdout
    errs = re.findall(r'^UVM_(ERROR|FATAL) .*$', txt, re.M)
    passed = p.returncode == 0 and 'TEST PASSED' in txt and not errs
    first = errs[0] if errs else ''
    return (test, seed, 'PASS' if passed else 'FAIL', time.time() - t0, first)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--sim', default=os.environ.get('SIM', 'vcs'))
    ap.add_argument('--jobs', type=int, default=8)
    ap.add_argument('--tag', action='append', default=[])
    ap.add_argument('--test', action='append', default=[])
    ap.add_argument('--seeds', type=int, help='override the seed count of every selected test')
    ap.add_argument('--plus', default='', help='extra plusargs passed to every run')
    ap.add_argument('--cov', action='store_true')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--junit', default=os.path.join(HERE, 'run', 'regress.xml'))
    a = ap.parse_args()

    tests = load_tests(os.path.join(HERE, 'tests.yml'))
    if a.tag:  tests = [t for t in tests if set(t['tags']) & set(a.tag)]
    if a.test: tests = [t for t in tests if t['name'] in a.test]
    jobs = [(t['name'], s) for t in tests for s in range(1, (a.seeds or t['seeds']) + 1)]
    print(f'{len(jobs)} runs ({len(tests)} tests) on {a.sim}, {a.jobs} in parallel')

    if not a.dry_run:
        subprocess.run(['make', '-s', '-C', HERE, 'compile', f'SIM={a.sim}', f'COV={1 if a.cov else 0}'], check=True)

    results = []
    with cf.ThreadPoolExecutor(max_workers=a.jobs) as ex:
        futs = [ex.submit(run_one, a.sim, n, s, a.plus, a.dry_run, a.cov) for n, s in jobs]
        for f in cf.as_completed(futs):
            r = f.result(); results.append(r)
            print(f'  {r[2]:4s} {r[0]:32s} seed={r[1]:<3d} {r[3]:6.0f}s  {r[4][:90]}')
    results.sort()
    n_pass = sum(r[2] == 'PASS' for r in results)
    print(f'\n{n_pass}/{len(results)} passed')
    for r in results:
        if r[2] == 'FAIL': print(f'  FAIL {r[0]} seed={r[1]}: {r[4][:120]}')

    if not a.dry_run:
        os.makedirs(os.path.dirname(a.junit), exist_ok=True)
        suite = ET.Element('testsuite', name='boom_exe_uvm', tests=str(len(results)), failures=str(len(results) - n_pass))
        for name, seed, st, dt, msg in results:
            tc = ET.SubElement(suite, 'testcase', name=f'{name}_seed{seed}', time=f'{dt:.1f}')
            if st != 'PASS': ET.SubElement(tc, 'failure', message=msg or 'failed')
        ET.ElementTree(suite).write(a.junit)
        if a.cov and a.sim == 'vcs':
            subprocess.run(['make', '-s', '-C', HERE, 'cov-report', 'SIM=vcs'])
    sys.exit(0 if n_pass == len(results) else 1)

if __name__ == '__main__':
    main()
