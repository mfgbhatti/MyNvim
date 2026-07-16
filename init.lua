-- ~/.config/nvim/init.lua
-- A lightweight Neovim config for 0.12+
-- Relies on native features (vim.pack, native LSP, native autocomplete)
-- instead of lazy.nvim / mason / nvim-cmp.

-- 1. Options
require 'config.options'

-- 2 Some utility functions
require 'config.utils'

-- 3. Plugins (native vim.pack — no plugin manager needed)

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo) return 'https://github.com/' .. repo end

-- vim.pack.add() clones/installs on first run. `:Pack update` to update,
-- `:Pack del <name>` to remove. See :help vim.pack
vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }
vim.pack.add { gh 'folke/snacks.nvim', gh 'nvim-mini/mini.statusline' }

-- 4. Treesitter
require 'plugins.treesitter'

-- 5. Snacks.nvim (picker / explorer / etc.)

require 'plugins.snacks'

-- 6. LSP (native, no mason)

-- You must have the language server binaries installed on your system
-- (e.g. via your OS package manager, npm -g, pip, go install, etc).
-- Uncomment / add the servers you actually use.

vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { 'init.lua', '.luarc.json', '.stylua.toml', '.git' },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false

    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath 'config'
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
      workspace = {
        checkThirdParty = false,
        library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
          '${3rd}/luv/library',
          '${3rd}/busted/library',
        }),
      },
    })
  end,
  settings = {
    Lua = { format = { enable = false } },
  },
})
vim.lsp.enable 'lua_ls'

vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'manage.py', 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  init_options = {
    settings = {
      -- ruff server settings, e.g.:
      lint = { enable = true },
      format = { preview = true },
    },
  },
})
vim.lsp.enable 'ruff'

vim.lsp.config('basedpyright', {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'manage.py', 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = 'standard' },
    },
    python = {
      pythonPath = vim.fn.getcwd() .. '/.venv/bin/python',
    },
  },
})
vim.lsp.enable 'basedpyright'

-- vim.lsp.config("ts_ls", {})
-- vim.lsp.enable("ts_ls")

vim.diagnostic.config {
  severity_sort = true,
  virtual_text = { spacing = 2, prefix = '●' },
  float = { border = 'rounded', source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
  },
}

-- LSP keybindings via Snacks.keymap: auto-scoped to buffers whose attached
-- client supports the given method, and auto-applied to future buffers too.
-- Same keys you already had — just no longer needs the manual LspAttach loop.
require('snacks').keymap.set('n', 'gn', vim.lsp.buf.rename, {
  lsp = { method = 'textDocument/rename' },
  desc = 'Rename',
})
require('snacks').keymap.set({ 'n', 'x' }, 'ga', vim.lsp.buf.code_action, {
  lsp = { method = 'textDocument/codeAction' },
  desc = 'Goto Code Action',
})
require('snacks').keymap.set('n', 'gr', require('snacks').picker.lsp_references, {
  lsp = { method = 'textDocument/references' },
  nowait = true,
  desc = 'Goto References',
})
require('snacks').keymap.set('n', 'gi', require('snacks').picker.lsp_implementations, {
  lsp = { method = 'textDocument/implementation' },
  desc = 'Goto Implementation',
})
require('snacks').keymap.set('n', 'gd', require('snacks').picker.lsp_definitions, {
  lsp = { method = 'textDocument/definition' },
  desc = 'Goto Definition',
})
require('snacks').keymap.set('n', 'gD', vim.lsp.buf.declaration, {
  lsp = { method = 'textDocument/declaration' },
  desc = 'Goto Declaration',
})
require('snacks').keymap.set('n', 'gO', require('snacks').picker.lsp_symbols, {
  lsp = { method = 'textDocument/documentSymbol' },
  desc = 'Open Document Symbols',
})
require('snacks').keymap.set('n', 'gW', require('snacks').picker.lsp_workspace_symbols, {
  lsp = { method = 'workspace/symbol' },
  desc = 'Open Workspace Symbols',
})
require('snacks').keymap.set('n', 'gt', require('snacks').picker.lsp_type_definitions, {
  lsp = { method = 'textDocument/typeDefinition' },
  desc = 'Goto Type Definition',
})
require('snacks').keymap.set(
  'n',
  '<leader>th',
  function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
  {
    lsp = { method = 'textDocument/inlayHint' },
    desc = 'Toggle Inlay Hints',
  }
)

-- Document highlight + cleanup isn't a keymap, so it still needs LspAttach directly.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local function client_supports_method(client, method, bufnr)
      if vim.fn.has 'nvim-0.11' == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if
      client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
    then
      local highlight_augroup = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds {
            group = 'user-lsp-highlight',
            buffer = event2.buf,
          }
        end,
      })
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'basedpyright' then
      client.server_capabilities.hoverProvider = false -- let ruff/basedpyright coexist without doubling hover
    end
  end,
})

-- Load progress
require 'config.progress'

-- 7. Formatting (native, no conform.nvim)
-- Uses the attached LSP client's formatter when it supports
-- textDocument/formatting; otherwise shells out to an external CLI
-- formatter you must have installed (stylua, prettier, black, etc).
local formatters_by_ft = {
  lua = 'stylua --indent-type Spaces --indent-width 2 -',
  -- python = "black -q -",
  -- javascript = "prettier --parser babel",
  -- javascriptreact = "prettier --parser babel",
  -- typescript = "prettier --parser typescript",
  -- typescriptreact = "prettier --parser typescript",
  -- json = "prettier --parser json",
  -- yaml = "prettier --parser yaml",
  -- markdown = "prettier --parser markdown",
}

local function format_buffer()
  local lsp_clients = vim.lsp.get_clients { bufnr = 0, method = 'textDocument/formatting' }
  if #lsp_clients > 0 then
    vim.lsp.buf.format { async = true }
    return
  end

  local cmd = formatters_by_ft[vim.bo.filetype]
  if not cmd then
    vim.notify('No formatter configured for filetype: ' .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end

  local view = vim.fn.winsaveview()
  vim.cmd(string.format('silent! %%!%s', cmd))
  if vim.v.shell_error ~= 0 then
    vim.notify('Format failed: ' .. cmd, vim.log.levels.ERROR)
    vim.cmd 'undo'
  end
  vim.fn.winrestview(view)
end

vim.keymap.set('n', '<leader>f', format_buffer, { desc = 'Format buffer' })

-- 8. Statusline (hand-rolled, no plugin)

-- require("mini.statusline").setup({})
local statusline = require 'mini.statusline'
-- Set `use_icons` to true if you have a Nerd Font
statusline.setup { use_icons = true }
--
-- You can configure sections in the statusline by overriding their
-- default behavior. For example, here we set the section for
-- cursor location to LINE:COLUMN
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- 9. General keymaps

require 'config.keymaps'
--
--  vim: set ts=2 sts=2 sw=2 et :
