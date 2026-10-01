#!/usr/bin/env python3
"""Grid of live previews of the current session's Claude Code and Codex panes.

Bound to Alt+a (opened in a display-popup). Each tile shows the bottom of the
pane's screen, its directory, and a status badge (needs you / working / idle).

Keys: arrows or hjkl move, 1-9 pick a tile, Enter jumps to the pane, q/Esc quit.

`agent_grid.py --list` prints the agent panes and their status and exits.
"""
import math
import os
import re
import select
import subprocess
import sys
import termios
import time
import tty
import unicodedata

REFRESH = 0.5  # seconds between captures
GAP_X, GAP_Y = 3, 1  # blank columns / rows between tiles
HOME = os.path.expanduser("~")
SEP = "@@agent-grid-sep-7f3a@@"

# --- status detection ---------------------------------------------------------

# Only the bottom of the screen matters: that's where Claude/Codex draw the
# spinner, the input box, and permission / question dialogs.
NEEDS_YOU = [
    re.compile(r"^\s*[❯›>]\s*1\.\s"),          # permission / approval menu: "❯ 1. Yes"
    re.compile(r"Esc to cancel", re.I),          # Claude question / dialog footer
    re.compile(r"Press enter to confirm", re.I), # Codex approval footer
]
WORKING = [
    re.compile(r"esc to interrupt", re.I),
    re.compile(r"^\S\s+\w[\w\s'-]*…\s*\("),      # Claude spinner: "· Roosting… (1m 4s"
    re.compile(r"^\S\s+Working\s*\("),           # Codex: "• Working (3s"
]

STATUS_BADGE = {
    "needs": ("\x1b[1;97;41m", " ! needs you "),
    "working": ("\x1b[30;43m", " ● working "),
    "idle": ("\x1b[30;42m", " ✓ idle "),
}


def detect_status(plain_lines):
    tail = [l for l in plain_lines if l.strip()][-14:]
    if any(p.search(l) for p in NEEDS_YOU for l in tail):
        return "needs"
    if any(p.search(l) for p in WORKING for l in tail):
        return "working"
    return "idle"


# --- finding agent panes ------------------------------------------------------

def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True).stdout


def agent_kind(cmd, pane_pid):
    """'claude' / 'codex' / None, from the pane's foreground process."""
    if cmd in ("claude", "codex"):
        return cmd
    try:
        with open(f"/proc/{pane_pid}/stat") as f:
            tpgid = f.read().rsplit(")", 1)[1].split()[5]
        with open(f"/proc/{tpgid}/cmdline", "rb") as f:
            argv = f.read().decode(errors="replace").split("\0")[:3]
    except (OSError, IndexError):
        return None
    for a in argv:
        base = os.path.basename(a)
        if base in ("claude", "codex", "codex.js"):
            return "codex" if base.startswith("codex") else "claude"
        if "@openai/codex" in a:
            return "codex"
        if "claude-code" in a or "/claude/versions/" in a:
            return "claude"
    return None


def list_agents(current_session):
    fmt = "\t".join(["#{pane_id}", "#{session_name}", "#{window_index}",
                     "#{pane_pid}", "#{pane_current_command}", "#{pane_current_path}"])
    agents = []
    for line in tmux("list-panes", "-s", "-t", current_session, "-F", fmt).splitlines():
        pid, sess, win, ppid, cmd, path = line.split("\t")
        kind = agent_kind(cmd, ppid)
        if kind:
            agents.append(dict(id=pid, session=sess, window=win, kind=kind, path=path))
    return agents


def capture(agents):
    """Fill agent['lines'] (with colors) and agent['status']; one tmux call."""
    args = []
    for a in agents:
        args += ["capture-pane", "-p", "-e", "-t", a["id"], ";",
                 "display-message", "-p", SEP, ";"]
    r = subprocess.run(["tmux", *args[:-1]], capture_output=True, text=True,
                       errors="replace")
    chunks = r.stdout.split(SEP + "\n")
    if r.returncode != 0 or len(chunks) < len(agents):
        # A pane vanished mid-chain; fall back to one call per pane.
        chunks = [tmux("capture-pane", "-p", "-e", "-t", a["id"]) for a in agents]
    for a, text in zip(agents, chunks):
        lines = text.split("\n")
        while lines and not strip_ansi(lines[-1]).strip():
            lines.pop()
        a["lines"] = lines
        a["status"] = detect_status([strip_ansi(l) for l in lines])


# --- ANSI-aware cropping ------------------------------------------------------

