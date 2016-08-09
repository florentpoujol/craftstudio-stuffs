CS.Screen.SetSize( 840, 500 )

TimeLimit = 30 -- seconds
DrillingTimeModifier = 1

Blocks = {
    air = {
        id = Map.EmptyBlockId,
        isDrillable = false,
    },
    
    dirt = {
        id = 1,
        odd = 1,
        drillingTime = 0.5,
        isDrillable = true,
    },

    stone = {
        id = 2,
        odd = 30,
        drillingTime = 1.5,
        isDrillable = false,
    },
    
    oil = {
        id = 3,
        odd = 120,
        drillingTime = 1,
        
        drillEffect = function()
            UI.hud.timeGO.tweener.elapsed = UI.hud.timeGO.tweener.elapsed - Tools.refinery.timeBonus
        end
    },
    
    obsidian = {
        id = 4,
        odd = 100,
        isDrillable = false,
    },
    
    gold = {
        id = 5,
        odd = 100,
        drillingTime = 0.8,
        isDrillable = true,
        goldAmount = 1,
        
        drillEffect = function()
            UI.hud.goldGO.UpdateGoldAmount( Blocks.gold.goldAmount )
        end
    },
    
    grass = {
        id = 6,
        drillingTime = 0.8,
        isDrillable = true,
    },
    
    verticalpipe = {        id = 16    },
    horizontalpipe = {        id = 17    },
    downdrill = {        id = 18    },
    topleftelbow = {        id = 19,    },
    toprightelbow = {        id = 20,    },
    bottomleftelbow = {        id = 21,    },
    bottomrightelbow = { id = 22,    },
    leftdrill = {        id = 23,    },
    updrill = {        id = 24,    },
    rightdrill = {        id = 25,    },
}


function GetBlockById( id )
    for name, data in pairs( Blocks ) do
        if data.id == id then
            return data
        end
    end
end


Tools = {
    OnPurchase = function(toolName)
        local tool = Tools[toolName]
        if toolName ~= "engine" then
            tool.isPurchased = true    
        end
        UI.hud.goldGO.UpdateGoldAmount( -tool.cost )
    end,
    
    irondrill = {
        name = "Iron Drill",
        effectText = "Drill stone.",
        OnPurchase = function()
            Blocks.stone.isDrillable = true
            Tools.OnPurchase( "irondrill" )
        end,
        isPurchased = false,
        cost = 3,
    },
    
    refinery = {
        name = "Refinery",
        effectText = "Convert oil to;8 seconds",
        timeBonus = 8, -- seconds
        OnPurchase = function()
            Blocks.oil.isDrillable = true
            Tools.OnPurchase( "refinery" )
        end,
        isPurchased = false,
        cost = 4,
    },
    
    engine = {
        name = "Engine Mark++",
        effectText = "Increase drilling speed;by 20%.;Can be purchase more;than once",
        OnPurchase = function()
            Tools.OnPurchase( "engine" )
            DrillingTimeModifier = DrillingTimeModifier * 0.8
            -- or
            -- DrillingTimeModifier = DrillingTimeModifier - DrillingTimeModifier * 0.20
        end,
        cost = 2,
        purchaseCount = 0,
    },
    
    time = {
        name = "Shareholders' benevolence",
        effectText = "Buy yourself 5 seconds.",
        timeBonus = 5, -- second
        OnPurchase = function()
            Tools.OnPurchase( "time" )
            UI.hud.timeGO.tweener.elapsed = UI.hud.timeGO.tweener.elapsed - Tools.time.timeBonus
        end,
        
        cost = 2,
        purchaseCount = 0,
    }
}


Daneel.UserConfig = {
    debug = {
        enableDebug = true,
        enableStackTrace = true
    }
}

function SetupClickables()
    --local scaleOffset = Vector3(0.2)
    local scaleMultiplier = 1.2
    local OnMouseEnter = function(go)
        go.transform.localScale = go.transform.localScale * scaleMultiplier
    end
    local OnMouseExit = function(go)
        go.transform.localScale = go.transform.localScale * (1-(scaleMultiplier-1))
    end
    
    for i, go in pairs( GameObject.GetWithTag( "clickable" ) ) do
        go.OnMouseEnter = OnMouseEnter
        go.OnMouseExit = OnMouseExit
    end
end


function UpdateLeaderboard( score )
    if Leaderboard.password ~= nil and PlayerId ~= nil then
        local data = { 
            name = PlayerName,
            score = (score or PlayerScore or 0)
        }
        
        Leaderboard.UpdatePlayerData( PlayerId, data, function(_data, errorMsg)
            if errorMsg then
                print("ERROR Leaderboard.UpdatePlayerData ", errorMsg)
            elseif _data and _data.success then
                --print("SUCCESS Leaderboard.UpdatePlayerData ", _data.success, data.name, data.score)
            end
        end )
    end
end


function SavePlayerData()
    local data = {
        playerId = PlayerId,
        playerName = PlayerName,
        playerScore = PlayerScore
    }
    Daneel.Storage.Save("LeaderboardPlayerData", data, function(data, error)
        if error ~= nil then
            print("Error saving player data in storage", error, PlayerId, PlayerName, PlayerScore)
        else
            --print("SUCCESS saving player data in storage", PlayerId, PlayerName, PlayerScore)
        end
    end )
end

