-- Pick an image
local image = "bandit_maggie_tech.png"
-- Path env var is HOME on unix and HOMEPATH on windows
local home = os.getenv( "HOME" ) or os.getenv( "HOMEPATH" )
local fullPath = home .. "/.config/wezterm/backgrounds/" .. image
-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.font = wezterm.font_with_fallback {
  'JetBrains Mono',
  'Fira Mono',
}

config.background = {
    {
        source = { File = fullPath, },
        hsb = {
            brightness = 0.03,
            hue = 1.2,
            saturation = 1.3,
        },
        repeat_x = "NoRepeat",
        repeat_y = "NoRepeat",
        height = "Cover",
        horizontal_align = "Center",
    }
}

local launch_menu = {}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	config.default_prog = { "cmd.exe ", "/k", "C:\\Program Files\\Git\\bin\\bash.exe" }
end

config.launch_menu = launch_menu

config.color_scheme = "Dracula (Official)"
config.use_fancy_tab_bar = false

return config
