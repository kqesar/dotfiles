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
