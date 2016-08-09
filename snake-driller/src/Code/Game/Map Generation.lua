--[[PublicProperties
mainMenu boolean False
/PublicProperties]]

MapGO = nil

-- Because the tileset has a tile size of 16, the block coordinates are the same as the scene coordinates

function Behavior:Awake()
    MapGO = self.gameObject
    self.gameObject.s = self
    
    local map = self.gameObject.mapRenderer.map
    
    Map.LoadFromPackage( map.path, function(map)
        self.map = map
        self.gameObject.mapRenderer.map = map
    end )


    -- used in GetRandomBlockId()
    self.blockIdByOdd = {}
    for name, data in pairs( Blocks ) do
        if data.odd ~= nil then
            table.insert( self.blockIdByOdd, {
                odd = data.odd,
                blockID = data.id
            } )
        end
    end
    self.blockIdByOdd = table.sortby( self.blockIdByOdd, "odd", "desc" ) -- big odds first
    
    
    self.frameCount = -1
end

function Behavior:Start()
    if self.mainMenu == false then  
        local screenSize = CS.Screen.GetSize()
        local sizeRatio = screenSize.x / screenSize.y -- is > 1 when height is the smalles side of the screen
        local orthoScale = PlayerGO.camera.orthographicScale
        
        -- size of the screen in blocks
        self.screenBlockSize = Vector2( orthoScale * sizeRatio, orthoScale ) -- only work when height is the smallest side of the screen
        
        self.lastPlayerPosition = Vector3(0,1,0)
        self.lastMoveDirection = "down"
        
        self:UpdateMap()
    end
end

-- Update the map blocks so that they fill the whole screen
function Behavior:UpdateMap( moveDirection )
    local playerPos = PlayerGO.transform.position
    
    -- get the block in front of the player
    if moveDirection ~= nil then
        -- when called from Player Control script
        local drillBlockId = Blocks[moveDirection.."drill"].id      
        self.map:SetBlockAt( playerPos.x, playerPos.y, 0, drillBlockId )
        
        
        -- update the last block ("trail" block)
        local pipeBlockId = Blocks.verticalpipe.id
        if self.lastMoveDirection == "down" then
            if moveDirection == "down" then
                 -- vertical
            elseif moveDirection == "left" then
                pipeBlockId = Blocks.topleftelbow.id
            elseif moveDirection == "right" then
                pipeBlockId = Blocks.toprightelbow.id
            elseif moveDirection == "up" then
                -- error, can't do that
            end
        
        elseif self.lastMoveDirection == "left" then
            if moveDirection == "down" then
                 pipeBlockId = Blocks.bottomrightelbow.id
            elseif moveDirection == "left" then
                pipeBlockId = Blocks.horizontalpipe.id
            elseif moveDirection == "right" then
                -- error
            elseif moveDirection == "up" then
                pipeBlockId = Blocks.toprightelbow.id
            end       
        
        elseif self.lastMoveDirection == "right" then
            if moveDirection == "down" then
                 pipeBlockId = Blocks.bottomleftelbow.id
            elseif moveDirection == "left" then
                -- error
            elseif moveDirection == "right" then
                pipeBlockId = Blocks.horizontalpipe.id
            elseif moveDirection == "up" then
                pipeBlockId = Blocks.topleftelbow.id
            end
            
         elseif self.lastMoveDirection == "up" then
            if moveDirection == "down" then
                 --error
            elseif moveDirection == "left" then
                pipeBlockId = Blocks.bottomleftelbow.id
            elseif moveDirection == "right" then
                pipeBlockId = Blocks.bottomrightelbow.id
            elseif moveDirection == "up" then
                -- vertical
            end
        end

        self.map:SetBlockAt( self.lastPlayerPosition.x, self.lastPlayerPosition.y, 0, pipeBlockId )
        self.lastMoveDirection = moveDirection
    end
    
    self.lastPlayerPosition = playerPos

    
    -- loop on all the block
     for x = playerPos.x - self.screenBlockSize.x/2 - 1, playerPos.x + self.screenBlockSize.x/2 + 1 do
        for y = playerPos.y - self.screenBlockSize.y/2 - 1, playerPos.y + self.screenBlockSize.y/2 + 1 do
            if y <= -1 and self.map ~= nil then
                local blockID = self.map:GetBlockIDAt( x, y, 0 )
                if blockID == Map.EmptyBlockID then
                    local blockId = self:GetRandomBlockID()
                    if blockId == Blocks.dirt.id and y == -1 then
                        blockId = Blocks.grass.id
                    end
                    self.map:SetBlockAt( x, y, 0, blockId )
                end
             end
        end
    end
end


function Behavior:GetRandomBlockID()
    for i, data in ipairs( self.blockIdByOdd ) do
        local random = math.random(data.odd) -- return an integer between 0 and upper
        if random == 1 then
            return data.blockID
        end
    end
    return Blocks.dirt.id
end


function Behavior:Update()
    if self.mainMenu == true then
        self.frameCount = self.frameCount + 1
        
        if self.frameCount % 60 == 0 then
            
            self.gameObject.transform:Move( Vector3(0,1,0) )
            local position = self.gameObject.transform.position
            
            -- loop on all the block
            for x = -30, 30 do
                for y = -position.y-30, -position.y+30 do
                    if self.map ~= nil then -- seems to take a while in the webplayer
                        local blockID = self.map:GetBlockIDAt( x, y, 0 )
                        if blockID == Map.EmptyBlockID then
                            local blockId = self:GetRandomBlockID()
                            self.map:SetBlockAt( x, y, 0, blockId )
                            
                        end
                    end
                end
            end
        end    
    end
end