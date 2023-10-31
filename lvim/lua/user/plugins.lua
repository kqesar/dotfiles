-- -- Additional Plugins <https://www.lunarvim.org/docs/plugins#user-plugins>
lvim.plugins = {
  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  {
    "brenoprata10/nvim-highlight-colors",
    config = function ()
      require("nvim-highlight-colors").setup({
        render = 'first_column',
        enable_tailwind = true,
      })
    end
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

require("nvim-highlight-colors").toggle()
