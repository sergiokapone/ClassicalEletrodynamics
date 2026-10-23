#!/usr/bin/env python3
"""Cleans the git history of the repository (GitHub: sergiokapone/ClassicalEletrodynamics) so that it does not grow without end.

Removed from the WHOLE history:
  - the paths listed in purge-paths.txt (one per line; 'regex:...' lines are regular expressions, as in git filter-repo);
  - old versions of the files in docs/ (the published site is rebuilt and committed again and again).
Never removed: any file of the current commit (its tree is compared before and after; nothing is pushed if it changed)
and any version that was ever at a path outside docs/ (the pictures in docs/ are byte copies of */Pictures/*).

Before rewriting: a full backup (git bundle) next to the project. After: origin is restored and the branch and tags
are force-pushed. Needs git filter-repo (pip install git-filter-repo).

Usage: python clean_repo.py            report, ask for YES, clean and push
       python clean_repo.py --dry-run  only the report: what would be removed and how much it takes"""
import argparse, datetime, os, re, shutil, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
LIST = 'purge-paths.txt'
REMOTE = 'https://github.com/sergiokapone/ClassicalEletrodynamics.git'     # used if the repository has no origin


def git(*args, check=True):
    r = subprocess.run(['git', '-c', 'core.quotepath=off', *args], cwd=ROOT, capture_output=True,
                       text=True, encoding='utf-8', errors='replace')
    if check and r.returncode:
        sys.exit('ERROR: git %s\n%s' % (' '.join(args), r.stderr.strip()))
    return r.stdout


def run(*cmd):
    """A command whose output the user sees; returns the exit code."""
    return subprocess.run(cmd, cwd=ROOT).returncode


def read_list():
    pats = []
    for line in open(os.path.join(ROOT, LIST), encoding='utf-8'):
        line = line.strip()
        if line and not line.startswith('#'): pats.append(line)
    return pats


def matcher(pats):
    """The same rules as git filter-repo --paths-from-file: a plain line is a file or a folder, 'regex:' a regex."""
    lits = [p for p in pats if not p.startswith('regex:')]
    rxs = [re.compile(p[6:]) for p in pats if p.startswith('regex:')]
    def match(path):
        return any(path == l or path.startswith(l.rstrip('/') + '/') for l in lits) or any(r.search(path) for r in rxs)
    return match


def history_blobs():
    """Every (version, path) pair that ever entered the history: one line per changed file of every commit,
    ':<old mode> <new mode> <old id> <new id> <status>\\t<path>'."""
    for line in git('log', '--all', '--root', '-m', '--raw', '--no-renames', '--no-abbrev', '--format=').splitlines():
        if not line.startswith(':') or '\t' not in line: continue
        head, path = line.split('\t', 1)
        f = head.split(' ')
        if set(f[3]) == {'0'} or f[1] == '160000': continue          # deleted file / submodule
        yield f[3], path


def sizes():
    """object id -> size on disk"""
    out = {}
    for line in git('cat-file', '--batch-all-objects', '--batch-check=%(objectname) %(objectsize:disk)').splitlines():
        oid, size = line.split(' ')
        out[oid] = int(size)
    return out


def pack_size():
    m = re.search(r'^size-pack: (.*)$', git('count-objects', '-vH'), re.M)
    return m.group(1) if m else '?'


