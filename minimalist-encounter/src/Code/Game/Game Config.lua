

Game = {
    showMenu = true,
    
    menuGO = nil,
    hudGO = nil,
    hudBackground = nil,
    cameraGO = nil,
    scoreGO = nil,
    rockGO = nil,
    
    mapPlane = nil,
    
    enemySpawns = {},
    
    score = 0,
    rockReserve = 0,
       
    mouseControl = {
        actionInterval = 0.2,
    },
    
    rock = {
        scaleToRessourceRatio = 500,
        scoreModifier = 0.1, -- score won for every units of rock harvested
    },
    
    harvester = {
        harvestAmount = 3, -- amount of ressource taken by harvesters from rocks every second
        harvestEnergyCost = 0.5, -- amount of energy spend per second when harvesting
        range = 3,
        energyConstructionCost = 10,
        rockConstructionCost = 10,
        maxEnergyReserve = 5,
        score = 5,
        destructionPenalty = 5,
    },
    
    powerstation = {
        actionInterval = 1,
        range = 3,
        maxEnergyReserve = 3,
        energyConstructionCost = 10,
        rockConstructionCost = 40,
        score = 10,
        destructionPenalty = 10,
    },
    
    node = {
        range = 3,
        energyConstructionCost = 5,
        rockConstructionCost = 10,
        maxEnergyReserve = 2,
        score = 5,
        destructionPenalty = 5,
    },
    
    energy = {
        actionInterval = 0.1,
        speed = 4, -- units per second
        lifeTime = 15, -- lifeTime. Will be destroyed if not used by a building at that time
    },
    
    tower = {
        actionInterval = 0.5,
        damage = 20, -- damage every actionInterval
        energyConstructionCost = 12,
        rockConstructionCost = 50,
        maxEnergyReserve = 5,
        range = 5,
        score = 20,
        destructionPenalty = 20,
        shootEnergyCost = 1, -- amount of energy spend per second when shooting
    },
    
    enemy = {
        score = 10,
        actionInterval = 1,
        speed = 2,
        range = 1.5,
        damage = 1, -- damage every action interval
        health = 100,
        -- damage sucks up the energyReserve
        -- building is destroyed when take damage and energy reserve < 0
    },

}


function Daneel.UserConfig()
    return {
        debug = {
            enableDebug = true, -- Enable/disable Daneel's global debugging features (error reporting + stacktrace).
            enableStackTrace = true, -- Enable/disable the Stack Trace.
        },
        
        
        scriptPaths = {            
            rockScript = "Game/Rock",
            
            buildingScript = "Buildings/Building",
            rangeScript = "Buildings/Range",
            harvesterScript = "Buildings/harvester",
            stationScript = "Buildings/powerstation",
            nodeScript = "Buildings/node",
            
            energyScript = "Game/Energy",
            
            enemyScript = "Game/Enemy",
        },
        
        textRenderer = {
            font = "Russo One",
            alignment = "left",
        },
    }
end

function Lang.UserConfig()
    return  {
        languageNames = {
            "English",
            "French"
        }, -- list of the languages supported by the game
        
        current = "English", -- Current language
        default = "French", -- Default language
    }
end
