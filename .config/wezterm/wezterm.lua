-- Pick an image
local image = "solen-feyissa-aQHilAxwPHk-unsplash.jpg"
-- Path env var is HOME on unix and HOMEPATH on windows
local home = os.getenv( "HOME" ) or os.getenv( "HOMEPATH" )
local fullPath = home .. "/.config/wezterm/backgrounds/" .. image
return {
    background = {
        {
            source = { File = fullPath, },
            hsb = { brightness = 0.01 },
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            height = "Cover",
            horizontal_align = "Right",
        }
    },
}
