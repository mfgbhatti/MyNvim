-- inspired and helped by https://github.com/nvim-lua/kickstart.nvim
--
--
-- [[ Options ]] --
do
  -- Enable faster startup by caching compiled Lua modules
  vim.loader.enable()

  -- Set <space> as the leader key
  -- See `:help mapleader`
  --  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
  vim.g.mapleader = ' '
  vim.g.maplocalleader = ' '

  -- Set to true if you have a Nerd Font installed and selected in the terminal
  vim.g.have_nerd_font = true

  -- [[ Setting options ]]
  --  See `:help vim.o`
  -- NOTE: You can change these options as you wish!
  --  For more options, you can see `:help option-list`

  -- Make line numbers default
  vim.o.number = false -- on mobile
  -- You can also add relative line numbers, to help with jumping.
  --  Experiment for yourself to see if you like it!
  -- vim.o.relativenumber = true

  -- Enable mouse mode, can be useful for resizing splits for example!
  vim.o.mouse = 'a'

  -- Don't show the mode, since it's already in the status line
  vim.o.showmode = false

  -- Sync clipboard between OS and Neovim.
  --  Schedule the setting after `UiEnter` because it can increase startup-time.
  --  Remove this option if you want your OS clipboard to remain independent.
  --  See `:help 'clipboard'`
  vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

  -- Enable break indent
  vim.o.breakindent = true

  -- Enable undo/redo changes even after closing and reopening a file
  vim.o.undofile = true

  -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
  vim.o.ignorecase = true
  vim.o.smartcase = true

  -- Keep signcolumn on by default
  vim.o.signcolumn = 'yes'

  -- Decrease update time
  vim.o.updatetime = 250

  -- Decrease mapped sequence wait time
  vim.o.timeoutlen = 300

  -- Configure how new splits should be opened
  vim.o.splitright = true
  vim.o.splitbelow = true

  -- Sets how neovim will display certain whitespace characters in the editor.
  --  See `:help 'list'`
  --  and `:help 'listchars'`
  --
  --  Notice listchars is set using `vim.opt` instead of `vim.o`.
  --  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
  --   See `:help lua-options`
  --   and `:help lua-guide-options`
  vim.o.list = true
  vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

  -- Preview substitutions live, as you type!
  vim.o.inccommand = 'split'

  -- Show which line your cursor is on
  vim.o.cursorline = true

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.o.scrolloff = 10

  -- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
  -- instead raise a dialog asking if you wish to save the current file(s)
  -- See `:help 'confirm'`
  vim.o.confirm = true
end

-- [[ Easy Moving ]] -- -- using mobile
-- vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
-- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
-- vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
-- vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
-- vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
-- vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- [[ Text Highlight ]] --
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("user-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Modeline ]] --
local function append_modeline()
  local expandtab_str = vim.o.expandtab and "" or "no"
  local modeline = string.format(" vim: set ts=%d sts=%d sw=%d %set :", vim.o.tabstop, vim.o.softtabstop, vim.o.shiftwidth, expandtab_str)
  modeline = string.gsub(vim.o.commentstring, "%%s", modeline)
  vim.api.nvim_buf_set_lines(0, -1, -1, true, { modeline })
end
vim.keymap.set("n", "<Leader>ml", append_modeline, { silent = true })

-- [[ Plugin Manager Intro ]] --
do
  -- `vim.pack` is a new plugin manager built into Neovim,
  --  which provides a Lua interface for installing and managing plugins.
  --
  --  See `:help vim.pack`, `:help vim.pack-examples` or the
  --  excellent blog post from the creator of vim.pack and mini.nvim:
  --  https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack
  --
  --  To inspect plugin state and pending updates, run
  --    :lua vim.pack.update(nil, { offline = true })
  --
  --  To update plugins, run
  --    :lua vim.pack.update()
  --
  --
  --  Throughout the rest of the config there will be examples
  --  of how to install and configure plugins using `vim.pack`.
  --
  --  In this section we set up some autocommands to run build
  --  steps for certain plugins after they are installed or updated.

  local function run_build(name, cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd }):wait()
    if result.code ~= 0 then
      local stderr = result.stderr or ""
      local stdout = result.stdout or ""
      local output = stderr ~= "" and stderr or stdout
      if output == "" then
        output = "No output from build command."
      end
      vim.notify(("Build failed for %s:\n%s"):format(name, output), vim.log.levels.ERROR)
    end
  end
  --
  -- This autocommand runs after a plugin is installed or updated and
  --  runs the appropriate build command for that plugin if necessary.
  --
  -- See `:help vim.pack-events`
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      if kind ~= "install" and kind ~= "update" then
        return
      end
      --
      if name == "telescope-fzf-native.nvim" and vim.fn.executable "make" == 1 then
        run_build(name, { "make" }, ev.data.path)
        return
      end
      --
      if name == "LuaSnip" then
        if vim.fn.has "win32" ~= 1 and vim.fn.executable "make" == 1 then
          run_build(name, { "make", "install_jsregexp" }, ev.data.path)
        end
        return
      end
      --
      if name == "nvim-treesitter" then
        if not ev.data.active then
          vim.cmd.packadd "nvim-treesitter"
        end
        vim.cmd "TSUpdate"
        return
      end
    end,
  })
