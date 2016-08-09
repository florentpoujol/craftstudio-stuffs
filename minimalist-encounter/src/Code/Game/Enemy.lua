
function Behavior:Awake()
    self.gameObject.isAlive = true
    self.health = Game.enemy.health
    self.lastFrameHealth = self.health
    self.target = nil
    self.isAttacking = false
    self.position = nil
end

function Behavior:Start()
    -- health bar
    
    local pivot = GameObject.New("Prefabs/Bar", {
        parent = self.gameObject,
        transform = {
            localPosition = Vector3(0, 1.5, 0),
            localScale = Vector3(1.66, 1.66,1.66)
        }
    })
    pivot.transform.eulerAngles = Vector3(30, 180, 0) -- does not seems to work when set in the params table above ??
    
    local background = pivot:GetChild("Background", true)
    background.progressBar:Set({
        maxLength = 1.05,
        height = 0.25,
        progress = "100%",
    })
    background.modelRenderer.opacity = 0.2
    
    local foreground = pivot:GetChild("Foreground", true)
    foreground.transform.localPosition = Vector3(0.025,0,0.01)
    foreground.progressBar:Set({
        maxLength = 1,
        height = 0.2,
        maxValue = self.heatlh,
        progress = "100%",
    })
    foreground.modelRenderer.opacity = 0.2
    
    self.gameObject.healthBarPivot = pivot
    self.gameObject.healthBarBackground = background
    self.gameObject.healthBar = foreground.progressBar
    self.positionOffset = Vector3(0,1,0)
end


function Behavior:Update()
    if self.gameObject.isAlive == false then
        return
    end
    
    self.position = self.gameObject.transform.position
    
    -- health bar
    if self.health < self.lastFrameHealth then
        self.lastFrameHealth = self.health
        self.gameObject.healthBar:UpdateProgress(self.health)
        
        if self.gameObject.healthBarBackground.modelRenderer.opacity < 1 then
            self.gameObject.healthBar.gameObject.modelRenderer.opacity = 1
            self.gameObject.healthBarBackground.modelRenderer.opacity = 1
        end
    end
    
    -- alive target : move toward the target and check if it is close enougth to attack
    if self.target ~= nil and not self.target.isDestroyed and self.target.isAlive then
        local targetPosition = self.target.transform.position
        local direction = self.target.transform.position - self.position
        local distance = direction:Length()
        
        if distance > Game.enemy.range then
            self.isAttacking = false
            self.gameObject.transform:MoveOriented( direction:Normalized() * Daneel.Time.deltaTime * Game.enemy.speed )
        else
            self.isAttacking = true
        end
    end
    
    -- dead target
    if self.target == nil or self.target.isDestroyed or not self.target.isAlive then
       self.target = nil
       self.isAttacking = false
    end
    
    -- Get a target (the closest building)
    if self.target == nil then
        local buildings = {}
        if GameObject.Tags.buildings ~= nil then
            buildings = table.copy(GameObject.Tags.buildings)
        end
        if GameObject.Tags.nodes ~= nil then
            buildings = table.merge(buildings, GameObject.Tags.nodes)
        end
        
        if #buildings <= 0 then
            -- All buildings have been destroyed
            Daneel.Event.Fire("OnGameOver")
            return
        end
        
        local closestBuilding = { distance = 999999, building = nil }
        
        for i, building in ipairs(buildings) do
            if building.inner ~= nil and building.isAlive then
                local distance = Vector3.Distance(self.position, building.transform.position)
                if distance < closestBuilding.distance then
                    closestBuilding.distance = distance
                    closestBuilding.building = building
                end
            end
        end
        
        self.target = closestBuilding.building
        
        if self.target == nil then
            print("ERROR with enemy, no suitable buildings")
            enemy:Destroy()
            return
        end
    end
    
    if self.target ~= nil and self.isAttacking then -- when the enemy is close enough
        self.target.buildingScript:TakeDamage( Game.enemy.damage * Daneel.Time.deltaTime )
    end
end


-- called from the tower
function Behavior:TakeDamage(amount)
    self.health = self.health - amount
    if self.health <= 0 then
        self.gameObject.isAlive = false
        self.gameObject:Destroy()
        Daneel.Event.Fire("UpdateGameScore", Game.enemy.score)
    end
end
