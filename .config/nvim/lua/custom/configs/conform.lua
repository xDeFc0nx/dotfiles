local options = {
  lsp_fallback = true,

  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "prettier" },
    css = { "prettier" },
    html = { "prettier" },
    sh = { "shfmt" },

    -- Additional languages and their formatters
    markdown = { "prettier" },
    typescript = { "prettier" },
    yaml = { "prettier" },
    json = { "prettier" },
    -- Newly added languages
    c = { "clang-format" },
    bash = { "shfmt" },
    fish = { "fish_indent" },
  },
  format_on_save = {
    -- These options will be passed to conform.format()
    lsp_fallback = true,
  },
}

require("conform").setup(options)
-- Autocmd to trigger formatting on save
vim.api.nvim_exec(
  [[
  autocmd BufWritePre * lua require("conform").format()
]],
  false
)