end

---Because most plugins are hosted on GitHub, you can use the helper
---function to have less repetition in the following sections.
---@param repo string
---@return string
local function gh(repo)
  return "https://github.com/" .. repo
end

-- [[ Start Installing Plugins ]] --
do
  -- [[ Install Guess Indent ]] --
  -- vim.pack.add { gh "NMAC427/guess-indent.nvim" }
  -- require("guess-indent").setup {}

  -- vim.pack.add { gh "lewis6991/gitsigns.nvim" }
  -- require("gitsigns").setup {
  --   signs = {
  --     add = { text = "+" }, ---@diagnostic disable-line: missing-fields
  --     change = { text = "~" }, ---@diagnostic disable-line: missing-fields
  --     delete = { text = "_" }, ---@diagnostic disable-line: missing-fields
  --     topdelete = { text = "‾" }, ---@diagnostic disable-line: missing-fields
  --     changedelete = { text = "~" }, ---@diagnostic disable-line: missing-fields
  --   },
  -- }
  --
  -- [[ Colorscheme ]]
  vim.pack.add { gh "folke/tokyonight.nvim" }
  ---@diagnostic disable-next-line: missing-fields
  require("tokyonight").setup {
    transparent = false,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  }

  vim.cmd.colorscheme "tokyonight-night"
end

