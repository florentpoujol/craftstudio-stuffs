--[[PublicProperties
isLevelEditor boolean False
/PublicProperties]]

function Behavior:Awake()
    self.gameObject.s = self
    
    Game.isLevelEditor = self.isLevelEditor
    Game.structureGO = self.gameObject
    
    self.mouseOverGO = self.gameObject:GetChild("Mouse Over Map")
    self.mouseOverGO.mapRenderer.map:SetBlockAt( 0, 0, 0, BlockIdsByColor.structureMouseOver )
    
    self.buildedBlockLocations = {} -- array of map locations (Vector3)
    self.blocksCreatedCount = 0
    self.blocksRemovedCount = 0
    
    -- hide the mouse over game object when it is not needed anymore
    self.gameObject.OnMouseExit = function()
        self.mouseOverGO.transform.position = Vector3(0,200,0)
    end
    self.gameObject.OnMouseExit()
    
    
    self.gameObject.OnMouseOver = function( go, raycastHit )
        local location = raycastHit.hitBlockLocation
        local normal = raycastHit.normal
        
        if location == nil then -- happens in the webplayer since the structure base is mocked by a single model
            local localPosition = self.gameObject.transform:WorldToLocal( raycastHit.hitLocation ) -- hitLocation is actually a world position, not a map location
            
            location = localPosition/4 -- 4=64/16  64 being the structure's tile set's tile size
            location.x = math.round(location.x)
            location.y = math.round(location.y)
            location.z = math.round(location.z)
        end
        
        local nextLoc = location + normal
        go.nextBuildLocation = nextLoc
        
        if 
               nextLoc.x < -Game.structureSize or location.x > Game.structureSize
            or nextLoc.z < -Game.structureSize or location.z > Game.structureSize
            or nextLoc.y < 1 or nextLoc.y > Game.structureSize*2+1
        then
            self.gameObject.OnMouseExit()
            return
        end
        
        if normal.x == -1 or normal.y == -1 or normal.z == -1 then
            -- prevent the scale to be less than 0.99 when the normal has a negative component
            normal = -normal
        end
        
        self.mouseOverGO.transform.localPosition = location * Game.locationToPosition
        self.mouseOverGO.transform.localScale = Vector3(0.99) + normal * 0.02 -- increase the block's scale by 0.02 along the normal's axis (so that only the face of the level map block overred by the mouse appear yellow instead of gray)
    end
    
    
    self.gameObject.OnClick = function( go, raycastHit )
        if raycastHit ~= nil and not Game.endLevel then
            local location = raycastHit.hitBlockLocation
            if location == nil then -- see in OnMouseOver for explanations
                local localPosition = self.gameObject.transform:WorldToLocal( raycastHit.hitLocation )
                location = localPosition/4
                location.x = math.round(location.x)
                location.y = math.round(location.y)
                location.z = math.round(location.z)
            end
            location = location + raycastHit.normal
            
            if
                    location.x >= -Game.structureSize and location.x <= Game.structureSize
                and location.z >= -Game.structureSize and location.z <= Game.structureSize
                and location.y >= 1 and location.y <= Game.structureSize*2+1
            then
                if CS.IsWebPlayer or Game.mockWebPlayer then
                    self.structureMap:SetBlockAt( location.x, location.y, location.z, BlockIdsByColor.orange, nil, go )
                else
                    self.structureMap:SetBlockAt( location.x, location.y, location.z, BlockIdsByColor.orange )
                end
                table.insert( self.buildedBlockLocations, location )
                self.blocksCreatedCount = self.blocksCreatedCount + 1
                self:UpdateSilhouettes()
            end
        end
    end
    
    
    --if self.isLevelEditor then
        local function removeBlock( go, raycastHit )
            if raycastHit ~= nil and not Game.endLevel then
                local location = raycastHit.hitBlockLocation
                if location == nil then -- see in OnMouseOver for explanations
                    local localPosition = self.gameObject.transform:WorldToLocal( raycastHit.hitLocation )
                    location = localPosition/4
                    location.x = math.round(location.x)
                    location.y = math.round(location.y)
                    location.z = math.round(location.z)
                end

                if 
                        location.x >= -Game.structureSize and location.x <= Game.structureSize
                    and location.z >= -Game.structureSize and location.z <= Game.structureSize
                    and location.y >= 1 and location.y <= Game.structureSize*2+1
                then
                    self.blocksRemovedCount = self.blocksRemovedCount + 1
                    table.removevalue( self.buildedBlockLocations, location )
                    
                    if CS.IsWebPlayer or Game.mockWebPlayer then
                        self.structureMap:SetBlockAt( location.x, location.y, location.z, BlockIdsByColor.none, nil, go )
                    else
                        self.structureMap:SetBlockAt( location.x, location.y, location.z, BlockIdsByColor.none )                    
                    end
                    
                    self.gameObject.OnMouseExit()
                    self:UpdateSilhouettes()
                end
            end
        end
        self.gameObject.OnRightClick = removeBlock
    --end
    
    --
    self.gameObject.isRotating = false
    self.rotationAnimationOnCompleteCallback = function()
        self.gameObject.isRotating = false
        self:UpdateSilhouettes()
    end
    
    --
    Map.LoadFromPackage( "Structure", function( map )
        self.structureMap = map
        self.gameObject.mapRenderer.map = map
        
        if CS.IsWebPlayer or Game.mockWebPlayer then
            self.gameObject.mapMocks = {}
            self.gameObject.mapMocks[ "0_0_0" ] = self.gameObject:GetChild("Base Mock")
        end
        
        for x=-Game.structureSize, Game.structureSize do
            for z=-Game.structureSize, Game.structureSize do
                map:SetBlockAt( x, 0, z, BlockIdsByColor.structureBase )
            end
        end
        
        self.isReady = true
        self:CheckForReady()
    end )
    
    Game.endLevel = false
