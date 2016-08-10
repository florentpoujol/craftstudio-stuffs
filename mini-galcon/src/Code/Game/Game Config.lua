
function Daneel.UserConfig()
    return {
        scriptPaths = {
            ship = "Game/Ship"
        },
        
        textRenderer = {
            font = "Calibri",
            alignment = "left",
        },
        
        debug = {
            enableDebug = true, -- Enable/disable Daneel's global debugging features (error reporting + stacktrace).
            enableStackTrace = true, -- Enable/disable the Stack Trace.
        },
    }
end


Game = {
    difficulty = 15,
    camera = nil,
    
    shipCount = 0,
    shipSpeed = 4, -- units per second
    
    -- planets
    selectedPlanets = {},
    selectionPlane = nil,
    selectionBox = nil,
    
    planetCount = 10, -- modified by the input in the main menu
    planetProductionSpeed = 2, -- 2 ships per second
    maxShipSpawnPerFrame = 1,
    planetSafeZoneModifier = 2, -- modifier for the planet's scale to create an area where no other planets can be created, in order to prevent overlaping
    
    --
    playerTeam = 2,
    enemyTeam = 1,
    
    -- corespondance between the font tile ID and the character that actually makes the TextRenderer render this tile
    spriteID_to_char = {
        " ", 
        "!",
        '"',
        "#",
        "$",
        "%",
        "&",
    },
    
    char_to_spriteID = {
        [" "] = 1, -- neutral team
        ["!"] = 2, -- 2, 3, 4 = teams
        ['"'] = 3,
        ["#"] = 4,
        ["$"] = 5, -- rounded outline (not used)
        ["%"] = 6, -- squared outline
        ["&"] = 7,
    },
}