ESC_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b.")


def strip_ansi(s):
    return ESC_RE.sub("", s)


def char_width(ch):
    if unicodedata.combining(ch) or ch in "​‍︎️":
        return 0
    return 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1


def text_width(s):
    return sum(char_width(c) for c in s)


def crop(line, width):
    """Cut a line with SGR colors to `width` cells, padded, colors reset."""
    out, used, pos = [], 0, 0
    for m in ESC_RE.finditer(line):
        used = _put(line[pos:m.start()], width, out, used)
        if m.group().endswith("m") and m.group().startswith("\x1b["):
            out.append(m.group())  # keep colors, drop cursor moves / OSC links
        pos = m.end()
    used = _put(line[pos:], width, out, used)
    return "".join(out) + "\x1b[0m" + " " * (width - used)


def _put(text, width, out, used):
    for ch in text:
        w = char_width(ch)
        if used + w > width:
            break
        out.append(ch)
        used += w
    return used


def fit(s, width):
    """Plain text cut to `width` cells, keeping the end (the useful part of a path)."""
    if text_width(s) <= width:
        return s
    while s and text_width(s) > width - 1:
        s = s[1:]
    return "…" + s


# --- drawing ------------------------------------------------------------------

def choose_grid(n, width, height):
    best = None
    for cols in range(1, n + 1):
        rows = math.ceil(n / cols)
        tw, th = width // cols, height // rows
        score = min(tw / 2.2, th)  # terminal cells are ~2.2x taller than wide
        if best is None or score > best[0]:
            best = (score, cols, rows)
    return best[1], best[2]


def draw_tile(a, idx, x, y, w, h, selected):
    if selected:
        border, (tl, tr, bl, br, hz, vt) = "\x1b[1;36m", "┏┓┗┛━┃"
    else:
        border, (tl, tr, bl, br, hz, vt) = "\x1b[38;5;240m", "╭╮╰╯─│"
    iw, ih = max(w - 2, 1), max(h - 2, 0)
    color, badge = STATUS_BADGE[a["status"]]

    path = a["path"].replace(HOME, "~", 1) if a["path"].startswith(HOME) else a["path"]
    num = f" {idx + 1} " if idx < 9 else " "
    room = iw - text_width(num) - text_width(badge) - 3
    title = fit(path, max(room, 1))
    pad = iw - text_width(num) - text_width(title) - 2 - text_width(badge) - 1
    if pad < 0:  # too narrow for the badge: drop it
        badge, color = "", ""
        title = fit(path, max(iw - text_width(num) - 2, 1))
        pad = iw - text_width(num) - text_width(title) - 2
    name_style = "\x1b[1;97m" if selected else "\x1b[97m"
    top = (f"{border}{tl}{num}\x1b[0m{name_style} {title} \x1b[0m{border}"
           f"{hz * max(pad, 0)}\x1b[0m{color}{badge}\x1b[0m{border}{hz if badge else ''}{tr}")

    where = f" {a['kind']} · window {a['window']} "
    where = where if text_width(where) <= iw - 1 else ""
    bottom = (f"{border}{bl}{hz}\x1b[0m\x1b[38;5;245m{where}\x1b[0m{border}"
              f"{hz * (iw - 1 - text_width(where))}{br}\x1b[0m")

    body = a["lines"][-ih:] if ih else []
    body = [""] * (ih - len(body)) + body
    out = [f"\x1b[{y + 1};{x + 1}H{top}"]
    for i, line in enumerate(body):
        out.append(f"\x1b[{y + 2 + i};{x + 1}H{border}{vt}\x1b[0m{crop(line, iw)}{border}{vt}\x1b[0m")
    out.append(f"\x1b[{y + h};{x + 1}H{bottom}")
    return "".join(out)


def render(agents, sel, size):
    W, H = size
    n = len(agents)
    cols, rows = choose_grid(n, W, H - 1)
    out = []
    for i, a in enumerate(agents):
        r, c = divmod(i, cols)
        # Split the area plus one trailing gap into equal cells, then drop each
        # cell's trailing gap, so tiles stay flush with the edges.
        x0, x1 = c * (W + GAP_X) // cols, (c + 1) * (W + GAP_X) // cols - GAP_X
        y0, y1 = r * (H - 1 + GAP_Y) // rows, (r + 1) * (H - 1 + GAP_Y) // rows - GAP_Y
        out.append(draw_tile(a, i, x0, y0, x1 - x0, y1 - y0, i == sel))

    counts = {s: sum(a["status"] == s for a in agents) for s in STATUS_BADGE}
    summary = " · ".join(f"{counts[s]} {label}" for s, label in
                         (("needs", "need you"), ("working", "working"), ("idle", "idle"))
                         if counts[s])
    keys = "←↓↑→/hjkl move · 1-9 pick · Enter go · q quit"
    gap = W - text_width(keys) - text_width(summary) - 2
    footer = f" {keys}{' ' * max(gap, 1)}{summary} " if gap > 0 else f" {keys}"
    out.append(f"\x1b[{H};1H\x1b[38;5;245m{crop(footer, W)}")
    return "".join(out), cols


