lvim.format_on_save = {
  enabled = true,
}
lvim.lint_on_save = true
lvim.lsp.diagnostics.update_in_insert = true
lvim.lsp.document_highlight = true
lvim.lsp.installer.setup.automatic_installation = true

-- -- linters and formatters <https://www.lunarvim.org/docs/languages#lintingformatting>
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "stylua", filetypes = { "lua" } },
  {
    command = "prettier",
    extra_args = { "--print-width", "100" },
    filetypes = { "typescript", "typescriptreact", "javascript", "vue", "svelte" },
  },
}
local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  --  { command = "flake8", filetypes = { "python" } },
  -- {
  --   command = "shellcheck",
  --   args = { "--severity", "warning" },
  -- },
  {
    command = "eslint", filetypes = { "typescript", "javascript", "vue", "typescriptreact", "svelte" }
  }
}
