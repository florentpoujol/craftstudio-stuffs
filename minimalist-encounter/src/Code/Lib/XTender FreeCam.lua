-- Credit : XTenders from the "XTenders Suicase" project
-- modified

local CAM_SPEED = 0.15

local mouseLocked = true

function Behavior:Awake() 
    self.lookAngles = { x=0, y=0 }
    CraftStudio.Input.LockMouse()
end
 
function Behavior:Update()

    if CraftStudio.Input.WasButtonJustPressed("RightMouse") then

        if mouseLocked then
            CraftStudio.Input.UnlockMouse()
            mouseLocked = false
        else
            CraftStudio.Input.LockMouse()
            mouseLocked = true
        end

    end
     
    if mouseLocked then
        local mouseDelta = CraftStudio.Input.GetMouseDelta()
     
        -- Apply mouse delta
        self.lookAngles.x = self.lookAngles.x - mouseDelta.x / 10
        self.lookAngles.y = self.lookAngles.y - mouseDelta.y / 10
      
        -- Update camera orientation
        self.gameObject.transform:SetLocalEulerAngles( Vector3:New(self.lookAngles.y, self.lookAngles.x, 0) )
        
        local moveSpeed = CAM_SPEED;
    
        if CraftStudio.Input.IsButtonDown( "RightArrow" ) then
            self.gameObject.transform:MoveOriented(Vector3:New(moveSpeed, 0, 0))     
        end
    
        if CraftStudio.Input.IsButtonDown( "LeftArrow" ) then
            self.gameObject.transform:MoveOriented(Vector3:New(-moveSpeed, 0, 0))
        end
    
        if CraftStudio.Input.IsButtonDown( "UpArrow" ) then
            self.gameObject.transform:MoveOriented(Vector3:New(0, 0, -moveSpeed))     
        end
    
        if CraftStudio.Input.IsButtonDown( "DownArrow" ) then
            self.gameObject.transform:MoveOriented(Vector3:New(0, 0, moveSpeed))     
        end
    end
end