end


function Behavior:CheckForReady()
    if self.isReady and
       #Game.silhouetteGOs == 2 and
       Game.silhouetteGOs[1].s.isReady and
       Game.silhouetteGOs[2].s.isReady
    then
        self:UpdateSilhouettes()
    end
end


function Behavior:UpdateSilhouettes()   
    for i, go in pairs( Game.silhouetteGOs ) do
        go.s:UpdateSilhouette()
    end
end


-- Called by [Level Editor/Save]
function Behavior:GetStructureData()
    local data = {} -- block ids (number) by location (string)
    
    for x = -Game.structureSize, Game.structureSize do
        for y = 1, 7 do
            for z = -Game.structureSize, Game.structureSize do
                local blockID = self.structureMap:GetBlockIDAt( x, y, z )
                if blockID ~= Map.EmptyBlockID then
                    data[x.."_"..y.."_"..z] = blockID
                end
            end
        end
    end
    
    return data
end



function Behavior:Update()

    --[[if 
        self.isLevelEditor == false
        and not Game.endLevel
        and CS.Input.WasButtonJustPressed( "RightMouse" )
    then
        local location = table.remove( self.buildedBlockLocations )
        if location ~= nil then
            self.blocksRemovedCount = self.blocksRemovedCount + 1
            
            if CS.IsWebPlayer or Game.mockWebPlayer then
                self.structureMap:SetBlockAt( location.x, location.y, location.z, Map.EmptyBlockID, nil, self.gameObject )
            else
                self.structureMap:SetBlockAt( location.x, location.y, location.z, Map.EmptyBlockID )
            end
            
            self.gameObject.OnMouseExit()
            self:UpdateSilhouettes()
        end
    end]]
    
    if not Game.endLevel and CS.Input.WasButtonJustPressed( "RotateLeft" ) and not Game.structureGO.isRotating then
        self.gameObject.isRotating = true
        self.gameObject:Animate( "eulerAngles", Vector3(0,90,0), 0.5, self.rotationAnimationOnCompleteCallback, { isRelative = true } )
        --[[self.gameObject:Animate( "position", Vector3(0,4,0), 0.1, {
            isRelative = true,
            OnComplete = function()
                self.gameObject:Animate( "eulerAngles", Vector3(0,90,0), 0.5, { 
                    isRelative = true,
                    OnComplete = function()
                        self.gameObject:Animate( "position", Vector3(0,-4,0), 0.1, {
                            isRelative = true,
                            OnComplete = self.rotationAnimationOnCompleteCallback
                        } )
                    end
                } )
            end
        } )]]
        
    end
    
    if not Game.endLevel and CS.Input.WasButtonJustPressed( "RotateRight" ) and not Game.structureGO.isRotating then
        self.gameObject.isRotating = true
        
        self.gameObject:Animate( "eulerAngles", Vector3(0,-90,0), 0.5, self.rotationAnimationOnCompleteCallback, { isRelative = true } )
        
    end
end
