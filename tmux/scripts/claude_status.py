#!/usr/bin/env python3
"""Flag tmux windows that hold a working Claude Code session.

Sets the window option @cc_busy to 1 on every window with a pane running a
Claude Code session that is working, and unsets it everywhere else; the tab
formats in .tmux.conf draw the Claude mark from it. Prints nothing: it runs as
a #() job in status-right, which re-runs it every status-interval.

  claude_status.py <socket_path>   (pass #{socket_path})

Source of truth is ~/.claude/sessions/<pid>.json, which every interactive
session keeps up to date (same approach as ~/projects/cc-busy-indicator):
  status  busy     model/tool loop is running        -> working
          shell    user dropped into a shell (!cmd)
          waiting  blocked on a permission/question
          idle     sitting at the prompt
  tmux    "<session>:@<window>.%<pane>" at launch; only the pane id is used,
          since the pane may have been moved to another window since.
A file is stale unless its pid is alive with the recorded procStart (rules out
PID reuse). Pane ids are per server, so the process's $TMUX must name this
server's socket, or a session in another tmux server could light up a tab here.
"""
import json
import os
import subprocess
import sys

WORKING = {"busy"}


def proc_start(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            # comm (field 2) may contain spaces and ')': split after the last ')'
            return f.read().rsplit(")", 1)[1].split()[19]
    except (OSError, IndexError):
        return None


def tmux_socket(pid):
    try:
        with open(f"/proc/{pid}/environ", "rb") as f:
            env = f.read().split(b"\0")
    except OSError:
        return None
    for var in env:
        if var.startswith(b"TMUX="):
            return var[5:].decode(errors="replace").split(",")[0]
    return None


def working_panes(socket):
    config = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude")
    sessions = os.path.join(config, "sessions")
    try:
        names = os.listdir(sessions)
    except OSError:
        return set()
    panes = set()
    for name in names:
        if not name.endswith(".json"):
            continue
        try:
            with open(os.path.join(sessions, name)) as f:
                s = json.load(f)
            pid, pane = int(s["pid"]), s["tmux"].rsplit(".", 1)[1]
        except (OSError, ValueError, KeyError, IndexError, TypeError, AttributeError):
            continue
        status = s.get("status")
        if status is None and s.get("entrypoint") == "sdk-cli":
            status = "busy"  # `claude -p` writes no status and only lives for one turn
        if status not in WORKING:
            continue
        start = proc_start(pid)
        if start is None or ("procStart" in s and str(s["procStart"]) != start):
            continue
        if tmux_socket(pid) != socket:
            continue
        panes.add(pane)
    return panes


def main():
    socket = sys.argv[1] if len(sys.argv) > 1 else None
    if not socket:
        sys.exit("usage: claude_status.py <tmux socket path>")
    tmux = ["tmux", "-S", socket]
    busy = working_panes(socket)

    out = subprocess.run(
        tmux + ["list-panes", "-a", "-F", "#{pane_id} #{window_id} #{@cc_busy}"],
        capture_output=True, text=True,
    ).stdout
    want, have = set(), set()
    for line in out.splitlines():
        pane, window, flag = (line.split(" ") + [""])[:3]
        if pane in busy:
            want.add(window)
        if flag:
            have.add(window)

    # Only touch what changed: every set-option redraws all clients.
    cmds = []
    for w in want - have:
        cmds += ["set", "-w", "-t", w, "@cc_busy", "1", ";"]
    for w in have - want:
        cmds += ["set", "-wu", "-t", w, "@cc_busy", ";"]
    if cmds:
        subprocess.run(tmux + cmds[:-1], capture_output=True)


if __name__ == "__main__":
    main()
