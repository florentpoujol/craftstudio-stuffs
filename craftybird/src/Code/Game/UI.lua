
Daneel.UserConfig = {     
    debug = {
        enableDebug = false,
        enableStackTrace = false
    }
}

Leaderboard.gameId = "craftybird"
Leaderboard.password = "e4Tf5ZEv16"
Leaderboard.url = "http://csleaderboard.florentpoujol.fr/index.php"

Leaderboard.playerId = "" -- is set via Javascript after that the PHP file has get the id and leaderboard data

CS.Screen.SetSize(840, 500) -- webplayer size

UI = {}
GamePaused = false
BestScore = 0


function Behavior:Awake()
    GameObject.Get("Pipes Placeholder"):Destroy()
    
    -- Score
    UI.score = GameObject.Get("Score")
    UI.score.value = 0
    UI.score.Update = function( go )
        go.value = go.value + 1
        go.textRenderer.text = go.value
        
        go:Animate("localScale", Vector3(0.4), 1, { startValue = Vector3(1) }) -- makes the score's text instanly bigger then slowly back at normal size
    end
    
    UI.score.textRenderer.text = 0
    
    
    -- Game over screen
    UI.gameOver = GameObject.Get("Game Over")
    UI.gameOver.Show = function( go )
        go.transform.localPosition = Vector3(0)
        
        if UI.score.value > BestScore then
            BestScore = UI.score.value
            
            if Leaderboard.playerId ~= "" and Leaderboard.gameData ~= nil then
                -- Leaderboard.playerId is only set when using the webplayer I setup at
                -- http://florentpoujol.fr/content/craftstudio/crafty-bird/index.php
                
                Leaderboard.UpdatePlayerData( Leaderboard.playerId, { score = BestScore }, function(e)
                    if e and e.error then
                        print("Error Updating player data:", e )
                    end
                end )
            end
        end
        
        local scoreGO = go:GetChild("Score")
        scoreGO.textRenderer.text = "SCORE: "..UI.score.value
        
        local bestGO = go:GetChild("Best Score")
        bestGO.textRenderer.text = "YOUR BEST: "..BestScore
    end
    
    UI.gameOver.transform.localPosition = Vector3(0,-50,0) -- hide the game over screen
    
    -- Start spawning the pipes
    Pipes.Spawn()
    
    -- Get ready
    local getReady = GameObject.Get("Get Ready")
    
    --Tween.Timer( 1, function() -- wait 1 second for the game to actually initialize and open
        getReady:Animate("opacity", 0, 3, function()
            -- start the game when the  get ready text has completely fade out
            BirdGO.s:StartGame()
        end)
    --end )
end

function Behavior:Start()
    if Leaderboard.playerId ~= "" and CS.IsWebPlayer and Leaderboard.gameData == nil then
        Leaderboard.playerId = tostring(Leaderboard.playerId)
        
        Leaderboard.GetGameData( function( data, e )
            if e ~= nil then
                print("error getting game data on leaderboard", e )
                return
            end
            
            Leaderboard.gameData = data
            local player = data.dataByPlayerId[ Leaderboard.playerId ]
            if player then 
                BestScore = tonumber(player.score) or 0
            end
        end )
    end
end


function Behavior:Update()
    if GamePaused then
        if CS.Input.WasButtonJustPressed( "Space" ) or CS.Input.WasButtonJustPressed( "LeftMouse" ) then
            Scene.Load("Level")
        end
    end
end
