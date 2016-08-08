
function Behavior:Awake()
    self.gameObject.networkSync:Setup( 2 )
    
    self.direction = Vector3(0)
    self.initialSpeed = 5
    self.speed = 5 -- units per second
    self.roundPlayed = 0
    
    self.triggers = {
        GameObject.Get( "Top.Bounce Trigger" ),
        GameObject.Get( "Bottom.Bounce Trigger" ),
        GameObject.Get( "Paddle Left.Bounce Trigger" ),
        GameObject.Get( "Paddle Right.Bounce Trigger" ),
        
        GameObject.Get( "Left.Score Trigger" ),
        GameObject.Get( "Right.Score Trigger" ),
    }
    
    self.scoreGOs = {
        Right = GameObject.Get( "Score Left" ),
        Left = GameObject.Get( "Score Right" )
    }
       
    self:InitRound()
end


function Behavior:InitRound( data )
    self.gameObject.transform.position = Vector3( 0, 0, -5 )
    
    if data ~= nil then -- when called by the server on each players
        self.direction = Vector3( data.direction )
        self.speed = data.speed
        return
    end
    
    local x = math.randomrange( -1, 1 )
    self.direction = Vector3( x, math.randomrange( -x/2, x/2 ), 0 ):Normalized()
    self.speed = self.initialSpeed + self.roundPlayed / 2
    
    if IsHost then
        self.gameObject.networkSync:SendMessageToPlayers( "InitRound", { direction = self.direction,speed = self.speed }, Server.playerIds )
    end
end
CS.Network.RegisterMessageHandler( Behavior.InitRound, CS.Network.MessageSide.Players )



function Behavior:Update()
    if IsMultiPlayer and not IsHost then
        return
    end
    -- runs only when solo or host

    self.speed = self.speed + (1/600) -- offset by 1 every in 10 seconds (600 frames)
    
    if CS.Input.WasButtonJustPressed( "Enter" ) then
        self:InitRound()
        return
    end
    
    if IsMultiPlayer then
        self.gameObject.networkSync:SendMessageToPlayers( "MoveBall", { speed = self.speed }, Server.playerIds )
    else
        self:MoveBall()
    end
end


function Behavior:MoveBall( data )
    if data ~= nil then
        self.speed = data.speed
    end
    
    self.gameObject.transform:Move(  self.direction  * self.speed / 60 )
    -- FIXME : not using Vector3() here cause an exception "76: attempt to perform arithmetic on field 'direction' (a table value)"
    -- yet the direction
end
CS.Network.RegisterMessageHandler( Behavior.MoveBall, CS.Network.MessageSide.Players )


function Behavior:OnTriggerEnter( data )
    if IsMultiPlayer and not IsHost then
        return
    end
    
    local trigger = data[1]    
    local parentName = trigger.parent.name
    
    if trigger.name == "Bounce Trigger" then
        
        local normal = Vector3( 0, 1, 0 ) -- botom
        if parentName == "Top" then
            normal = Vector3( 0, -1, 0 )
        elseif parentName == "Bottom" then
            normal = Vector3( 0, 1, 0 )
        elseif parentName == "Paddle Left" then
            normal = Vector3( 1, 0, 0 )
        elseif parentName == "Paddle Right" then
            normal = Vector3( -1, 0, 0 )
        end
        
        -- http://www.3dkingdoms.com/weekly/weekly.php?a=2
        -- general bounce formula : NewVector = -2*( IncomingV dot Normal ) * Normal + IncomingV
        local newDirection = -2 * Vector3.Dot( self.direction, normal ) * normal + self.direction
        self.direction = newDirection:Normalized()
        
        if IsMultiPlayer then
            self.gameObject.networkSync:SendMessageToPlayers( "SetDirection", { direction = self.direction }, Server.playerIds )
        end
    
    elseif trigger.name == "Score Trigger" then
        
        if IsMultiPlayer then
            self.gameObject.networkSync:SendMessageToPlayers( "SetScore", { parentName = parentName }, Server.playerIds )
        else
            self:SetScore( { parentName = parentName } )
        end

        self.roundPlayed = self.roundPlayed + 1
        self:InitRound()
    end
end


-- player
function Behavior:SetDirection( data )
    self.direction = Vector3( data.direction )
end
CS.Network.RegisterMessageHandler( Behavior.SetDirection, CS.Network.MessageSide.Players )


function Behavior:SetScore( data )
    local scoreGO = self.scoreGOs[ data.parentName ]
    scoreGO.textRenderer.text = scoreGO.textRenderer.text + 1
end
CS.Network.RegisterMessageHandler( Behavior.SetScore, CS.Network.MessageSide.Players )
