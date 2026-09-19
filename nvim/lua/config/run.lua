-- :X — run the current file as an executable and show its output in a scratch buffer.
--
--   :X arg1 arg2   run ./current-file arg1 arg2, stream stdout+stderr into a split
--   :X!            same, but in a real terminal split (for programs that read stdin)
--   :XX            re-run with the previous arguments

local M = {}

local BUFNAME = "[Run Output]"
local last_args = ""
local job = nil

-- Find the window already showing the output buffer, or open one below.
local function output_buf()
  local buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b):match("%[Run Output%]$") then
      buf = b
      break
    end
  end

  if not buf then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, BUFNAME)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].swapfile = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, silent = true, desc = "Close output" })
  end

  local win
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(w) == buf then
      win = w
      break
    end
  end
  if not win then
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("botright 15split")
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].wrap = false
    vim.api.nvim_set_current_win(cur)
  end

  return buf, win
end

-- Append lines and keep the view pinned to the bottom while it streams.
local function append(buf, win, lines)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  vim.bo[buf].modifiable = false
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end
end

-- vim.system hands us arbitrary chunks, not whole lines; buffer the remainder.
local function line_sink(buf, win)
  local pending = ""
  return function(_, data)
    if data == nil then
      if pending ~= "" then
        local last = pending
        pending = ""
        vim.schedule(function() append(buf, win, { last }) end)
      end
      return
    end
    pending = pending .. data
    local lines = vim.split(pending:gsub("\r\n", "\n"), "\n", { plain = true })
    pending = table.remove(lines)
    if #lines > 0 then
      vim.schedule(function() append(buf, win, lines) end)
    end
  end
end

function M.run(args, interactive)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    vim.notify("No file in this buffer", vim.log.levels.ERROR)
    return
  end

  vim.cmd("silent update")

  if vim.fn.executable(file) == 0 then
    vim.notify("Not executable: " .. vim.fn.fnamemodify(file, ":t") .. " (chmod +x it first)", vim.log.levels.ERROR)
    return
  end

  last_args = args or ""
  local cmd = vim.fn.shellescape(file) .. (last_args ~= "" and " " .. last_args or "")
  local pretty = "./" .. vim.fn.fnamemodify(file, ":t") .. (last_args ~= "" and " " .. last_args or "")
  local cwd = vim.fn.fnamemodify(file, ":h")

  if interactive then
    vim.cmd("botright 15split")
    vim.fn.termopen({ vim.o.shell, "-c", cmd }, { cwd = cwd })
    vim.cmd("startinsert")
    return
  end

  if job then
    job:kill(15)
    job = nil
  end

  local buf, win = output_buf()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "$ " .. pretty, "" })
  vim.bo[buf].modifiable = false

  -- one sink per stream, so a partial stdout line never glues onto stderr
  local out, err = line_sink(buf, win), line_sink(buf, win)
  local started = vim.uv.hrtime()
  job = vim.system({ vim.o.shell, "-c", cmd }, {
    cwd = cwd,
    text = true,
    stdout = out,
    stderr = err,
  }, function(res)
    out(nil, nil)
    err(nil, nil)
    local ms = math.floor((vim.uv.hrtime() - started) / 1e6)
    vim.schedule(function()
      job = nil
      append(buf, win, { "", ("[exit %d, %dms]"):format(res.code, ms) })
    end)
  end)
end

vim.api.nvim_create_user_command("X", function(opts)
  M.run(opts.args, opts.bang)
end, { nargs = "*", bang = true, complete = "file", desc = "Run current file with args" })

vim.api.nvim_create_user_command("XX", function(opts)
  M.run(last_args, opts.bang)
end, { bang = true, desc = "Re-run current file with the previous args" })

return M
