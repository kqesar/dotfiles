-- -- Additional Plugins <https://www.lunarvim.org/docs/plugins#user-plugins>
lvim.plugins = {
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  {
    "folke/tokyonight.nvim",
  },
  {
    'iamcco/markdown-preview.nvim',
    config = function()
      vim.fn["mkdp#util#install"]()
    end,
  }
}

vim.cmd [[colorscheme tokyonight]]
vim.cmd [[colorscheme tokyonight-night]]
vim.cmd [[colorscheme tokyonight-day]]
vim.cmd [[colorscheme tokyonight-moon]]
vim.cmd [[colorscheme tokyonight-storm]]
