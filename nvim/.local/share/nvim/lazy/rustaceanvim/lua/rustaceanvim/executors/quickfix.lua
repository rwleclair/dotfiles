local compat = require('rustaceanvim.compat')

local function clear_qf()
  vim.fn.setqflist({}, ' ', { title = 'cargo' })
end

local function scroll_qf()
  if vim.bo.buftype ~= 'quickfix' then
    vim.api.nvim_command('cbottom')
  end
end

local function append_qf(line)
  vim.fn.setqflist({}, 'a', { lines = { line } })
  scroll_qf()
end

local function copen()
  vim.cmd('copen')
end

---@type RustaceanExecutor
local M = {
  execute_command = function(command, args, cwd)
    -- open quickfix
    copen()
    -- go back to the previous window
    vim.cmd.wincmd('p')
    -- clear the quickfix
    clear_qf()

    -- start compiling
    local cmd = vim.list_extend({ command }, args)
    compat.system(
      cmd,
      cwd and { cwd = cwd } or {},
      vim.schedule_wrap(function(sc)
        ---@cast sc vim.SystemCompleted
        local data = sc.stdout or sc.stderr
        append_qf(data)
      end)
    )
  end,
}

return M
