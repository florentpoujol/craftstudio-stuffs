
--[[
with transform:Move
ship moving every frame : 760
ship moving every 2 frame : 1280
ship moving every 3 frame : 1500

with transform.position
ship moving every frame : 440
ship moving every 2 frame : 750
ship moving every 3 frame : 950

ship moving every frame + distance check each rame : 440
ship moving + distance check every 10 frames : 680
ship moving + distance check every 20 frames : 720
ship moving + distance check every 30 frames : 760

ship moving every 2 frame + distance check every 20 frame : 1000
]]

function Behavior:Awake()
    self.gameObject.orbitDiameter = 2
    
    -- team
    function self.gameObject.GetTeam( gameObject )
        local team = Game.char_to_spriteID[ gameObject.textRenderer.text ]
        if team == nil then team = 1 end
        return team
    end
    
    
    function self.gameObject.UpdateTeam( gameObject, team )
        gameObject.textRenderer.text = Game.spriteID_to_char[ team ]
    end
    
    
    -- ship count
    --self.gameObject.shipCounter = self.gameObject.child.textRenderer 
    
    --self.gameObject.shipCount = tonumber( self.gameObject.shipCounter.text )
    self.gameObject.shipCount = 0
    if self.gameObject.shipCount == nil then
        self.gameObject.shipCount = 0
    end

    
    function self.gameObject.UpdateShipCount( gameObject, delta, team )
        gameObject.shipCount = gameObject.shipCount + delta
        
        if gameObject.shipCount <= 0 then
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
    
    
    -- benchmark
    Daneel.Event.Listen( "OnFireButtonJustPressed", function()
        --print( "spawships")
        self.shipsToSpawn = Game.benchmarkShipToSpawn
    end )
    
    self.targetPlanet = GameObject.NewFromScene( "Planet", {
        transform = { 
            position = self.gameObject.transform.position + Vector3( 40, 0, 0 )
        },
        textRenderer = {
            font = "Planets",
            text = Game.spriteID_to_char[ self.gameObject:GetTeam() ]
        }
    } )
    
    self.shipSpawnedLastFrame = false
end



function Behavior:Update()
    --[[if self.gameObject:GetTeam() > 1 then
        self.gameObject:UpdateShipCount( self.productionSpeed * Daneel.Time.deltaTime )
    end]]
    
    -- spawn the ships over multiple frames
    if self.shipsToSpawn > 0 and self.shipSpawnedLastFrame == false then
        local spawnedShips = 0
        local orbitDiameter = self.gameObject.orbitDiameter
        
        for i=1, self.shipsToSpawn do
            GameObject.NewFromScene( "Ship", {
                Ship = {
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
            --if spawnedShips >= Game.maxShipSpawnPerFrame then
                return
            --end
        end
    else
        self.shipSpawnedLastFrame = false
    end
end

--[[
-- select the planet
function Behavior:OnClick()
    if self.gameObject:GetTeam() <= 1 then return end
    Game.selectedPlanet = self.gameObject
    if Game.outline ~= nil then
        Game.outline.transform.position = self.gameObject.transform.position
    else
        Game.outline = GameObject.NewFromScene( "Outline", { transform = { position = self.gameObject.transform.position } } )
    end
end


-- this planet become the target
function Behavior:OnRightClick()
    if Game.selectedPlanet ~= nil then
        Game.selectedPlanet:SpawnShips( self.gameObject )
        Game.selectedPlanet = nil
        Game.outline.transform.position = Vector3(1000,1000,0)
    end
end]]

