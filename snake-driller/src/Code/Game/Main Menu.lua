
PlayerId = nil -- id of the player on the leaderboard
PlayerName = ""
PlayerScore = 0
PlayerBestScore = 0

function Behavior:Awake()
    local show = function( gameObject )
        gameObject.transform.localPosition = Vector3(0,0,0)
        gameObject.isDisplayed = true
    end
    
    local hide = function( gameObject )
        gameObject.transform.localPosition = Vector3(0,0,100)
        gameObject.isDisplayed = false
    end

    local playGO = GameObject.Get("Play")
    playGO.OnClick = function()
        Scene.Load("Level")
    end
    
    local leaderboardGO = GameObject.Get("Leaderboard")
    leaderboardGO.OnClick = function()
        Scene.Load("Leaderboard")
    end
    
    local howtoGO = GameObject.Get("How To Play")
    local panelGO = GameObject.Get("How To Play Panel")
    panelGO.Show = function(go)
        go.transform.localPosition = Vector3(-154,-36,1)
        go.isDisplayed = true
    end
    panelGO.Hide = hide
    local backGO = panelGO:GetChild("Back")
    backGO.OnClick = function()
        panelGO:Hide()
    end
    howtoGO.OnClick = function()
        panelGO:Show()
    end
    -- the rest on the buttons (Play, Leaderboard) stays clickable while the panel is shown

    self.howtoPanelGO = panelGO
    
    
    local exitGO = GameObject.Get("Quit")
    if CS.IsWebPlayer then
        exitGO.textRenderer.text = ""
    else
        exitGO.OnClick = function()
            CS.Exit()
        end
    end
    
    -- Credits
    local linkGO = GameObject.Get("Credits.2")
    linkGO.OnClick = function()
        CS.Web.Open( "http://florentpoujol.fr" )
    end
    
    local linkGO = GameObject.Get("Credits.4")
    linkGO.OnClick = function()
        CS.Web.Open( "http://craftstud.io" )
    end
    

end

function Behavior:Start()
    -- player name and leaderboard
    local inputGO = GameObject.Get("Player Name.Input")
    inputGO.input.OnFocus = function(input)
        if not input.isFocused then
            inputGO.ValidateInput(input)
        end
    end
    
    
    inputGO.ValidateInput = function(input)
        if Leaderboard.password ~= nil then
            local playerName = input.gameObject.textRenderer.text:trim()
            
            if playerName == "" or playerName == input.defaultValue then
                return
            end

            PlayerName = playerName
            
            if PlayerId == nil then -- ideally should check if there has been an error with loading the id from storage
                
                -- get the player id from the LB then save the player data and set the player on the LB
                Leaderboard.GetNextPlayerId( function(data, errorMsg)
                    if errorMsg then
                        error( errorMsg )
                    elseif data then
                        PlayerId = data.nextPlayerId
                        UpdateLeaderboard()
                        SavePlayerData()
                    end
                end )
                
            else
                UpdateLeaderboard() -- just update the player name
                SavePlayerData()
            end
        else
            print("Player name input Validate() : Leaderboard in unaccessible")
        end
    end
    
    inputGO.input.OnValidate = inputGO.ValidateInput
    
    local bestScoreGO = GameObject.Get("Best Score.Value")
    
    
    -- load player name and id from save
    Daneel.Storage.Load("LeaderboardPlayerData", function(data, error)
        if data ~= nil then
            PlayerId = data.playerId
            PlayerName = data.playerName
            PlayerScore = data.playerScore or 0
            PlayerBestScore = PlayerScore
            inputGO.textRenderer.text = PlayerName
            bestScoreGO.textRenderer.text = PlayerScore
            --print("Player data loaded from storage", PlayerId, PlayerName, PlayerScore)
        end
    end )
    
    
    SetupClickables()
end






function Behavior:Update()
    if CS.Input.WasButtonJustPressed("Escape") then
        if self.howtoPanelGO.isDisplayed then
            self.howtoPanelGO:Hide()
        end
    end
end

