-- Leaderboard.lua
--
-- Wrapper for CraftStudio to work with the "CraftStudio Leaderboard" PHP script.
-- <https://github.com/florentpoujol/CraftStudio-Leaderboard>
-- 
-- Copyright © 2014 Florent POUJOL, published under the WTFPL license.
-- <florentpoujol.fr>

Leaderboard = {
    gameId = "SnakeDriller",
    password = nil,
    url = "http://csleaderboard.florentpoujol.fr/index.php",
}

function Behavior:Awake()
    Daneel.Storage.Load("lbp", nil, function(data)
        Leaderboard.password = data
        Daneel.Event.Fire("LeaderboardReady")
        --print("Leaderboard password loaded successfully")
    end)
end


function Leaderboard.Check()
    local msg = ""
    if Leaderboard.url == nil then
        msg = msg.."Leaderboard.url is not set. "
    end
    if Leaderboard.gameId == nil then
        msg = msg.."Leaderboard.gameId is not set. "
    end
    if Leaderboard.password == nil then
        msg = msg.."Leaderboard.password is not set. "
    end
    if msg ~= "" then
        print("Leaderboard.Check() : "..msg)
        return false
    end
    return true
end


-- @param callback (function) The callback function to call when the request is completed. The callback is passed with 
function Leaderboard.Query( funcName, data, callback )
    if Leaderboard.Check() then
        data.gameId = Leaderboard.gameId
        data.password = Leaderboard.password

        CS.Web[funcName]( Leaderboard.url, data, CS.Web.ResponseType.JSON, 
            function( error, data ) 
                local errorMsg = nil
                local userData = nil
                if error ~= nil then
                    errorMsg = error.message
                elseif data ~= nil then
                    if data.error ~= nil then
                        errorMsg = data.error
                    else
                        userData = data
                    end
                end
                if type( callback ) == "function" then
                    callback( userData, errorMsg )
                elseif errorMsg ~= nil then
                    print("Leaderboard ERROR : ", errorMsg)
                end
            end 
        )
    end
end





function Leaderboard.UpdateGameData( data, callback )
    data.action = "updategamedata"
    Leaderboard.Query( "Post", data, callback )
end

function Leaderboard.UpdatePlayerData( playerId, data, callback )
    data.playerId = playerId
    data.action = "updateplayerdata"
    Leaderboard.Query( "Post", data, callback )
end


function Leaderboard.Create( data, callback )
    data = data or {}
    data.gameId = data.gameId or Leaderboard.gameId
    data.password = data.password or Leaderboard.password

    if data.gameId == nil or data.password == nil then
        print("Leaderboard.Create() : Need a gameId and password to create a game on the leaderboard.")
    else
        data.action = "create"
        Leaderboard.Query( "Get", data, function( _data, errorMsg )
            if _data and _data.success then
                Leaderboard.gameId = data.gameId
                Leaderboard.password = data.password
            end

            callback( _data, errorMsg )
        end )
    end
end

--- Get the next available player id 
-- Under the "nextPlayerId" key in the data table passed to the callback.
-- @param callback (function) The callback function to call when the request is completed.
function Leaderboard.GetNextPlayerId( callback )
    Leaderboard.Query( "Get", { action = "getnextplayerid" }, callback )
end

-- @param callback (function) The callback function to call when the request is completed.
function Leaderboard.GetGameData( callback )
    Leaderboard.Query( "Get", { action = "getgamedata" }, callback )
end


-- @param callback (function) The callback function to call when the request is completed.
function Leaderboard.GetPlayerData( playerId, callback )
    Leaderboard.Query( "Get", { action = "getplayerdata", playerId = playerId }, callback )
end

