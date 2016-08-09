--[[PublicProperties
scene string ""
spawnRate number 0
duration number 0
isPaused boolean False
/PublicProperties]]
--[[
Scripted behavior that can append a scene (spawn a game object) repeatedly.

Properties :
    
    scene (string) The fully qualified path of the scene to append.
    spawnRate (number) The rate in scene per second at which to append the scenes
    duration (number) The time in second during which to spawn
    isPaused (boolean) Tell wether the spawner is paused or not.
    isCompleted (boolean) Is 'false' while the timer runs, becomes 'true' when is has completed (time >= duration ).
    elapsed (number)

Function :

    spawner:Spawn() Spawn the scene and move the spawned game object at the coordinates of this game object. Doesn't modify any of the properties.
]]

--[[PublicProperties
scene string ""
spawnRate number 0
duration number 0
isPaused boolean  true
/PublicProperties]]

function Behavior:Awake()
    self.isCompleted = false
    self.elapsed = 0 -- elapsed time, delay excluded
    self.frameCount = 0
    self.lastTime = os.clock()
    self.gameObject.spawner = self
end

function Behavior:Update()
    local currentTime = os.clock()
    local deltaTime = currentTime - self.lastTime
    self.lastTime = currentTime
    
    if self.isPaused == false and self.isCompleted == false and self.duration ~= 0 then
        self.frameCount = self.frameCount + 1
        if self.frameCount % (60 / self.spawnRate) == 0 then
            self:Spawn()
        end

        self.elapsed = self.elapsed + deltaTime
        if self.duration > 0 and self.elapsed >= self.duration then
            self.isComplete = true
        end
    end
end

function Behavior:Spawn()
    if self.scene ~= nil then
        if type( self.scene ) == "string" then
            self.scene = CS.FindAsset( self.scene, "Scene" )
        end
        if self.scene == nil then
            error( "spawner:Spawn() : The 'scene' property is nil." )
        end
        
        local gameObject = CS.AppendScene( self.scene )
        
        if gameObject ~= nil then
            local selfPosition = self.gameObject.transform:GetPosition()
            if gameObject.physics ~= nil then
                gameObject.physics:WarpPosition( selfPosition )
            else
                gameObject.transform:SetPosition( selfPosition )
            end
        end
    end
end