-- [[ Autocomplete Engine ]] --
-- NOTE: moved above LSP Configuration so blink.cmp is on the
-- runtimepath (and its capabilities are available) before we
-- wire it into the LSP server setup below.
do
  -- [[ Snippet Engine ]] --

  -- NOTE: You can also specify plugin using a version range for its git tag.
  --  See `:help vim.version.range()` for more info
  vim.pack.add { { src = gh "L3MON4D3/LuaSnip", version = vim.version.range "2.*" } }
  require("luasnip").setup {}

  vim.pack.add { { src = gh "saghen/blink.cmp", version = vim.version.range "1.*" } }
  require("blink.cmp").setup {
    keymap = {
      -- 'default' (recommended) for mappings similar to built-in completions
      --   <c-y> to accept ([y]es) the completion.
      --    This will auto-import if your LSP supports it.
      --    This will expand snippets if the LSP sent a snippet.
      -- 'super-tab' for tab to accept
      -- 'enter' for enter to accept
      -- 'none' for no mappings
      --
      -- For an understanding of why the 'default' preset is recommended,
      -- you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      --
      -- All presets have the following mappings:
      -- <tab>/<s-tab>: move to right/left of your snippet expansion
      -- <c-space>: Open menu or open docs if already open
      -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
      -- <c-e>: Hide menu
      -- <c-k>: Toggle signature help
      --
      -- See `:help blink-cmp-config-keymap` for defining your own keymap
      preset = "default",

      -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
      --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    completion = {
      -- By default, you may press `<c-space>` to show the documentation.
      -- Optionally, set `auto_show = true` to show the documentation after a delay.
      documentation = { auto_show = false, auto_show_delay_ms = 500 },
    },

    sources = {
      default = { "lsp", "path", "snippets" },
    },

    snippets = { preset = "luasnip" },

    -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
    -- which automatically downloads a prebuilt binary when enabled.
    --
    -- By default, we use the Lua implementation instead, but you may enable
    -- the rust implementation via `'prefer_rust_with_warning'`
    --
    -- See `:help blink-cmp-config-fuzzy` for more information
    fuzzy = { implementation = "lua" },

    -- Shows a signature help window while you type arguments for a function
    signature = { enabled = true },
  }
end

-- [[ LSP Configuration ]] --
do
  vim.pack.add { gh "j-hui/fidget.nvim" }
  require("fidget").setup {}

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
    callback = function(event)
      local map = function(keys, func, desc, mode)
        mode = mode or "n"
        vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
      end

      map("gn", vim.lsp.buf.rename, "Rename")
      map("ga", vim.lsp.buf.code_action, "Goto Code Action", { "n", "x" })
      map("gr", require("snacks").picker.lsp_references, "Goto References")
      map("gi", require("snacks").picker.lsp_implementations, "Goto Implementation")
      map("gd", require("snacks").picker.lsp_definitions, "Goto Definition")
      map("gD", vim.lsp.buf.declaration, "Goto Declaration")
      map("gO", require("snacks").picker.lsp_symbols, "Open Document Symbols")
      map("gW", require("snacks").picker.lsp_workspace_symbols, "Open Workspace Symbols")
      map("gt", require("snacks").picker.lsp_type_definitions, "Goto Type Definition")

      local function client_supports_method(client, method, bufnr)
        if vim.fn.has "nvim-0.11" == 1 then
          return client:supports_method(method, bufnr)
        else
          return client.supports_method(method, { bufnr = bufnr })
        end
      end

      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
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
            vim.api.nvim_clear_autocmds {
              group = "user-lsp-highlight",
              buffer = event2.buf,
            }
          end,
        })
      end

      if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
        map("<leader>th", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
        end, "Toggle Inlay Hints")
      end
    end,
  })

  -- [[ LSP servers and clients ]] --
  -- NOTE: Place any or all language server here to get all the capabilities
  -- NOTE: only put actual LSP servers here (not formatters/linters like
  -- stylua, prettierd, shellcheck, etc.) — this table is looped below to
  -- call `lspconfig[name].setup(...)`, and non-LSP tools would break that.
  ---@type table<string, vim.lsp.Config>
  local servers = {
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "basic",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
          },
        },
      },
    },
    -- djlsp = {},
    html = {}, -- alias for html-lsp
    eslint = {}, -- eslint is a lsp
    cssls = {}, -- alias css-lsp
    css_variables = {}, -- alias for css-variables-language-server
    bashls = {},
    -- ts_ls = {}, -- alias for typescript-language-server
    -- markdown_oxide = {},
    emmet_ls = {
      filetypes = {
        "css",
        "html",
        "javascript",
        "scss",
        -- "pug",
        -- "typescript",
      },
    },
    emmet_language_server = {
      filetypes = {
        "css",
        "html",
        "javascript",
        -- "sass",
        -- "pug",
      },
    },
    -- alias for yaml-language-server
    -- yamlls = {
    --   yaml = {
    --     schemas = {
    --       ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = "/*.k8s.yaml",
    --     },
    --   },
    -- },

    -- Special Lua Config, as recommended by neovim help docs
    lua_ls = {
      on_init = function(client)
        client.server_capabilities.documentFormattingProvider = false -- Disable formatting (formatting is done by stylua)

        if client.workspace_folders then
          local path = client.workspace_folders[1].name
          if path ~= vim.fn.stdpath "config" and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc")) then
            return
          end
        end

        client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
          runtime = {
            version = "LuaJIT",
            path = { "lua/?.lua", "lua/?/init.lua" },
          },
          workspace = {
            checkThirdParty = false,
            -- NOTE: this is a lot slower and will cause issues when working on your own configuration.

            library = vim.tbl_extend("force", vim.api.nvim_get_runtime_file("", true), {
              "${3rd}/luv/library",
              "${3rd}/busted/library",
            }),
          },
        })
      end,
      ---@type lspconfig.settings.lua_ls
      settings = {
        Lua = {
          format = { enable = false }, -- Disable formatting (formatting is done by stylua)
        },
      },
    },
  }

  vim.pack.add {
    gh "neovim/nvim-lspconfig",
    gh "mason-org/mason.nvim",
    gh "mason-org/mason-lspconfig.nvim",
    gh "WhoIsSethDaniel/mason-tool-installer.nvim",
  }
  require("mason").setup {}

  -- Merge blink.cmp's completion capabilities into each server's capabilities,
  -- then hand each installed server off to lspconfig to actually enable it.
  local capabilities = require("blink.cmp").get_lsp_capabilities()

  require("mason-lspconfig").setup {
    ensure_installed = {},
    automatic_installation = false,
    handlers = {
      function(server_name)
        local server = servers[server_name] or {}
        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
        require("lspconfig")[server_name].setup(server)
      end,
    },
  }

  -- NOTE: You can add other tools here that you want Mason to install.
  -- Formatters/linters (not LSP servers) go in this extra list, not in `servers` above.
  local ensure_installed = vim.tbl_keys(servers or {})
  vim.list_extend(ensure_installed, {
    "stylua",
    -- "black",
    -- "eslint_d", -- eslint_d is a linter
    -- "markdownlint",
    -- "isort", -- for python
    "shellcheck",
    "shfmt",
    "prettierd",

    -- "djlint",  -- for django
    -- "yamlfmt",
  })
  require("mason-tool-installer").setup { ensure_installed = ensure_installed }
