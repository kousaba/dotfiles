return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, {}) -- ファイル名検索
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {}) -- 全ファイル中身検索
    vim.keymap.set('n', '<leader>fb', builtin.buffers, {})  -- 開いているバッファ検索
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, {}) -- ヘルプ検索
  end
}
