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
    require("neo-tree").setup({
      window = {
        position = "left",
        width = 30,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
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
          hide_by_name = {
            ".git",
            "thumbs.db",
            "node_modules",
          },
        },
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },
        use_libuv_file_matcher = true,
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
        },
        symbols = {
          added     = "✚",
          modified  = "",
          deleted   = "✖",
          renamed   = "󰁔",
          untracked = "",
          ignored   = "",
          unstaged  = "󰄱",
          staged    = "",
          conflict  = "",
        },
      }
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd("Neotree show")
      end
    })
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
