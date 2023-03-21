-- Path env var is HOME on unix and HOMEPATH on windows
local home = os.getenv( "HOME" ) or os.getenv( "HOMEPATH" )
local fullPath = home .. "/.config/wezterm/space-astronaut.jpg"
local wezterm = require 'wezterm'
local gpus = wezterm.gui.enumerate_gpus()
return {
    webgpu_preferred_adapter = gpus[2],
    front_end = 'WebGpu',
    background = {
        {
            source = { File = fullPath, },
            hsb = { brightness = 0.07 },
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            height = "Cover",
            horizontal_align = "Right",
        }
    },
}
