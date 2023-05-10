vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.relativenumber = true

-- general
lvim.log.level = "info"
lvim.format_on_save = {
  enabled = true,
  pattern = "*.lua",
  timeout = 1000,
}

lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

lvim.builtin.which_key.mappings["f"] = {
  function()
    require("lvim.core.telescope.custom-finders").find_project_files { previewer = true }
  end,
  "Find File",
}

lvim.builtin.telescope.theme = "center";
lvim.builtin.telescope.defaults.vimgrep_arguments = {
  'rg',
  '--color=never',
  '--no-heading',
  '--with-filename',
  '--line-number',
  '--column',
  '--smart-case',
  '--ignore-file',
  '.gitignore',
  "--glob=!.git/",
}

lvim.builtin.telescope.defaults.file_ignore_patterns = {
  "^./.git/", "^node_modules/", "^vendor/"
}

lvim.builtin.telescope.pickers.find_files = {
  hidden = false,
  path_display = { "abslute" }
}

-- -- Change theme settings
-- lvim.colorscheme = "lunar"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

--
lvim.builtin.treesitter.auto_install = true

-- Disables the project mode: will be using folder mode.
lvim.builtin.project.active = false
lvim.builtin.lir.active = false

-- terminal
lvim.builtin["terminal"].execs = {
  { nil, "<leader>ta", "Horizontal Terminal", "horizontal", 0.3 },
  { nil, "<leader>tb", "Vertical Terminal",   "vertical",   0.4 },
  { nil, "<leader>tc", "Float Terminal",      "float",      nil },
}
