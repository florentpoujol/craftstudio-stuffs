
function Behavior:Awake()
    self.target = nil -- the gameObject the energy moves toward
    self.past = nil -- the last gameObject the energy has reached
    self.birthTime = Daneel.Time.time
    self.isDepleted = false
    self.GOPosition = self.gameObject.transform.position
    self.targetPosition = nil
end


function Behavior:Update()
    -- destroy energy if too old
    -- or target building has been destroyed
    if 
        self.birthTime + Game.energy.lifeTime < Daneel.Time.time or
        (self.target ~= nil and self.target.isAlive == false)
    then
        self.gameObject:Destroy()
        return
    end
    
    
    self.GOPosition = self.gameObject.transform.position
    
    -- move toward target
    if self.target ~= nil and self.target.isAlive == true then
        local direction = self.targetPosition - self.GOPosition
        self.gameObject.transform:MoveOriented( direction:Normalized() * Daneel.Time.deltaTime * Game.energy.speed  )
    end   
    
    -- do something once close enought to the current target
    if 
        self.target ~= nil and self.target.isAlive == true and
        Vector3.Distance(self.GOPosition, self.targetPosition) <= 0.1
    then
        if self.isDepleted == true then
            self.gameObject:Destroy()
            return
        end
        
        -- if current target needs energy, fill the reserve and destroy
        if self.target.energyReserve <= Game[self.target.buildingType].maxEnergyReserve - 1  then
            if self.isDepleted ~= true then
                self.target.energyReserve = self.target.energyReserve + 1 
                self.isDepleted = true
            end
            self.gameObject:Destroy()
            return
        else
            -- target does not need energy, it must be a fully constructed node
            -- It shouldn't be a full building since ??
        end
                
        -- Choose next node, or next building to go to
        local nextTarget = nil
        local nearbyBuildings = self.target.nearbyBuildings
        local nearbyNodes = self.target.nearbyNodes          
        
        if nearbyBuildings == nil then 
            -- target is a building that needed energy, but that gets enought of it while the energy was moving
            -- should not happen anymore since the energy reserve of a building is updated when the energy choose the building as target
            self.target = self.past
            return
        end
        
        if #nearbyBuildings > 0 then
            -- at least one building in range
            -- first check for building in construction
            for i, building in ipairs(nearbyBuildings) do
                if building.isBuilt == false then
                    nextTarget = building
                    break
                end
            end
        end
        
        -- now look for nodes in construction
        if nextTarget == nil and #nearbyNodes > 0 then
            for i, node in ipairs(nearbyNodes) do
                if node.isBuilt == false then
                    nextTarget = node
                    break
                end
            end
        end
        
        -- if still no target, check buildings that needs energy
        -- then pick one of them at random
        if nextTarget == nil and #nearbyBuildings > 0 then
            local thirstyBuildings = {}
            for i, building in ipairs(nearbyBuildings) do
                if building.energyReserve <= Game[building.buildingType].maxEnergyReserve - 1 then
                    table.insert(thirstyBuildings, building)
                end
            end
            
            if #thirstyBuildings > 0 then
                local rand = math.round(math.randomrange(1, #thirstyBuildings)) 
                nextTarget = thirstyBuildings[rand]
            end
            
            if nextTarget ~= nil then
                -- building chosen,
                -- update its energy Reserve now (even if the energy has reach it yet), so that other energy do not choose this building
                nextTarget.energyReserve = nextTarget.energyReserve + 1
                self.isDepleted = true
            end
        end
        
        -- if still no target, there is no buildings of interest around nor node in construction
        -- check for other nodes but the previous one (if possible)
        if nextTarget == nil then
            if #nearbyNodes == 0 then -- the energy is just out of a powerstation, but the node is not in range of any other nodes
                self.gameObject:Destroy()
                return
            end
            
            while nextTarget == nil do
                local rand = math.round(math.randomrange(1, #nearbyNodes)) 
                nextTarget = nearbyNodes[rand]
                
                if nextTarget == self.past and #nearbyNodes >= 2 then -- prevent going back unless there is no choice, effectively force energy to move forward when on a "highway"
                    nextTarget = nil
                end
            end
        end
        
        if nextTarget == nil then
            print("error with energy")
            self.gameObject:Destroy()
            return
        end
        
        
        self.past = self.target
        self.target = nextTarget
        
        if self.target.inner == nil or self.target.transform == nil then
            self.target = nil
            return
        end
        
        self.targetPosition = self.target.transform.position
    end -- end if close enought
end
