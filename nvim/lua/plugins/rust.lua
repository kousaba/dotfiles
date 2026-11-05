return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  config = function()
    vim.g.rustaceannvim = {
      tools = {
        float_win_config = {
          border = 'rounded',
        },
      },
      server = {
        cmd = function()
          return { "rustup", "run", "stable", "rust-analyzer" }
        end,
        on_attach = function(client, bufnr)
          vim.keymap.set("n", "<leader>ca", function() vim.cmd.RustLsp('codeAction') end,
            { desc = "CodeAction", buffer = bufnr })
          vim.keymap.set("n", "K", function() vim.cmd.RustLsp('hover', 'actions') end,
            { desc = "Hover Actions", buffer = bufnr })
        end,
        default_settings = {
          ['rust-analyzer'] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            diagnostics = { enable = true },
          },
        },
      },
    }
  end
}
