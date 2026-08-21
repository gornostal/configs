# My configs

This project contains configs for apps that run via CLI.

## Instructions

When doing any significant modifications, change this file also.

## Activation

Run `setup.sh` to activate all configs. It symlinks the Neovim, Tmux, Fish, and Claude Code configs into their standard locations, skipping any that already exist.

```bash
./setup.sh
```


## Neovim Configuration

```
nvim/
├── init.lua              # Entry point
├── lua/
│   ├── config/
│   │   ├── options.lua   # Basic settings (line numbers, tabs, etc.)
│   │   └── keymaps.lua   # Key bindings
│   └── plugins/
│       └── init.lua      # All plugins (LSP, completion, theme)
└── .gitignore
```

On first launch of Neovim, lazy.nvim will auto-install all plugins. Then Mason will install the language servers (pyright for Python, omnisharp for .NET).

## Plugins included

| Plugin | Description |
|--------|-------------|
| **lazy.nvim** | Plugin manager |
| **catppuccin** | Color scheme (mocha flavor) |
| **copilot.vim** | GitHub Copilot AI code completion |
| **neoscroll.nvim** | Smooth scrolling animations |
| **telescope.nvim** | Fuzzy finder for files, grep, buffers |
| **flash.nvim** | Quick jumps with labels |
| **gitsigns.nvim** | Git change indicators in the gutter |
| **mason.nvim** | Language server installer |
| **mason-lspconfig.nvim** | Auto-configures LSP servers from Mason |
| **nvim-lspconfig** | LSP configuration |
| **nvim-cmp** | Autocompletion engine |
| **LuaSnip** | Snippet engine |
| **nvim-treesitter** | Syntax highlighting and code parsing |
| **roslyn.nvim** | Roslyn LSP for .NET with Razor/CSHTML support |
| **neo-tree.nvim** | File tree sidebar (ASCII icons, no Nerd Font needed) |
| **codediff.nvim** | VSCode-style diff viewer; unified single-pane layout with treesitter highlighting |

## Key bindings

`Space` is the leader key.

### General

| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlight |
| `<leader>w` | Toggle line wrap |
| `<leader>tg` | Toggle line numbers (git signs stay visible) |
| `<leader>bd` | Delete current buffer |
| `<leader>e` | Toggle file tree sidebar |
| `<leader>o` | Reveal current file in the tree |

### Window Navigation

| Key | Action |
|-----|--------|
| `Ctrl+h` | Move to left window |
| `Ctrl+j` | Move to lower window |
| `Ctrl+k` | Move to upper window |
| `Ctrl+l` | Move to right window |

### LSP (Language Server)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Show hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code actions |
| `<leader>f` | Format file |

### Telescope (Fuzzy Finder)

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search in files) |
| `<leader>fb` | Find open buffers |
| `<leader>fh` | Search help tags |
| `<leader>fk` | Find keymaps |
| `<leader>fp` | Print full file path |
| `<leader>fr` | Recent files |

### Git (Gitsigns)

| Key | Action |
|-----|--------|
| `]h` | Next hunk |
| `[h` | Previous hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hd` | Diff this |

### Flash

| Key | Action |
|-----|--------|
| `s` | Flash jump |
| `S` | Flash Treesitter |
| `r` | Remote Flash (operator-pending) |
| `R` | Treesitter search |
| `Ctrl+s` | Toggle Flash search (command-line) |

### Git Diff

| Key | Action |
|-----|--------|
| `<leader>gs` | Git status (fuzzy find changed files) |
| `<leader>diff` | Show unstaged changes + new files |
| `<leader>dic` | Show staged changes (git diff --cached) |

#### CodeDiff

Unified (single-pane) diff viewer: additions and deletions in one window with full
treesitter highlighting on both, plus character-level highlights inside changed lines.
Press `t` inside a diff to switch to side-by-side. The diff engine is a prebuilt C
library that the plugin downloads from GitHub releases on first use — no compiler needed,
but the first `:CodeDiff` requires network access.

The file-list sidebar (explorer) is **hidden by default** — a diff opens on a changed file
straight away, and `<leader>tb` reveals the list when you want to jump between files.

| Key | Action |
|-----|--------|
| `<leader>gd` | Open CodeDiff on the working-tree changes |
| `<leader>tb` | Show/hide the file list (inside a diff view) |
| `<leader>te` | Focus the file list (inside a diff view) |

Inside a diff view: `t` toggle inline/side-by-side, `]c`/`[c` next/prev hunk, `]f`/`[f`
next/prev file, `gc` compact mode (fold unchanged), `-` stage/unstage file,
`<leader>hs`/`<leader>hu`/`<leader>hr` stage/unstage/discard hunk, `g?` help, `q` close.
`]c` crosses file boundaries (`cycle_hunks_across_files`), so it walks every hunk in the
change set without going back to the file list — the closest thing to scrolling a plain
`git diff`. `gS` jumps between the staged and unstaged version of the current file.

The plugin spec carries a small monkeypatch: upstream's `navigate_next`/`navigate_prev`
call `nvim_win_is_valid(explorer.winid)` unguarded, and `winid` is `nil` while the explorer
is hidden — so with `hidden = true`, `]f` and cross-file `]c` error out. Remove the patch
once upstream adds the nil guard.

Other invocations worth knowing: `:CodeDiff main...` (PR-style diff against a base branch),
`:CodeDiff main` (vs a branch), `:CodeDiff --staged`, `:CodeDiff file HEAD` (current file only),
`:CodeDiff history` (commit browser), `:CodeDiff -- src/api` (scope to a path).

### Autocompletion

| Key | Action |
|-----|--------|
| `Tab` | Next completion item / expand snippet |
| `Shift+Tab` | Previous completion item |
| `Enter` | Accept completion |
| `Ctrl+Space` | Trigger completion manually |
| `Ctrl+e` | Abort completion |
| `Ctrl+b` | Scroll docs up |
| `Ctrl+f` | Scroll docs down |

### Smooth Scrolling

| Key | Action |
|-----|--------|
| `Ctrl+u` | Scroll up (half page) |
| `Ctrl+d` | Scroll down (half page) |
| `Ctrl+b` | Scroll up (full page) |
| `Ctrl+f` | Scroll down (full page) |
| `zt` | Scroll cursor to top |
| `zz` | Scroll cursor to center |
| `zb` | Scroll cursor to bottom |

### Visual Mode

| Key | Action |
|-----|--------|
| `<` | Indent left (stay in visual) |
| `>` | Indent right (stay in visual) |
| `J` | Move selected lines down |
| `K` | Move selected lines up |


## Tmux Configuration

```
tmux/
├── .tmux.conf
└── scripts/
    ├── fuzzy_insert_path.sh        # Two-step fuzzy insert: dir picker, optional file picker (Tab)
    └── join_pane_from_session.sh   # Fuzzy-pick a pane from another session and join-pane it here
