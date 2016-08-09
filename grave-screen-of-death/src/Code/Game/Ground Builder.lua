function Behavior:Awake()
    self.gameObject:AddTag("ground") -- needed for mouse hover
    self.map = nil
end

function Behavior:Start()
    -- do that from start to let other script register to the OnGroundBuild event
    --[[self.gameObject.mapRenderer:LoadNewMap( function( map )        
        self.map = map
        Game.groundMap = map
        self:Build()
    end )]]
    self.map = self.gameObject.mapRenderer.map
    Game.groundMap = self.map
    self:Build()
end


function Behavior:Build()    
    local levelHalfSize = Game.levelHalfSize
    for x=-levelHalfSize.x, levelHalfSize.x do
        for z=-levelHalfSize.y, levelHalfSize.y do
            self.map:SetBlockAt(x,0,z, BlockIds.darkGrass )
        end
    end
    
    -- patches
    local patches = math.random(5,10)
    for i=1, patches do
        -- get a pos at random
        local pos = Vector2( math.random(Game.levelSize.x-3),  math.random(Game.levelSize.y-3) ) - levelHalfSize
        
        -- get patch size at random
        local size = Vector2( math.random(1,5), math.random(1,5) )
        local blockId = math.random(7,9)
        
        for x= pos.x-size.x, pos.x+size.x do
            for z= pos.y-size.y, pos.y+size.y do     
                self.map:SetBlockAt(x,0,z, blockId )
            end
        end
    end
    
    -- flowers ! Trees !
    -- id 12 to 15
    local count = math.random( 40, 80 )

    for i=1, count do
        local pos = Vector2( math.random(Game.levelSize.x-3),  math.random(Game.levelSize.y-3) ) - levelHalfSize
        
        if math.random(5) == 5 then
            local id = math.random(2)
            local tree = Scene.Append("Entities/Tree", Game.entitiesParentGO )
            tree.transform.position = Vector3(pos.x, 0.501, pos.y)
            --print("tree")
        elseif math.random(3) >= 2 then
            local blockId = math.clamp( self.map:GetBlockIDAt(pos.x, 0, pos.y), 6, 9 )
            blockId = blockId + 6
            self.map:SetBlockAt(pos.x, 0, pos.y, blockId)
        end
        
    end
        
    -- make sure the spawn is solid
    for x=-3, 3 do
        for z=-3, 3  do
            --self.map:SetBlockAt(x,0,z, BlockIds.temp )
        end
    end
    
    Event.Fire("OnGroundBuild") -- make player spawn from level manager
end

-- Set Game.worldMousePosition
function Behavior:OnMouseOver( raycastHit )
    Game.worldMousePosition = raycastHit.hitPosition
end

Daneel.Debug.RegisterScript(Behavior)
