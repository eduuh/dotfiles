vim.opt.shell = "pwsh.exe -NoLogo"
vim.opt.shellcmdflag =
  "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
vim.cmd [[
		let &shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
		let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
		set shellquote= shellxquote=
  ]]

vim.g.clipboard = {
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = "win32yank.exe -i --crlf",
  },
  paste = {
    ["+"] = "win32yank.exe -o --lf",
    ["*"] = "win32yank.exe -o --lf",
  },
}

-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = false
lvim.colorscheme = "lunar"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<BS>"] = "<C-^>"
vim.keymap.set("v", "N", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "E", ":m '>+1<CR>gv=gv")
vim.keymap.set("n","<C-p>",":lua require('telescope.builtin').find_files({ hidden=false , no_ignore=false, no_ignore_parent=true })<CR>")

local opts = { noremap = true, silent = true }
-- quick fix list
vim.keymap.set("n","<S-n>",":cnext<CR>",opts)
vim.keymap.set("n","<S-p>",":cprev<CR>",opts)

local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
  -- for input mode
  i = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
    ["<C-n>"] = actions.cycle_history_next,
    ["<C-p>"] = actions.cycle_history_prev,
  },
  -- for normal mode
  n = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
  },
}

lvim.builtin.which_key.mappings["f"] = {
  function()
    require("lvim.core.telescope.custom-finders").find_project_files { previewer = false }
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
  path_display = {"absolute"}
}

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = true
lvim.builtin.nvimtree.setup.manual_mode = true
-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
  "scss",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true


lvim.lsp.installer.setup.ensure_installed = {
    "jsonls",
    "cssls",
    "tsserver",
}


lvim.plugins = {
 { "wellle/targets.vim"},
 { 'wakatime/vim-wakatime'},
 { 'github/copilot.vim'},
  {"turbio/bracey.vim"},
  {"rest-nvim/rest.nvim"}
}


