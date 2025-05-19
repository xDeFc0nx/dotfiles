-- Setup installer & lsp configs
local mason = require("mason")
local mason_lsp = require("mason-lspconfig")
local ufo_utils = require("utils._ufo")
local ufo_config_handler = ufo_utils.handler
local lspconfig = require("lspconfig")

-- Require server-specific configuration files
-- Make sure these files exist in lua/config/lsp/servers/
local ts_ls_config = require("config.lsp.servers.tsserver")
local tailwindcss_config = require("config.lsp.servers.tailwindcss")
local cssls_config = require("config.lsp.servers.cssls")
local eslint_config = require("config.lsp.servers.eslint")
local jsonls_config = require("config.lsp.servers.jsonls")
local lua_ls_config = require("config.lsp.servers.lua_ls")
local vuels_config = require("config.lsp.servers.vuels")
local python_config = require("config.lsp.servers.python") -- Assuming pyright config is here

mason.setup({
  ui = {
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = EcoVim.ui.float.border or "rounded",
  },
})

-- Define common handlers (like signature help), capabilities, and on_attach *once*
-- Renamed 'handlers' to 'common_extra_handlers' for clarity in the new structure
local common_extra_handlers = {
  ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = EcoVim.ui.float.border }),
  -- Add other common handlers here if any
}

local common_capabilities = require('blink.cmp').get_lsp_capabilities()

local function common_on_attach(client, bufnr)
  -- Enable inlay hints globally for clients that support it
  if client.supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr })
  end
  -- Add any other logic you want to run for ALL attached LSP clients here
  -- For example, setting buffer-local keymaps that apply to all LSPs
  -- require("your_general_lsp_keymaps").setup(bufnr)
end

-- Global override for floating preview border - Keep this
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or EcoVim.ui.float.border or "rounded" -- default to EcoVim border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end
vim.lsp.util.open_floating_preview = vim.lsp.util.open_floating_preview


