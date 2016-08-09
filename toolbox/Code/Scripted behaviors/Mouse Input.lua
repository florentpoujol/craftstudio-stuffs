--[[PublicProperties
tags string ""
updateInterval number 5
/PublicProperties]]
--[[

IMPORTANT :
- this file depends on the Tags file that you can find in the toolbox too
- You need to add a "LeftMouse" and a "RightMouse" control in the game's Controls (in the project's Administration)


Add this script as a scripted behavior to a camera and set the tags public property (concatenate several tags with a coma) to enable interaction between the mouse and game objects when they have the proper tag and are visible from the camera.
The updateInterval property is the number of frames between two interactions.

When a game object is hovered by the mouse for the first frame (it is hovered this frame, but it wasn't the last frame), the OnMouseEnter message is sent on the game object.
The frame the mouse stops hovering the game object (it is not hovered this frame but was hovered the last frame), the OnMouseExit message is sent on the game object.

As long as the mouse stays over the game object, the OnMouseOver message is sent each frame (each updateInterval) on the game object.
The OnClick (for a single left click), OnDoubleClick (for a double left click) and OnRightClick messages are sent on the game object when the click just happens and the mouse hovers the game object.
A double click is two left clicks separated by no more frames than the value of input.doubleClickDelay in the config. Default is 20 frames (1/3 of a second).

Using the click messages requires you to setup a "LeftMouse" and a "RightMouse" button in your game controls (in the Administration > Game Controls tab).

Check the value of the isMouveOver property on the game object to know if it is currently hovered by the mouse. The property is true when the game object is hovered, or false (or nil) otherwise.

]]

--[[PublicProperties
tags string ""
updateInterval number 5
/PublicProperties]]

local doubleClickDelay = 20 -- Maximum number of frames between two clicks of the left mouse button to be considered as a double click

function Behavior:Awake()
    if self.gameObject.camera == nil then
        CS.Destroy( self )
        error( "MouseInput:Awake() : GameObject with name '" .. self.gameObject:GetName() .. "' has no Camera component attached." )
    end  

    self.tags = self.tags:split( "," )
    for i, tag in pairs( self.tags ) do
        self.tags[ i ] = tag:gsub( "^%s+", "" ):gsub( "%s+$", "" ) -- trim
    end
    self.gameObject.mouseInput = self
    self.frameCount = 0
    self.lastLeftClickFrame = -doubleClickDelay
end

function Behavior:Update()
    self.frameCount = self.frameCount + 1

    local leftMouseJustPressed = CS.Input.WasButtonJustPressed( "LeftMouse" )
    local leftMouseDown = CS.Input.IsButtonDown( "LeftMouse" )
    local rightMouseJustPressed = CS.Input.WasButtonJustPressed( "RightMouse" )
    
    local doubleClick = false
    if leftMouseJustPressed then
        doubleClick = ( self.frameCount <= self.lastLeftClickFrame + doubleClickDelay )   
        self.lastLeftClickFrame = self.frameCount
    end

    local vector = CS.Input.GetMouseDelta()
    local drag = false
    if vector.x ~= 0 or vector.y ~= 0 then
        drag = true
    end

    local mousePosition = CS.Input.GetMousePosition()

    for i, tag in pairs( self.tags ) do
        local gameObjects = GameObject.Tags[ tag ]
        if gameObjects ~= nil then

            for i, gameObject in pairs( gameObjects ) do
                if gameObject.transform ~= nil then
                    -- OnMouseEnter, OnMouseOver, OnMouseExit, gameObject.isMouseOver
                    if self.frameCount % self.updateInterval == 0 then
                        local ray = self.gameObject.camera:CreateRay( mousePosition )
                                                
                        if ray:IntersectsGameObject( gameObject ) then
                            -- the mouse pointer is over the gameObject
                            -- the action will depend on if this is the first time it hovers the gameObject
                            -- or if it was already over it the last frame
                            -- also on the user's input (clicks) while it hovers the gameObject
                            if gameObject.isMouseOver then
                                gameObject:SendMessage( "OnMouseOver" )
                            else
                                gameObject.isMouseOver = true
                                gameObject:SendMessage( "OnMouseEnter" )
                            end

                        elseif gameObject.isMouseOver then
                            -- was the gameObject still hovered the last frame ?
                            gameObject.isMouseOver = false
                            gameObject:SendMessage( "OnMouseExit" )
                        end
                    end

                    if gameObject.isMouseOver then
                        if leftMouseJustPressed then
                            gameObject:SendMessage( "OnClick" )

                            if doubleClick then
                                gameObject:SendMessage( "OnDoubleClick" )
                            end
                        end

                        if leftMouseDown and drag then
                            gameObject:SendMessage( "OnDrag" )
                        end

                        if rightMouseJustPressed then
                            gameObject:SendMessage( "OnRightClick" )
                        end
                    end
                else -- else if gameObject is destroyed
                    table.remove( gameObjects, i )
                end
            end -- end looping on gameObjects with current tag
        end
    end -- end looping on tags

end -- end of Behavior:Update() function

--- Check if the provided ray intersects the provided gameObject's modelRenderer, mapRenderer or textRenderer.
-- @param ray (Ray) The ray.
-- @param gameObject (GameObject) The gameObject instance.
-- @return (boolean) True if a renderer is hit, false otherwise.
function Ray.IntersectsGameObject( ray, gameObject )
    local distance = nil
    local component = gameObject.modelRenderer
    if component ~= nil then
        distance = ray:IntersectsModelRenderer( component )
    end

    if distance == nil then
        component = gameObject.mapRenderer
        if component ~= nil then
            distance = ray:IntersectsMapRenderer( component )
        end
    end

    if distance == nil then
        component = gameObject.textRenderer
        if component ~= nil then
            distance = ray:IntersectsTextRenderer( component )
        end
    end

    if distance ~= nil then
        return true
    end

    return false
end

if string.split == nil then
    --- Split the provided string in several chunks, using the provided delimiter.
    -- The delimiter can be a pattern and can be several characters long.
    -- If the string does not contain the delimiter, a table containing only the whole string is returned.
    -- @param s (string) The string.
    -- @param delimiter (string) The delimiter.
    -- @return (table) The chunks.
    function string.split( s, delimiter )
        local chunks = {}
        if delimiterIsPattern == nil and #delimiter == 1 then
            delimiterIsPattern = false
        end
        
        if s:find( delimiter, 1, true ) ~= nil then
            if string.startswith( s, delimiter ) then
                s = s:sub( #delimiter+1, #s )
            end
            if not s:endswith( delimiter ) then
                s = s .. delimiter
            end

            local chunk = ""
            local ts = string.totable( s )
            local i = 1

            while i <= #ts do
                local char = ts[i]
                if char == delimiter or s:sub( i, i-1 + #delimiter ) == delimiter then
                    table.insert( chunks, chunk )
                    chunk = ""
                    i = i + #delimiter
                else
                    chunk = chunk..char
                    i = i + 1
                end
            end

            if #chunk > 0 then
                table.insert( chunks, chunk )
            end
        end

        if #chunks == 0 then
            chunks = { s }
        end

        return chunks
    end
end
