function Behavior:Awake()
    local backGO = GameObject.Get("Back Main Menu")
    backGO.OnClick = function()
        Scene.Load("Main Menu")
    end
end

function Behavior:Start()
    SetupClickables()
    
    self.nameTextArea = GameObject.Get("Name Column.TextArea").textArea
    self.scoreTextArea = GameObject.Get("Score Column.TextArea").textArea
    
    if Leaderboard.password ~= nil then
        Leaderboard.GetGameData( function(data, error)
            if error then
                print(error)
            elseif data and data.dataByPlayerId then
                self:UpdateTable( data.dataByPlayerId )
            end
        end )
    end
end

function Behavior:UpdateTable( dataByPlayerId )

    local playerDataByScore = {}
    for id, data in pairs( dataByPlayerId ) do
        data.score = tonumber(data.score)
        table.insert(playerDataByScore, data)
    end  
    playerDataByScore = table.sortby( playerDataByScore, "score", "desc" ) -- ?? it should be "desc" (big values first)
     
    local nameListText = ""
    local scoreListText = ""
    
    for i, data in ipairs( playerDataByScore ) do
        nameListText = nameListText .. data.name..";"
        scoreListText = scoreListText .. data.score..";"        
    end
    
    self.nameTextArea.text = nameListText
    self.scoreTextArea.text = scoreListText
end

function Behavior:Update()
    if CS.Input.WasButtonJustPressed("Escape") then
        Scene.Load("Main Menu")
    end
end
