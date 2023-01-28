-- Path env var is HOME on unix and HOMEPATH on windows
local home = os.getenv( "HOME" ) or os.getenv( "HOMEPATH" )
local fullPath = home .. "/.config/wezterm/space-astronaut.jpg"
return {
    background = {
        {
            source = { File = fullPath, },
            hsb = { brightness = 0.07 },
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            height = "Cover",
            width = "Cover",
            horizontal_align = "Center",
        }
    }
}
