return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function lsp_status()
        local msg = 'No Active LSP'
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
      require("lualine").setup({
        options = {
          theme = "catppuccin",
          component_separators = {
            left = '',
            right = ''
          },
          section_separators = {
            left = '', right = ''
          },
          globalstatus = true
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = {
            'branch',
            { 'diff', symbols = { added = ' ', modified = ' ', removed = ' ' } },
            { 'diagnostics', sources = { 'nvim_diagnostic' } }
          },
          lualine_c = {
            { 'filename', path = 1 },
          },
          lualine_x = {
            {
              function()
                local reg = vim.fn.reg_recording()
                if reg == "" then return "" end
                return "󰑊 Recording @" .. reg
              end,
              color = { fg = "ff9e64" },
            },
            'encoding',
            'fileformat',
            'filetype',
          },
          lualine_y = {
            { lsp_status, icon = ' LSP:', color = { fg = '#ffffff', gui = 'bold' } }
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
        transparent_background = true,
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
