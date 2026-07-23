return {
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
}
