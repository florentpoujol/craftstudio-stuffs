table.print(Sound)

-- Allow to pass a mouseInput component as argument to force the update of this component
function MouseInput.Update( mouseInput )
    MouseInput.frameCount = MouseInput.frameCount + 1
    
    local mouseDelta = CS.Input.GetMouseDelta()
    local mouseIsMoving = false
    if mouseDelta.x ~= 0 or mouseDelta.y ~= 0 then
        mouseIsMoving = true
    end

    local leftMouseJustPressed = false
    local leftMouseDown = false
    local leftMouseJustReleased = false
    if MouseInput.buttonExists.LeftMouse then
        leftMouseJustPressed = CS.Input.WasButtonJustPressed( "LeftMouse" )
        leftMouseDown = CS.Input.IsButtonDown( "LeftMouse" )
        leftMouseJustReleased = CS.Input.WasButtonJustReleased( "LeftMouse" )
    end

    local rightMouseJustPressed = false
    if MouseInput.buttonExists.RightMouse then
        rightMouseJustPressed = CS.Input.WasButtonJustPressed( "RightMouse" )
    end

    local wheelUpJustPressed = false
    if MouseInput.buttonExists.WheelUp then
        wheelUpJustPressed = CS.Input.WasButtonJustPressed( "WheelUp" )
    end

    local wheelDownJustPressed = false
    if MouseInput.buttonExists.WheelDown then
        wheelDownJustPressed = CS.Input.WasButtonJustPressed( "WheelDown" )
    end
    
    local forceUpdate = (mouseInput ~= nil)
 
    if 
        forceUpdate == true or
        mouseIsMoving == true or
        leftMouseJustPressed == true or 
        leftMouseDown == true or
        leftMouseJustReleased == true or 
        rightMouseJustPressed == true or
        wheelUpJustPressed == true or
        wheelDownJustPressed == true
    then
        local doubleClick = false
        if leftMouseJustPressed then
            doubleClick = ( MouseInput.frameCount <= MouseInput.lastLeftClickFrame + MouseInput.Config.doubleClickDelay )   
            MouseInput.lastLeftClickFrame = MouseInput.frameCount
        end

        local reindexComponents = false
        
        local components = MouseInput.components
        if mouseInput ~= nil then
            components = { mouseInput }
        end
        
        for i=1, #components do
            local component = components[i]
            local mi_gameObject = component.gameObject -- mouse input game object

            if mi_gameObject.inner ~= nil and not mi_gameObject.isDestroyed and mi_gameObject.camera ~= nil then
                local ray = mi_gameObject.camera:CreateRay( CS.Input.GetMousePosition() )
                
                for j=1, #component._tags do
                    local tag = component._tags[j]
                    local gameObjects = GameObject.GetWithTag( tag )

                    for k=1, #gameObjects do
                        local gameObject = gameObjects[k]
                        -- gameObject is the game object whose position is checked against the raycasthit
                            
                        local raycastHit = ray:IntersectsGameObject( gameObject )
                        if raycastHit ~= nil then
                            -- the mouse pointer is over the gameObject
                            if not gameObject.isMouseOver then
                                gameObject.isMouseOver = true
                                Daneel.Event.Fire( gameObject, "OnMouseEnter", gameObject )
                            end

                        elseif gameObject.isMouseOver == true then
                            -- the gameObject was still hovered the last frame
                            gameObject.isMouseOver = false
                            Daneel.Event.Fire( gameObject, "OnMouseExit", gameObject )
                        end
                        
                        if gameObject.isMouseOver == true then
                            Daneel.Event.Fire( gameObject, "OnMouseOver", gameObject, raycastHit )

                            if leftMouseJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnClick", gameObject )

                                if doubleClick == true then
                                    Daneel.Event.Fire( gameObject, "OnDoubleClick", gameObject )
                                end
                            end

                            if leftMouseDown == true and mouseIsMoving == true then
                                Daneel.Event.Fire( gameObject, "OnDrag", gameObject )
                            end

                            if leftMouseJustReleased == true then
                                Daneel.Event.Fire( gameObject, "OnLeftClickReleased", gameObject )
                            end

                            if rightMouseJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnRightClick", gameObject )
                            end

                            if wheelUpJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnWheelUp", gameObject )
                            end
                            if wheelDownJustPressed == true then
                                Daneel.Event.Fire( gameObject, "OnWheelDown", gameObject )
                            end
                        end
                    end -- for gameObjects with current tag
                end -- for component._tags
            else
                -- this component's game object is dead or has no camera component
                components[i] = nil
                reindexComponents = true
            end -- gameObject is alive
        end -- for MouseInput.components

        if reindexComponents == true then
            if mouseInput == nil then
                MouseInput.components = table.reindex( components )
            end
        end
    end -- if mouseIsMoving, ...
end -- end MouseInput.Update() 


--- Register all functions of a scripted behavior to be included in the stacktrace.
-- Within a script, the 'Behavior' variable is the script asset.
-- @param script (Script) The script asset.
function Daneel.Debug.RegisterScript( script )
    if type( script ) ~= "table" or getmetatable( script ) ~= Script then
        error("Daneel.Debug.SetupScript(script): Provided argument is not a script asset. Within a script, the 'Behavior' variable is the script asset.")
    end
    local infos = Daneel.Debug.functionArgumentsInfo
    local forbiddenNames = { "Update", "inner" }
    -- Awake, is never included in the stacktrace anyway because CraftStudio
    -- keeps the reference to the function first set in the script.
    -- Overloading it at runtime has no effect.
    -- 05/12/2014 It isn't the case for Start()

    local scriptPath = Map.GetPathInPackage( script )
    for name, func in pairs( script ) do
        local fullName = scriptPath.."."..name
        if 
            not string.startswith( name, "__") and
            not table.containsvalue( forbiddenNames, name ) and
            infos[fullName] == nil
        then
            infos[fullName] = { script = script }
        end
    end
end


function Trigger.GetGameObjectsInRange( trigger )
    local triggerPosition = trigger.gameObject.transform:GetPosition() 
    local gameObjectsInRange = {}
    for i=1, #trigger._tags do
        local gameObjects = GameObject.GetWithTag( trigger._tags[i] )
        for j=1, #gameObjects do
            local gameObject = gameObjects[j]
            if 
                gameObject ~= trigger.gameObject and
                trigger:IsGameObjectInRange( gameObject, triggerPosition )
            then
                table.insertonce( gameObjectsInRange, gameObject )
            end
        end
    end
    return gameObjectsInRange
end
