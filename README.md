# My configs

This project contains configs for apps that run via CLI.

## Instructions

When doing any significant modifications, change this file also.

## Setup Script

```
setup.sh
```

Links the Neovim and Tmux configs into their standard locations if they are not already present.


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

## To activate this config

Symlink it to Neovim's config location:

```bash
ln -s ~/projects/configs/nvim ~/.config/nvim
```

Then start Neovim:

```bash
nvim
```

On first launch, lazy.nvim will auto-install all plugins. Then Mason will install the language servers (pyright for Python, omnisharp for .NET).

## Plugins included

| Plugin | Description |
|--------|-------------|
| **lazy.nvim** | Plugin manager |
| **catppuccin** | Color scheme (mocha flavor) |
| **copilot.vim** | GitHub Copilot AI code completion |
| **neoscroll.nvim** | Smooth scrolling animations |
| **telescope.nvim** | Fuzzy finder for files, grep, buffers |
| **gitsigns.nvim** | Git change indicators in the gutter |
| **mason.nvim** | Language server installer |
| **mason-lspconfig.nvim** | Auto-configures LSP servers from Mason |
| **nvim-lspconfig** | LSP configuration |
| **nvim-cmp** | Autocompletion engine |
| **LuaSnip** | Snippet engine |

## Key bindings

`Space` is the leader key.

### General

| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlight |
| `<leader>w` | Toggle line wrap |
| `<leader>g` | Toggle line numbers (git signs stay visible) |
| `<leader>bd` | Delete current buffer |

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

### Git Diff

| Key | Action |
|-----|--------|
| `<leader>diff` | Show unstaged changes + new files |
| `<leader>dic` | Show staged changes (git diff --cached) |

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
└── .tmux.conf
```

### To activate

```bash
ln -s ~/projects/configs/tmux/.tmux.conf ~/.tmux.conf
```

### Features

- Prefix key: `Ctrl+a` (instead of default `Ctrl+b`)
- Vi mode enabled
- Mouse support
- 10000 line scrollback history
- Windows/panes start at index 1

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
| `Prefix r` | Reload config |
| `Prefix v` | Split vertically |
| `Prefix h` | Split horizontally |
| `Prefix T` | Move window to position 1 |

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
| `F1` | Previous window |
| `F2` | Next window |