-- === THIS IS THE REPLACED PART ===
-- Configure mason-lspconfig.setup with the 'handlers' key.
-- This replaces the previous separate mason_lsp.setup and setup_handlers calls.
mason_lsp.setup({
  -- A list of servers to automatically install if they're not already installed
  ensure_installed = {
    "bashls",
    "cssls",
    "eslint",
    "graphql",
    "html",
    "jsonls",
    "lua_ls",
    "prismals",
    "tailwindcss",
    "denols",
    "gopls",
    "vuels",
    "pyright", -- Assuming you need pyright
    "zls", -- Included based on your last shared code, but can be removed if not needed
    -- Add any other language servers you need mason to install here
  },
  -- Whether servers that are set up (via lspconfig) should be automatically installed if they're not already installed.
  automatic_installation = true,

  -- Define handlers directly in the setup call under the 'handlers' key
  handlers = {
    -- Default handler for servers without a specific entry
    -- This will use the common on_attach, capabilities, and the extra handlers
    -- You can override any of these in the server-specific handlers below
    ["*"] = function(server_name)
      lspconfig[server_name].setup({
        on_attach = common_on_attach,      -- Use the common on_attach function
        capabilities = common_capabilities, -- Use the common capabilities
        handlers = common_extra_handlers,  -- Use the common extra handlers
        -- Server-specific settings should go in their dedicated handler functions below
      })
    end,

    -- Server-specific handlers.
    -- These functions will be called to setup the corresponding language server.
    -- Merge common settings with server-specific ones from config files.
    ["tsserver"] = function()
      -- Use vim.tbl_deep_extend to merge common_capabilities with any specific ones for tsserver/typescript-tools
      local tsserver_capabilities = vim.tbl_deep_extend('force', {}, common_capabilities, ts_ls_config.capabilities or {})

      -- Merge common extra handlers and handlers from tsserver config file
      local tsserver_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, ts_ls_config.handlers or {})

      require("typescript-tools").setup({
        capabilities = tsserver_capabilities,
        handlers = tsserver_handlers,
        on_attach = function(client, bufnr)
           common_on_attach(client, bufnr) -- Call the common on_attach first
           if ts_ls_config.on_attach then -- If the server config has its own on_attach, call it
             ts_ls_config.on_attach(client, bufnr)
           end
           -- Specific on_attach logic for tsserver (like which-key attachment)
           pcall(require("plugins.which-key.setup").attach_typescript, bufnr)
        end,
        settings = ts_ls_config.settings,
        root_dir = function(fname)
          return lspconfig.util.find_package_json_ancestor(fname) or vim.fn.getcwd()
        end,
        single_file_support = false
      })
    end,

    ["tailwindcss"] = function()
      -- TailwindCSS often has specific capabilities needed
      local tailwind_capabilities = vim.tbl_deep_extend('force', {}, common_capabilities, {
          textDocument = {
              completion = { completionItem = { snippetSupport = true } },
              colorProvider = { dynamicRegistration = false },
              foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
          },
      }, tailwindcss_config.capabilities or {})

      local tailwind_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, tailwindcss_config.handlers or {})

      lspconfig.tailwindcss.setup({
        capabilities = tailwind_capabilities,
        filetypes = tailwindcss_config.filetypes,
        handlers = tailwind_handlers,
        init_options = tailwindcss_config.init_options,
        on_attach = function(client, bufnr)
           common_on_attach(client, bufnr)
           if tailwindcss_config.on_attach then
             tailwindcss_config.on_attach(client, bufnr)
           end
        end,
        settings = tailwindcss_config.settings,
        flags = { debounce_text_changes = 1000 },
      })
    end,

    ["cssls"] = function()
      local cssls_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, cssls_config.handlers or {})
      lspconfig.cssls.setup({
        capabilities = common_capabilities,
        handlers = cssls_handlers,
        on_attach = function(client, bufnr)
           common_on_attach(client, bufnr)
           if cssls_config.on_attach then
             cssls_config.on_attach(client, bufnr)
           end
        end,
        settings = cssls_config.settings,
      })
    end,

    ["denols"] = function()
      local denols_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, require("config.lsp.servers.denols").handlers or {}) -- Assuming denols has a config file
      lspconfig.denols.setup({
        on_attach = common_on_attach,
        capabilities = common_capabilities,
        handlers = denols_handlers,
        root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
        settings = require("config.lsp.servers.denols").settings or {}, -- Assuming denols has a config file
      })
    end,

    ["eslint"] = function()
       local eslint_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, eslint_config.handlers or {})
       lspconfig.eslint.setup({
         capabilities = common_capabilities,
         handlers = eslint_handlers,
         on_attach = function(client, bufnr)
           common_on_attach(client, bufnr)
           if eslint_config.on_attach then
             eslint_config.on_attach(client, bufnr)
           end
         end,
         settings = eslint_config.settings,
         flags = {
           allow_incremental_sync = false,
           debounce_text_changes = 1000,
           exit_timeout = 1500,
         },
       })
    end,

    ["jsonls"] = function()
      local jsonls_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, jsonls_config.handlers or {})
      lspconfig.jsonls.setup({
        capabilities = common_capabilities,
        handlers = jsonls_handlers,
        on_attach = common_on_attach, -- jsonls_config doesn't seem to have a specific on_attach, use common
        settings = jsonls_config.settings,
      })
    end,

    ["lua_ls"] = function()
      local lua_ls_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, lua_ls_config.handlers or {})
      lspconfig.lua_ls.setup({
        capabilities = common_capabilities,
        handlers = lua_ls_handlers,
        on_attach = common_on_attach, -- lua_ls_config doesn't seem to have a specific on_attach, use common
        settings = lua_ls_config.settings,
      })
    end,

    ["vuels"] = function()
      local vuels_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, vuels_config.handlers or {})
      lspconfig.vuels.setup({
        filetypes = vuels_config.filetypes,
        handlers = vuels_handlers,
        init_options = vuels_config.init_options,
        on_attach = function(client, bufnr)
           common_on_attach(client, bufnr)
           if vuels_config.on_attach then
             vuels_config.on_attach(client, bufnr)
           end
        end,
        settings = vuels_config.settings,
      })
    end,

    ["pyright"] = function()
        -- Ensure python_config is loaded
        local pyright_handlers = vim.tbl_deep_extend('force', {}, common_extra_handlers, python_config.handlers or {})
        lspconfig.pyright.setup({
            on_attach = common_on_attach, -- Use common on_attach
            capabilities = common_capabilities, -- Use common capabilities
            handlers = pyright_handlers, -- Use common handlers
            settings = python_config.settings, -- Load pyright settings
            -- Add any pyright specific options here
        })
    end,
    -- If you need specific setup for 'bashls', 'graphql', 'html', 'json5', 'markdown', 'prisma', 'vim', 'zls',
    -- add dedicated handlers for them here. Otherwise, they will use the default `["*"]` handler.
  },
  -- === END OF REPLACED PART ===
})

-- UFO setup remains the same
require("ufo").setup({
  fold_virt_text_handler = ufo_config_handler,
  close_fold_kinds_for_ft = { default = { "imports" } },
})

