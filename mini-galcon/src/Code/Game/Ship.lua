function Behavior:Awake()
    self.targetPlanet = nil
    self.direction = Vector3(0)
    self.timeToCheckForDistance = 0
    self.frameCount = 0
    self.Team = 1
    self.gameObject.isDestroyed = false
    
    --Game.UpdateShipCounter( 1 )
    
    function self.gameObject.GetTeam( gameObject )
        return self.Team
    end
    
    function self.gameObject.SetTeam( gameObject, team )
        self:SetTeam( team )
    end
end


function Behavior:SetTeam( team )
    self.Team = team
    self.gameObject.modelRenderer.model = "Ships/Ship" .. team
end


function Behavior:Start()
    self.targetPlanetPosition = self.targetPlanet.transform.position 
    
    self.direction = self.targetPlanetPosition - self.gameObject.transform.position
    
    -- last know distance to the target planet
    self.lastDistance = self.direction:SqrLength()
    
    -- 90% of the time the ship is supposed to take to reach the target planet
    -- the ship won't check for distance with the planet until that time
    self.timeToCheckForDistance = math.sqrt( self.lastDistance ) / Game.shipSpeed * 0.95
    
    self.direction:Normalize()

    local angle = math.deg( math.atan2( self.direction.y, self.direction.x ) ) - 90
    self.gameObject.transform.eulerAngles = Vector3( 0, 0, angle )
    
    self.gameObject.modelRenderer.animation = "Move"
end





function Behavior:Update()
    self.frameCount = self.frameCount + 1
    
    if  self.frameCount % 30 == 0 then -- every 30 frames (0.5 seconds)
        self.gameObject.transform:Move( self.direction * Game.shipSpeed / 2 )
        
        if self.frameCount / 60 > self.timeToCheckForDistance then
            local distance = (self.targetPlanetPosition - self.gameObject.transform.position):SqrLength();
            
            if
                distance > self.lastDistance or -- ship is moving away of the planet
                distance < 1
            then
                -- planet reached
                if self.Team ==  self.targetPlanet:GetTeam() then
                    self.targetPlanet:UpdateShipCount( 1 )
                else
                    self.targetPlanet:UpdateShipCount( -1, self.gameObject:GetTeam() )
                end
                
                --Game.UpdateShipCounter( -1 ) 
                self.gameObject:Destroy()         
                return
            end
            
            self.lastDistance = distance
        end
    end
end
