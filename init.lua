-- ~/.config/nvim/init.lua
-- A lightweight Neovim config for 0.12+
-- Relies on native features (vim.pack, native LSP, native autocomplete)
-- instead of lazy.nvim / mason / nvim-cmp.

-- 1. Options

-- a. Enable faster startup by caching compiled Lua modules
vim.loader.enable()

-- b. Leader key (space)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- c. Core options

vim.o.number = false -- mobile
-- vim.o.relativenumber = true not using numbers
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.scrolloff = 8

vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2
-- smartindent is intentionally left off: it inserts real <Tab> characters
-- when computing indentation, ignoring 'expandtab'. Treesitter's own
-- indentexpr (wired up in section 3) handles indentation correctly instead.
vim.o.autoindent = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.undofile = true
vim.o.swapfile = false
vim.o.updatetime = 250

vim.o.termguicolors = true
vim.o.mouse = "a"
-- Turn it on if you need to copyy paste using dd, x et  to system clipboard
-- vim.o.clipboard = "unnamedplus"

vim.o.laststatus = 3 -- one global statusline
vim.o.cmdheight = 1

--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Preview substitutions live, as you type!
vim.o.inccommand = "split"

-- Native autocomplete (no nvim-cmp / blink.cmp needed)
-- Let's turn off global autocomplete while toggle it depending on files in buffer
-- vim.o.autocomplete = true
vim.o.completeopt = "menu,menuone,noselect,popup,fuzzy"
vim.o.complete = ".,w,b,u,t" -- add "o" if you want LSP omnifunc mixed in everywhere
vim.o.pumheight = 10

-- c. Modeline
local function append_modeline()
  local expandtab_str = vim.o.expandtab and "" or "no"
  local modeline = string.format(
    " vim: set ts=%d sts=%d sw=%d %set :",
    vim.o.tabstop,
    vim.o.softtabstop,
    vim.o.shiftwidth,
    expandtab_str
  )
  modeline = string.gsub(vim.o.commentstring, "%%s", modeline)
  vim.api.nvim_buf_set_lines(0, -1, -1, true, { modeline })
end
vim.keymap.set("n", "<Leader>ml", append_modeline, { silent = true })

-- d. github short url
---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo)
  return "https://github.com/" .. repo
end

-- e. Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("Highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- f. colorscheme
vim.cmd.colorscheme("murphy") -- catppuccin murphy
-- 2. Plugins (native vim.pack — no plugin manager needed)

-- vim.pack.add() clones/installs on first run. `:Pack update` to update,
-- `:Pack del <name>` to remove. See :help vim.pack
vim.pack.add({ { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" } })
vim.pack.add({ gh("folke/snacks.nvim"), gh("nvim-mini/mini.statusline") })

-- 3. Treesitter

-- First run: :TSUpdate to compile parsers for the languages below.
require("nvim-treesitter").setup()

local parsers = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "bash",
  "markdown",
  "markdown_inline",
  "python",
  "javascript",
  "typescript",
  "json",
  "yaml",
}
require("nvim-treesitter").install(parsers)

local function treesitter_try_attach(buf, language)
  -- Check if a parser exists and load it
  if not vim.treesitter.language.add(language) then
    return
  end
  -- Enable syntax highlighting and other treesitter features
  vim.treesitter.start(buf, language)

  local has_indent_query = vim.treesitter.query.get(language, "indents") ~= nil

  if has_indent_query then
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end
local no_autocomplete_ft = {
  snacks_picker_input = true,
  snacks_picker_list = true,
  snacks_input = true,
}
local available_parsers = require("nvim-treesitter").get_available()
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    -- native autocomplete: only for real file buffers, never for pickers
    -- disabled global in vim options section 1
    vim.bo[buf].autocomplete = vim.bo[buf].buftype == "" and not no_autocomplete_ft[filetype]

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then
      return
    end

    local installed_parsers = require("nvim-treesitter").get_installed("parsers")

    if vim.tbl_contains(installed_parsers, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      require("nvim-treesitter").install(language):await(function()
        treesitter_try_attach(buf, language)
      end)
    else
      treesitter_try_attach(buf, language)
    end
  end,
})

-- 4. Snacks.nvim (picker / explorer / etc.)
require("snacks").setup({

  -- your configuration comes here
  bigfile = { enabled = false },
  dashboard = { enabled = false },
  explorer = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  notifier = {
    enabled = true,
    timeout = 3000,
  },
  picker = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = false },
  statuscolumn = { enabled = false },
  words = { enabled = true },
  terminal = { enable = true },
})

-- 5. LSP (native, no mason)

-- You must have the language server binaries installed on your system
-- (e.g. via your OS package manager, npm -g, pip, go install, etc).
-- Uncomment / add the servers you actually use.

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { "init.lua", ".luarc.json", ".stylua.toml", ".git" },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false

    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath("config")
        and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
      runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
      workspace = {
        checkThirdParty = false,
        library = vim.tbl_extend("force", vim.api.nvim_get_runtime_file("", true), {
          "${3rd}/luv/library",
          "${3rd}/busted/library",
        }),
      },
    })
  end,
  settings = {
    Lua = { format = { enable = false } },
  },
})
vim.lsp.enable("lua_ls")

