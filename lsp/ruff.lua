return {
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
}
