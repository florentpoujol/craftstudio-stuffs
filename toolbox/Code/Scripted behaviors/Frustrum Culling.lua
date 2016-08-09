--[[PublicProperties
tags string ""
updateInterval number 10
maskName string "Mask"
/PublicProperties]]
--[[
IMPORTANT : this file depends on the Tags file that you can find in the toolbox too

Attach this script as a scripted behavior on a camera (a game object with a Camera component).

The point of this script is to determine if a game object is "visible" by the player or not but its not actual frustrum culling.
The checked game objects are the one with one of the tags set via the tags publoic property.
A game object is considered "visible" when a straight line starting at the camera and going toward the game object goes through the mask.

The mask is a game object with a model renderer, attached as a child of this camera, and nammed "Mask" (or anything after the value of the 'maskName' public property).
In order to operate as "frustrum culling", the mask should be placed close and in front of the camera and scaled so that it blocks the view from the camera. Obviously the mask's modelRenderer should have an opacity of 0. 

The 'OnCameraEnter' message is sent on a game object when it become visible (it is inside the mask from the camera's point of view).
And so the 'OnCameraExit' message is sent on a game object when it become "invisible"

Check the 'gameObject.isVisibleFromCamera' property to know from which camera a game object is visible.
It's table whose keys are the camera game objects and the values are booleans.
]]

--[[PublicProperties
tags string ""
updateInterval number 10
maskName string "Mask"
/PublicProperties]]

function Behavior:Awake()
    if self.gameObject.camera == nil then
        CS.Destroy( self )
        error( "FrustrumCulling:Awake() : GameObject with name '" .. self.gameObject:GetName() .. "' has no Camera component." )
    end  

    self.cullingMask = self.gameObject:FindChild( self.maskName )
    if self.cullingMask == nil then
        CS.Destroy( self )
        error( "FrustrumCulling:Awake() : Mask with name '" .. self.maskName .. "' was not found as a child of gameObject with name '" .. self.gameObject:GetName() .. "'." )
    end
    if self.cullingMask.modelRenderer == nil then
        CS.Destroy( self )
        error( "FrustrumCulling:Awake() : Mask with name '" .. self.maskName .. "' has no ModelRenderer component." )
    end

    self.tags = self.tags:split( ",", true )
    self.gameObject.frustrumCulling = self
    self.frameCount = 0
end

function Behavior:Start()
    for i, tag in pairs( self.tags ) do
        local gameObjects = GameObject.Tags[ tag ]
        if gameObjects ~= nil then

            for i, gameObject in pairs( gameObjects ) do
                if gameObject.isVisibleFromCamera == nil then
                    gameObject.isVisibleFromCamera = {}
                end
            end
        end
    end
end

function Behavior:Update()
    self.frameCount = self.frameCount + 1
    
    if self.frameCount % self.updateInterval == 0 then
        local cameraPosition = self.gameObject.transform:GetPosition()
        
        for i, tag in pairs( self.tags ) do
            local gameObjects = GameObject.Tags[ tag ]
            if gameObjects ~= nil then

                for i, gameObject in pairs( gameObjects ) do
                    if gameObject.transform ~= nil then
                        local ray = Ray:New( cameraPosition, gameObject.transform:GetPosition() - cameraPosition )

                        if ray:IntersectsModelRenderer( self.cullingMask.modelRenderer ) then
                            if gameObject.isVisibleFromCamera[ self.gameObject ] ~= true then
                                -- gameObject was not visible from this camera the last time
                                gameObject.isVisibleFromCamera[ self.gameObject ] = true
                                gameObject:SendMessage( "OnCameraEnter", self.gameObject )
                            end

                        elseif gameObject.isVisibleFromCamera[ self.gameObject ] == true then
                            -- gameObject was visible from this camera the last time but is not anymore
                            gameObject.isVisibleFromCamera[ self.gameObject ] = false
                            gameObject:SendMessage( "OnCameraExit", self.gameObject )
                        end
                    else
                        gameObjects[ i ] = nil
                    end
                end
            end
        end
    end
end

if string.split == nil then
    function string.split( s, delimiter, trim )
        s = s .. delimiter
        local fields = { s:match( 
            (s:gsub( "([^"..delimiter.."]+)"..delimiter, "(%1)"..delimiter ))
        ) }
        if trim then
            for i, s in pairs( fields ) do
                fields[ i ] = s:gsub( "^%s+", "" ):gsub( "%s+$", "" )
            end
        end
        return fields
    end
end
