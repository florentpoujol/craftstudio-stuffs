
function Behavior:Awake()
    self.gameObject.networkSync:Setup( 1 )

    self.paddle = {
        Left = GameObject.Get( "Paddle Left" ),
        Right = GameObject.Get( "Paddle Right" )
    }
    
    self.side = "Left"
    
    if IsMultiPlayer then
        self.side = Client.side
    end
    
    self.paddle[ self.side ].modelRenderer.model = "Red"
    
    self.paddleSpeed = 6 -- units per second
    self.zero = Vector3(0)
end


function Behavior:Update()
    if CS.Input.WasButtonJustPressed( "Escape" ) then
        Scene.Load( "Menu" )
    end
    
    if not IsMultiPlayer and CS.Input.WasButtonJustPressed( "Space" ) then
        -- switch paddle
        self.paddle[ self.side ].modelRenderer.model = "White"
        if self.side == "Left" then
            self.side = "Right"
        else
            self.side = "Left"
        end
        self.paddle[ self.side ].modelRenderer.model = "Red"
    end
    
    self.direction = self.zero
    
    if CS.Input.IsButtonDown( "Up" ) then
        self.direction = Vector3( 0, 1, 0 )
    elseif CS.Input.IsButtonDown( "Down" ) then
        self.direction = Vector3( 0, -1, 0 )
    end
    
    if self.direction ~= self.zero then
        --print("direction", self.direction)
        if IsMultiPlayer then
            self.gameObject.networkSync:SendMessageToServer( "GetInputFromPlayer", { direction = self.direction, side = self.side } )
        else
            self:MovePaddle( { direction = self.direction, side = self.side } )
        end
    end
end


-- server
function Behavior:GetInputFromPlayer( data, playerId )
    -- I ave to use a server-side function since players other than the host can't directly send messages to other players
    self.gameObject.networkSync:SendMessageToPlayers( "MovePaddle", data, Server.playerIds )
end
CS.Network.RegisterMessageHandler( Behavior.GetInputFromPlayer, CS.Network.MessageSide.Server )


--players
function Behavior:MovePaddle( data )
    local direction = self.direction
    local paddle = self.paddle[ self.side ]
    local paddlePosition = paddle.transform.position
    
    if data ~= nil then
        direction = Vector3( data.direction )
        paddle = self.paddle[ data.side ]
        paddlePosition = paddle.transform.position
    end
    
    if ( direction == Vector3( 0, 1, 0 ) and paddlePosition.y >= 4.8 ) or
       ( direction == Vector3( 0, -1, 0 ) and paddlePosition.y <= -4.8 ) then
        return
    end
    paddle.transform:Move( direction * self.paddleSpeed / 60 )
end
CS.Network.RegisterMessageHandler( Behavior.MovePaddle, CS.Network.MessageSide.Players )
