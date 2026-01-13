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

-- Close current buffer
keymap("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer", silent = true })

-- Toggle line numbers (sign column stays visible for git signs)
keymap("n", "<leader>g", function()
  vim.o.number = not vim.o.number
  vim.o.relativenumber = not vim.o.relativenumber
end, { desc = "Toggle line numbers", silent = true })

-- Git diff in a scratch buffer
local function show_diff(cmd, title)
  local output = vim.fn.systemlist(cmd)
  if #output == 0 then
    vim.notify("No changes", vim.log.levels.INFO)
    return
  end
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.filetype = "diff"
  vim.api.nvim_buf_set_name(0, title)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  vim.bo.modifiable = false
end

-- Unstaged changes + new files
keymap("n", "<leader>diff", function()
  show_diff("git diff && git ls-files --others --exclude-standard | xargs -I{} git diff --no-index /dev/null {} 2>/dev/null", "[Git Diff]")
end, { desc = "Git diff (unstaged + new)", silent = true })

-- Staged changes
keymap("n", "<leader>dic", function()
  show_diff("git diff --cached", "[Git Diff - Staged]")
end, { desc = "Git diff (staged)", silent = true })
