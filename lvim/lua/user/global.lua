-- general
lvim.log.level = "info"
lvim.builtin.treesitter.auto_install = true
lvim.colorscheme = "tokyonight"
lvim.builtin.lualine.style = 'lvim'
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true
lvim.builtin.treesitter.rainbow.enable = true
lvim.builtin.treesitter.autotag.enable = true
lvim.builtin.treesitter.matchup.enable = true
lvim.builtin.treesitter.textsubjects.enable = true
lvim.builtin.treesitter.playground.enable = true
lvim.builtin.treesitter.ensure_installed = "all"
lvim.builtin.treesitter.textsubject = {
  enable = true
}
lvim.builtin["terminal"].open_mapping = "<c-t>"
lvim.builtin["terminal"].start_in_insert = true
lvim.builtin.terminal.float_opts.border = "double"
lvim.builtin.terminal.persist_size = true
lvim.builtin.terminal.size = 40
-- lvim.builtin.project.show_hidden = true
lvim.builtin.project.detection_method = { "lsp" }
lvim.builtin.telescope.defaults.layout_strategy = "horizontal"
lvim.builtin.telescope.defaults.layout_config = {
  horizontal = {
    width = 0.8,
    height = 0.8
  }
}
lvim.builtin.telescope.defaults.path_display = { "absolute" }
lvim.transparent_window = true
