return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  -- ファイルを開いたときに確実にロードされるようにする
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    -- pcall (Protected Call) を使って、モジュールがない場合にエラーで止まらないようにします
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then return end

    configs.setup({
      ensure_installed = { "lua", "cpp", "java", "asm", "vim", "vimdoc", "query", "bash" },
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    })
  end,
}
