local M = {}

---@return { textDocument: lsp_text_document, position: nil }
local function get_params()
  return {
    textDocument = vim.lsp.util.make_text_document_params(),
    position = nil, -- get em all
  }
end

---@type { [string]: boolean? } Used to prevent this plugin from adding the same configuration twice
local _dap_configuration_added = {}

---@class RADebuggableArgs
---@field cargoArgs string[]
---@field cargoExtraArgs string[]
---@field executableArgs string[]
---@field workspaceRoot string | nil

---@param args RADebuggableArgs
---@return string
local function build_label(args)
  local ret = ''
  for _, value in ipairs(args.cargoArgs) do
    ret = ret .. value .. ' '
  end

  for _, value in ipairs(args.cargoExtraArgs) do
    ret = ret .. value .. ' '
  end

  if not vim.tbl_isempty(args.executableArgs) then
    ret = ret .. '-- '
    for _, value in ipairs(args.executableArgs) do
      ret = ret .. value .. ' '
    end
  end
  return ret
end

---@class RADebuggable
---@field args RADebuggableArgs

---@param result RADebuggable[]
---@return string[] option_strings
local function get_options(result)
  ---@type string[]
  local option_strings = {}

  for _, debuggable in ipairs(result) do
    local label = build_label(debuggable.args)
    local str = label
    table.insert(option_strings, str)
  end

  return option_strings
end

---@param args RADebuggableArgs
---@return boolean
local function is_valid_test(args)
  local is_not_cargo_check = args.cargoArgs[1] ~= 'check'
  return is_not_cargo_check
end

-- rust-analyzer doesn't actually support giving a list of debuggable targets,
-- so work around that by manually removing non debuggable targets (only cargo
-- check for now).
-- This function also makes it so that the debuggable commands are more
-- debugging friendly. For example, we move cargo run to cargo build, and cargo
-- test to cargo test --no-run.
---@param result RADebuggable[]
local function sanitize_results_for_debugging(result)
  ---@type RADebuggable[]
  local ret = vim.tbl_filter(function(value)
    ---@cast value RADebuggable
    return is_valid_test(value.args)
  end, result or {})

  local overrides = require('rustaceanvim.overrides')
  for _, value in ipairs(ret) do
    overrides.sanitize_command_for_debugging(value.args.cargoArgs)
  end

  return ret
end

---@param debuggables RADebuggable[]
local function ui_select_debuggable(debuggables)
  local options = get_options(debuggables)
  if #options == 0 then
    return
  end
  vim.ui.select(options, { prompt = 'Debuggables', kind = 'rust-tools/debuggables' }, function(_, choice)
    if choice == nil then
      return
    end

    local args = debuggables[choice].args
    local rt_dap = require('rustaceanvim.dap')
    local ok, dap = pcall(require, 'dap')
    if ok then
      rt_dap.start(args, true, dap.run)
    end
    local cached_commands = require('rustaceanvim.cached_commands')
    cached_commands.set_last_debuggable(args)
  end)
end

---@param debuggables RADebuggable[]
local function add_debuggables_to_nvim_dap(debuggables)
  local ok, dap = pcall(require, 'dap')
  if not ok then
    return
  end
  local rt_dap = require('rustaceanvim.dap')
  dap.configurations.rust = dap.configurations.rust or {}
  for _, debuggable in pairs(debuggables) do
    rt_dap.start(debuggable.args, false, function(configuration)
      local name = 'Cargo: ' .. build_label(debuggable.args)
      if not _dap_configuration_added[name] then
        configuration.name = name
        table.insert(dap.configurations.rust, configuration)
        _dap_configuration_added[name] = true
      end
    end)
  end
end

---@param callback fun(result:RADebuggable[])
local function mk_handler(callback)
  return function(_, result, _, _)
    ---@cast result RADebuggable[]
    if result == nil then
      return
    end
    result = sanitize_results_for_debugging(result)
    callback(result)
  end
end

local rl = require('rustaceanvim.rust_analyzer')

---@param handler? lsp.Handler See |lsp-handler|
local function runnables_request(handler)
  rl.buf_request(0, 'experimental/runnables', get_params(), handler)
end

--- Sends the request to rust-analyzer to get the debuggables and handles them
function M.debuggables()
  runnables_request(mk_handler(ui_select_debuggable))
end

--- Sends the request to rust-analyzer to get the debuggables and adds them to nvim-dap's
--- configurations
function M.add_dap_debuggables()
  runnables_request(mk_handler(add_debuggables_to_nvim_dap))
end

return M
