
Pipes = {
    spawnPosition = Vector3(60,0,-6),
    
    moveSpeed = 15, -- units per second
    
    gap = { min = 12, max = 16 }, -- units
    frequency = { min = 2, max = 4 }, -- seconds
    
    Spawn = function()
        GameObject.New( "Pipes" ) -- append the Pipes scene (prefab)
    end
}

local lastSpawnY = 0

function Behavior:Awake()
    self.topGO = self.gameObject:GetChild("Top")
    self.bottomGO = self.gameObject:GetChild("Bottom")
    
    -- Set the spawn position
    local minSpawn = lastSpawnY-10
    if minSpawn < -18 then minSpawn = -18 end
    
    local maxSpawn = lastSpawnY+10
    if maxSpawn > 20 then maxSpawn = 20 end
    -- this prevent the pipes to spawn to far away (vertically) of the previous pipes
    
    Pipes.spawnPosition.y = math.randomrange( minSpawn, maxSpawn )   
    self.gameObject.transform.position = Pipes.spawnPosition
    
    -- Set the gap between two pipes
    self.gap = math.randomrange( Pipes.gap.min, Pipes.gap.max ) -- the size in scene units of the gap
    self.topGO.transform.localPosition = Vector3(0,self.gap/2,0)  
    self.bottomGO.transform.localPosition = Vector3(0,-self.gap/2,0) -- both pipes ar at equal distance from this game oject origin
    
    -- Schedule the next spawn
    Tween.Timer( math.randomrange( Pipes.frequency.min, Pipes.frequency.max), Pipes.Spawn )
    
    self.isActive = true -- check collisions ?
    self.isPassed = false -- bird has reach it yet ?
end

local birdHalfWidth = 2.6*1.5 -- 85/2/16 = 2.65625   85 is the width in texture pixels of the bird's model
local birdHalfHeight = 1.8*1.5 -- 60/2/16 = 1.875
-- 1.5 is the scale of the bird's model

local collisionOffset = 4.6 + birdHalfWidth -- the horizontal distance between the bird's origin and the pipes's middle
-- 148/2/16 = 4.625 = the half-width in scene units of the pipe

function Behavior:Update()
    if GamePaused then
        return
    end
    
    -- Move the pipes
    self.gameObject.transform:Move( Vector3( -Pipes.moveSpeed * Daneel.Time.deltaTime, 0,0 ) )
    local position = self.gameObject.transform.position
    
    -- calculate the distance between the right side of the bird and the left side of the pipe
    local collisionDistance = position.x + 25 - collisionOffset -- +25  because the bird is at x=-25
    
    -- Check collision with the bird
    if self.isActive and collisionDistance < 0 and BirdGO ~= nil then
        local birdPos = BirdGO.transform.position
        
        -- we know that the bird is close enough to collide
        -- now check if it is in the pipe's gap
        if
            birdPos.y + birdHalfHeight >= position.y + self.gap/2 or -- too high
            birdPos.y - birdHalfHeight <= position.y - self.gap/2 -- too low
       then
            BirdGO.s:Die()
            return
        end
    end
    
    -- Check when the bird pass the pipes
    if not self.isPassed and position.x <= -25 then -- the bird's x coordinate is always -25
        self.isPassed = true
        Pipes.moveSpeed = Pipes.moveSpeed + 0.1 -- increase difficulty a little
        UI.score:Update()
    end
    
    -- Deactivate the collision detection when the bird is finally behind the pipe
    if self.isActive and collisionDistance < -collisionOffset*2 then
        self.isActive = false
    end
    
    -- Destroy the pipes when they reach the far left of the level
    if position.x < -60 then
        self.gameObject:Destroy()
    end
end
