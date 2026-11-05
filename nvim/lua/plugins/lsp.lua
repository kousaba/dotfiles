return {
  -- LSP 本体の設定
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        -- 1. asm_lsp を追加
        ensure_installed = { "lua_ls", "clangd", "jdtls", "asm_lsp" },
      })

      -- 共通キーバインド設定 (LspAttach)
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

      -- 保存時に自動整形
      vim.api.nvim_create_autocmd("BufWritePre", {
        -- アセンブリの拡張子 (.s, .asm) も追加しておくと便利です
        pattern = { "*.lua", "*.cpp", "*.c", "*.java", "*.s", "*.S", "*.asm" },
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- --- 各言語の設定 ---

      -- Lua
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })
      vim.lsp.enable('lua_ls')

      -- C++
      vim.lsp.config('clangd', { capabilities = capabilities })
      vim.lsp.enable('clangd')

      -- Java
      vim.lsp.config('jdtls', {
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { "pom.xml", "gradle.build", ".git" }),
      })
      vim.lsp.enable('jdtls')

      -- 2. Assembly (asm_lsp) の設定を追加
      vim.lsp.config('asm_lsp', {
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { ".git", ".asm_lsp.toml" }),
        filetypes = { "asm", "s", "S" },
        settings = {
          assembler = "nasm",
          instruction_set = "x86",
        },
      })

      -- 3. python
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
      -- 4. 有効化
      vim.lsp.enable('pyright')
      vim.lsp.enable('asm_lsp')
    end,
  },
}
