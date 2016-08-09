--[[PublicProperties
tags string ""
range number 0
updateInterval number 10
/PublicProperties]]
--[[
IMPORTANT : this file depends on the Tags file that you can find in the toolbox too

A trigger is a game object that checks its proximity against other game objects and interact with those who are within a certains distance (when the range public property is strictly postiv) or within a model or map.


    -----
    Interactions
    -----

When a game object enters a trigger for the first frame (it is in range this frame, but it wasn't the last frame), the OnTriggerEnter message is sent on the game object as well as on the trigger.

As long as a game object stays in range of one or several trigger(s), the OnTriggerStay message is sent each frame on the game object and on each trigger it is in range of.

The frame a game object leaves a trigger's range (it is not in range this frame but was in range the last frame), the OnTriggerExit message is sent on the game object as well as on the trigger.

Each of these messages pass along the trigger or the game object as first and only argument.

    -- in a scripted behavior attached to a game object :
    function Behavior:OnTriggerEnter( data )
        local trigger = data[1]
        print( "The game object of name '"..self.gameObject:GetName().."' just reach the trigger of name '"..trigger:GetName().."'." )
    end
     
    function Behavior:OnTriggerStay( data )
        local trigger = data[1]
        if CS.Input.WasButtonJustRealeased( "Fire" ) then
            print( "The 'Fire' button was just released while the game object of name '"..self.gameObject:GetName().."' is inside the trigger of name '"..trigger:GetName().."'." )
        end
    end
     
    ----------
    -- in a scripted behavior attached to a trigger :
    function Behavior:OnTriggerExit( data )
        local gameObject = data[1]
        print( "The game object of name '"..gameObject.name.."' just exited the trigger of name '"..self.gameObject.name.."'." )
    end

You can get the game objects currently in range at any time via the gameObjectsInRange property (it's a table of game objects).


    -----
    Properties
    -----

tags (string) The tags the game objects must have for their proximity to be checked by the triggers. Concatenate several tags with a colon.
range (number) The trigger's radius. If inferior or equal to 0, the will will use its ModelRenderer or MapRenderer.
updateInterval (number) The number of frames between each frames.
]]

--[[PublicProperties
tags string ""
range number 0
updateInterval number 10
/PublicProperties]]

function Behavior:Awake()
    self.gameObjectsInRange = {} -- the gameObjects that touches this trigger
    self.tags = self.tags:split( ",", true )
    self.frameCount = 0
    self.ray = Ray:New()
end

function Behavior:Update()
    self.frameCount = self.frameCount + 1
    if self.frameCount % self.updateInterval == 0 then
        local triggerPosition = self.gameObject.transform:GetPosition()
        
        for i, tag in ipairs( self.tags ) do
            local gameObjects = GameObject.Tags[ tag ]
            if gameObjects ~= nil then
                
                for i, gameObject in pairs( gameObjects ) do
                    if gameObject.transform ~= nil then
                        table.remove( gameObjects, i )
                    elseif gameObject ~= self.gameObject then

                        local gameObjectIsInTrigger = false
                        local gameObjectPosition = gameObject.transform:GetPosition()
                        local directionToTrigger = triggerPosition - gameObjectPosition
                        local distanceToTriggerSquared = directionToTrigger:SqrLength()

                        if self.range > 0 and distanceToTriggerSquared <= self.range^2 then
                            gameObjectIsInTrigger = true

                        elseif self.range <= 0 then
                            self.ray.position = gameObjectPosition
                            self.ray.direction = directionToTrigger:Normalized() -- ray from the gameObject to the trigger
                            local distance = nil

                            if self.gameObject.modelRenderer ~= nil then
                                distance = self.ray:IntersectsModelRenderer( self.gameObject.modelRenderer )
                            elseif self.gameObject.mapRenderer ~= nil then
                                distance = self.ray:IntersectsMapRenderer( self.gameObject.mapRenderer )
                            end

                            if distance ~= nil and distance^2 > distanceToTriggerSquared then
                                -- distance from the GO to the model or map is superior to the distance to the trigger origin
                                -- that means the GO is inside of the model/map
                                -- the ray goes throught the GO origin before intersecting the model/map 
                                gameObjectIsInTrigger = true
                            end
                        end

                        local gameObjectWasInRange = false
                        for i, _gameObject in pairs( self.gameObjectsInRange ) do
                            if _gameObject == gameObject then
                                gameObjectWasInRange = true
                                break
                            end
                        end

                        if gameObjectIsInTrigger then
                            if gameObjectWasInRange then
                                -- already in this trigger
                                gameObject:SendMessage( "OnTriggerStay", self.gameObject )
                                self.gameObject:SendMessage( "OnTriggerStay", gameObject )
                            else
                                -- just entered the trigger
                                table.insert( self.gameObjectsInRange, gameObject )
                                gameObject:SendMessage( "OnTriggerEnter", self.gameObject )
                                self.gameObject:SendMessage( "OnTriggerEnter", gameObject )
                            end
                        elseif gameObjectWasInRange then
                            -- was the gameObject still in this trigger the last frame ?
                            for i, _gameObject in pairs( self.gameObjectsInRange ) do
                                if _gameObject == gameObject then
                                    table.remove( self.gameObjectsInRange, i )
                                    break
                                end
                            end
                            gameObject:SendMessage( "OnTriggerExit", self.gameObject )
                            self.gameObject:SendMessage( "OnTriggerExit", gameObject )
                        end
                    end
                end
            end
        end
    end
end

if string.split == nil then
    function string.split( s, delimiter, trim )
        s = s .. delimier
        local fields = { s:match( 
            (s:gsub( "([^"..delimiter.."]*)"..delimiter, "(%1)"..delimiter ))
        ) }
        if trim then
            for i, s in pairs( fields ) do
                fields[ i ] = s:gsub( "^%s+", "" ):gsub( "%s+$", "" )
            end
        end
        return fields
    end
end
