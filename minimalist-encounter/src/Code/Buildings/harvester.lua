
function Behavior:Awake()
    self.gameObject.buildingType = "harvester"
    self.nearbyRocks = {}
    self.harvestedRock = nil
end


function Behavior:Start()
    self.gameObject.trigger.range = Game.harvester.range
    self.gameObject.trigger.tags = { "rocks" }
    self.nearbyRocks = self.gameObject.trigger:GetGameObjectsInRange()
    
    -- create the laser
    self.laserGO = GameObject.New("laser", {
        parent = self.gameObject,
        transform = {
            position = self.gameObject.transform.position,
            localScale = Vector3:New(0.01),
        },
        modelRenderer = { model = "Laser" },
    })
end


function Behavior:Update()
    if self.gameObject.isBuilt == false or self.gameObject.energyReserve <= 0 or #self.nearbyRocks <= 0 then
        self.laserGO.modelRenderer.opacity = 0
        return
    end

    
    -- The rock being harvested has been destroyed > need to choose a new one
    if self.harvestedRock == nil or self.harvestedRock.isDestroyed then
        self.harvestedRock = nil
        self.laserGO.modelRenderer.opacity = 0
        
        for i, rock in ipairs(self.nearbyRocks) do
            if rock.isDestroyed then
                table.remove(self.nearbyRocks, i)
            else
                self.harvestedRock = rock
                break -- choose the first rock alive
            end
        end
        
        if self.harvestedRock ~= nil  then
            -- new rock chosen, reorient the laser
            local rockPosition = self.harvestedRock.transform.position
            self.laserGO.transform:LookAt(rockPosition)
            
            local distance = Vector3.Distance(rockPosition, self.laserGO.transform.position)
            self.laserGO.transform.localScale = Vector3:New(0.05,0.05, distance)
        end
    end
   
    -- harvesting
    if self.harvestedRock ~= nil and not self.harvestedRock.isDestroyed then
        self.laserGO.modelRenderer.opacity = 1
        self.gameObject.energyReserve = self.gameObject.energyReserve - Game.harvester.harvestEnergyCost * Daneel.Time.deltaTime
        if self.gameObject.energyReserve < 0 then 
            self.gameObject.energyReserve = 0
        end
        
        local amount = self.harvestedRock.rockScript:Harvest(Game.harvester.harvestAmount * Daneel.Time.deltaTime)
        Daneel.Event.Fire("UpdateRockScore", amount)
    end
end