def mb(n): return '%.1f MB' % (n / 1048576)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--dry-run', action='store_true', help='only report, change nothing')
    args = ap.parse_args()

    # --- 0. checks ---------------------------------------------------------------------------------
    if not os.path.isfile(os.path.join(ROOT, LIST)): sys.exit('ERROR: no %s next to the script' % LIST)
    if git('rev-parse', '--is-inside-work-tree', check=False).strip() != 'true': sys.exit('ERROR: not a git repository')
    branch = git('rev-parse', '--abbrev-ref', 'HEAD').strip()
    pats = read_list()
    match = matcher(pats)

    # --- 1. what goes ------------------------------------------------------------------------------
    keep = {line.split()[2] for line in git('ls-tree', '-r', 'HEAD').splitlines() if line.split()[1] == 'blob'}
    head_paths = git('ls-tree', '-r', '--name-only', 'HEAD').splitlines()
    docs, listed = set(), set()
    for oid, path in history_blobs():
        if match(path): listed.add(oid)
        elif path.startswith('docs/'): docs.add(oid)
        else: keep.add(oid)
    docs -= keep | listed
    listed -= keep
    sz = sizes()
    in_head = [p for p in head_paths if match(p)]

    print('Repository: %s, branch %s, packed size %s' % (ROOT, branch, pack_size()))
    print('Paths from %s: %s' % (LIST, ', '.join(pats)))
    print('  their versions in the history: %d (%s)' % (len(listed), mb(sum(sz.get(o, 0) for o in listed))))
    print('Old versions of files in docs/: %d (%s)' % (len(docs), mb(sum(sz.get(o, 0) for o in docs))))
    if in_head:
        print('WARNING: the current commit has files from %s, they would be deleted too:\n  %s' % (LIST, '\n  '.join(in_head)))
    if args.dry_run:
        print('Dry run: nothing changed.')
        return
    if not listed and not docs:
        print('Nothing to clean.')
        return

    if subprocess.run(['git', 'filter-repo', '--version'], cwd=ROOT, capture_output=True).returncode:
        sys.exit('ERROR: git filter-repo not found. Install: pip install git-filter-repo')
    if git('status', '--porcelain', '--untracked-files=no').strip():
        sys.exit('ERROR: uncommitted changes in tracked files: filter-repo would throw them away. Commit them first.')
    remote = git('remote', 'get-url', 'origin', check=False).strip() or REMOTE
    tree = git('rev-parse', 'HEAD^{tree}').strip()

    print('\nThe history of %s and all tags will be rewritten and FORCE-PUSHED to %s.' % (branch, remote))
    print('Everyone who has cloned the repository gets a different history.')
    if input('Continue? Type YES in capitals: ').strip() != 'YES':
        print('Cancelled.')
        return

    # --- 2. backup ---------------------------------------------------------------------------------
    ts = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    bundle = os.path.abspath(os.path.join(ROOT, '..', '%s-backup-%s.bundle' % (os.path.basename(ROOT), ts)))
    print('\n[1/5] Backup of the whole repository: %s' % bundle)
    if run('git', 'bundle', 'create', bundle, '--all'): sys.exit('ERROR: git bundle failed')

    # filter-repo deletes listed files that are tracked from the disk too: keep the copies that lie in the project
    tmp = tempfile.mkdtemp(prefix='clean_repo-')
    saved = []
    for dirpath, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d != '.git']
        for f in files:
            rel = os.path.relpath(os.path.join(dirpath, f), ROOT).replace(os.sep, '/')
            if match(rel):
                dst = os.path.join(tmp, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(os.path.join(ROOT, rel), dst); saved.append(rel)
    print('[2/5] Copies of %d files from the list that lie on disk: %s' % (len(saved), tmp))

    # --- 3. rewrite --------------------------------------------------------------------------------
    blobs = os.path.join(tmp, 'purge-blobs.txt')
    with open(blobs, 'w', encoding='ascii', newline='\n') as f: f.write(''.join(o + '\n' for o in sorted(docs)))
    print('[3/5] git filter-repo ...')
    code = run('git', 'filter-repo', '--invert-paths', '--paths-from-file', LIST, '--strip-blobs-with-ids', blobs, '--force')
    for rel in saved:
        dst = os.path.join(ROOT, rel)
        if not os.path.exists(dst):
            os.makedirs(os.path.dirname(dst), exist_ok=True); shutil.copy2(os.path.join(tmp, rel), dst)
    if code: sys.exit('ERROR: git filter-repo failed. Backup: %s' % bundle)
    tree2 = git('rev-parse', 'HEAD^{tree}').strip()
    if tree2 != tree:
        sys.exit('ERROR: the files of the current commit changed (%s -> %s). Nothing was pushed.\n'
                 'Compare: git diff %s %s --stat    Restore: git clone "%s"' % (tree, tree2, tree, tree2, bundle))
    print('      the current commit is the same (tree %s)' % tree)

    # --- 4. push -----------------------------------------------------------------------------------
    print('[4/5] origin -> %s' % remote)
    git('remote', 'remove', 'origin', check=False)
    git('remote', 'add', 'origin', remote)
    print('[5/5] force push of %s and the tags' % branch)
    if run('git', 'push', 'origin', branch, '--force', '-u'):
        sys.exit('ERROR: push failed. The local history is already rewritten. Backup: %s' % bundle)
    run('git', 'push', 'origin', '--force', '--tags')
    shutil.rmtree(tmp, ignore_errors=True)
    print('\nDone. Packed size now %s. Backup: %s' % (pack_size(), bundle))


if __name__ == '__main__':
    main()
