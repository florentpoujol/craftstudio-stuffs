
IsConnected = false

function Behavior:Awake()
    local serverButton = GameObject.Get("Server Button")
    serverButton:AddTag("button")
    serverButton.OnClick = function()
        CS.Network.Server.Start()
        serverButton.textRenderer.text = "Server Started"
    end
    
    local connectButton = GameObject.Get("Connect Button")
    connectButton:AddTag("button")
    connectButton.OnClick = function()
        connectButton.textRenderer.text = "Connecting..."
        CS.Network.Connect( "127.0.0.1", CS.Network.DefaultPort, function()
            connectButton.textRenderer.text = "Connected"
            IsConnected = true
        end )
    end
    
    
    -- This function is called on a client when it is disconnected from a server.
    CS.Network.OnDisconnected( function()
        Chat.gameObject.textRenderer.text = "You have been disconnected"
        connectButton.textRenderer.text = "Connect to server"
        IsConnected = false
    end )
end


-- List (array) of connected player ids
PlayerIds = {}

CS.Network.Server.OnPlayerJoined( 
    function( player )
        table.insert( PlayerIds, player.id )

        -- You can call Chat:BroadcastText() directly because the function passed to CS.Network.Server.OnPlayerJoined() is only called on the server
        Chat:BroadcastText( { text = "Player "..player.id.." connected" } )
    end
)

CS.Network.Server.OnPlayerLeft( 
    function( playerId )
        table.removevalue( PlayerIds, playerId )
        Chat:BroadcastText( { text = "Player "..playerId.." disconnected" } )
    end
)
