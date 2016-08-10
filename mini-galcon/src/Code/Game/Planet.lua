
function Behavior:Awake()  
    self.gameObject.orbitDiameter = 2
    
    self.outline = self.gameObject:GetChild( "Outline" )
    self.outline.textRenderer.opacity = 0
    
    self.scale = self.gameObject.transform.localScale.x
    
    -- team
    function self.gameObject.GetTeam( gameObject )
        local team = Game.char_to_spriteID[ gameObject.textRenderer.text ]
        if team == nil then team = 1 end
        return team
    end
    
    
    function self.gameObject.UpdateTeam( gameObject, team )
        gameObject.textRenderer.text = Game.spriteID_to_char[ team ]
        Daneel.Event.Fire( "CheckVictory" )
    end
    
    
    -- ship count
    self.gameObject.shipCounter = self.gameObject.child.textRenderer 
    
    self.gameObject.shipCount = tonumber( self.gameObject.shipCounter.text )
    if self.gameObject.shipCount == nil then
        self.gameObject.shipCount = 0
    end

    
    function self.gameObject.UpdateShipCount( gameObject, delta, team )
        gameObject.shipCount = gameObject.shipCount + delta
        
        if gameObject.shipCount <= 0 and team ~= nil then
            gameObject.shipCount = 0
            self.shipsToSpawn = 0
            gameObject:UpdateTeam( team )
        end
        
        gameObject.shipCounter.text = math.floor( gameObject.shipCount ) 
    end
    
    
    -- spawn ships
    self.shipsToSpawn = 0
    self.targetPlanet = nil
    
    function self.gameObject.SpawnShips( gameObject, targetPlanet )
        if targetPlanet == gameObject then return end
        
        self.targetPlanet = targetPlanet
        self.shipsToSpawn = gameObject.shipCount
    end 

end


function Behavior:Update()
    if self.gameObject:GetTeam() > 1 then
        self.gameObject:UpdateShipCount( Game.planetProductionSpeed * self.scale * Daneel.Time.deltaTime )
    end
    
    
    -- spawn the ships over multiple frames
    if self.shipsToSpawn > 0 then
        local spawnedShips = 0
        local orbitDiameter = self.gameObject.orbitDiameter
        
        for i=1, self.shipsToSpawn do
            local ship = GameObject.New( "Prefabs/Ship", {
                ship = {
                    targetPlanet = self.targetPlanet,
                    team = self.gameObject:GetTeam()
                },
                
                transform = {
                    position = self.gameObject.transform.position + Vector3( math.randomrange( -orbitDiameter, orbitDiameter ), math.randomrange( -orbitDiameter, orbitDiameter ), 0 )
                }
            } )
            
            spawnedShips = spawnedShips + 1
            self.shipsToSpawn = self.shipsToSpawn - 1
            self.gameObject.shipCount = self.gameObject.shipCount - 1
            self.shipSpawnedLastFrame = true            
            if spawnedShips >= Game.maxShipSpawnPerFrame then
                return
            end
        end
    else
        self.shipSpawnedLastFrame = false
    end
end


function Behavior:OnSelected()
    if self.gameObject:GetTeam() <= 1 then return end
    
    if not table.containsvalue( Game.selectedPlanets, self.gameObject ) then
        table.insert( Game.selectedPlanets, self.gameObject )
    end
    self.outline.textRenderer.opacity = 1
end


function Behavior:OnUnSelected()
    table.removevalue( Game.selectedPlanets, self.gameObject )
    self.outline.textRenderer.opacity = 0
end


-- this planet become the target
function Behavior:OnRightClick()
    local selectedPlanets = table.copy( Game.selectedPlanets )
    for i, planet in ipairs( selectedPlanets ) do
        planet:SpawnShips( self.gameObject )
        Daneel.Event.Fire( planet, "OnUnSelected" )
    end
    Game.selectedPlanets = {}
end

