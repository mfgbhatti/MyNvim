-- [[ Autolint ]] --
-- Runs linters via nvim-lint, using the same tools already installed
-- through mason-tool-installer in init.lua (shellcheck, eslint_d, etc).

vim.pack.add { "https://github.com/mfussenegger/nvim-lint" }

local lint = require "lint"

-- Maps filetypes to the linter(s) nvim-lint should run.
lint.linters_by_ft = {
  bash = { "shellcheck" },
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  typescriptreact = { "eslint_d" },
}

local lint_augroup = vim.api.nvim_create_augroup("user-lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = lint_augroup,
  callback = function()
    -- Only run linters for filetypes that have one configured
    local names = lint.linters_by_ft[vim.bo.filetype]
    if names and #names > 0 then
      lint.try_lint()
    end
  end,
})

vim.keymap.set("n", "<leader>ll", function()
  lint.try_lint()
end, { desc = "Trigger linting for current file" })
