-- a. Enable faster startup by caching compiled Lua modules
vim.loader.enable()

-- b. Leader key (space)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- c. Core options

vim.o.number = false -- mobile
-- vim.o.relativenumber = true not using numbers
vim.o.cursorline = true
vim.o.signcolumn = 'yes'
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
-- vim.o.mouse = 'a' -- mouse sport
-- Turn it on if you need to copyy paste using dd, x et  to system clipboard
-- vim.o.clipboard = "unnamedplus"

vim.o.laststatus = 3 -- one global statusline
vim.o.cmdheight = 1

--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Native autocomplete (no nvim-cmp / blink.cmp needed)
-- Let's turn off global autocomplete while toggle it depending on files in buffer
-- vim.o.autocomplete = true
vim.o.completeopt = 'menu,menuone,noselect,popup,fuzzy'
vim.o.complete = '.,w,b,u,t' -- add "o" if you want LSP omnifunc mixed in everywhere
vim.o.pumheight = 10

--  vim: set ts=2 sts=2 sw=2 et :
