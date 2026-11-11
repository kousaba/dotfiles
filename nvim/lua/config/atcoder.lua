-- nvim/lua/config/atcoder.lua
local profile = _G.DotProfile

local function copy_to_clipboard(text)
  -- 1. クラウド/SSH環境、またはGUIクリップボードコマンドが無い場合はOSC 52で送信
  if profile.env == "cloud" or os.getenv("SSH_CONNECTION") then
    -- Neovim 0.10+ のビルトイン OSC 52 コピー
    vim.fn.setreg('+', text)
    print("✅ [OSC52] Bundled and copied to local clipboard!")
    return
  end

  -- 2. ローカル環境のネイティブコマンド判別
  local clip_cmd = nil
  if vim.fn.executable('pbcopy') == 1 then
    clip_cmd = 'pbcopy'
  elseif vim.fn.executable('wl-copy') == 1 then
    clip_cmd = 'wl-copy'
  elseif vim.fn.executable('xsel') == 1 then
    clip_cmd = 'xsel --clipboard --input'
  elseif vim.fn.executable('clip.exe') == 1 then
    clip_cmd = 'clip.exe'
  end

  if clip_cmd then
    local pipe = io.popen(clip_cmd, "w")
    if pipe then
      pipe:write(text)
      pipe:close()
      print("✅ Successfully bundled kousaba-lib and copied to clipboard!")
      return
    end
  end

  -- フォールバック: レジスタに直接格納
  vim.fn.setreg('+', text)
  print("✅ Copied to register '+'")
end

vim.api.nvim_create_user_command('AcCopy', function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local final_lines = {}
  local home = os.getenv("HOME")
  local lib_path = home .. "/cp/lib/src/lib.rs"

  local f = io.open(lib_path, "r")
  if f then
    local lib_content = f:read("*all")
    f:close()

    table.insert(final_lines, "pub mod kousaba_lib {")
    for line in lib_content:gmatch("([^\n]*)\n?") do
      local processed_line = line:gsub("crate::", "self::")
      table.insert(final_lines, "    " .. processed_line)
    end
    table.insert(final_lines, "}")
  else
    -- ライブラリが見つからない環境（クラウド等）でも単体ファイルをコピーできるように警告のみ
    print("⚠️ Library not found at " .. lib_path .. " (copying current buffer only)")
  end

  for _, line in ipairs(lines) do
    if not line:match("^use kousaba_lib") then
      table.insert(final_lines, line)
    end
  end

  copy_to_clipboard(table.concat(final_lines, "\n"))
end, {})

vim.keymap.set('n', '<leader>y', ':AcCopy<CR>', { silent = true })
