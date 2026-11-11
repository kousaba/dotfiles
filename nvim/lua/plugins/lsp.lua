-- nvim/lua/plugins/lsp.lua
local profile = _G.DotProfile

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()

      -- スペックに応じて自動インストールするLSPを制限
      local ensure_installed = {}
      if profile.spec == "high" then
        ensure_installed = { "lua_ls", "clangd", "jdtls", "asm_lsp", "pyright" }
      else
        -- Low スペック時は頻度の高いもの最小限に留める
        ensure_installed = { "lua_ls" }
      end

      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
      })

      -- 共通キーバインド
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
        end,
      })

      -- 保存時自動整形（Lowスペック時は動作を軽くするため必要最低限に）
      if profile.spec == "high" then
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = { "*.lua", "*.cpp", "*.c", "*.java", "*.s", "*.S", "*.asm", "*.py" },
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- 各言語サーバーの初期化
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })
      vim.lsp.enable('lua_ls')

      -- Highスペック時のみ追加LSPをアクティブ化
      if profile.spec == "high" then
        vim.lsp.config('clangd', { capabilities = capabilities })
        vim.lsp.enable('clangd')

        vim.lsp.config('jdtls', {
          capabilities = capabilities,
          root_dir = vim.fs.root(0, { "pom.xml", "gradle.build", ".git" }),
        })
        vim.lsp.enable('jdtls')

        vim.lsp.config('asm_lsp', {
          capabilities = capabilities,
          root_dir = vim.fs.root(0, { ".git", ".asm_lsp.toml" }),
          filetypes = { "asm", "s", "S" },
          settings = { assembler = "nasm", instruction_set = "x86" },
        })
        vim.lsp.enable('asm_lsp')

        vim.lsp.config('pyright', {
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        })
        vim.lsp.enable('pyright')
      end
    end,
  },
}