vim.lsp.config("ruff", {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "manage.py", "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
  init_options = {
    settings = {
      -- ruff server settings, e.g.:
      lint = { enable = true },
      format = { preview = true },
    },
  },
})
vim.lsp.enable("ruff")

vim.lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "manage.py", "pyproject.toml", "setup.py", "requirements.txt", ".git" },
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = "standard" },
    },
    python = {
      pythonPath = vim.fn.getcwd() .. "/.venv/bin/python",
    },
  },
})
vim.lsp.enable("basedpyright")

-- vim.lsp.config("pyright", {})
-- vim.lsp.enable("pyright")

-- vim.lsp.config("ts_ls", {})
-- vim.lsp.enable("ts_ls")

-- vim.lsp.config("gopls", {})
-- vim.lsp.enable("gopls")

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = { spacing = 2, prefix = "●" },
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})

-- LSP keybindings via Snacks.keymap: auto-scoped to buffers whose attached
-- client supports the given method, and auto-applied to future buffers too.
-- Same keys you already had — just no longer needs the manual LspAttach loop.
require("snacks").keymap.set("n", "gn", vim.lsp.buf.rename, {
  lsp = { method = "textDocument/rename" },
  desc = "Rename",
})
require("snacks").keymap.set({ "n", "x" }, "ga", vim.lsp.buf.code_action, {
  lsp = { method = "textDocument/codeAction" },
  desc = "Goto Code Action",
})
require("snacks").keymap.set("n", "gr", require("snacks").picker.lsp_references, {
  lsp = { method = "textDocument/references" },
  nowait = true,
  desc = "Goto References",
})
require("snacks").keymap.set("n", "gi", require("snacks").picker.lsp_implementations, {
  lsp = { method = "textDocument/implementation" },
  desc = "Goto Implementation",
})
require("snacks").keymap.set("n", "gd", require("snacks").picker.lsp_definitions, {
  lsp = { method = "textDocument/definition" },
  desc = "Goto Definition",
})
require("snacks").keymap.set("n", "gD", vim.lsp.buf.declaration, {
  lsp = { method = "textDocument/declaration" },
  desc = "Goto Declaration",
})
require("snacks").keymap.set("n", "gO", require("snacks").picker.lsp_symbols, {
  lsp = { method = "textDocument/documentSymbol" },
  desc = "Open Document Symbols",
})
require("snacks").keymap.set("n", "gW", require("snacks").picker.lsp_workspace_symbols, {
  lsp = { method = "workspace/symbol" },
  desc = "Open Workspace Symbols",
})
require("snacks").keymap.set("n", "gt", require("snacks").picker.lsp_type_definitions, {
  lsp = { method = "textDocument/typeDefinition" },
  desc = "Goto Type Definition",
})
require("snacks").keymap.set("n", "<leader>th", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, {
  lsp = { method = "textDocument/inlayHint" },
  desc = "Toggle Inlay Hints",
})

