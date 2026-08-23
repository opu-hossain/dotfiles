vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true

vim.g.mapleader = " "
vim.g.localmapleader = " "
vim.opt.tags = "./tags;,tags"

-- custom remaps
vim.keymap.set("n", "<leader>fd", vim.cmd.Ex)

-- Clear highlights with the Escape key
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- visual block mode with just block
vim.keymap.set("n", "b", "<C-v>")

-- Splitting (tmux-style: intuitive single-key creation)
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>")
vim.keymap.set("n", "<leader>sh", "<cmd>split<CR>")
vim.keymap.set("n", "<leader>sc", "<cmd>close<CR>")
vim.keymap.set("n", "<leader>so", "<cmd>only<CR>")

-- Resizing (tmux-style: repeatable, intuitive direction)
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<CR>")
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<CR>")
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize -2<CR>")
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize +2<CR>")
