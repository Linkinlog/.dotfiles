Path = os.getenv("HOME") .. "/.config/wezterm/space-astronaut.jpg"
return {
    background = {
        {
            source = { File = Path, },
            hsb = { brightness = 0.07 },
            repeat_x = "NoRepeat",
            repeat_y = "NoRepeat",
            height = "Cover",
            width = "Cover",
            horizontal_align = "Center",
        }
    }
}
