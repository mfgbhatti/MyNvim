-- a. Modeline
local function append_modeline()
  local expandtab_str = vim.o.expandtab and '' or 'no'
  local modeline = string.format(
    ' vim: set ts=%d sts=%d sw=%d %set :',
    vim.o.tabstop,
    vim.o.softtabstop,
    vim.o.shiftwidth,
    expandtab_str
  )
  modeline = string.gsub(vim.o.commentstring, '%%s', modeline)
  vim.api.nvim_buf_set_lines(0, -1, -1, true, { modeline })
end
vim.keymap.set('n', '<Leader>ml', append_modeline, { silent = true })

-- b. Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('Highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- c. colorscheme
vim.cmd.colorscheme 'murphy' -- catppuccin murphy

--  vim: set ts=2 sts=2 sw=2 et :
