--[[PublicProperties
spawnNextGround boolean False
/PublicProperties]]

local groundSpeed = 20 -- units per second (pipes are 15)
local groundPositionX = 108 -- spawn position and 

function Behavior:Awake()
    self.spawnPosition = self.gameObject.transform.position
    self.spawnPosition.x = groundPositionX
end

function Behavior:Update()
    if GamePaused then
        return
    end
    
    self.gameObject.transform:Move( Vector3( -groundSpeed * Daneel.Time.deltaTime, 0,0 ) )
    
    if self.gameObject.transform.position.x < -groundPositionX then
        -- this ground piece has reached the far left of the level, move it to the far right, so that the ground appear to be infinite
        self.gameObject.transform.position = self.spawnPosition
    end
end