end

-- [[ Autoformat ]] --
do
  vim.pack.add { gh "stevearc/conform.nvim" }
  require("conform").setup {
    notify_on_error = false,
    format_on_save = function(bufnr)
      -- You can specify filetypes to autoformat on save here:
      local enabled_filetypes = {
        -- lua = true,
        -- python = true,
      }
      if enabled_filetypes[vim.bo[bufnr].filetype] then
        return { timeout_ms = 500 }
      else
        return nil
      end
    end,
    default_format_opts = {
      lsp_format = "fallback", -- Use external formatters if configured below, otherwise use LSP formatting. Set to `false` to disable LSP formatting entirely.
    },
    -- You can also specify external formatters in here
    formatters_by_ft = {
      -- lua = { "stylua" },
      python = { "isort", "black" },
      htmldjango = { "djlint" },
      -- yaml = { "yamlfmt" },
      bash = { "shfmt" },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd" },
      css = { "prettierd" },
    },
  }

  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    require("conform").format { async = true }
  end, { desc = "Format buffer" })
end

-- [[ Folke Snacks ]] --
do
  vim.pack.add { gh "folke/snacks.nvim" }

  require("snacks").setup {
    styles = {
      input = {
        keys = {
          n_esc = { "<C-c>", { "cmp_close", "cancel" }, mode = "n", expr = true },
          i_esc = { "<C-c>", { "cmp_close", "stopinsert" }, mode = "i", expr = true },
        },
      },
    },
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    picker = {
      enabled = true,
      layout = {
        -- presets options : "default" , "ivy" , "ivy-split" , "telescope" , "vscode", "select" , "sidebar"
        -- preset = "vscode", -- defaults to this layout unless overidden
        cycle = false,
      },
    },
    explorer = {
      enabled = true,
      layout = {
        cycle = false,
      },
    },
    -- lazygit = { enabled = true },
    indent = { enabled = true },
    rename = { enabled = true },
    notifier = { enabled = true },
    toggle = { enabled = true },
    terminal = { enable = true }, -- this is to run django commands in nvim window
  }

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

  vim.keymap.set("n", "<leader>dr", django_term "python manage.py runserver", { desc = "Django runserver" })
  vim.keymap.set("n", "<leader>dm", django_term "python manage.py migrate", { desc = "Django migrate" })
  vim.keymap.set("n", "<leader>dk", django_term "python manage.py makemigrations", { desc = "Django makemigrations" })

  -- [[ Top Pickers & Explorer ]] --
  vim.keymap.set("n", "<leader><space>", function()
    require("snacks").picker.buffers()
  end, { desc = "Buffers" })

  vim.keymap.set("n", "<leader>,", function()
    require("snacks").picker.smart()
  end, { desc = "Smart Find Files" })

  vim.keymap.set("n", "<leader>e", function()
    require("snacks").explorer()
  end, { desc = "Open file explorer" })

  vim.keymap.set("n", "<leader>n", function()
    require("snacks").picker.notifications()
  end, { desc = "Notification History" })

  vim.keymap.set("n", "<leader>/", function()
    require("snacks").picker.grep()
  end, { desc = "Grep" })

  -- [[ lazygit keys ]] --
  vim.keymap.set("n", "<leader>lg", function()
    require("snacks").lazygit()
  end, { desc = "Open lazygit" })

  vim.keymap.set("n", "<leader>lgg", function()
    require("snacks").lazygit.log()
  end, { desc = "Open lazygit log" })

  -- [[ Search ]] --
  vim.keymap.set("n", "<leader>sk", function()
    require("snacks").picker.keymaps { layout = "ivy" }
  end, { desc = "Keymaps" })

  vim.keymap.set("n", "<leader>scf", function()
    require("snacks").picker.files { cwd = vim.fn.stdpath "config" }
  end, { desc = "Find Config File" })

  vim.keymap.set("n", "<leader>sf", function()
    require("snacks").picker.files()
  end, { desc = "Find Files" })

  vim.keymap.set("n", "<leader>sg", function()
    require("snacks").picker.git_files()
  end, { desc = "Find Git Files" })

  vim.keymap.set("n", "<leader>sp", function()
    require("snacks").picker.projects()
  end, { desc = "Projects" })

  vim.keymap.set("n", "<leader>sr", function()
    require("snacks").picker.recent()
  end, { desc = "Recent" })

  vim.keymap.set("n", '<leader>s"', function()
    require("snacks").picker.registers()
  end, { desc = "Registers" })

  vim.keymap.set("n", "<leader>s/", function()
    require("snacks").picker.search_history()
  end, { desc = "Search History" })

  vim.keymap.set("n", "<leader>sa", function()
    require("snacks").picker.autocmds()
  end, { desc = "Autocmds" })

  vim.keymap.set("n", "<leader>sb", function()
    require("snacks").picker.lines()
  end, { desc = "Buffer Lines" })

  vim.keymap.set("n", "<leader>sc", function()
    require("snacks").picker.command_history()
  end, { desc = "Command History" })

  vim.keymap.set("n", "<leader>sC", function()
    require("snacks").picker.commands()
  end, { desc = "Commands" })

  vim.keymap.set("n", "<leader>sd", function()
    require("snacks").picker.diagnostics()
  end, { desc = "Diagnostics" })

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

  vim.keymap.set("n", "<leader>sl", function()
    require("snacks").picker.loclist()
  end, { desc = "Location List" })

  vim.keymap.set("n", "<leader>sm", function()
    require("snacks").picker.marks()
  end, { desc = "Marks" })

  vim.keymap.set("n", "<leader>sM", function()
    require("snacks").picker.man()
  end, { desc = "Man Pages" })

  vim.keymap.set("n", "<leader>sL", function()
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

  -- [[ Misc ]] --
  vim.keymap.set("n", "<leader>rn", function()
    require("snacks").rename.rename_file()
  end, { desc = "Fast Rename Current File" })

  vim.keymap.set("n", "<leader>C", function()
    require("snacks").picker.colorschemes()
  end, { desc = "Colorschemes" })

  -- Setup some globals for debugging
  _G.dd = function(...)
    require("snacks").debug.inspect(...)
  end
  _G.bt = function()
    require("snacks").debug.backtrace()
  end
  vim.print = _G.dd -- Override print to use snacks for `:=` command

  -- Create some toggle mappings
  require("snacks").toggle.option("spell", { name = "Spelling" }):map "<leader>us"
  require("snacks").toggle.option("wrap", { name = "Wrap" }):map "<leader>uw"
  require("snacks").toggle.option("relativenumber", { name = "Relative Number" }):map "<leader>uL"
  require("snacks").toggle.diagnostics():map "<leader>ud"
  require("snacks").toggle.line_number():map "<leader>ul"
  require("snacks").toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map "<leader>uc"
  require("snacks").toggle.indent():map "<leader>ug"
  require("snacks").toggle.dim():map "<leader>uz"
end

-- [[ Collection of various small independent plugins/modules ]] --

-- [[ mini.nvim ]] --
do
  --  A collection of various small independent plugins/modules
  vim.pack.add { gh "nvim-mini/mini.nvim" }

  -- If a nerd font is available, load the icons module for pretty icons in various plugins.
  if vim.g.have_nerd_font then
    require("mini.icons").setup()
    -- Used for backwards compatibility with plugins that require `nvim-web-devicons` (e.g. telescope.nvim)
    MiniIcons.mock_nvim_web_devicons()
  end

  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yiiq - [Y]ank [I]nside [I]+1 [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require("mini.ai").setup {
    -- NOTE: Avoid conflicts with the built-in incremental selection mappings on Neovim>=0.12 (see `:help treesitter-incremental-selection`)
    mappings = {
      around_next = "aa",
      inside_next = "ii",
    },
    n_lines = 500,
  }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require("mini.surround").setup()

  -- Simple and easy statusline.
  --  You could remove this setup call if you don't like it,
  --  and try some other statusline plugin
  local statusline = require "mini.statusline"
  -- Set `use_icons` to true if you have a Nerd Font
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- You can configure sections in the statusline by overriding their
  -- default behavior. For example, here we set the section for
  -- cursor location to LINE:COLUMN
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function()
    return "%2l:%-2v"
  end

  -- [[ Highlight todo, notes, etc in comments ]] --

  -- Highlight todo, notes, etc in comments
  vim.pack.add { gh "folke/todo-comments.nvim" }
  require("todo-comments").setup { signs = false }
end

-- [[ Configure Treesitter ]]
do
  --  Used to highlight, edit, and navigate code
  --
  --  See `:help nvim-treesitter-intro`

  -- NOTE: You can also specify a branch or a specific commit
  vim.pack.add { { src = gh "nvim-treesitter/nvim-treesitter", version = "main" } }

  -- Ensure basic parsers are installed
  local parsers = { "bash", "c", "diff", "html", "lua", "luadoc", "markdown", "markdown_inline", "query", "vim", "vimdoc" }
  require("nvim-treesitter").install(parsers)

  ---@param buf integer
  ---@param language string
  local function treesitter_try_attach(buf, language)
    -- Check if a parser exists and load it
    if not vim.treesitter.language.add(language) then
      return
    end
    -- Enable syntax highlighting and other treesitter features
    vim.treesitter.start(buf, language)

    -- Enable treesitter based folds
    -- For more info on folds see `:help folds`
    -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- vim.wo.foldmethod = 'expr'

    -- Check if treesitter indentation is available for this language, and if so enable it
    -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
    local has_indent_query = vim.treesitter.query.get(language, "indents") ~= nil

    -- Enable treesitter based indentation
    if has_indent_query then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end

  local available_parsers = require("nvim-treesitter").get_available()
  vim.api.nvim_create_autocmd("FileType", {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then
        return
      end

      local installed_parsers = require("nvim-treesitter").get_installed "parsers"

      if vim.tbl_contains(installed_parsers, language) then
        -- Enable the parser if it is already installed
        treesitter_try_attach(buf, language)
      elseif vim.tbl_contains(available_parsers, language) then
        -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
        require("nvim-treesitter").install(language):await(function()
          treesitter_try_attach(buf, language)
        end)
      else
        -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
        treesitter_try_attach(buf, language)
      end
    end,
  })
end

-- [[ Extra plugins ]] --
do
  require "plugins.lint"
end
-- [[ lazygit.nvim ]] --
-- do
--   vim.pack.add { gh "kdheepak/lazygit.nvim" }
--   require("lazygit").setup {}
--
--   -- Toggle LazyGit floating window
--   vim.keymap.set({ "n", "t" }, "<leader>gg", function () require("lazygit").toggle_lazygit() end, {
--     silent = true,
--     desc = "Toggle LazyGit",
--   })
-- end
-- -- vim: set ts=2 sts=2 sw=2 et :
