-- Basic Neovim options
local opt = vim.opt

-- Line numbers (hidden by default, toggle with <leader>g)
opt.number = false
opt.relativenumber = false

-- Tabs & indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
-- Floats have no background of their own (transparent colorscheme), so outline them
opt.winborder = "rounded"

-- Behavior
opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 1000

-- Reload files changed on disk (e.g. by an agent in another pane). 'autoread' alone
-- only acts once Neovim checks, so check on focus/buffer enter and when idle.
-- FocusGained needs `focus-events on` in tmux.
opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("reload_changed_files", { clear = true }),
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- Completion
opt.completeopt = "menu,menuone,noselect"
