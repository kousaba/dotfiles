-- nvim/lua/plugins/neo-tree.lua
local profile = _G.DotProfile

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { silent = true })

    -- アイコン文字のフォールバック
    local symbols = profile.has_nerd_font and {
      added     = "✚",
      modified  = "",
      deleted   = "✖",
      renamed   = "󰁔",
      untracked = "",
      ignored   = "",
      unstaged  = "󰄱",
      staged    = "",
      conflict  = "",
    } or {
      added     = "+",
      modified  = "*",
      deleted   = "d",
      renamed   = "r",
      untracked = "?",
      ignored   = "!",
      unstaged  = "u",
      staged    = "s",
      conflict  = "c",
    }

    require("neo-tree").setup({
      window = {
        position = "left",
        width = 30,
        mappings = {
          ["<space>"] = "none",
          ["l"] = "open",
          ["h"] = "close_node",
        },
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      default_component_configs = {
        icon = {
          enabled = profile.has_nerd_font,
        },
        symbols = symbols,
      }
    })

    -- High スペック時のみ起動時に自動表示
    if profile.spec == "high" then
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.cmd("Neotree show")
        end
      })
    end

    -- 最後のウィンドウがNeo-treeなら終了
    vim.api.nvim_create_autocmd("BufEnter", {
      group = vim.api.nvim_create_augroup("NeoTreeAutoQuit", { clear = true }),
      callback = function()
        local stats = vim.api.nvim_list_wins()
        if #stats == 1 then
          local ft = vim.bo[vim.api.nvim_win_get_buf(stats[1])].filetype
          if ft == "neo-tree" then
            vim.cmd("quit")
          end
        end
      end,
    })
  end
}
