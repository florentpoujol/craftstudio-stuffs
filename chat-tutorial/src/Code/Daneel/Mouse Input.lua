--[[PublicProperties
tags string ""
updateInterval number 2
/PublicProperties]]
-- Mouse Input.lua
-- Enable mouse interactions with game objects when added to a game object with a camera component.
--
-- Last modified for v1.3.0
-- Copyright © 2013-2014 Florent POUJOL, published under the MIT license.

MouseInput = {}

if CS.DaneelModules == nil then
    CS.DaneelModules = {}
end
CS.DaneelModules[ "MouseInput" ] = MouseInput

function MouseInput.DefaultConfig()
    return {
        doubleClickDelay = 20 -- Maximum number of frames between two clicks of the left mouse button to be considered as a double click
    }
end
MouseInput.Config = MouseInput.DefaultConfig()


----------------------------------------------------------------------------------



function Behavior:Awake()
    if not MouseInput.isLoaded then
        if table.getvalue( _G, "MouseInputUserConfig" ) ~= nil and type( MouseInputUserConfig ) == "function" then
            MouseInput.Config = MouseInputUserConfig()
        end
        MouseInput.isLoaded = true
    end

    Daneel.Debug.StackTrace.BeginFunction( "MouseInput:Awake" )

    if self.gameObject.camera == nil then
        CS.Destroy( self )
        error( "MouseInput:Awake() : GameObject with name '" .. self.gameObject:GetName() .. "' has no Camera component attached." )
    end  

    self.tags = string.split( self.tags, "," )
    for k, v in pairs( self.tags ) do
        self.tags[ k ] = string.trim( v )
    end
    self.gameObject.mouseInput = self
    self.frameCount = 0
    self.lastLeftClickFrame = -MouseInput.Config.doubleClickDelay
    
    self.update = false -- prevent the system to miss a click if it happens when   self.frameCount % self.updateInterval ~= 0  by forcing the update
    Daneel.Event.Listen(
        { "OnLeftMouseButtonWasJustPressed", "OnLeftMouseButtonDown", "OnRightMouseButtonWasJustPressed" },
        function() self.update = true end
    )


    Daneel.Debug.StackTrace.EndFunction()
end

function Behavior:Update()
    self.frameCount = self.frameCount + 1
    if self.update or self.frameCount % self.updateInterval == 0 then
        self.update = false

        local leftMouseJustPressed = CS.Input.WasButtonJustPressed( "LeftMouse" )
        local leftMouseDown = CS.Input.IsButtonDown( "LeftMouse" )
        local rightMouseJustPressed = CS.Input.WasButtonJustPressed( "RightMouse" )
        
        local doubleClick = false
        if leftMouseJustPressed then
            doubleClick = ( self.frameCount <= self.lastLeftClickFrame + MouseInput.Config.doubleClickDelay )   
            self.lastLeftClickFrame = self.frameCount
        end

        local vector = CS.Input.GetMouseDelta()
        local drag = false
        if vector.x ~= 0 or vector.y ~= 0 then
            drag = true
        end

        local mousePosition = CS.Input.GetMousePosition()
        local reindex = true
        
        for i, tag in pairs( self.tags ) do
            local gameObjects = GameObject.Tags[ tag ]
            if gameObjects ~= nil then

                for i, gameObject in pairs( gameObjects ) do
                    if gameObject.inner ~= nil then
                        -- OnMouseEnter, OnMouseOver, OnMouseExit, gameObject.isMouseOver
                        local ray = self.gameObject.camera:CreateRay( mousePosition )
                                                
                        if ray:IntersectsGameObject( gameObject ) then
                            -- the mouse pointer is over the gameObject
                            -- the action will depend on if this is the first time it hovers the gameObject
                            -- or if it was already over it the last frame
                            -- also on the user's input (clicks) while it hovers the gameObject
                            if gameObject.isMouseOver then
                                Daneel.Event.Fire( gameObject, "OnMouseOver", gameObject )
                            else
                                gameObject.isMouseOver = true
                                Daneel.Event.Fire( gameObject, "OnMouseEnter", gameObject )
                            end

                        elseif gameObject.isMouseOver then
                            -- was the gameObject still hovered the last frame ?
                            gameObject.isMouseOver = false
                            Daneel.Event.Fire( gameObject, "OnMouseExit", gameObject )
                        end
                        

                        if gameObject.isMouseOver then
                            if leftMouseJustPressed then
                                Daneel.Event.Fire( gameObject, "OnClick", gameObject )

                                if doubleClick then
                                    Daneel.Event.Fire( gameObject, "OnDoubleClick", gameObject )
                                end
                            end

                            if leftMouseDown and drag then
                                Daneel.Event.Fire( gameObject, "OnDrag", gameObject )
                            end

                            if rightMouseJustPressed then
                                Daneel.Event.Fire( gameObject, "OnRightClick", gameObject )
                            end
                        end
                    else -- else if gameObject is destroyed
                        gameObjects[ i ] = nil
                        reindex = true
                    end
                end -- end looping on gameObjects with current tag

                if reindex then
                    GameObject.Tags[ tag ] = table.reindex( gameObjects )
                    reindex = false
                end
            end
        end -- end looping on tags
    end

end -- end of Behavior:Update() function
