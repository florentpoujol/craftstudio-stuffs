-- Modified jump script from "Simple Jump Tutorial" project   http://open.craftstud.io/176.31.207.61/9c0851c4-4dcc-4a70-a922-8ad0b964c4c2

local gravity = -0.02
BirdGO = nil

function Behavior:Awake()
    BirdGO = self.gameObject
    self.gameObject.s = self
    
    GamePaused = false -- Make sure the game is "unpaused"

    self.gameStarted = false
    
    -- Define a vertical speed for the bird
    self.velocityY = 0
end

-- Called from UI:Awake() when the get ready text has completely fade out
function Behavior:StartGame()
    self.gameStarted = true -- makes the Update() function below run
    
    -- Use a tweener to orient the bird toward the ground when it is falling.
    self.noseDiveTweener = self.gameObject:Animate( "eulerAngles", Vector3(0,0,-60), 1.5, { 
        destroyOnComplete = false,
        easeType = "inOutQuad",
        startValue =  Vector3(0,0,20), -- face a little upward
        elapsed = 0.5 -- prevent the bird to suddently face up at the start of the game, yet the player hasn't pressed any key yet
    } )
    
    -- Animate the birds wings (start now and loop)
    self.gameObject.modelRenderer.animation = "Flap"
end

function Behavior:Update()
    if GamePaused or self.gameStarted == false then
        return
    end
    
    -- Get input
    if CS.Input.WasButtonJustPressed( "Space" ) or CS.Input.WasButtonJustPressed( "LeftMouse" ) then
        self.velocityY = 0.35
        self.noseDiveTweener:Restart()
    end
    
    -- Apply gravity (which is an acceleration) to our vertical speed
    self.velocityY = self.velocityY + gravity
    
    -- Apply the object's velocity to its position
    self.gameObject.transform:Move( Vector3( 0, self.velocityY, 0 ) )
    
    -- Check if bird has hit the ground or the top of the screen
    -- Collision against the pipes are handled by the pipes themselves, in the Pipes script
    local pos = self.gameObject.transform.position
    if pos.y < -22 or pos.y > 35 then
        self:Die()
    end
end

-- The bird has hit the ground, "ceiling" or a pipe
function Behavior:Die()
    GamePaused = true -- stops the ground, pipes and bird
    self.noseDiveTweener:Pause()
    self.gameObject.modelRenderer:StopAnimationPlayback() -- stops the flap animation
    
    UI.gameOver:Show()
end
