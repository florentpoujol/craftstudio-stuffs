
function Behavior:Update()
    -- handle moving the view when the mouse is close to the border of the screen
    local mousePosition = CS.Input.GetMousePosition()
    local screenSize = CS.Screen.GetSize()
    if mousePosition.x < -50 or mousePosition.x > screenSize.x + 50 or
       mousePosition.y < -50 or mousePosition.y > screenSize.y + 50 then
        -- mouse too far outside of the game's window
        return
    end
    
    local direction = Vector3(0)
    local borderSize = 40 -- pixels
    
    
    if mousePosition.x < borderSize then
        direction = direction + Vector3( -1, 0, 0 )
    elseif mousePosition.x > screenSize.x - borderSize then
        direction = direction + Vector3( 1, 0, 0 )
    end
    
    if mousePosition.y < borderSize then
        direction = direction + Vector3( 0, 1, 0 )
    elseif mousePosition.y > screenSize.y - borderSize then
        direction = direction + Vector3( 0, -1, 0 )
    end
    
    if direction ~= Vector3(0) then
        Game.camera.transform:Move( direction * 0.5 )
    end
    
    
    -- handle Zoom with scroll wheel
    if CS.Input.IsButtonDown( "WheelUp" ) then
        Game.camera.transform:Move( Vector3( 0, 0, 1 ) )
        
    elseif CS.Input.IsButtonDown( "WheelDown" ) then
        Game.camera.transform:Move( Vector3( 0, 0, -1 ) )
    end
end
