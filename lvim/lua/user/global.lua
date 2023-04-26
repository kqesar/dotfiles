-- general
lvim.log.level = "info"
lvim.format_on_save = {
  enabled = true,
}
lvim.builtin.treesitter.ensure_installed = { "comment", "markdown_inline", "regex" }
lvim.builtin.treesitter.auto_install = true
lvim.colorscheme = "lunar"
lvim.lint_on_save = true
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true
lvim.builtin.treesitter.rainbow.enable = true
lvim.builtin.treesitter.ensure_installed = "all"
lvim.builtin.treesitter.textsubject = {
  enable = true
}
lvim.builtin["terminal"].open_mapping = "<c-t>"
lvim.builtin["terminal"].start_in_insert = true
lvim.lsp.diagnostics.update_in_insert = true
lvim.lsp.document_highlight = true
lvim.lsp.installer.setup.automatic_installation = true
lvim.builtin.project.show_hidden = true
lvim.builtin.project.detection_method = { "lsp" }
lvim.builtin.telescope.defaults.path_display = { "absolute" }
lvim.transparent_window = true


-- -- linters and formatters <https://www.lunarvim.org/docs/languages#lintingformatting>
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "stylua", filetypes = { "lua" } },
  {
    command = "prettier",
    extra_args = { "--print-width", "100" },
    filetypes = { "typescript", "typescriptreact" },
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
    command = "eslint", filetypes = { "typescript", "javascript", "vue", "typescriptreact" }
  }
}

-- -- Additional Plugins <https://www.lunarvim.org/docs/plugins#user-plugins>
lvim.plugins = {
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  {
    "folke/tokyonight.nvim",
  }
}

vim.cmd [[colorscheme tokyonight]]
vim.cmd [[colorscheme tokyonight-night]]
vim.cmd [[colorscheme tokyonight-storm]]
vim.cmd [[colorscheme tokyonight-day]]
vim.cmd [[colorscheme tokyonight-moon]]
