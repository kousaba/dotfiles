return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  config = function()
    require("ibl").setup({
      scope = { enabled = true, show_start = true },
    })
  end
}
