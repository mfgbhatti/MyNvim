local Snacks = require 'snacks'

vim.keymap.set('n', '<leader>w', '<cmd>write<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit' })
vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })

-- clear search highlight
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- copy and paste system clipboard on demand
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'Yank to system clipboard' })
vim.keymap.set('n', '<leader>Y', '"+Y', { desc = 'Yank line to system clipboard' })
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"+p', { desc = 'Paste from system clipboard' })

local venv_bin = vim.fn.getcwd() .. '/.venv/bin'

local function django_term(cmd)
  return function()
    Snacks.terminal(cmd, {
      cwd = vim.fn.getcwd(),
      env = { PATH = venv_bin .. ':' .. vim.env.PATH },
      win = { position = 'float' },
    })
  end
end

vim.keymap.set('n', '<leader>dr', django_term 'python manage.py runserver', { desc = 'Django runserver' })
vim.keymap.set('n', '<leader>dm', django_term 'python manage.py migrate', { desc = 'Django migrate' })
vim.keymap.set('n', '<leader>dk', django_term 'python manage.py makemigrations', { desc = 'Django makemigrations' })

-- snacks keybindings
--
vim.keymap.set('n', '<leader><space>', function() Snacks.picker.smart() end, { desc = 'Smart Find Files' })
vim.keymap.set('n', '<leader>,', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
vim.keymap.set('n', '<leader>/', function() Snacks.picker.grep() end, { desc = 'Grep' })
vim.keymap.set('n', '<leader>:', function() Snacks.picker.command_history() end, { desc = 'Command History' })
vim.keymap.set('n', '<leader>n', function() Snacks.picker.notifications() end, { desc = 'Notification History' })
vim.keymap.set('n', '<leader>e', function() Snacks.explorer() end, { desc = 'File Explorer' })

-- find
vim.keymap.set('n', '<leader>fb', function() Snacks.picker.buffers() end, { desc = 'Buffers' })
vim.keymap.set(
  'n',
  '<leader>fc',
  function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end,
  { desc = 'Find Config File' }
)
vim.keymap.set('n', '<leader>ff', function() Snacks.picker.files() end, { desc = 'Find Files' })
vim.keymap.set('n', '<leader>fg', function() Snacks.picker.git_files() end, { desc = 'Find Git Files' })
vim.keymap.set('n', '<leader>fp', function() Snacks.picker.projects() end, { desc = 'Projects' })
vim.keymap.set('n', '<leader>fr', function() Snacks.picker.recent() end, { desc = 'Recent' })

-- git
vim.keymap.set('n', '<leader>gb', function() Snacks.picker.git_branches() end, { desc = 'Git Branches' })
vim.keymap.set('n', '<leader>gl', function() Snacks.picker.git_log() end, { desc = 'Git Log' })
vim.keymap.set('n', '<leader>gL', function() Snacks.picker.git_log_line() end, { desc = 'Git Log Line' })
vim.keymap.set('n', '<leader>gs', function() Snacks.picker.git_status() end, { desc = 'Git Status' })
vim.keymap.set('n', '<leader>gS', function() Snacks.picker.git_stash() end, { desc = 'Git Stash' })
vim.keymap.set('n', '<leader>gd', function() Snacks.picker.git_diff() end, { desc = 'Git Diff (Hunks)' })
vim.keymap.set('n', '<leader>gf', function() Snacks.picker.git_log_file() end, { desc = 'Git Log File' })

-- gh
vim.keymap.set('n', '<leader>gi', function() Snacks.picker.gh_issue() end, { desc = 'GitHub Issues (open)' })
vim.keymap.set(
  'n',
  '<leader>gI',
  function() Snacks.picker.gh_issue { state = 'all' } end,
  { desc = 'GitHub Issues (all)' }
)
vim.keymap.set('n', '<leader>gp', function() Snacks.picker.gh_pr() end, { desc = 'GitHub Pull Requests (open)' })
vim.keymap.set(
  'n',
  '<leader>gP',
  function() Snacks.picker.gh_pr { state = 'all' } end,
  { desc = 'GitHub Pull Requests (all)' }
)

-- grep / search
vim.keymap.set('n', '<leader>sb', function() Snacks.picker.lines() end, { desc = 'Buffer Lines' })
vim.keymap.set('n', '<leader>sB', function() Snacks.picker.grep_buffers() end, { desc = 'Grep Open Buffers' })
vim.keymap.set('n', '<leader>sg', function() Snacks.picker.grep() end, { desc = 'Grep' })
vim.keymap.set(
  { 'n', 'x' },
  '<leader>sw',
  function() Snacks.picker.grep_word() end,
  { desc = 'Visual selection or word' }
)
vim.keymap.set('n', '<leader>s"', function() Snacks.picker.registers() end, { desc = 'Registers' })
vim.keymap.set('n', '<leader>s/', function() Snacks.picker.search_history() end, { desc = 'Search History' })
vim.keymap.set('n', '<leader>sa', function() Snacks.picker.autocmds() end, { desc = 'Autocmds' })
vim.keymap.set('n', '<leader>sc', function() Snacks.picker.command_history() end, { desc = 'Command History' })
vim.keymap.set('n', '<leader>sC', function() Snacks.picker.commands() end, { desc = 'Commands' })
vim.keymap.set('n', '<leader>sd', function() Snacks.picker.diagnostics() end, { desc = 'Diagnostics' })
vim.keymap.set('n', '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, { desc = 'Buffer Diagnostics' })
vim.keymap.set('n', '<leader>sh', function() Snacks.picker.help() end, { desc = 'Help Pages' })
vim.keymap.set('n', '<leader>sH', function() Snacks.picker.highlights() end, { desc = 'Highlights' })
vim.keymap.set('n', '<leader>si', function() Snacks.picker.icons() end, { desc = 'Icons' })
vim.keymap.set('n', '<leader>sj', function() Snacks.picker.jumps() end, { desc = 'Jumps' })
vim.keymap.set('n', '<leader>sk', function() Snacks.picker.keymaps() end, { desc = 'Keymaps' })
vim.keymap.set('n', '<leader>sl', function() Snacks.picker.loclist() end, { desc = 'Location List' })
vim.keymap.set('n', '<leader>sm', function() Snacks.picker.marks() end, { desc = 'Marks' })
vim.keymap.set('n', '<leader>sM', function() Snacks.picker.man() end, { desc = 'Man Pages' })
vim.keymap.set('n', '<leader>sp', function() Snacks.picker.lazy() end, { desc = 'Search for Plugin Spec' })
vim.keymap.set('n', '<leader>sq', function() Snacks.picker.qflist() end, { desc = 'Quickfix List' })
vim.keymap.set('n', '<leader>sR', function() Snacks.picker.resume() end, { desc = 'Resume' })
vim.keymap.set('n', '<leader>su', function() Snacks.picker.undo() end, { desc = 'Undo History' })
vim.keymap.set('n', '<leader>uC', function() Snacks.picker.colorschemes() end, { desc = 'Colorschemes' })

-- Other
vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Toggle Zen Mode' })
vim.keymap.set('n', '<leader>Z', function() Snacks.zen.zoom() end, { desc = 'Toggle Zoom' })
vim.keymap.set('n', '<leader>.', function() Snacks.scratch() end, { desc = 'Toggle Scratch Buffer' })
vim.keymap.set('n', '<leader>S', function() Snacks.scratch.select() end, { desc = 'Select Scratch Buffer' })
vim.keymap.set('n', '<leader>bd', function() Snacks.bufdelete() end, { desc = 'Delete Buffer' })
vim.keymap.set('n', '<leader>cR', function() Snacks.rename.rename_file() end, { desc = 'Rename File' })
vim.keymap.set({ 'n', 'v' }, '<leader>gB', function() Snacks.gitbrowse() end, { desc = 'Git Browse' })
vim.keymap.set('n', '<leader>gg', function() Snacks.lazygit() end, { desc = 'Lazygit' })
vim.keymap.set('n', '<leader>un', function() Snacks.notifier.hide() end, { desc = 'Dismiss All Notifications' })
vim.keymap.set({ 'n', 't' }, '<c-/>', function() Snacks.terminal() end, { desc = 'Toggle Terminal' })
vim.keymap.set({ 'n', 't' }, '<c-_>', function() Snacks.terminal() end, { desc = 'which_key_ignore' })
vim.keymap.set({ 'n', 't' }, ']]', function() Snacks.words.jump(vim.v.count1) end, { desc = 'Next Reference' })
vim.keymap.set({ 'n', 't' }, '[[', function() Snacks.words.jump(-vim.v.count1) end, { desc = 'Prev Reference' })
vim.keymap.set(
  'n',
  '<leader>N',
  function()
    Snacks.win {
      file = vim.api.nvim_get_runtime_file('doc/news.txt', false)[1],
      width = 0.6,
      height = 0.6,
      wo = { spell = false, wrap = false, signcolumn = 'yes', statuscolumn = ' ', conceallevel = 3 },
    }
  end,
  { desc = 'Neovim News' }
)

--  vim: set ts=2 sts=2 sw=2 et :
