
CS.Screen.SetSize(900, 506) -- 1.78 = 16:9   840x470

Game = {
    levelToLoad = nil, -- set in [Level Cartridge/SetData levelNameGO OnClick event]
    deletedLinkCount = 0, -- updated in [Connection/OnClick], used in [Level Master/EndLevel]
    backgroundNextColorId = 1,
}


AllowedConnectionsByColor= {
    Red = { "Red", "Orange", "Purple", "White" },
    Yellow = { "Yellow", "Orange", "Green", "White" },
    Blue = { "Blue", "Green", "Purple", "White" },
    
    Orange = { "Orange", "Red", "Yellow", "White" },
    Green = { "Green", "Yellow", "Blue", "White" },
    Purple = { "Purple", "Red", "Blue", "White" },
    
    White = { "White", "Yellow", "Orange", "Red",  "Purple", "Blue", "Green"  },
}

SpecialColor = { White = true, Orange = true, Green = true,  Purple = true } -- their color is always used for the connections

-- " ", "!", '"', "#", "$", "%", "&", "'", "(", ")", "*", "+"
-- , - . / 0 à 9
TextByColor = {
    White = " ",
    Purple = "!",
    Green = '"',
    Orange = "#",
    Bleu = "$",
    Jaune = "%",
    Rouge = "&"
} -- or you can use the first letter of the color (upper case)
TextByColor = {
    White = "W",
    Purple = "P",
    Green = "G",
    Orange = "O",
    Blue = "B",
    Yellow = "Y",
    Red = "R"
}


Daneel.UserConfig = {
    debug = {
        enableDebug = false,
        enableStackTrace = false,
    }
}

