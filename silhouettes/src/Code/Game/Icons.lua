--[[PublicProperties
IconName string ""
/PublicProperties]]

local fontAwesome = CS.FindAsset("Font Awesome")

-- " ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+"
-- , - . / 0 à 9

fontAwesome.textByIconName = {
    users = " ",
    cog = "!",
    spin_white = '"',
    spin_black = "#",
    editor = "$",
    table = "%",
    caret = "&",
    home = "'",
    arrow_circle = "(",
    circle_white = ")",
    circle_blue = "*",
    user = "+",
    link = ",",
    calendar = "-",
    clock = ".",
    cube = "/",
    refresh = "0",
    caret_white = "1",
    check = "2",
}

function Behavior:Awake()
    local font = self.gameObject.textRenderer.font
    
    if font.textByIconName ~= nil then
        self.gameObject.textRenderer.text = font.textByIconName[ self.IconName ]
    else
        self.gameObject.textRenderer.font = "Calibri"
        self.gameObject.textRenderer.text = "~"
    end
end
