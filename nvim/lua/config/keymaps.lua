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

-- Git diff helpers
local function show_git_diff(cmd, title)
  local output = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 and #output == 0 then
    vim.notify("Not a git repository or no changes", vim.log.levels.WARN)
    return
  end
  -- Add separator between file sections
  local formatted = {}
  local separator = string.rep("━", 60)
  for i, line in ipairs(output) do
    if line:match("^diff %-%-git ") and i > 1 then
      table.insert(formatted, "")
      table.insert(formatted, separator)
      table.insert(formatted, "")
    end
    table.insert(formatted, line)
  end
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "diff"
  vim.api.nvim_buf_set_name(0, title)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
  vim.bo.modifiable = false
end

-- Show changed and untracked files (unstaged changes)
keymap("n", "<leader>diff", function()
  show_git_diff("git diff", "[Git Diff - Unstaged]")
end, { desc = "Git diff (unstaged changes)", silent = true })

-- Show staged file changes
keymap("n", "<leader>dic", function()
  show_git_diff("git diff --cached", "[Git Diff - Staged]")
end, { desc = "Git diff (staged changes)", silent = true })
