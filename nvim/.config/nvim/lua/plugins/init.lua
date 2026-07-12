return {

	{
		"christoomey/vim-tmux-navigator",
		-- init = function()
		-- 	vim.g.tmux_navigator_no_mappings = 1
		-- end,
		-- config = function()
		-- 	vim.keymap.set("n", "<leader>h", "<cmd>TmuxNavigateLeft<CR>")
		-- 	vim.keymap.set("n", "<leader>j", "<cmd>TmuxNavigateDown<CR>")
		-- 	vim.keymap.set("n", "<leader>k", "<cmd>TmuxNavigateUp<CR>")
		-- 	vim.keymap.set("n", "<leader>l", "<cmd>TmuxNavigateRight<CR>")
		-- end,
	},

	{
		"tpope/vim-fugitive",
		config = function()
			vim.keymap.set("n", "<leader>gg", "<cmd>Git<CR>")
			vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<CR>")
			vim.keymap.set("n", "<leader>gl", "<cmd>Git log --oneline<CR>")

			vim.keymap.set("n", "<leader>gP", "<cmd>Git push<CR>")
			vim.keymap.set("n", "<leader>gF", "<cmd>Git pull<CR>")
		end,
	},

	-- Gruvbox
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			require("gruvbox").setup({ contrast = "hard", transparent_mode = true })
			vim.cmd("colorscheme gruvbox")
		end,
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({ options = { theme = "gruvbox" } })
		end,
	},

	-- File tree
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup()
			vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
		end,
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = {
					"lua",
					"python",
					"kotlin",
					"javascript",
					"typescript",
					"bash",
					"html",
					"css",
					"json",
					"yaml",
					"markdown",
					"c",
					"cpp",
					"rust",
				},
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},

	-- Mason
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"pyright", -- Python
					"lua_ls", -- Lua
					"ts_ls", -- JS/TS
					"kotlin_language_server", -- Kotlin
					"html", -- HTML
					"cssls", -- CSS
					"rust_analyzer", -- Rust
					-- clangd is NOT installed via Mason, it comes from pacman
				},
				automatic_installation = true,
			})
		end,
	},

	-- LSP config (nvim 0.11 API)
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local caps = require("cmp_nvim_lsp").default_capabilities()

			-- Mason-managed servers
			local servers = {
				"pyright",
				"lua_ls",
				"ts_ls",
				"kotlin_language_server",
				"html",
				"cssls",
				"rust_analyzer",
			}
			for _, server in ipairs(servers) do
				vim.lsp.config(server, { capabilities = caps })
				vim.lsp.enable(server)
			end

			-- clangd from system (C/C++)
			vim.lsp.config("clangd", {
				capabilities = caps,
				cmd = { "clangd" },
				filetypes = { "c", "cpp", "objc", "objcpp" },
			})
			vim.lsp.enable("clangd")

			-- Keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, opts)
					vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
					vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				end,
			})
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping.select_next_item(),
					["<S-Tab>"] = cmp.mapping.select_prev_item(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},

	-- Formatter
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					python = { "black" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					-- html = { "prettier" },
					css = { "prettier" },
					lua = { "stylua" },
					kotlin = { "ktlint" },
					c = { "clang_format" },
					cpp = { "clang_format" },
					rust = { "rustfmt" },
				},
				format_on_save = { timeout_ms = 500, lsp_fallback = true },
			})
		end,
	},

	-- Fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					mappings = {
						i = { -- insert mode (default mode when Telescope opens)
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
						},
						n = { -- normal mode (after pressing <Esc> inside Telescope)
							["j"] = actions.move_selection_next,
							["k"] = actions.move_selection_previous,
						},
					},
				},
			})

			vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
			vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
			vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
		end,
	},

	-- Indent guides
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		config = function()
			require("ibl").setup()
		end,
	},

	-- Auto pairs
	{
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup()
		end,
	},

	-- Comment toggle
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- Gitsigns
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,
				current_line_blame_opts = {
					delay = 300,
					virt_text_pos = "eol",
				},
				current_line_blame_formatter = "   <author> • <author_time:%R> • <summary>",
			})

			-- Custom blame highlight: Gruvbox yellow, italic
			vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", {
				fg = "#d79921", -- Gruvbox yellow
				italic = true,
			})

			vim.keymap.set("n", "<leader>gs", ":Gitsigns toggle_signs<CR>")
			vim.keymap.set("n", "<leader>gb", ":Gitsigns toggle_current_line_blame<CR>")
			vim.keymap.set("n", "]c", ":Gitsigns next_hunk<CR>")
			vim.keymap.set("n", "[c", ":Gitsigns prev_hunk<CR>")
			vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>")
		end,
	},

	-- Which-key
	{
		"folke/which-key.nvim",
		config = function()
			require("which-key").setup()
		end,
	},

	-- DAP (debugger)
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"jay-babu/mason-nvim-dap.nvim",
		},
		config = function()
			-- Auto-install codelldb via Mason
			require("mason-nvim-dap").setup({
				ensure_installed = { "codelldb" },
				automatic_installation = true,
			})

			local dap = require("dap")
			local dapui = require("dapui")

			-- Adapter
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- C (and C++) launch config
			dap.configurations.c = {
				{
					name = "Launch",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					initCommands = { "breakpoint set --name main" },
					args = {},
				},
			}
			dap.configurations.cpp = dap.configurations.c

			-- UI setup
			dapui.setup()

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Keymaps
			local map = vim.keymap.set
			map("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
			map("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP breakpoint" })
			map("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
			map("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
			map("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
			map("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })
			map("n", "<leader>dq", dap.terminate, { desc = "DAP terminate" })
		end,
	},
	-- lazy.nvim
	{ "tpope/vim-obsession" },
}
