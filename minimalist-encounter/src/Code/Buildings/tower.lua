
function Behavior:Awake()
    self.gameObject.buildingType = "tower"
    self.target = nil
    self.targetPosition = nil
    self.targetDistance = nil
end


function Behavior:Start()
    self.position = self.gameObject.transform.position
    self.laserGOPosition = self.position + Vector3:New(0, 0.5, 0)
    self.gameObject.trigger.range = Game.tower.range
    self.gameObject.trigger.tags = {"enemies"}
    
    -- create the laser
    self.laserGO = GameObject.New("laser", {
        parent = self.gameObject,
        transform = {
            position = self.laserGOPosition,
            localScale = Vector3:New(0.01),
        },
        modelRenderer = { model = "Laser" },
    })
end


function Behavior:Update()
    if not self.gameObject.isAlive or not self.gameObject.isBuilt or self.gameObject.energyReserve <= 0 then
        self.laserGO.modelRenderer.opacity = 0
        return
    end
    
    -- choose a new target if dead or not in range anymore
    if
        self.target == nil or self.target.isDestroyed or not self.target.isAlive or
        Vector3.Distance(self.target.transform.position, self.position) <= Game.tower.range
    then 
        self.laserGO.modelRenderer.opacity = 0
        
        self.target = nil
        
        local enemies = self.gameObject.trigger:GetGameObjectsInRange()
        if #enemies >= 1 then
            self.target = enemies[1]
        end
    end

    -- Shoot the target (if any)
    if self.target ~= nil and not self.target.isDestroyed and self.target.isAlive then
        local targetPosition = self.target.transform.position
        local targetDistance = Vector3.Distance(targetPosition, self.laserGOPosition)
        
        self.laserGO.transform:LookAt(targetPosition)
        self.laserGO.transform.localScale = Vector3:New(0.05,0.05, targetDistance)
        self.laserGO.modelRenderer.opacity = 1
            
        self.gameObject.energyReserve = self.gameObject.energyReserve - Game.tower.shootEnergyCost * Daneel.Time.deltaTime
        if self.gameObject.energyReserve < 0 then self.gameObject.energyReserve = 0 end
        
        self.target.enemyScript:TakeDamage(Game.tower.damage * Daneel.Time.deltaTime)
    end
end
