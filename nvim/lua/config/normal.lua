vim.opt.hlsearch = true                         -- 自動でハイライトを消す
vim.opt.completeopt = { "menuone", "noselect" } -- 補完窓の挙動
vim.opt.hidden = true                           -- バッファを切り替えるときに保存していなくてもよくする
vim.opt.cmdheight = 0                           -- コマンドラインの高さ
vim.opt.timeoutlen = 300                        -- 入力待ち時間(一つのコマンドの)

-- ビジュアルモードで連続してインデントを変える
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- 行の入れ替え
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==")
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==")
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- 検索語を画面中央に表示
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- 削除時にクリップボードの汚染を防ぐ
-- 既存の normal.lua のクリップボード設定部分に追記・修正:
if _G.DotProfile.env == "cloud" or os.getenv("SSH_CONNECTION") then
  -- OSC 52を利用してリモート先の Neovim からローカルのクリップボードへヤンクを届ける
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
else
  vim.opt.clipboard = "unnamedplus"
end

vim.opt.number = true                                                   -- 行番号
vim.opt.relativenumber = true                                           -- 相対行番号
vim.opt.cursorline = true                                               -- カーソル行ハイライト
vim.opt.laststatus = 3                                                  -- ステータスラインを常に表示
vim.opt.signcolumn = "yes"                                              -- サインカラムを常に表示
vim.opt.termguicolors = true                                            -- 24bitカラー対応
vim.opt.showcmd = true                                                  -- 入力中のコマンドを表示
vim.opt.title = true                                                    -- タイトルをターミナルのウィンドウ名に繁栄
vim.opt.scrolloff = 8                                                   -- スクロール時に上下に確保する行数
vim.opt.sidescrolloff = 8
vim.opt.expandtab = true                                                -- タブをスペースに変換
vim.opt.tabstop = 2                                                     -- タブ幅
vim.opt.shiftwidth = 2                                                  -- 自動インデントの幅
vim.opt.softtabstop = 2                                                 -- 連続した空白についてTabやBSで移動する幅
vim.opt.ignorecase = true                                               -- 検索で大文字小文字の区別をなくす
vim.opt.smartcase = true                                                -- 大文字が含まれていたら区別
vim.opt.hlsearch = true                                                 -- 検索結果をハイライト
vim.opt.incsearch = true                                                -- 入力中から検索結果を表示
vim.opt.wrapscan = true                                                 -- 検索をファイルの末尾まで行ったら先頭に戻る
vim.opt.clipboard = "unnamedplus"                                       -- クリップボードをOSと同期
vim.opt.mouse = "a"                                                     -- マウス操作を有効化
vim.opt.backspace = { "indent", "eol", "start" }                        -- バックスペースで消せるもの
vim.opt.autoread = true                                                 -- 編集中のファイルが途中で変更されたらそれを反映する
vim.opt.swapfile = false                                                -- スワップファイルを作らない
vim.opt.undofile = true                                                 -- Undoの履歴をファイルに保存(エディタを閉じてもやり直しできる)
vim.opt.wildmenu = true                                                 -- コマンドラインモードでの保管を強化
vim.opt.showmatch = true                                                -- かっこを入力したときに対応するかっこを一瞬強調する
vim.opt.matchtime = 1
vim.opt.splitright = true                                               -- 新しいウィンドウを右側に置く
vim.opt.splitbelow = true                                               -- 新しいウィンドウを下側に置く
vim.keymap.set("n", "<Leader>w", ":w<CR>", { desc = "Save file" })      -- 保存をspace + w
vim.keymap.set("n", "<Esc><Esc>", ":nohlsearch<CR>", { silent = true }) -- Esc二回でハイライトを消す
vim.keymap.set("n", "j", "gj")                                          -- j,kを見た目上の行で移動
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "<C-h>", "<C-w>h")                                  -- ctrl + hjklでウィンドウ間を移動
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Split window right" }) -- ウィンドウ分割
vim.keymap.set("n", "<leader>s", "<cmd>split<CR>", { desc = "Split window below" })
vim.keymap.set("n", "<leader>q", "<cmd>close<CR>", { desc = "Close window" })        -- ウィンドウを閉じる
vim.keymap.set("n", "<C-right>", "<cmd>vertical resize +5<CR>")                      -- ウィンドウの幅を調整
vim.keymap.set("n", "<C-left>", "<cmd>vertical resize -5<CR>")
vim.keymap.set("n", "<C-up>", "<cmd>resize +5<CR>")
vim.keymap.set("n", "<C-down>", "<cmd>resize -5<CR>")
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" }) -- エラー内容表示
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.asm", "*.s", "*.S" },
  callback = function()
    vim.bo.filetype = "asm"
    vim.g.asmsyntax = "nasm" -- Intel(NASM)記法のシンタックスを適用
  end,
})
