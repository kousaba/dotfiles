local function get_clip_cmd()
  if vim.fn.executable('pbcopy') == 1 then
    return 'pbcopy'
  elseif vim.fn.executable('wl-copy') == 1 then
    return 'wl-copy'
  elseif vim.fn.executable('xsel') == 1 then
    return 'xsel --clipboard --input'
  elseif vim.fn.executable('clip.exe') == 1 then
    return 'clip.exe'
  end
  return nil
end

vim.api.nvim_create_user_command('AcCopy', function()
  local clip_cmd = get_clip_cmd()
  if not clip_cmd then return end

  -- 1. 現在のエディタの全行を取得
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local final_lines = {}
  local lib_content = nil

  -- 2. 自作ライブラリ (kousaba-lib) の場所を特定して読み込む
  -- ~/cp/lib/src/lib.rs を想定
  local home = os.getenv("HOME")
  local lib_path = home .. "/cp/lib/src/lib.rs"
  local f = io.open(lib_path, "r")
  if f then
    lib_content = f:read("*all")
    f:close()
  else
    print("❌ Library not found at: " .. lib_path)
    return
  end

  -- 3. 行を走査して、use kousaba_lib... を書き換える
  -- 自作ライブラリの中身を最初に埋め込む
  table.insert(final_lines, "pub mod kousaba_lib {")
  for line in lib_content:gmatch("([^\n]*)\n?") do
    -- ライブラリ内の crate:: を kousaba_lib:: に書き換える必要がある場合の処理
    local processed_line = line:gsub("crate::", "self::")
    table.insert(final_lines, "    " .. processed_line)
  end
  table.insert(final_lines, "}")

  -- 元のファイルの各行を処理
  for _, line in ipairs(lines) do
    -- use kousaba_lib... の行はスキップ（既に埋め込んだので）
    if not line:match("^use kousaba_lib") then
      -- crate:: 呼び出しがあれば self:: または kousaba_lib:: に読み替え
      -- (単純なケースならそのまま)
      table.insert(final_lines, line)
    end
  end

  -- 4. クリップボードに送る
  local final_text = table.concat(final_lines, "\n")
  local pipe = io.popen(clip_cmd, "w")
  if pipe then
    pipe:write(final_text)
    pipe:close()
    print("✅ Successfully bundled kousaba-lib and copied to clipboard!")
  else
    print("❌ Failed to pipe to clipboard")
  end
end, {})

vim.keymap.set('n', '<leader>y', ':AcCopy<CR>', { silent = true })