-- Document highlight + cleanup isn't a keymap, so it still needs LspAttach directly.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
  callback = function(event)
    local function client_supports_method(client, method, bufnr)
      if vim.fn.has("nvim-0.11") == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if
      client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
    then
      local highlight_augroup = vim.api.nvim_create_augroup("user-lsp-highlight", { clear = false })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup("user-lsp-detach", { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({
            group = "user-lsp-highlight",
            buffer = event2.buf,
          })
        end,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "basedpyright" then
      client.server_capabilities.hoverProvider = false -- let ruff/basedpyright coexist without doubling hover
    end
  end,
})

-- 6. Formatting (native, no conform.nvim)
-- Uses the attached LSP client's formatter when it supports
-- textDocument/formatting; otherwise shells out to an external CLI
-- formatter you must have installed (stylua, prettier, black, etc).
local formatters_by_ft = {
  lua = "stylua --indent-type Spaces --indent-width 2 -",
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
  local lsp_clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting" })
  if #lsp_clients > 0 then
    vim.lsp.buf.format({ async = true })
    return
  end

  local cmd = formatters_by_ft[vim.bo.filetype]
  if not cmd then
    vim.notify("No formatter configured for filetype: " .. vim.bo.filetype, vim.log.levels.WARN)
    return
  end

  local view = vim.fn.winsaveview()
  vim.cmd(string.format("silent! %%!%s", cmd))
  if vim.v.shell_error ~= 0 then
    vim.notify("Format failed: " .. cmd, vim.log.levels.ERROR)
    vim.cmd("undo")
  end
  vim.fn.winrestview(view)
end

-- 7. Statusline (hand-rolled, no plugin)

-- require("mini.statusline").setup({})
local statusline = require("mini.statusline")
-- Set `use_icons` to true if you have a Nerd Font
statusline.setup({ use_icons = true })
--
--     -- You can configure sections in the statusline by overriding their
--       -- default behavior. For example, here we set the section for
--         -- cursor location to LINE:COLUMN
--           ---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function()
  return "%2l:%-2v"
end

-- 8. General keymaps

vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("n", "<leader>f", format_buffer, { desc = "Format buffer" })

-- clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- copy and paste system clipboard on demand
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

local venv_bin = vim.fn.getcwd() .. "/.venv/bin"

local function django_term(cmd)
  return function()
    Snacks.terminal(cmd, {
      cwd = vim.fn.getcwd(),
      env = { PATH = venv_bin .. ":" .. vim.env.PATH },
      win = { position = "float" },
    })
  end
end

vim.keymap.set("n", "<leader>dr", django_term("python manage.py runserver"), { desc = "Django runserver" })
vim.keymap.set("n", "<leader>dm", django_term("python manage.py migrate"), { desc = "Django migrate" })
vim.keymap.set("n", "<leader>dk", django_term("python manage.py makemigrations"), { desc = "Django makemigrations" })

-- snacks keybindings
--
vim.keymap.set("n", "<leader><space>", function()
  require("snacks").picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>,", function()
  require("snacks").picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>/", function()
  require("snacks").picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>:", function()
  require("snacks").picker.command_history()
end, { desc = "Command History" })
vim.keymap.set("n", "<leader>n", function()
  require("snacks").picker.notifications()
end, { desc = "Notification History" })
vim.keymap.set("n", "<leader>e", function()
  require("snacks").explorer()
end, { desc = "File Explorer" })

-- find
vim.keymap.set("n", "<leader>fb", function()
  require("snacks").picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fc", function()
  require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find Config File" })
vim.keymap.set("n", "<leader>ff", function()
  require("snacks").picker.files()
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function()
  require("snacks").picker.git_files()
end, { desc = "Find Git Files" })
vim.keymap.set("n", "<leader>fp", function()
  require("snacks").picker.projects()
end, { desc = "Projects" })
vim.keymap.set("n", "<leader>fr", function()
  require("snacks").picker.recent()
end, { desc = "Recent" })

-- git
vim.keymap.set("n", "<leader>gb", function()
  require("snacks").picker.git_branches()
end, { desc = "Git Branches" })
vim.keymap.set("n", "<leader>gl", function()
  require("snacks").picker.git_log()
end, { desc = "Git Log" })
vim.keymap.set("n", "<leader>gL", function()
  require("snacks").picker.git_log_line()
end, { desc = "Git Log Line" })
vim.keymap.set("n", "<leader>gs", function()
  require("snacks").picker.git_status()
end, { desc = "Git Status" })
vim.keymap.set("n", "<leader>gS", function()
  require("snacks").picker.git_stash()
end, { desc = "Git Stash" })
vim.keymap.set("n", "<leader>gd", function()
  require("snacks").picker.git_diff()
end, { desc = "Git Diff (Hunks)" })
vim.keymap.set("n", "<leader>gf", function()
  require("snacks").picker.git_log_file()
end, { desc = "Git Log File" })

-- gh
vim.keymap.set("n", "<leader>gi", function()
  require("snacks").picker.gh_issue()
end, { desc = "GitHub Issues (open)" })
vim.keymap.set("n", "<leader>gI", function()
  require("snacks").picker.gh_issue({ state = "all" })
end, { desc = "GitHub Issues (all)" })
vim.keymap.set("n", "<leader>gp", function()
  require("snacks").picker.gh_pr()
end, { desc = "GitHub Pull Requests (open)" })
vim.keymap.set("n", "<leader>gP", function()
  require("snacks").picker.gh_pr({ state = "all" })
end, { desc = "GitHub Pull Requests (all)" })

-- grep / search
vim.keymap.set("n", "<leader>sb", function()
  require("snacks").picker.lines()
end, { desc = "Buffer Lines" })
vim.keymap.set("n", "<leader>sB", function()
  require("snacks").picker.grep_buffers()
end, { desc = "Grep Open Buffers" })
vim.keymap.set("n", "<leader>sg", function()
  require("snacks").picker.grep()
end, { desc = "Grep" })
vim.keymap.set({ "n", "x" }, "<leader>sw", function()
  require("snacks").picker.grep_word()
end, { desc = "Visual selection or word" })
vim.keymap.set("n", '<leader>s"', function()
  require("snacks").picker.registers()
end, { desc = "Registers" })
vim.keymap.set("n", "<leader>s/", function()
  require("snacks").picker.search_history()
end, { desc = "Search History" })
vim.keymap.set("n", "<leader>sa", function()
  require("snacks").picker.autocmds()
end, { desc = "Autocmds" })
vim.keymap.set("n", "<leader>sc", function()
  require("snacks").picker.command_history()
end, { desc = "Command History" })
vim.keymap.set("n", "<leader>sC", function()
  require("snacks").picker.commands()
end, { desc = "Commands" })
vim.keymap.set("n", "<leader>sd", function()
  require("snacks").picker.diagnostics()
end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>sD", function()
  require("snacks").picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })
vim.keymap.set("n", "<leader>sh", function()
  require("snacks").picker.help()
end, { desc = "Help Pages" })
vim.keymap.set("n", "<leader>sH", function()
  require("snacks").picker.highlights()
end, { desc = "Highlights" })
vim.keymap.set("n", "<leader>si", function()
  require("snacks").picker.icons()
end, { desc = "Icons" })
vim.keymap.set("n", "<leader>sj", function()
  require("snacks").picker.jumps()
end, { desc = "Jumps" })
vim.keymap.set("n", "<leader>sk", function()
  require("snacks").picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sl", function()
  require("snacks").picker.loclist()
end, { desc = "Location List" })
vim.keymap.set("n", "<leader>sm", function()
  require("snacks").picker.marks()
end, { desc = "Marks" })
vim.keymap.set("n", "<leader>sM", function()
  require("snacks").picker.man()
end, { desc = "Man Pages" })
vim.keymap.set("n", "<leader>sp", function()
  require("snacks").picker.lazy()
end, { desc = "Search for Plugin Spec" })
vim.keymap.set("n", "<leader>sq", function()
  require("snacks").picker.qflist()
end, { desc = "Quickfix List" })
vim.keymap.set("n", "<leader>sR", function()
  require("snacks").picker.resume()
end, { desc = "Resume" })
vim.keymap.set("n", "<leader>su", function()
  require("snacks").picker.undo()
end, { desc = "Undo History" })
vim.keymap.set("n", "<leader>uC", function()
  require("snacks").picker.colorschemes()
end, { desc = "Colorschemes" })

-- Other
vim.keymap.set("n", "<leader>z", function()
  require("snacks").zen()
end, { desc = "Toggle Zen Mode" })
vim.keymap.set("n", "<leader>Z", function()
  require("snacks").zen.zoom()
end, { desc = "Toggle Zoom" })
vim.keymap.set("n", "<leader>.", function()
  require("snacks").scratch()
end, { desc = "Toggle Scratch Buffer" })
vim.keymap.set("n", "<leader>S", function()
  require("snacks").scratch.select()
end, { desc = "Select Scratch Buffer" })
vim.keymap.set("n", "<leader>bd", function()
  require("snacks").bufdelete()
end, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>cR", function()
  require("snacks").rename.rename_file()
end, { desc = "Rename File" })
vim.keymap.set({ "n", "v" }, "<leader>gB", function()
  require("snacks").gitbrowse()
end, { desc = "Git Browse" })
vim.keymap.set("n", "<leader>gg", function()
  require("snacks").lazygit()
end, { desc = "Lazygit" })
vim.keymap.set("n", "<leader>un", function()
  require("snacks").notifier.hide()
end, { desc = "Dismiss All Notifications" })
vim.keymap.set({ "n", "t" }, "<c-/>", function()
  require("snacks").terminal()
end, { desc = "Toggle Terminal" })
vim.keymap.set({ "n", "t" }, "<c-_>", function()
  require("snacks").terminal()
end, { desc = "which_key_ignore" })
vim.keymap.set({ "n", "t" }, "]]", function()
  require("snacks").words.jump(vim.v.count1)
end, { desc = "Next Reference" })
vim.keymap.set({ "n", "t" }, "[[", function()
  require("snacks").words.jump(-vim.v.count1)
end, { desc = "Prev Reference" })
vim.keymap.set("n", "<leader>N", function()
  require("snacks").win({
    file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
    width = 0.6,
    height = 0.6,
    wo = { spell = false, wrap = false, signcolumn = "yes", statuscolumn = " ", conceallevel = 3 },
  })
end, { desc = "Neovim News" })

-- Debug globals + toggle mappings (was inside init()'s VeryLazy autocmd;
-- run directly since VeryLazy is a lazy.nvim-only event)
_G.dd = function(...)
  require("snacks").debug.inspect(...)
end
_G.bt = function()
  require("snacks").debug.backtrace()
end
vim._print = function(_, ...)
  dd(...)
end

require("snacks").toggle.option("spell", { name = "Spelling" }):map("<leader>us")
require("snacks").toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
require("snacks").toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
require("snacks").toggle.diagnostics():map("<leader>ud")
require("snacks").toggle.line_number():map("<leader>ul")
require("snacks").toggle
  .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
  :map("<leader>uc")
require("snacks").toggle.treesitter():map("<leader>uT")
require("snacks").toggle
  .option("background", { off = "light", on = "dark", name = "Dark Background" })
  :map("<leader>ub")
require("snacks").toggle.inlay_hints():map("<leader>uh")
require("snacks").toggle.indent():map("<leader>ug")
require("snacks").toggle.dim():map("<leader>uD")
--  vim: set ts=2 sts=2 sw=2 et :
