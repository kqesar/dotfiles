-- keymaps for normal mode
lvim.keys.normal_mode["<C-l>"] = ":BufferLineCycleNext<CR>"
lvim.keys.normal_mode["<C-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-x>"] = ":bd<CR>"
lvim.keys.normal_mode["<C-d>"] = "yyP"
lvim.keys.normal_mode["<C-x>"] = ":bd<CR>"
lvim.keys.normal_mode["<C-d>"] = "yyP"

-- keymaps for insert mode
lvim.keys.insert_mode["<C-d>"] = "<Esc>yyPi"
lvim.keys.insert_mode["<C-d>"] = "<Esc>yyPi"

-- keymaps with leader key
lvim.leader = "space"
lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }
lvim.builtin.which_key.mappings["R"] = { ":Telescope oldfiles<CR>", "Recent Files" }
