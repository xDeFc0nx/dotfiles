return {

    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.treesitter")
        end,
    },

    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvchad.configs.lspconfig").defaults()
            require("configs.lspconfig")
        end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-lspconfig" },
        config = function()
            require("configs.mason-lspconfig")
        end,
    },

    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.lint")
        end,
    },

    {
        "rshkarin/mason-nvim-lint",
        event = "VeryLazy",
        dependencies = { "nvim-lint" },
        config = function()
            require("configs.mason-lint")
        end,
    },

    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        config = function()
            require("configs.conform")
        end,
    },

    {
        "zapling/mason-conform.nvim",
        event = "VeryLazy",
        dependencies = { "conform.nvim" },
        config = function()
            require("configs.mason-conform")
        end,
    },
    {
        "wakatime/vim-wakatime",
        lazy = false,
        setup = function()
            vim.cmd([[packadd wakatime/vim-wakatime]])
        end,
    },
    {
        "andweeb/presence.nvim",
        lazy = false,
    },
    {
        "xiyaowong/transparent.nvim",
        lazy = false,
        groups = { -- table: default groups
            "Normal",
            "NormalNC",
            "Comment",
            "Constant",
            "Special",
            "Identifier",
            "Statement",
            "PreProc",
            "Type",
            "Underlined",
            "Todo",
            "String",
            "Function",
            "Conditional",
            "Repeat",
            "Operator",
            "Structure",
            "LineNr",
            "NonText",
            "SignColumn",
            "CursorLine",
            "CursorLineNr",
            "StatusLine",
            "StatusLineNC",
            "EndOfBuffer",
            "TSComment",
            "TSConstant",
            "TSKeyword",
            "TSString",
            "TSFunction",
            "TSVariable",
            "TSOperator",
            "TSParameter",
        },
        extra_groups = {
            "NormalFloat", -- plugins which have float panel such as Lazy, Mason, LspInfo
            "NvimTreeNormal", -- NvimTree
        }, -- table: additional groups that should be cleared
        exclude_groups = {}, -- table: groups you don't want to clear
    },
    {
        "Jezda1337/nvim-html-css",
        opts = {
            sources = {
                {
                    name = "html-css",
                    option = {
                        enable_on = { "html" }, -- html is enabled by default
                        notify = false,
                        documentation = {
                            auto_show = true, -- show documentation on select
                        },
                        -- add any external scss like one below
                        style_sheets = {
                            "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
                            "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",
                            "https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css", -- Tailwind CSS CDN
                        },
                    },
                },
            },
        },
    },
}