# --- input / main loop --------------------------------------------------------

KEYS = {
    "\x1b[A": "up", "\x1bOA": "up", "k": "up",
    "\x1b[B": "down", "\x1bOB": "down", "j": "down",
    "\x1b[C": "right", "\x1bOC": "right", "l": "right",
    "\x1b[D": "left", "\x1bOD": "left", "h": "left",
    "\r": "go", "\n": "go", " ": "go",
    "q": "quit", "\x1b": "quit", "\x03": "quit",
}


def read_keys(fd):
    data = os.read(fd, 64).decode(errors="ignore")
    keys = []
    while data:
        for seq in sorted(KEYS, key=len, reverse=True):
            if data.startswith(seq):
                keys.append(KEYS[seq])
                data = data[len(seq):]
                break
        else:
            if data[0].isdigit() and data[0] != "0":
                keys.append(int(data[0]) - 1)
            data = data[1:]
    return keys


def move(sel, key, n, cols):
    if key == "left":
        return (sel - 1) % n
    if key == "right":
        return (sel + 1) % n
    if key == "up":
        return sel - cols if sel - cols >= 0 else sel
    if key == "down":
        return min(sel + cols, n - 1) if sel // cols < (n - 1) // cols else sel
    return sel


def jump(client, a):
    target = f"{a['session']}:{a['window']}"
    cmd = ["tmux", "switch-client"] + (["-c", client] if client else []) + ["-t", target,
           ";", "select-window", "-t", target, ";", "select-pane", "-t", a["id"]]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        tmux("display-message", f"agent_grid: {r.stderr.strip()}")


def main():
    client = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] != "--list" else ""
    current_session = tmux("display-message", "-p", *(["-c", client] if client else []),
                           "#{session_name}").strip()

    if "--list" in sys.argv:
        agents = list_agents(current_session)
        capture(agents)
        for a in agents:
            print(f"{a['id']}\t{a['status']}\t{a['kind']}\t{a['session']}:{a['window']}\t{a['path']}")
        return

    agents = list_agents(current_session)
    if not agents:
        tmux("display-message", "No Claude/Codex panes running")
        return

    fd = sys.stdin.fileno()
    saved = termios.tcgetattr(fd)
    tty.setcbreak(fd)
    sys.stdout.write("\x1b[?1049h\x1b[?25l")
    sel, chosen, last_size, last_n, last_capture = 0, None, None, None, 0
    try:
        while True:
            now = time.monotonic()
            if now - last_capture >= REFRESH:
                sel_id = agents[sel]["id"] if agents else None
                agents = list_agents(current_session)
                if not agents:
                    break
                capture(agents)
                ids = [a["id"] for a in agents]
                sel = ids.index(sel_id) if sel_id in ids else min(sel, len(agents) - 1)
                last_capture = now

            size = os.get_terminal_size()
            if size != last_size or len(agents) != last_n:
                sys.stdout.write("\x1b[2J")  # layout changed: clear leftovers
                last_size, last_n = size, len(agents)
            frame, cols = render(agents, sel, size)
            sys.stdout.write("\x1b[H" + frame)
            sys.stdout.flush()

            ready, _, _ = select.select([fd], [], [], max(REFRESH - (time.monotonic() - last_capture), 0.05))
            if not ready:
                continue
            for key in read_keys(fd):
                if key == "quit":
                    return
                if key == "go":
                    chosen = agents[sel]
                    return
                if isinstance(key, int):
                    if key < len(agents):
                        sel = key
                else:
                    sel = move(sel, key, len(agents), cols)
    finally:
        sys.stdout.write("\x1b[0m\x1b[?25h\x1b[?1049l")
        sys.stdout.flush()
        termios.tcsetattr(fd, termios.TCSADRAIN, saved)
        if chosen:
            jump(client, chosen)


if __name__ == "__main__":
    main()
