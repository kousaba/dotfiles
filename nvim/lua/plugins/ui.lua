-- nvim/lua/plugins/ui.lua
local profile = _G.DotProfile

return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    enabled = profile.has_nerd_font, -- Nerd Fontsがない場合はロードしない
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function lsp_status()
        local msg = 'No LSP'
        local buf_ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if next(clients) == nil then return msg end
        for _, client in ipairs(clients) do
          local filetypes = client.config.filetypes
          if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
            return client.name
          end
        end
        return msg
      end

      -- アイコンの有無でセパレータと記号を切り替え
      local component_sep = profile.has_nerd_font and { left = '', right = '' } or { left = '|', right = '|' }
      local section_sep   = profile.has_nerd_font and { left = '', right = '' } or { left = '', right = '' }
      local diff_symbols  = profile.has_nerd_font
          and { added = ' ', modified = ' ', removed = ' ' }
          or { added = '+', modified = '~', removed = '-' }

      require("lualine").setup({
        options = {
          theme = "catppuccin",
          icons_enabled = profile.has_nerd_font,
          component_separators = component_sep,
          section_separators = section_sep,
          globalstatus = true
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            'branch',
            { 'diff',        symbols = diff_symbols },
            { 'diagnostics', sources = { 'nvim_diagnostic' } }
          },
          lualine_c = {
            { 'filename', path = 1 },
          },
          lualine_x = {
            'encoding',
            'fileformat',
            'filetype',
          },
          lualine_y = {
            { lsp_status, icon = (profile.has_nerd_font and ' LSP:' or 'LSP:') }
          },
          lualine_z = { 'progress', 'location' },
        },
      })
    end
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = (profile.env == "local"), -- クラウド/SSH時はコントラスト確保のため黒背景に
        integrations = {
          neotree = true,
          treesitter = true,
          gitsigns = true,
          telescope = true,
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
