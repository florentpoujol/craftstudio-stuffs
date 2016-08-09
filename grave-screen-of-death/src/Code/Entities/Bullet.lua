
function Behavior:Awake()
    self.gameObject.s = self
    self.speed = Game.bulletSpeed -- 80 /second
    self.frameCount = 0
end

function Behavior:SetTarget( target, targetGO ) -- targetGO is the enemy's renderer
    self.target = target
    if targetGO ~= nil then
        self.enemyGO = targetGO.parent 
    end
    
    self.direction = (target - self.gameObject.transform.position):Normalized()
    self.speedDirection = self.direction * self.speed * 1/60
    self.gameObject.transform:LookAt(target)
end

function Behavior:Update()
    if Game.isPaused then
        return
    end
    
    self.frameCount = self.frameCount + 1
    if self.frameCount > 60 then
        self.gameObject:Destroy()
    end
    
    if self.direction ~= nil then
        self.gameObject.transform:Move( self.speedDirection )
        local selfPosition = self.gameObject.transform.position
         
        if self.enemyGO ~= nil and self.enemyGO.inner ~= nil then
            local sqrDist = (self.enemyGO.transform.position - selfPosition):GetSqrLength()
            if sqrDist < 3 then
                self.enemyGO.s:TakeDamage( Game.playerShootDamage )
                self.gameObject:Destroy()
                return
            end
        end
        
        local sqrDist = (self.target - selfPosition):GetSqrLength()
        if sqrDist < 1 then
            self.gameObject:Destroy()
        end
    end    
end
