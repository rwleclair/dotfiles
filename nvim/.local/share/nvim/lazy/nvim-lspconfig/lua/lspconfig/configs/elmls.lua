local util = require 'lspconfig.util'
local api = vim.api

local elm_root_pattern = util.root_pattern 'elm.json'

return {
  default_config = {
    cmd = { 'elm-language-server' },
    -- TODO(ashkan) if we comment this out, it will allow elmls to operate on elm.json. It seems like it could do that, but no other editor allows it right now.
    filetypes = { 'elm' },
    root_dir = function(fname)
      local filetype = api.nvim_buf_get_option(0, 'filetype')
      if filetype == 'elm' or (filetype == 'json' and fname:match 'elm%.json$') then
        return elm_root_pattern(fname)
      end
    end,
    init_options = {
      elmReviewDiagnostics = 'off', -- 'off' | 'warning' | 'error'
      skipInstallPackageConfirmation = false,
      disableElmLSDiagnostics = false,
      onlyUpdateDiagnosticsOnSave = false,
    },
    capabilities = {
      offsetEncoding = { 'utf-8', 'utf-16' },
    },
  },
  docs = {
    description = [[
https://github.com/elm-tooling/elm-language-server#installation

If you don't want to use Nvim to install it, then you can use:
```sh
npm install -g elm elm-test elm-format @elm-tooling/elm-language-server
```
]],
  },
}
