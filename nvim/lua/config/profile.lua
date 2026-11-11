-- nvim/lua/config/profile.lua
local default_profile = {
  spec = "high",        -- "high" | "low"
  env = "local",        -- "local" | "cloud"
  has_nerd_font = true, -- true | false
  has_sudo = true,
}

local home = os.getenv("HOME")
local profile_path = home .. "/.config/dotfiles/profile.lua"

local ok, profile = pcall(dofile, profile_path)
if ok and type(profile) == "table" then
  return vim.tbl_deep_extend("force", default_profile, profile)
else
  return default_profile
end
