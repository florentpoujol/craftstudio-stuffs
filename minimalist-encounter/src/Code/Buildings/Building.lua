--[[PublicProperties
isBuiltInScene boolean False
energyReserve number 0
/PublicProperties]]

-- ScriptedBehavior on every buildings
-- Handle general building setup and construction

-- Public properties : for when the building is built in the scene
-- isBuiltInScene : when true, the building has been built inside the scene before runtime
-- energyReserve


function Behavior:Awake()
    self.gameObject.buildingScript = self
    self.lineRenderers = {}
    
    -- self.gameObject.buildingType is set by the building-specific scripts
    -- this require the building scriptedBehavior to be added after the building-specific script
    -- (but all that is done here in Awake could be done in Start)
    
    self.maxEnergyReserve = Game[self.gameObject.buildingType].maxEnergyReserve
    self.gameObject.energyReserve = math.clamp(self.energyReserve, 0, self.maxEnergyReserve)
    self.lastFrameEnergyReserve = -1
    
    self.energyConstructionCost = Game[self.gameObject.buildingType].energyConstructionCost
    self.energySpentForConstruction = 0
        
    self.gameObject.isBuilt = self.isBuiltInScene
    self.gameObject.modelRenderer.opacity = 0.1
    if self.gameObject.isBuilt == true then
        self.gameObject.modelRenderer.opacity = 1
    end
    
    self.gameObject.isAlive = true
    Daneel.Event.Listen("OnBuildingDestroyed", self.gameObject)
end


function Behavior:Start()
    if self.gameObject.buildingType ~= "node" then 
        -- this is done here in Start because the position of the building is set after Awake is called
        -- (via the params argument of GameObject.New() in the BuildingCreation:OnLeftMouseButtonJustPressed())
        Daneel.Event.Fire("OnNewBuilding", self.gameObject)
    end
    
    -- health bar
    -- need to wait for the camera GameObject to exists and config.game.cameraGO to be set in Game/Awake()
    
    local pivot = GameObject.New("Prefabs/Bar", {
        parent = self.gameObject,
        transform = {
            localPosition = Vector3(0, 1.5, 0),
        }
    })
    pivot.transform.eulerAngles = Vector3(30, 180, 0) 

    local background = pivot:GetChild("Background", true)
    background.progressBar:Set({
        maxLength = 1.05,
        height = 0.25,
        value = "100%",
    })
    
    local foreground = pivot:GetChild("Foreground", true)
    foreground.transform.localPosition = Vector3(0.025,0,0.01)
    --print("------------------ Set foreground")
    foreground.progressBar:Set({
        maxLength = 1,
        height = 0.2,
    })
    
    self.gameObject.healthBarPivot = pivot
    self.gameObject.healthBarBackground = background
    self.gameObject.healthBar = foreground.progressBar
    
    if self.gameObject.isBuilt then
        foreground.progressBar:Set({
            maxValue = self.maxEnergyReserve,
            value = self.gameObject.energyReserve,
        })
    else 
        foreground.progressBar:Set({
            maxValue = self.energyConstructionCost,
            value =  0,
        })
    end
    
    -- line to other buildings
    
end


function Behavior:Update()
    if self.energyConstructionCost > 0 and not self.gameObject.isBuilt and self.gameObject.energyReserve >= 1 then
        self.gameObject.energyReserve = self.gameObject.energyReserve - 1
        self.energySpentForConstruction = self.energySpentForConstruction + 1
        self.gameObject.modelRenderer.opacity = self.energySpentForConstruction / self.energyConstructionCost
        
        if self.energySpentForConstruction >= self.energyConstructionCost then
            self.gameObject.isBuilt = true
            self.gameObject.healthBar.maxValue = self.maxEnergyReserve
            self.gameObject.healthBar.value =  0
            Daneel.Event.Fire("UpdateGameScore", Game[self.gameObject.buildingType].score)
        else
            self.gameObject.healthBar.value =  self.energySpentForConstruction
        end
    end
    
    if self.gameObject.energyReserve ~= self.lastFrameEnergyReserve  then
        self.lastFrameEnergyReserve = self.gameObject.energyReserve
    
        self.gameObject.healthBar:UpdateProgress( math.clamp(self.gameObject.energyReserve, 0, self.maxEnergyReserve) )
        
        if self.gameObject.energyReserve == self.maxEnergyReserve then
            self.gameObject.healthBar.gameObject.modelRenderer.opacity = 0.2
            self.gameObject.healthBarBackground.modelRenderer.opacity = 0.2
        elseif self.gameObject.healthBar.gameObject.modelRenderer.opacity ~= 1 then
            self.gameObject.healthBar.gameObject.modelRenderer.opacity = 1
            self.gameObject.healthBarBackground.modelRenderer.opacity = 1
        end
    end
end


-- Called by enemy script
function Behavior:TakeDamage(amount)
    if self.gameObject.energyReserve < 0 or not self.gameObject.isAlive or self.gameObject.isDestroyed then return end
    
    self.gameObject.energyReserve = self.gameObject.energyReserve - amount
    if self.gameObject.energyReserve < 0 then
        self.gameObject:Destroy()
        Daneel.Event.Fire("UpdateGameScore", (0-Game[self.gameObject.buildingType].destructionPenalty))
    end
end


-- fired by CraftStudio.Destroy() on the destroyed building only
function Behavior:OnDestroy()
    self.gameObject.isAlive = false
    Daneel.Event.Fire("OnBuildingDestroyed", self.gameObject) -- broadcast the gameObject to all buildings
end

-- called on all buildings, receive the destroyedbuilding
function Behavior:OnBuildingDestroyed(data)
    local building = data[1]

    if self.gameObject.nearbyBuildings ~= nil then -- nodes
        table.removevalue(self.gameObject.nearbyBuildings, building)
    end 
    if self.gameObject.nearbyNodes ~= nil and building.buildingType == "node" then -- nodes and powerstation
        table.removevalue(self.gameObject.nearbyNodes, building)
    end
    
    for i, lineRndr in pairs( self.lineRenderers ) do
        if lineRndr.targetGO == building then
            lineRndr.gameObject:Destroy()
            table.remove( self.lineRenderers, i )
            break
        end
    end
end


-- draw a line to the provided buiding or node
function Behavior:DrawLine( targetGO, sourceGO )
    sourceGO = sourceGO or self.gameObject
    
    local go = GameObject.New( "", {
        parent = sourceGO,
        transform = { localPosition = Vector3(0) }
    } )
    local lineRndr = go:AddComponent( "LineRenderer", {
        endPosition = targetGO.transform.position,
        width = 0.1,
        targetGO = targetGO,
    } )

    go:AddComponent("modelrenderer", {
        model = "Energy Line",
        opacity = 0.4,
    } )
    
    table.insert( self.lineRenderers, lineRndr )
end
