#!/usr/bin/env python3
"""ClassicalElectrodynamics: one entry point for everything done with the project.

  python ced.py                 interactive shell (Tab completes commands and flags, Up/Down: history)
  python ced.py <command> ...   one command, e.g.  python ced.py html -SkipPrepare

The work is done by the scripts of the project (run.ps1, build-html.ps1, ...); this only calls them.
Type 'help' in the shell for the list of commands."""
import os, shlex, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
PS = shutil.which('pwsh') or shutil.which('powershell') or 'powershell'
PY = sys.executable
PDF = 'ClassicalElectrodynamics.pdf'

HTML_FLAGS = ['-Placeholder', '-SkipPrepare', '-NoImages', '-Full', '-Keep', '-NoClean', '-NoPublish', '-OutDir']


def ps(script, *args):
    """Runs a PowerShell script of the project; returns its exit code."""
    return subprocess.run([PS, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', os.path.join(ROOT, script), *args],
                          cwd=ROOT, env={**os.environ, 'CED_CLI': '1'}).returncode


def py(script, *args):
    return subprocess.run([PY, os.path.join(ROOT, script), *args], cwd=ROOT).returncode


def git(*args):
    return subprocess.run(['git', *args], cwd=ROOT).returncode


# --- commands: (function, flags for completion, help) ----------------------------------------------
def cmd_pdf(args):
    """PDF of the book: run.ps1 (latexmk, quiet; stops at the first error), then publish_pdf.ps1 (linearize ->
    docs/ClassicalElectrodynamics.pdf). pdf --no-publish: only the build, the PDF stays in the root; pdf --full: whole
    output; pdf --publish-only: no build, only linearize the PDF that is already in the root and put it into docs/."""
    if '--publish-only' in args:
        if not os.path.isfile(os.path.join(ROOT, PDF)): print('No %s: build it first (pdf).' % PDF); return 1
        return ps('publish_pdf.ps1')
    code = ps('run.ps1', *(['-Full'] if '--full' in args else []))
    if code: print('PDF build failed (code %d): docs/ is not touched.' % code); return code
    if '--no-publish' in args: return 0
    return ps('publish_pdf.ps1')


def cmd_html(args):
    """HTML version (lwarp) -> docs/: build-html.ps1 with its flags, e.g.  html -SkipPrepare -NoImages"""
    return ps('build-html.ps1', *args)


def cmd_serve(args):
    """Local web server for docs/ (search works only over http): serve [port]. Ctrl+C stops it."""
    try: return py(os.path.join('docs', 'serve.py'), *args)
    except KeyboardInterrupt: return 0


def cmd_clean(args):
    """Temporary files. clean aux: LaTeX auxiliary files (rm.ps1); clean bak: also editor backups *.bak*;
    clean html: what the HTML build leaves (clwarp-clean.ps1); clean all: aux + bak + html."""
    what = args[0] if args else 'aux'
    if what not in ('aux', 'bak', 'html', 'all'): print('clean aux | bak | html | all'); return 1
    code = 0
    if what in ('aux', 'bak', 'all'): code |= ps('rm.ps1', *(['-Bak'] if what != 'aux' else []))
    if what in ('html', 'all'): code |= ps('clwarp-clean.ps1')
    return code


def cmd_purge(args):
    """Clean the git history of old docs/ versions and the paths of purge-paths.txt (clean_repo.py).
    purge --dry-run: only show what would go and how much it takes. Without it: asks YES, then force-pushes."""
    return py('clean_repo.py', *args)


def cmd_size(args):
    """Size of the repository and its largest files over the whole history: size [n] (default 10)."""
    n = int(args[0]) if args and args[0].isdigit() else 10
    out = lambda *a, **k: subprocess.run(['git', '-c', 'core.quotepath=off', *a], cwd=ROOT, capture_output=True,
                                         text=True, encoding='utf-8', errors='replace', **k).stdout
    print(next((l for l in out('count-objects', '-vH').splitlines() if l.startswith('size-pack')), ''))
    objs = out('cat-file', '--batch-check=%(objecttype) %(objectsize:disk) %(rest)', input=out('rev-list', '--objects', '--all'))
    blobs = [l.split(' ', 2) for l in objs.splitlines() if l.startswith('blob ')]
    blobs.sort(key=lambda b: -int(b[1]))
    print('Largest files (every version counts; old docs/ versions go with purge):')
    for _, size, path in blobs[:n]: print('  %6.1f MB  %s' % (int(size) / 1048576, path))
    return 0


def cmd_status(args):
    """git status (short)."""
    return git('status', '--short', '--branch')


def cmd_push(args):
    """Commit everything and push: push "message" (default message: Update)."""
    msg = ' '.join(args) or 'Update'
    if git('add', '-A'): return 1
    if subprocess.run(['git', 'diff', '--cached', '--quiet'], cwd=ROOT).returncode == 0:
        print('Nothing to commit.')
    elif git('commit', '-m', msg): return 1
    return git('push')


COMMANDS = {
    'pdf': (cmd_pdf, ['--no-publish', '--full', '--publish-only']),
    'html': (cmd_html, HTML_FLAGS),
    'serve': (cmd_serve, ['8000', '--no-browser']),
    'clean': (cmd_clean, ['aux', 'bak', 'html', 'all']),
    'purge': (cmd_purge, ['--dry-run']),
    'size': (cmd_size, []),
    'status': (cmd_status, []),
    'push': (cmd_push, []),
}


def cmd_help(args=()):
    print('Commands:')
    for name, (fn, _) in COMMANDS.items():
        lines = [l.strip() for l in fn.__doc__.strip().splitlines()]
        print('  %-7s %s' % (name, lines[0]))
        for l in lines[1:]: print('  %-7s %s' % ('', l))
    print('  %-7s %s' % ('help', 'this list'))
    print('  %-7s %s' % ('exit', 'leave the shell (also Ctrl+D)'))
    return 0


def execute(argv):
    name, args = argv[0].lower(), argv[1:]
    if name in ('help', '?', '-h', '--help'): return cmd_help()
    if name not in COMMANDS:
        print("Unknown command '%s'. Type help." % name); return 1
    try:
        return COMMANDS[name][0](args)
    except KeyboardInterrupt:
        print('\nInterrupted.'); return 130


def shell():
    try:
        from prompt_toolkit import PromptSession
        from prompt_toolkit.completion import NestedCompleter
        from prompt_toolkit.history import FileHistory
        tree = {name: {f: None for f in flags} or None for name, (_, flags) in COMMANDS.items()}
        tree.update(help=None, exit=None)
        session = PromptSession(history=FileHistory(os.path.join(ROOT, '.ced_history')))
        ask = lambda: session.prompt('ced> ', completer=NestedCompleter.from_nested_dict(tree))
    except ImportError:                                       # no prompt_toolkit: plain input, no completion
        ask = lambda: input('ced> ')
    print('ClassicalElectrodynamics shell. help: commands, exit: leave.')
    while True:
        try:
            text = ask().strip()
        except KeyboardInterrupt:
            continue
        except EOFError:
            break
        if not text: continue
        if text in ('exit', 'quit', 'q'): break
        try:
            argv = shlex.split(text, posix=True)
        except ValueError as e:
            print('Cannot parse: %s' % e); continue
        code = execute(argv)
        if code: print('(exit code %d)' % code)


if __name__ == '__main__':
    os.chdir(ROOT)
    if len(sys.argv) > 1: sys.exit(execute(sys.argv[1:]))
    shell()
