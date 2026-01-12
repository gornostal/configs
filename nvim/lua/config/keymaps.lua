-- Keymaps
local keymap = vim.keymap.set

-- Clear search highlight with Escape
keymap("n", "<Esc>", ":nohlsearch<CR>", { silent = true })

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Stay in visual mode when indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Move lines up/down in visual mode
keymap("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
keymap("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

-- Toggle line wrap
keymap("n", "<leader>w", ":set wrap!<CR>", { desc = "Toggle line wrap", silent = true })

-- Toggle gutter (sign column and line numbers)
keymap("n", "<leader>g", function()
  if vim.o.signcolumn == "yes" then
    vim.o.signcolumn = "no"
    vim.o.number = false
    vim.o.relativenumber = false
  else
    vim.o.signcolumn = "yes"
    vim.o.number = true
    vim.o.relativenumber = true
  end
end, { desc = "Toggle gutter", silent = true })
