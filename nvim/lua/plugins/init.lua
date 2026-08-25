return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
  },

  -- Smooth scrolling
  {
    "karb94/neoscroll.nvim",
    config = function()
      require("neoscroll").setup({
        mappings = { "<C-u>", "<C-d>", "<C-f>", "zt", "zz", "zb" },
        hide_cursor = true,
        stop_eof = true,
        cursor_scrolls_alone = true,
        duration_multiplier = 1.0,
        easing = "quadratic",
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/" },
          preview = false,
        },
      })

      -- Load fzf extension for better performance
      pcall(telescope.load_extension, "fzf")

      -- Keymaps
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
    end,
  },

  -- Flash: quick jumps with labels
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "]h", gs.next_hunk, opts)
          vim.keymap.set("n", "[h", gs.prev_hunk, opts)
          vim.keymap.set("n", "<leader>hp", gs.preview_hunk, opts)
          vim.keymap.set("n", "<leader>hs", gs.stage_hunk, opts)
          vim.keymap.set("n", "<leader>hr", gs.reset_hunk, opts)
          vim.keymap.set("n", "<leader>hd", gs.diffthis, opts)
        end,
      })
    end,
  },

  -- Unified (single-panel) git diff viewer with treesitter highlighting
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "CodeDiff: changed files" },
    },
    opts = {
      diff = {
        layout = "inline",      -- single pane, +/- style; press `t` for side-by-side
        gutter_signs = true,
        jump_to_first_change = true,
        highlight_priority = 100,
        cycle_hunks_across_files = true, -- ]c/[c walks hunks across file boundaries
      },
      explorer = {
        hidden = true,          -- file list starts collapsed; <leader>tb shows it
        initial_focus = "modified",
        position = "left",
        width = 32,
        view_mode = "tree",
        indent_markers = true,
        icons = { folder_closed = "+", folder_open = "-" },
      },
      keymaps = {
        view = {
          -- defaults <leader>b / <leader>e collide with <leader>bd and neo-tree
          toggle_explorer = "<leader>tb",
          focus_explorer = "<leader>te",
        },
      },
    },
    config = function(_, opts)
      require("codediff").setup(opts)

      -- Workaround for an upstream bug (codediff e08a35a): navigate_next and
      -- navigate_prev call nvim_win_is_valid(explorer.winid) unguarded, but
      -- winid is nil while the explorer is hidden -- so ]f and ]c crossing a
      -- file boundary error out with "Invalid 'window'". -1 is never a valid
      -- window, so the check just returns false as intended. Drop this once
      -- upstream adds the nil guard it already has elsewhere in that file.
      -- explorer/init.lua re-exports these by value, so patch both tables.
      local actions = require("codediff.ui.explorer.actions")
      local explorer_mod = require("codediff.ui.explorer")
      for _, name in ipairs({ "navigate_next", "navigate_prev" }) do
        local original = actions[name]
        local patched = function(explorer)
          if explorer then
            explorer.winid = explorer.winid or -1
          end
          return original(explorer)
        end
        actions[name] = patched
        explorer_mod[name] = patched
      end
    end,
  },

  -- Treesitter: better syntax highlighting and code understanding
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- On the `main` branch highlighting is opt-in per buffer; markdown (and the
      -- code blocks inside it) needs it for render-markdown.nvim to look right.
      -- The markdown/markdown_inline parsers ship with Neovim, so no :TSInstall.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  -- In-buffer markdown rendering (headings, tables, code blocks, checkboxes)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown", "md" },
    keys = {
      { "<leader>m", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown rendering" },
    },
    opts = {
      -- ASCII / plain-Unicode icons: this setup deliberately avoids Nerd Fonts
      heading = {
        sign = false,
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
      },
      code = {
        sign = false,
        language_icon = false,
        width = "block",
        min_width = 60,
        left_pad = 2,
        right_pad = 2,
      },
      bullet = {
        icons = { "•", "◦", "▸", "▪" },
      },
      checkbox = {
        unchecked = { icon = "[ ]" },
        checked = { icon = "[x]" },
      },
      dash = { icon = "─" },
      quote = { icon = "▌" },
      link = {
        image = "",
        email = "",
        hyperlink = "",
      },
      -- needs the latex2text CLI; off by default here
      latex = { enabled = false },
    },
  },

  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  {
    "seblyng/roslyn.nvim",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
        -- your configuration comes here; leave empty for default settings
    },
  },

  -- Mason: installs language servers automatically
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ensure_installed = {
          "roslyn", -- .NET (custom registry)
        },
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })
    end,
  },

  -- Bridge between mason and lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",   -- Python
        },
        automatic_installation = true,
      })
    end,
  },

  -- LSP Configuration (Neovim 0.11+ API)
  {
    "neovim/nvim-lspconfig",
    dependencies = { "mason-lspconfig.nvim", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Configure language servers using vim.lsp.config (Neovim 0.11+)
      vim.lsp.config["pyright"] = {
        capabilities = capabilities,
      }
      vim.lsp.config["roslyn"] = {
        capabilities = capabilities,
      }

      -- Enable configured servers
      vim.lsp.enable({ "pyright", "roslyn" })

      -- Keymaps for LSP (activate when LSP attaches to buffer)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",     -- LSP completions
      "hrsh7th/cmp-buffer",       -- Buffer completions
      "hrsh7th/cmp-path",         -- Path completions
      "L3MON4D3/LuaSnip",         -- Snippet engine (required)
      "saadparwaiz1/cmp_luasnip", -- Snippet completions
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
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

  -- File tree sidebar
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
      { "<leader>o", "<cmd>Neotree reveal<cr>", desc = "Reveal current file in tree" },
    },
    opts = {
      close_if_last_window = true,
      enable_git_status = true,
      -- Plain ASCII instead of Nerd Font glyphs
      default_component_configs = {
        icon = {
          folder_closed = "+",
          folder_open = "-",
          folder_empty = "+",
          default = " ",
        },
        modified = { symbol = "[+]" },
        indent = {
          with_expanders = true,
          expander_collapsed = ">",
          expander_expanded = "v",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            added = "A",
            modified = "M",
            deleted = "D",
            renamed = "R",
            untracked = "?",
            ignored = "I",
            unstaged = "U",
            staged = "S",
            conflict = "C",
          },
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
        },
      },
      window = {
        width = 32,
      },
    },
  },
}