```

### Features

- Prefix key: `Ctrl+a` (instead of default `Ctrl+b`)
- Vi mode enabled
- Mouse support
- 10000 line scrollback history
- Windows/panes start at index 1

#### Nested / remote tmux

When you SSH into another host that runs this **same** config, both the local and
remote tmux share the `Ctrl+a`/`Ctrl+s` prefix and every `Alt`/`Shift` no-prefix
binding, so the local tmux would intercept them all. Press `F12` to flip the local
tmux into a passthrough ("off") state where every keystroke is forwarded to the
remote tmux — the status bar changes color while in this mode. Press `F12` again to
take control back. It nests to arbitrary depth (press `F12` once per level to step
inward). Install the config on the remote first: clone this repo there and run
`./setup.sh`.

### Plugins (via TPM)

| Plugin | Description |
|--------|-------------|
| **tpm** | Tmux Plugin Manager |
| **tmux-sensible** | Sensible defaults |
| **tmux-resurrect** | Save/restore sessions |
| **tmux-copycat** | Enhanced search |

### Key bindings

| Key | Action |
|-----|--------|
| `Ctrl+a` | Prefix (send with `Ctrl+a Ctrl+a`) |
| `F12` | Toggle passthrough to a nested/remote tmux — mutes local tmux so keys go to the inner session; press again to return (status bar changes color) |
| `Prefix r` | Reload config |
| `Prefix v` | Split vertically |
| `Prefix h` | Split horizontally |
| `Prefix T` | Move window to position 1 |
| `Alt+c` | Fuzzy insert path from dir history — Enter inserts dir, Tab opens file picker under selected dir (no prefix) |
| `Prefix j` | Fuzzy-pick a pane from another session and join-pane it into current window |
| `Prefix k` | Scroll up (page) |
| `Alt+z` | Zoom/unzoom current pane (no prefix) |
| `Alt+s` | Enter copy mode and search backward (no prefix) |

### Pane Navigation

| Key | Action |
|-----|--------|
| `Alt+Left` | Select pane left |
| `Alt+Right` | Select pane right |
| `Alt+Up` | Select pane up |
| `Alt+Down` | Select pane down |

### Window Navigation

| Key | Action |
|-----|--------|
| `Shift+Left` | Previous window |
| `Shift+Right` | Next window |
| `Alt+1`..`Alt+9` | Go to window 1-9 |
| `Alt+0` | Go to window 10 |


## Fish Configuration

```
fish/
├── config.fish          # Main config: PATH, abbreviations, aliases, env vars
├── conf.d/
│   ├── omf.fish         # Oh My Fish loader
│   └── rustup.fish      # Cargo/Rust env
└── functions/
    ├── fcd.fish         # Fuzzy cd from dir history (Ctrl+g)
    ├── fish_prompt.fish # Custom prompt with git/hg branch and dirty indicator
    ├── __log_dir.fish   # Logs every visited dir to dir_history on PWD change
    └── dotenv.fish      # Load KEY=value pairs from a .env file into the shell
```

### Notable abbreviations / aliases

| Abbr/Alias | Expands to |
|------------|-----------|
| `gs` | `git status` |
| `ga` | `git add -A` |
| `ss` / `sp` | `git stash save -u` / `git stash pop` |
| `d` / `dc` / `dps` | docker / docker compose / docker ps |
| `p` / `pc` | podman / podman compose |
| `k` / `kl` | kubectl / kubectl logs |
| `dn` | dotnet |
| `v` | `nvim` |
| `cv` | `claude` |
| `l` | `ls -lA` |
| `Ctrl+g` | `fcd` — fuzzy jump to dir from history |

### Go toolchain

`config.fish` puts `/usr/local/go/bin` and `~/go/bin` on `PATH`. Go is installed from the
upstream tarball, **not** from apt — the Ubuntu/elementary repos pin `golang-go` to an old
release. To install or upgrade it on a new machine:

```fish
curl -LO https://go.dev/dl/goX.Y.Z.linux-amd64.tar.gz
sudo apt remove golang-go golang-src   # only if the apt version is present
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf goX.Y.Z.linux-amd64.tar.gz
```

Check the current release at <https://go.dev/dl/>. No `GOPATH` is set; Go defaults to `~/go`.


## Claude Code Configuration

```
claude-code/
└── commands/             # User-level slash commands (linked to ~/.claude/commands)
```
