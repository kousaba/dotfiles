return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  enabled = (_G.DotProfile.spec == "high"), -- Low時は無効化
  config = function()
    require("todo-comments").setup()
    vim.keymap.set("n", "<leader>st", "<cmd>TodoTelescope<cr>")
  end
}
