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
| **catppuccin** | Color scheme (mocha dark / latte light, follows `background`) |
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
| **render-markdown.nvim** | In-buffer markdown rendering (headings, tables, code blocks, checkboxes) |

## Key bindings

`Space` is the leader key.

### General

| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlight |
| `<leader>w` | Toggle line wrap |
| `<leader>m` | Toggle markdown rendering (in a markdown buffer) |
| `Ctrl+b` / `Ctrl+n` | Scroll view half a screen left / right (`zH`/`zL`; needs `nowrap`) |
| `<leader>tg` | Toggle line numbers (git signs stay visible) |
| `<leader>tt` | Toggle light/dark theme (catppuccin latte/mocha, session-only) |
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

### Markdown

`render-markdown.nvim` renders markdown inside the real buffer — headings, tables, code
blocks, bullets, checkboxes and block quotes are drawn as virtual text, and the raw text
comes back on whichever line the cursor is on. No browser, no external renderer.

Icons are configured as plain ASCII/Unicode (`#`, `[ ]`, `•`) to match the rest of this
setup, which does not assume a Nerd Font. Sign-column icons are off so gitsigns keeps
the gutter. LaTeX rendering is disabled (it needs the `latex2text` CLI).

The `markdown` and `markdown_inline` treesitter parsers ship with Neovim, so nothing needs
installing. Since nvim-treesitter is on its `main` branch, highlighting is opt-in per
buffer — the treesitter spec has a `FileType markdown` autocmd calling
`vim.treesitter.start()`, which is also what syntax-highlights fenced code blocks.

| Key | Action |
|-----|--------|
| `<leader>m` | Toggle rendering on/off |

`:RenderMarkdown` also takes `enable`/`disable`/`toggle`/`expand`/`contract`/`log`/`debug`.

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

### Android SDK

`config.fish` exports `ANDROID_HOME`/`ANDROID_SDK_ROOT` (`~/Android/Sdk`) and puts the
SDK's `platform-tools` on `PATH`. Android Studio itself is installed as a Flatpak, but the
SDK lives on the host, so host-side tools (gradle, expo, `adb`) need these set explicitly.

`platform-tools` is added via `fish_add_path`, which prepends to `$fish_user_paths` and so
wins over `/usr/bin/adb` from the apt package `google-android-platform-tools-installer`
(35.0.0, older than the SDK's 37.0.0). This matters: two `adb` versions fighting over port
5037 is what leaves a connected device stuck in `offline` state.

`cmdline-tools/latest/bin` (`sdkmanager`, `avdmanager`) is added only if it exists — it
appears after installing **Android SDK Command-line Tools** from Android Studio's SDK
Manager.


## Claude Code Configuration

```
claude-code/
└── commands/             # User-level slash commands (linked to ~/.claude/commands)
```
