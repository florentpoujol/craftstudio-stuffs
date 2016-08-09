--[[PublicProperties
moveSpeed number 0.2
moveOriented boolean False
rotationSpeed number 10
isMouseLocked boolean True
/PublicProperties]]
--[[
------------------------------
    CameraControl
------------------------------

Script controlling the game object's movement based on user inputs.
Must be added as a scripted behavior on a game object.

You must map the following buttons (in the project's Administration > Game Controls tab) : 
RightMouse, CameraForward, CameraBackward, CameraLeft, CameraRight, CameraUp, CameraDown

Based on XTender's FreeCam and EgoMoveByCam scripts.

Properties :

    moveSpeed (number) [default=0.2] Movement speed modifier (higher = faster)
    moveOriented (boolean) [default=false] When true the gameObject moves like in the scene editor
    rotationSpeed (number) [default=10] Rotation speed modifier (smaller = faster)
    isMouseLocked (boolean) [default=true] Tell wether the camera starts in a locked state (true) or not (false).
]]

--[[PublicProperties
moveSpeed number 0.2
moveOriented boolean false
rotationSpeed number 10
isMouseLocked boolean true
/PublicProperties]]

function Behavior:Awake()
    self.lookAngles = self.gameObject.transform:GetLocalEulerAngles()
    
    if self.isMouseLocked then
        CS.Input.LockMouse()
    end
end

 
function Behavior:Update()

    if CS.Input.WasButtonJustPressed( "RightMouse" ) then
        if self.isMouseLocked then
            CS.Input.UnlockMouse()
            self.isMouseLocked = false
        else
            CS.Input.LockMouse()
            self.isMouseLocked = true
        end
    end
    
    --rotate
    if self.isMouseLocked then
        local mouseDelta = CS.Input.GetMouseDelta()
        
        self.lookAngles.x = self.lookAngles.x - mouseDelta.y / self.rotationSpeed
        self.lookAngles.y = self.lookAngles.y - mouseDelta.x / self.rotationSpeed
        
        self.gameObject.transform:SetLocalEulerAngles( self.lookAngles )
    end
    
    -- move
    self.moveVector = Vector3:New(0)
    
    if self.moveOriented then

        if CS.Input.IsButtonDown( "CameraLeft" ) then
            self.moveVector.x = -self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraRight" ) then
            self.moveVector.x = self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraUp" ) then
            self.moveVector.y = self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraDown" ) then
            self.moveVector.y = -self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraForward" ) then
            self.moveVector.z = -self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraBackward" ) then
            self.moveVector.z = self.moveSpeed 
        end
    
        --
        if self.moveVector ~= Vector3:New(0) then
            self.gameObject.transform:MoveOriented( self.moveVector )
        end

    else -- self.moveOiented == false
        -- move like in the scene (don't change altitude based on camera's orientation)
     
        local lookAxis = self.lookAngles.y / 180 * math.pi
        
        --
        if CS.Input.IsButtonDown( "CameraLeft" ) then
            self.moveVector.z = math.sin( lookAxis )
            self.moveVector.x = -math.cos( lookAxis )
        end
        
        if CS.Input.IsButtonDown( "CameraRight" ) then
            self.moveVector.z = -math.sin( lookAxis )
            self.moveVector.x = math.cos( lookAxis )
        end
        
        if CS.Input.IsButtonDown( "CameraUp" ) then
            self.moveVector.y = self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraDown" ) then
            self.moveVector.y = -self.moveSpeed 
        end
        
        if CS.Input.IsButtonDown( "CameraForward" ) then
            self.moveVector.z = self.moveVector.z + -math.cos( lookAxis )
            self.moveVector.x = self.moveVector.x + -math.sin( lookAxis )
        end
        
        if CS.Input.IsButtonDown( "CameraBackward" ) then
            self.moveVector.z = self.moveVector.z + math.cos( lookAxis )
            self.moveVector.x = self.moveVector.x + math.sin( lookAxis )
        end
        
        --
        local moveLength = math.sqrt( self.moveVector.x^2, self.moveVector.z^2 )
        if moveLength > 1 then
           self.moveVector.x = self.moveVector.x / moveLength
           self.moveVector.z = self.moveVector.z / moveLength
        end
        
        self.moveVector.x = self.moveVector.x * self.moveSpeed
        self.moveVector.z = self.moveVector.z * self.moveSpeed 
        
        if self.moveVector ~= Vector3:New(0) then
            self.gameObject.transform:Move( self.moveVector )
        end

    end -- end if self.moveOriented
end -- end Behavior:Update()
