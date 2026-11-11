return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  enabled = (_G.DotProfile.spec == "high"), -- Low時は無効化
  config = function()
    require("ibl").setup({
      scope = { enabled = true, show_start = true },
    })
  end
}
