-- load RustAnalyzer command
require('rustaceanvim.lsp')

local stub = require('luassert.stub')
describe('LSP client API', function()
  local RustaceanConfig = require('rustaceanvim.config.internal')
  local Types = require('rustaceanvim.types.internal')
  local ra_bin = Types.evaluate(RustaceanConfig.server.cmd)[1]
  if vim.fn.executable(ra_bin) == 1 then
    it('Can spin up rust-analyzer.', function()
      local lsp_start = stub(vim.lsp, 'start')
      local notify_once = stub(vim, 'notify_once')
      local notify = stub(vim, 'notify')
      local bufnr = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_buf_set_name(bufnr, 'test.rs')
      vim.bo[bufnr].filetype = 'rust'
      vim.api.nvim_set_current_buf(bufnr)
      vim.cmd.RustAnalyzer('start')
      assert.stub(lsp_start).was_called()
      assert.stub(notify_once).was_not_called()
      assert.stub(notify).was_not_called()
      -- FIXME: This might not work in a sandboxed nix build
      -- local ra = require('rustaceanvim.rust_analyzer')
      -- assert(
      --   vim.wait(30000, function()
      --     return #ra.get_active_rustaceanvim_clients(bufnr) > 0
      --   end),
      --   'Failed to start the rust-analyzer LSP client'
      -- )
    end)
  end
end)
