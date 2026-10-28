# My configs

Configs for CLI apps (Neovim, Tmux, Fish, Kitty, Claude Code) plus a few helper scripts.

## Instructions

This file is an overview: what lives where and what it is for, a line or two per item.
Details — how something works, why it is done that way, gotchas, install steps — go in
comments next to the code they describe, so they are found where they are needed and
change with it. Don't list keybindings, plugins or setting values here; the config files
are the source of truth. When adding or removing a component, update this file.

## Activation

```bash
./setup.sh
```

Symlinks every config (and `bin/` tools) into its standard location, **overwriting**
whatever is there so the repo is the only copy. Safe to re-run:

- already linked to the repo → left alone (`ok`)
- a symlink pointing elsewhere → replaced (`relink`)
- a real file or directory → moved to `<path>.bak.<timestamp>`, then linked (`backup`).
  Check the backup for local edits worth porting into the repo, then delete it.

New files in `bin/`, `fish/functions/`, `fish/conf.d/` and `desktop/` are picked up
automatically. Not done by `setup.sh`: the `Super+X` global shortcut (see
`bin/kitty-toggle`), TPM itself, and the Go toolchain (see `fish/config.fish`).

## What's here

### `nvim/` — Neovim

lazy.nvim installs the plugins on first launch, then Mason installs the language servers
(Python, .NET via Roslyn). Leader is `Space`; `<leader>fk` searches all keymaps.

- `lua/config/` — options, keymaps, and `run.lua` (`:X` runs the current file into a
  scratch split).
- `lua/plugins/init.lua` — every plugin: Telescope, LSP + completion, treesitter, neo-tree,
  gitsigns, flash, render-markdown, solarized. Icons are plain ASCII/Unicode; no Nerd
  Font assumed.

### `tmux/` — Tmux

Prefix `Ctrl+a`, vi mode, mouse with copy to the Wayland clipboard. `.tmux.conf` has
the bindings. Notable extras:

- `F12` — pass all keys through to a nested (SSH) tmux running this same config.
- `scripts/agent_grid.py` (`Alt+a`) — popup grid of the session's Claude Code / Codex
  panes with live previews and needs-you / working / idle badges.
- `scripts/fuzzy_insert_path.sh` (`Alt+c`, `Prefix c`) — fuzzy pick a dir (and file)
  from the fish dir history and insert or `cd` into it.
- `scripts/join_pane_from_session.sh` (`Prefix j`) — pull a pane in from another session.
- `scripts/ram_status.sh` — RAM usage in the status bar.
- `scripts/theme.sh` — light/dark theme: follows the terminal (kitty follows the
  desktop), or forced by the toggle at the end of the status bar (e.g. for Termius).
  `nvim_background.sh` switches running Neovims, which don't follow on their own.

### `fish/` — Fish shell

- `config.fish` — PATH (Go, Node via nvm, Android SDK, …), abbreviations, env vars.
- `functions/fish_prompt.fish` — prompt with git/hg branch and dirty marker; shows the
  user when it isn't the usual one and a padlock inside an `lfg unseal` session.
- `functions/__log_dir.fish` + `fcd.fish` — log every visited dir; `Ctrl+g` fuzzy-jumps
  back to one.
- `functions/dotenv.fish`, `nvm.fish` — load a `.env`; run nvm through bash.

Linked file by file, since `~/.config/fish` also holds machine-local state.

### `kitty/` — Kitty terminal

A single-pane terminal (tmux does splits and tabs) styled after elementary OS, on the
Gala compositor. The whole directory is linked as Kitty's config dir.

- `kitty.conf` — look, keys, and the kitty shortcuts unbound so tmux gets them.
- `elementary-dark.conf`, `elementary-light.conf` — color themes from elementary
  Terminal; the `*-theme.auto.conf` files make kitty follow the desktop light/dark
  setting.
- `shaders/rounded-corners.*` — rounded corners, Dock-style edge and drop shadow (the
  title bar is hidden).
- `gala-blur.c` — `LD_PRELOAD` library that gets Gala to blur behind the window (frosted
  glass); built by `setup.sh`.
- `minimize.py` — kitten used by `kitty-toggle`.

### `bin/` — helper tools (linked into `~/bin`)

- `kitty-toggle` — show/hide/start the single "main" kitty window; bound to `Super+X`.
- `notify <message>` — send a short Telegram message (credentials from `.env`).
- `runagent` — run Claude Code or Codex non-interactively (cron), with `notify` on
  failure. `runagent` with no args prints usage.
- `delta-themed` — git's pager: delta with light or dark colours to match the tmux theme.

### `desktop/`

`kitty-main.desktop` — launcher entry for the main kitty window, so docks group it.

### `claude-code/`

`commands/` — user-level slash commands, linked to `~/.claude/commands`.

### `usbc-monitor-hotplug/`

Workaround for external USB-C monitors not detected on hotplug. Installed separately;
see its own README.
