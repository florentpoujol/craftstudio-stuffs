
--[[
only two players
- the host is always "Player 1"
- the other client is always "Player 2"
]]

function Behavior:Awake()
    -- init the Network Sync
    self.gameObject.networkSync:Setup( 0 )
    
    IsMultiPlayer = true
    
    self.startButton = GameObject.Get( "Start Button" )
    self.playerNameGO = GameObject.Get( "Player Name" )
    
    self.waitingGO = GameObject.Get( "Waiting" )
    self.waitingStates = {
        hostWaitForClient = "Waiting for player 2 to connect...",
        hostReady = "Ready to start",
        clientReady = "Waiting for host to start the game",
    }
    self.waitingGO.textRenderer.text = "Connecting to " .. IpToConnectTo 
    
    
    if IsHost then
        self.startButton:AddTag( "button" )
        self.startButton.OnClick = function() self:LaunchGame() end
        
        self:SetupServer()
    else
        self.startButton.textRenderer.opacity = 0 
        -- the start button is still there in front of the camera but it does not work since the "button" tag and OnClick callback have not been added
        PlayerName = "Player 2"
        self.playerNameGO.textRenderer.text = "Player 2"
    end
    

    self:SetupClient() -- the host appens to run the serveur but is also a regular client on it's own server
end


function Behavior:Update()
    if CS.Input.WasButtonJustPressed( "Escape" ) then
        self.GoBackToMainMenu()
    end
end


function Behavior:GoBackToMainMenu()
    if IsHost then
        Server = nil
        CS.Network.Server.Stop()
    end
    
    Client = nil
    CS.Network.Disconnect()
    
    Scene.Load( "Menu" )
end


-- When host press the Start button
function Behavior:LaunchGame()
    Server.hasGameStarted = true
        
    local sides = {"Left", "Right"}
    for id, player in pairs( Server.playersById ) do
        if #sides <= 0 then break end
        
        player.side = sides[1]
        table.remove( sides, 1 )
    end
    
    Server.playerIds = table.getkeys( Server.playersById )

    -- Let people know the game started and move to the In-Game scene
    self.gameObject.networkSync:SendMessageToPlayers( "StartGame", { playersById = Server.playersById }, Server.playerIds )
end


--------------------------------------------------------------------------------
-- Setup 
--------------------------------------------------------------------------------

function Behavior:SetupServer()
    Server = {
        playersById = {},
        playerIds = {}, -- = table.getkeys( playersById )  - setup only when the game has started so that table.getkeys() is not called everytimes
        hasGameStarted = false,
    }
    
    CS.Network.Server.Start()
    
    -- called before the callback function On NetWork.Connect
    CS.Network.Server.OnPlayerJoined( 
        function( player )
            --print("OnPlayerJoined", player.id)

            if not Server.hasGameStarted and table.length( Server.playersById ) < MaxPlayersCount then
                -- Add new player to inactive player list until we get their setup info
                player.isActive = false
                Server.playersById[ player.id ] = player
            else
                -- Prevent any new players from joining once the game has started
                -- or the max player count has been reached
                CS.Network.Server.DisconnectPlayer( player.id )
            end
        end 
    )
    
    CS.Network.Server.OnPlayerLeft( 
        function( playerId )
            --print("CS.Network.Server.OnPlayerLeft", playerId)
            Server.playersById[ playerId ] = nil
            for i, id in ipairs( Server.playerIds ) do
                if id == playerId then
                    table.remove( Server.playerIds, i )
                    break
                end
            end
        end
    )
end


-- called from the client-side callback function when a player successfully connected to the server
function Behavior:ActivatePlayer( data, playerId )
    --print("ActivatePlayer", playerId)
    local player = Server.playersById[ playerId ]
    if player == nil then return end -- when can this happen ?
    
    player.isActive = true
    
    self.gameObject.networkSync:SendMessageToPlayers( "SetPlayerId", { playerId = playerId }, { playerId } )

    if IsHost and table.length( Server.playersById ) == 2 then
        self.waitingGO.textRenderer.text = self.waitingStates.hostReady
        self.startButton.textRenderer.opacity = 1
    end
end
CS.Network.RegisterMessageHandler( Behavior.ActivatePlayer, CS.Network.MessageSide.Server )


--------------------------------------------------------------------------------
-- Client 
--------------------------------------------------------------------------------

function Behavior:SetupClient()
    Client = {
        playerId = -1,
    }

    CS.Network.Connect( IpToConnectTo, CS.Network.DefaultPort, function()
        -- change the waiting text from "Connecting..." to something else
        if IsHost then
            self.waitingGO.textRenderer.text = self.waitingStates.hostWaitForClient
        else
            self.waitingGO.textRenderer.text = self.waitingStates.clientReady
        end
        
        self.gameObject.networkSync:SendMessageToServer( "ActivatePlayer" ) -- activate player on the server, set client game dat and notify other players
    end )
    
    -- Handle disconnection / inability to connect
    CS.Network.OnDisconnected( function()
        --print("CS.Network.OnDisconnected", Client.playerId)
        self:GoBackToMainMenu()
    end )
end


function Behavior:SetPlayerId( data )
    Client.playerId = data.playerId
end
CS.Network.RegisterMessageHandler( Behavior.SetPlayerId, CS.Network.MessageSide.Players )


-- Called from the LaunchGame(), when host clicks on the start game button
function Behavior:StartGame( data )
    Client.playersById = data.playersById
    Client.side = Client.playersById[ Client.playerId ].side
    Scene.Load( "Level" )
end
CS.Network.RegisterMessageHandler( Behavior.StartGame, CS.Network.MessageSide.Players )
