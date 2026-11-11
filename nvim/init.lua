-- nvim/init.lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- プロファイルの初期化
_G.DotProfile = require("config.profile")

require("config.atcoder")
require("config.lazy")
require("config.normal")
require("config.options")
