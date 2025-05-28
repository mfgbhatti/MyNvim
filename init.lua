-- spired and helped by https://github.com/nvim-lua/kickstart.nvim
--
--
-- [[ Options ]] --
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 500
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2

-- [[ Easy Moving ]] --
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

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

-- [[ lazy.vim (Plugin Manager) ]]--
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Setup lazy.nvim ]] --
require("lazy").setup {
  spec = {
    -- [[ Plugins start here ]] --
    {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      config = function()
        require("tokyonight").setup {
          transparent = true,
          styles = {
            sidebars = "transparent",
            floats = "transparent",
          },
        }
        vim.cmd.colorscheme "tokyonight-night"
      end,
    },
    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
    {
      -- [[ Main LSP Configuration ]] --
      "neovim/nvim-lspconfig",
      dependencies = {
        {
          "mason-org/mason.nvim",
          opts = {
            ui = {
              icons = {
                package_installed = "✓",
                package_pending = "➜",
                package_uninstalled = "✗",
              },
            },
          },
        },
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        { "j-hui/fidget.nvim", opts = {} },
        "saghen/blink.cmp",
      },
      config = function()
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

        -- [[ Diagnostic Config ]] --
        vim.diagnostic.config {
          severity_sort = true,
          float = { border = "rounded", source = "if_many" },
          underline = { severity = vim.diagnostic.severity.ERROR },
          signs = vim.g.have_nerd_font and {
            text = {
              [vim.diagnostic.severity.ERROR] = "󰅚 ",
              [vim.diagnostic.severity.WARN] = "󰀪 ",
              [vim.diagnostic.severity.INFO] = "󰋽 ",
              [vim.diagnostic.severity.HINT] = "󰌶 ",
            },
          } or {},
          virtual_text = {
            source = "if_many",
            spacing = 2,
            format = function(diagnostic)
              local diagnostic_message = {
                [vim.diagnostic.severity.ERROR] = diagnostic.message,
                [vim.diagnostic.severity.WARN] = diagnostic.message,
                [vim.diagnostic.severity.INFO] = diagnostic.message,
                [vim.diagnostic.severity.HINT] = diagnostic.message,
              }
              return diagnostic_message[diagnostic.severity]
            end,
          },
        }

        -- [[ LSP servers and clients ]] --
        local capabilities = require("blink.cmp").get_lsp_capabilities()
        local servers = {
          pyright = {},
          -- NOTE: install manually django-template-lsp from :MasonInstall
          html = {}, -- alias for html-lsp
          eslint = {}, -- eslint is a lsp
          cssls = {}, -- alias css-lsp
          css_variables = {}, -- alias for css-variables-language-server
          ts_ls = {}, -- alias for typescript-language-server
          markdown_oxide = {},
          emmet_ls = {
            filetypes = {
              "css",
              "html",
              "javascript",
              "scss",
              "pug",
              "typescript",
            },
          },
          emmet_language_server = {
            filetypes = {
              "css",
              "html",
              "javascript",
              "sass",
              "pug",
            },
          },
          -- alias for yaml-language-server
          yamlls = {
            yaml = {
              schemas = {
                ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = "/*.k8s.yaml",
              },
            },
          },

          lua_ls = {
            settings = {
              Lua = {
                completion = {
                  callSnippet = "Replace",
                },
              },
            },
          },
        }

        local ensure_installed = vim.tbl_keys(servers or {})
        vim.list_extend(ensure_installed, {
          "stylua",
          "black",
          "eslint_d", -- eslint_d is a linter
          "markdownlint",
          "isort",
          "shellcheck",
          "shfmt",
          "prettierd",
          "djlint",
          "yamlfmt",
        })
        require("mason-tool-installer").setup { ensure_installed = ensure_installed }

        require("mason-lspconfig").setup {
          ensure_installed = {}, -- explicitly set to an empty, only installs via mason-tool-installer)
          automatic_installation = false,
          handlers = {
            function(server_name)
              local server = servers[server_name] or {}
              server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
              require("lspconfig")[server_name].setup(server)
            end,
          },
        }
      end,
    },
    { -- Autoformat
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      cmd = { "ConformInfo" },
      keys = {
        {
          "<leader>f",
          function()
            require("conform").format { async = true, lsp_format = "fallback" }
          end,
          mode = "n",
          desc = "Format buffer",
        },
      },
      opts = {
        notify_on_error = false,
        format_on_save = function(bufnr)
          local disable_filetypes = { c = true, cpp = true }
          if disable_filetypes[vim.bo[bufnr].filetype] then
            return nil
          else
            return {
              timeout_ms = 500,
              lsp_format = "fallback",
            }
          end
        end,
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          htmldjango = { "djlint" },
          yaml = { "yamlfmt" },
          bash = { "shfmt" },
          javascript = { "prettierd", "prettier", stop_after_first = true },
          html = { "prettierd" },
          css = { "prettierd" },
        },
      },
    },
    {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
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
        lazygit = { enabled = true },
        indent = { enabled = true },
        rename = { enabled = true },
        notifier = { enabled = true },
        toggle = { enabled = true },
      },
      keys = {
        -- Top Pickers & Explorer
        {
          "<leader><space>",
          function()
            require("snacks").picker.buffers()
          end,
          desc = "Buffers",
        },
        {
          "<leader>,",
          function()
            require("snacks").picker.smart()
          end,
          desc = "Smart Find Files",
        },
        {
          "<leader>e",
          function()
            require("snacks").explorer()
          end,
          desc = "Open file explorer",
        },
        {
          "<leader>n",
          function()
            require("snacks").picker.notifications()
          end,
          desc = "Notification History",
        },
        {
          "<leader>/",
          function()
            require("snacks").picker.grep()
          end,
          desc = "Grep",
        },
        -- [[ lazygit keys ]] --
        {
          "<leader>lg",
          function()
            require("snacks").lazygit()
          end,
          desc = "Open lazygit",
        },
        {
          "<leader>lgg",
          function()
            require("snacks").lazygit.log()
          end,
          desc = "Open lazyit log",
        },
        -- [[ Search ]] --
        {
          "<leader>sk",
          function()
            require("snacks").picker.keymaps { layout = "ivy" }
          end,
          desc = "Keymaps",
        },
        {
          "<leader>scf",
          function()
            require("snacks").picker.files { cwd = vim.fn.stdpath "config" }
          end,
          desc = "Find Config File",
        },
        {
          "<leader>sf",
          function()
            require("snacks").picker.files()
          end,
          desc = "Find Files",
        },
        {
          "<leader>sg",
          function()
            require("snacks").picker.git_files()
          end,
          desc = "Find Git Files",
        },
        {
          "<leader>sp",
          function()
            require("snacks").picker.projects()
          end,
          desc = "Projects",
        },
        {
          "<leader>sr",
          function()
            require("snacks").picker.recent()
          end,
          desc = "Recent",
        },
        {
          '<leader>s"',
          function()
            require("snacks").picker.registers()
          end,
          desc = "Registers",
        },
        {
          "<leader>s/",
          function()
            require("snacks").picker.search_history()
          end,
          desc = "Search History",
        },
        {
          "<leader>sa",
          function()
            require("snacks").picker.autocmds()
          end,
          desc = "Autocmds",
        },
        {
          "<leader>sb",
          function()
            require("snacks").picker.lines()
          end,
          desc = "Buffer Lines",
        },
        {
          "<leader>sc",
          function()
            require("snacks").picker.command_history()
          end,
          desc = "Command History",
        },
        {
          "<leader>sC",
          function()
            require("snacks").picker.commands()
          end,
          desc = "Commands",
        },
        {
          "<leader>sd",
          function()
            require("snacks").picker.diagnostics()
          end,
          desc = "Diagnostics",
        },
        {
          "<leader>sh",
          function()
            require("snacks").picker.help()
          end,
          desc = "Help Pages",
        },
        {
          "<leader>sH",
          function()
            require("snacks").picker.highlights()
          end,
          desc = "Highlights",
        },
        {
          "<leader>si",
          function()
            require("snacks").picker.icons()
          end,
          desc = "Icons",
        },
        {
          "<leader>sj",
          function()
            require("snacks").picker.jumps()
          end,
          desc = "Jumps",
        },
        {
          "<leader>sl",
          function()
            require("snacks").picker.loclist()
          end,
          desc = "Location List",
        },
        {
          "<leader>sm",
          function()
            require("snacks").picker.marks()
          end,
          desc = "Marks",
        },
        {
          "<leader>sM",
          function()
            require("snacks").picker.man()
          end,
          desc = "Man Pages",
        },
        {
          "<leader>sp",
          function()
            require("snacks").picker.lazy()
          end,
          desc = "Search for Plugin Spec",
        },
        {
          "<leader>sq",
          function()
            require("snacks").picker.qflist()
          end,
          desc = "Quickfix List",
        },
        {
          "<leader>sR",
          function()
            require("snacks").picker.resume()
          end,
          desc = "Resume",
        },
        {
          "<leader>su",
          function()
            require("snacks").picker.undo()
          end,
          desc = "Undo History",
        }, -- [[ Misc ]] --
        {
          "<leader>rn",
          function()
            require("snacks").rename.rename_file()
          end,
          desc = "Fast Rename Current File",
        },
        {
          "<leader>C",
          function()
            require("snacks").picker.colorschemes()
          end,
          desc = "Colorschemes",
        },
      },
      init = function()
        vim.api.nvim_create_autocmd("User", {
          pattern = "VeryLazy",
          callback = function()
            -- Setup some globals for debugging (lazy-loaded)
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
          end,
        })
      end,
    },
    {
      -- [[Highlight, edit, and navigate code ]] --
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      main = "nvim-treesitter.configs",
      opts = {
        ensure_installed = {
          "bash",
          "diff",
          "html",
          "lua",
          "luadoc",
          "markdown",
          "markdown_inline",
          "vim",
          "vimdoc",
        },
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "ruby" },
        },
        indent = { enable = true, disable = { "ruby" } },
      },
    },
    {
      -- [[ Collection of various small independent plugins/modules ]] --
      "echasnovski/mini.nvim",
      config = function()
        require("mini.ai").setup { n_lines = 500 }
        require("mini.surround").setup()
        local statusline = require "mini.statusline"
        statusline.setup { use_icons = true }
        ---@diagnostic disable-next-line: duplicate-set-field
        statusline.section_location = function()
          return "%2l:%-2v"
        end
        --  Check out: https://github.com/echasnovski/mini.nvim
      end,
    },
    {
      -- [[ Highlight todo, notes, etc in comments ]] --
      "folke/todo-comments.nvim",
      event = "VimEnter",
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = { signs = false },
    },
    {
      -- [[ lazygit.nvim ]] --
      "kdheepak/lazygit.nvim",
      lazy = true,
      cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
      },
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      keys = {
        { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
      },
    },
    { import = "plugins" },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
}
-- vim: set ts=2 sts=2 sw=2 et :
