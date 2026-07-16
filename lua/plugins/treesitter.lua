-- First run: :TSUpdate to compile parsers for the languages below.
require('nvim-treesitter').setup()

local parsers = {
  'lua',
  'vim',
  'vimdoc',
  'query',
  'bash',
  'markdown',
  'markdown_inline',
  'python',
  'javascript',
  'typescript',
  'json',
  'yaml',
}
require('nvim-treesitter').install(parsers)

local function treesitter_try_attach(buf, language)
  -- Check if a parser exists and load it
  if not vim.treesitter.language.add(language) then return end
  -- Enable syntax highlighting and other treesitter features
  vim.treesitter.start(buf, language)

  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

  if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end
local no_autocomplete_ft = {
  snacks_picker_input = true,
  snacks_picker_list = true,
  snacks_input = true,
}
local available_parsers = require('nvim-treesitter').get_available()
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    -- native autocomplete: only for real file buffers, never for pickers
    -- disabled global in vim options section 1
    vim.bo[buf].autocomplete = vim.bo[buf].buftype == '' and not no_autocomplete_ft[filetype]

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      treesitter_try_attach(buf, language)
    end
  end,
})

--  vim: set ts=2 sts=2 sw=2 et :
