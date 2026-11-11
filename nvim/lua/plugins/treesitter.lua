-- nvim/lua/plugins/treesitter.lua
local profile = _G.DotProfile

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then return end

    -- Low スペック時は最低限のパーサのみDL
    local parsers = profile.spec == "low"
        and { "lua", "vim", "vimdoc", "bash" }
        or { "lua", "cpp", "java", "asm", "vim", "vimdoc", "query", "bash", "python", "rust" }

    configs.setup({
      ensure_installed = parsers,
      highlight = { enable = true },
      indent = { enable = (profile.spec == "high") }, -- Low時はインデント計算を省略
    })
  end,
}
