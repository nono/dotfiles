#!/usr/bin/env python3
"""Reduce the Claude Code transcripts of one repository to a JSON digest.

Finds every ~/.claude/projects directory that belongs to the given repository —
its live git worktrees, plus worktrees that were deleted but whose branch this
repository still knows — and counts what happened in them.

Usage: collect.py [--repo PATH] [--out DIR] [--days N]
Writes DIR/digest.json and DIR/messages.txt.
"""

import argparse
import collections
import datetime as dt
import glob
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser('~')
PROJECTS = os.path.join(HOME, '.claude', 'projects')
MESSAGE_CAP = 500  # human messages written to messages.txt
MESSAGE_MAX_CHARS = 700
TURN_BUCKETS = [(10, '<10s'), (30, '10-30s'), (60, '30s-1m'), (120, '1-2m'),
                (300, '2-5m'), (900, '5-15m'), (float('inf'), '>15m')]


def git(repo, *args):
    try:
        out = subprocess.run(['git', '-C', repo, *args], capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return ''
    return out.stdout if out.returncode == 0 else ''


def encode(path):
    """Claude Code encodes a cwd into a project directory name."""
    return re.sub(r'[^a-zA-Z0-9]', '-', path)


def first_meta(jsonl):
    """cwd and gitBranch of the first entry that carries them."""
    try:
        with open(jsonl, errors='replace') as fh:
            for line in fh:
                if '"cwd"' not in line:
                    continue
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                if e.get('cwd'):
                    return e['cwd'], e.get('gitBranch')
    except OSError:
        pass
    return None, None


def find_project_dirs(repo):
    """Project directories whose sessions ran inside this repository."""
    live = set()
    for line in git(repo, 'worktree', 'list', '--porcelain').splitlines():
        if line.startswith('worktree '):
            live.add(os.path.realpath(line[len('worktree '):]))
    known_refs = set()
    for line in git(repo, 'for-each-ref', '--format=%(refname:short)').splitlines():
        known_refs.add(line.strip())
        known_refs.add(line.strip().removeprefix('origin/'))

    found = {}
    for d in sorted(glob.glob(os.path.join(PROJECTS, '*'))):
        if not os.path.isdir(d):
            continue
        sessions = sorted(glob.glob(os.path.join(d, '*.jsonl')))
        if not sessions:
            continue
        cwd, branch = first_meta(sessions[0])
        if not cwd:
            continue
        real = os.path.realpath(cwd)
        if real in live:
            found[d] = (cwd, 'live worktree')
        elif branch and branch in known_refs and branch not in ('main', 'master'):
            # A worktree that was removed. Its branch still lives in this repo.
            found[d] = (cwd, 'removed worktree')
    return found


def bucket(seconds):
    for limit, label in TURN_BUCKETS:
        if seconds < limit:
            return label
    return TURN_BUCKETS[-1][1]


def strip_noise(text):
    text = re.sub(r'<system-reminder>.*?</system-reminder>', '', text, flags=re.S)
    return text.strip()


def is_typed_by_human(entry, content):
    """A user entry that the person typed, not a tool result or a harness event."""
    if entry.get('toolUseResult') is not None or entry.get('isMeta') or entry.get('isSidechain'):
        return False
    if not content or not content.strip():
        return False
    for marker in ('<task-notification>', '<command-name>', '<local-command',
                   'Caveat:', '[Request interrupted', 'was stopped by the user',
                   'were stopped by the user'):
        if content.startswith(marker) or marker in content[:60]:
            return False
    return True


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        if any(isinstance(p, dict) and p.get('type') == 'tool_result' for p in content):
            return ''
        return ' '.join(p.get('text', '') for p in content if isinstance(p, dict) and p.get('type') == 'text')
    return ''


def parse_ts(value):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError:
        return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', default=os.getcwd())
    ap.add_argument('--out', default='.')
    ap.add_argument('--days', type=int, default=0, help='keep only the last N days')
    args = ap.parse_args()

    repo = os.path.realpath(git(args.repo, 'rev-parse', '--show-toplevel').strip() or args.repo)
    dirs = find_project_dirs(repo)
    if not dirs:
        print(f'No transcripts found for {repo}', file=sys.stderr)
        return 1
    cutoff = None
    if args.days:
        cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=args.days)

    tools = collections.Counter()
    tool_errors = collections.Counter()
    bash_prefix = collections.Counter()
    bash_prefix_err = collections.Counter()
    bash_samples = collections.defaultdict(list)
    denials = []
    commands = collections.Counter()
    skills = collections.Counter()
    agents = collections.Counter()
    models = collections.Counter()
    turns = collections.Counter()
    per_day = collections.Counter()
    per_worktree = collections.Counter()
    interrupts = 0
    sidechain_tools = 0
    human_total = 0
    messages = []
    total_bytes = 0
    sessions = 0
    first_ts = last_ts = None

    for d, (cwd, kind) in dirs.items():
        label = os.path.basename(cwd)
        for jsonl in sorted(glob.glob(os.path.join(d, '*.jsonl'))):
            pending = {}
            open_human = None  # (timestamp, last assistant timestamp)
            counted = False
            try:
                fh = open(jsonl, errors='replace')
            except OSError:
                continue
            with fh:
                for line in fh:
                    try:
                        e = json.loads(line)
                    except ValueError:
                        continue
                    ts = parse_ts(e.get('timestamp'))
                    if cutoff and ts and ts < cutoff:
                        continue
                    if ts:
                        first_ts = min(first_ts or ts, ts)
                        last_ts = max(last_ts or ts, ts)
                        if not counted:
                            counted = True
                            sessions += 1
                            total_bytes += os.path.getsize(jsonl)
                            per_day[ts.date().isoformat()] += 1
                            per_worktree[label] += 1
                    etype = e.get('type')
                    msg = e.get('message') or {}
                    content = msg.get('content')

                    if etype == 'assistant':
                        if msg.get('model'):
                            models[msg['model']] += 1
                        if open_human and ts:
                            open_human[1] = ts
                        if isinstance(content, list):
                            for p in content:
                                if not isinstance(p, dict) or p.get('type') != 'tool_use':
                                    continue
                                name = p.get('name') or '?'
                                inp = p.get('input') or {}
                                tools[name] += 1
                                if e.get('isSidechain'):
                                    sidechain_tools += 1
                                pending[p.get('id')] = (name, inp)
                                if name == 'Skill':
                                    skills[str(inp.get('skill'))] += 1
                                elif name == 'Agent':
                                    agents[str(inp.get('subagent_type') or 'general-purpose')] += 1
                                elif name == 'Bash':
                                    bash_prefix[' '.join(str(inp.get('command', '')).split()[:2])] += 1
                        continue

                    if etype != 'user':
                        continue

                    raw = text_of(content)
                    if isinstance(content, list):
                        for p in content:
                            if not isinstance(p, dict) or p.get('type') != 'tool_result':
                                continue
                            name, inp = pending.pop(p.get('tool_use_id'), ('?', {}))
                            body = p.get('content')
                            if isinstance(body, list):
                                body = ' '.join(x.get('text', '') for x in body if isinstance(x, dict))
                            body = body if isinstance(body, str) else ''
                            if not p.get('is_error'):
                                continue
                            tool_errors[name] += 1
                            low = body.lower()
                            if 'requires approval' in low or 'permission' in low or 'blocked:' in low:
                                denials.append({'tool': name,
                                                'input': str(inp.get('command', inp))[:160],
                                                'reason': body[:160].replace('\n', ' ')})
                            if name == 'Bash':
                                key = ' '.join(str(inp.get('command', '')).split()[:2])
                                bash_prefix_err[key] += 1
                                if len(bash_samples[key]) < 2:
                                    bash_samples[key].append(body[:180].replace('\n', ' '))

                    if '[Request interrupted' in raw or 'stopped by the user' in raw:
                        interrupts += 1
                    m = re.search(r'<command-name>/?([\w-]+)</command-name>', raw)
                    if m:
                        commands[m.group(1)] += 1

                    cleaned = strip_noise(raw)
                    if is_typed_by_human(e, cleaned):
                        human_total += 1
                        if open_human and open_human[1] and open_human[0]:
                            turns[bucket((open_human[1] - open_human[0]).total_seconds())] += 1
                        open_human = [ts, None]
                        messages.append({'worktree': label,
                                         'ts': (e.get('timestamp') or '')[:16],
                                         'text': cleaned[:MESSAGE_MAX_CHARS]})
            if open_human and open_human[1] and open_human[0]:
                turns[bucket((open_human[1] - open_human[0]).total_seconds())] += 1

    failing = [{'prefix': k, 'errors': v, 'calls': bash_prefix.get(k, 0),
                'sample': (bash_samples.get(k) or [''])[0]}
               for k, v in bash_prefix_err.most_common(25)]

    digest = {
        'repo': repo,
        'generated': dt.datetime.now().isoformat(timespec='seconds'),
        'window': {'first': first_ts.isoformat() if first_ts else None,
                   'last': last_ts.isoformat() if last_ts else None,
                   'days_filter': args.days or None},
        'corpus': {'sessions': sessions, 'megabytes': round(total_bytes / 1e6, 1),
                   'worktrees': len(dirs), 'human_messages': human_total,
                   'interrupts': interrupts},
        'worktrees': [{'name': os.path.basename(cwd), 'path': cwd, 'kind': kind,
                       'sessions': per_worktree.get(os.path.basename(cwd), 0)}
                      for cwd, kind in dirs.values()],
        'tools': [{'name': k, 'calls': v, 'errors': tool_errors.get(k, 0)}
                  for k, v in tools.most_common()],
        'sidechain_tool_calls': sidechain_tools,
        'failing_bash': failing,
        'denials': denials[:40],
        'slash_commands': commands.most_common(),
        'skills': skills.most_common(),
        'subagents': agents.most_common(),
        'models': models.most_common(),
        'turn_durations': [{'bucket': label, 'turns': turns.get(label, 0)}
                           for _, label in TURN_BUCKETS],
        'sessions_per_day': sorted(per_day.items()),
    }

    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, 'digest.json'), 'w') as fh:
        json.dump(digest, fh, indent=2)

    short = [m for m in messages if len(m['text']) < 500]
    keep = short[-MESSAGE_CAP:] if len(short) > MESSAGE_CAP else short
    with open(os.path.join(args.out, 'messages.txt'), 'w') as fh:
        fh.write(f'# {len(keep)} of {human_total} human messages, shortest kept\n')
        for m in keep:
            fh.write(f"\n--- {m['worktree']} {m['ts']}\n{m['text']}\n")

    print(json.dumps(digest['corpus'], indent=2))
    print(f"wrote {args.out}/digest.json and {args.out}/messages.txt")
    return 0


if __name__ == '__main__':
    sys.exit(main())
