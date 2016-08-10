
function Behavior:Awake()
    self.gameObject.s = self
    self.silhouetteId = tonumber(self.gameObject.name)
    Game.silhouetteGOs[ self.silhouetteId ] = self.gameObject
    
    local position = self.gameObject.transform.position
    local directionToStructure = Vector3(0, position.y, 0) - position -- I probably should normalize the drection here but it doesn't cause issues

    --self.ray = Ray:New( Vector3(0), directionToStructure )
    self.ray = setmetatable({ position = Vector3(0), direction = directionToStructure }, Ray)
    self.rayData = {}

    for x=-Game.structureSize, Game.structureSize do
        for y=-Game.structureSize, Game.structureSize do
            local location = Vector3(x, y, 0) -- the location of the map block, also its local position (local) to this game object
            self.rayData[x.."_"..y] =  {
                location = location,
                position = self.gameObject.transform:LocalToWorld( location * Game.locationToPosition )
            }
        end
    end
    
    Map.LoadFromPackage( "Silhouette", function( map )       
        self.map = map
        self.gameObject.mapRenderer.map = map
        
        self.isReady = true
        Game.structureGO.s:CheckForReady()
    end )
    
    --
    local endLevelGO = self.gameObject:GetChild("End Level")
    endLevelGO.transform.localPosition = Vector3(0)
    self.endLevelGO = endLevelGO
    Daneel.Event.Listen("EndLevel", self.gameObject)        
    
    
    if self.silhouetteId == 1 then
        self.endGOs = endLevelGO.childrenByName   
        self.levelStartTime = os.clock()
    
    elseif self.silhouetteId == 2 then
        self.nextLevelSilhouetteGOs = {
            endLevelGO:GetChild("1", true),
            endLevelGO:GetChild("2", true)
        }
        self.nextLevelSilhouetteGOs[1].mapRenderer:LoadNewMap()
        self.nextLevelSilhouetteGOs[2].mapRenderer:LoadNewMap()

        self.levelNameGO = endLevelGO:GetChild("Level Name")
    end
end


function Behavior:Start()

end


-- Called by [Structure/Start]
function Behavior:UpdateSilhouette()
    if self.map == nil then
        -- happens in the webplayer when called the first time from [Structure/Start]
        -- will be called again when a new map will have been loaded
        return
    end
    
    local silhouetteData = { "", "", "", "", "", "", "" } -- for when in level editor, just so that the code below doesn't return errors
    local silhouette = -1
    local angle = math.warpangle( Game.structureGO.transform.eulerAngles.y )
    
    if not Game.isLevelEditor then -- standard level
        --[[
        angle   Silhouette 1          S2
        
        -45     Normal  Wall 1     Normal  Wall 2
        -135    Normal  Wall 2     Reverse Wall 1
        135     Reverse Wall 1     Reverse Wall 2
        45      Reverse Wall 2     Normal  Wall 1
        ]]
        
        silhouetteData = Game.selectedLevel.silhouettes[1] 
        silhouette = self.silhouetteId -- default, when angle == -45
        local reverse = false
        
        if angle == -135 then
            if self.silhouetteId == 1 then
                silhouette = 2
                reverse = true
            else
                silhouette = 1
            end
            
        elseif angle == 135 then
            reverse = true
    
        elseif angle == 45 then
            if self.silhouetteId == 1 then
                silhouette = 2
            else
                reverse = true
                silhouette = 1
            end
        end
        
        silhouetteData = table.copy( Game.selectedLevel.silhouettes[ silhouette ] )
        
        if reverse == true then
            for i, line in pairs( silhouetteData ) do
                silhouetteData[i] = line:reverse()
            end
        end
    end
    
    
    -- convert silhouetteData data
    local i = 0
    for y=Game.structureSize, -Game.structureSize, -1 do
        i = i + 1
        local line = silhouetteData[i] or ""
        
        for x= -Game.structureSize, Game.structureSize do
            local chari = x + Game.structureSize + 1
            local char = line:sub(chari, chari)

            if char == "x" then
                self.rayData[x.."_"..y].isGoal = true -- this tile must be "shadowed" by the structure
                --self.map:SetBlockAt( x, y, 0, BlockIdsByColor.yellow )
            else
                self.rayData[x.."_"..y].isGoal = false
            end
        end
    end
    
    
    local silCompleted = true -- true when only green tiles
    
    -- find shadowed tiles and set colors    
    for coords, data in pairs( self.rayData ) do
        self.ray.position = data.position
        
        local distance = nil
        if CS.IsWebPlayer or Game.mockWebPlayer then
        
            for coords, mapMockGO in pairs( Game.structureGO.mapMocks ) do -- only run in web player or when mocking web player
                if mapMockGO.location.y == data.location.y + 4 then -- only check for collision against the mapMock at the same altitude              
                    distance = self.ray:IntersectsModelRenderer( mapMockGO.modelRenderer )
                    print( "sil: check with model", distance, coords, mapMockGO.location.y, data.location.y)
                    if distance ~= nil then
                        break
                    end
                end
            end
        
        else
            distance = self.ray:IntersectsMapRenderer( Game.structureGO.mapRenderer, false )
        end
        
        local blockID = BlockIdsByColor.silhouetteBase
        
        if distance ~= nil then
            if data.isGoal == true then
                blockID = BlockIdsByColor.shadowMatch
                
            elseif data.isGoal == false then -- important to check for false instead of (false or nil)
                if Game.isLevelEditor then                   
                    blockID = BlockIdsByColor.strutureShadow
                else
                    blockID = BlockIdsByColor.shadowNoMatch
                end
                silCompleted = false
            end
            
        elseif distance == nil and data.isGoal == true then
            blockID = BlockIdsByColor.silhouetteGoal
            silCompleted = false
        end
        
        if self.map:GetBlockIDAt( data.location.x, data.location.y, data.location.z ) ~= blockID then
            self.map:SetBlockAt( data.location.x, data.location.y, data.location.z, blockID )
        end
    end
    
    
    if Game.selectedLevel ~= nil then -- is nil in level editor
        if Game.selectedLevel.completedSilhouettes == nil then
            Game.selectedLevel.completedSilhouettes = { false, false }
        end
        
        Game.selectedLevel.completedSilhouettes[ silhouette ] = silCompleted
    
        if 
            Game.selectedLevel.completedSilhouettes[1] == true and
            Game.selectedLevel.completedSilhouettes[2] == true
        then
            Daneel.Event.Fire("EndLevel") -- Listened by [Silhouette]
            --[[
            Game.silhouetteGOs[1].s:EndLevel()
            Game.silhouetteGOs[2].s:EndLevel()
            ]]
        end
    end
end


-- Called from [Level Editor/Save()]
function Behavior:GetSilhouetteData()
    local silhouetteData = {}
    for y=Game.structureSize, -Game.structureSize, -1 do
        local line = ""
        
        for x= -Game.structureSize, Game.structureSize do
            local blockID = self.map:GetBlockIDAt( x, y, 0 )

            if blockID ~= BlockIdsByColor.grayOutlined then
                line = line.."x"
            else
                line = line.." "
            end
        end
        
        table.insert( silhouetteData, line )
    end
    --table.print(silhouetteData)
    return silhouetteData
end


-- Called when the EndLevel event is fired at the end of [Silhouettes/UpdateSilhouette]
function Behavior:EndLevel()
    Game.endLevel = true
    self.endLevelGO.transform.localPosition = Vector3(0,0,2.2)
    
    if self.silhouetteId == 1 then
        local time = os.clock() - self.levelStartTime
        local minutes = math.floor( time/60 )
        if minutes < 10 then
            minutes = "0"..minutes
        end
        local seconds = math.round( time % 60 )
        if seconds < 10 then
            seconds = "0"..seconds
        end
        if time < 60 then
            self.endGOs.Time.label.value = seconds.."s"
        else
            self.endGOs.Time.label.value = minutes.."m "..seconds.."s"
        end
        
        self.endGOs.Blocks.label.value = table.getlength( Game.structureGO.s.buildedBlockLocations )
        self.endGOs.Blocks_Created.label.value = Game.structureGO.s.blocksCreatedCount
        self.endGOs.Blocks_Removed.label.value = Game.structureGO.s.blocksRemovedCount
        
        Game.structureGO:Animate("eulerAngles", Vector3(0,360,0), 5, {
            isRelative = true,
            loops = -1,
        } )
    
    elseif self.silhouetteId == 2 then
        
        Game.selectedLevel.isCompleted = true
        local nextLevel = nil
        
        for i, level in ipairs( Levels ) do
            if not level.isCompleted then
                nextLevel = level
                break
            end
        end
        
        if nextLevel == nil then
            nextLevel = Levels[ math.random( #Levels ) ]
        end
        
        -- Code of [Level Selection Cartridge/SetSilhouettes]
        for silId, silData in ipairs( nextLevel.silhouettes ) do
            if #silData == 5 then
                table.insert( silData, 1, "" )
                table.insert( silData, 1, "" )
            end
            
            local i = 0
            for y=Game.structureSize, -Game.structureSize, -1 do --top to bottom
                i = i + 1
                local line = silData[i]
                
                for x= -Game.structureSize, Game.structureSize do -- left to right
                    local chari = x+Game.structureSize+1
                    local char = line:sub(chari, chari)
                    
                    local blockID = BlockIdsByColor.white230Outlined
                    if char == "x" then
                        blockID = BlockIdsByColor.orange
                    end
                    self.nextLevelSilhouetteGOs[ silId ].mapRenderer.map:SetBlockAt( x, y, 0, blockID )
                end
            end
        end
        
        local textGO = self.levelNameGO.childrenByName.Text
        textGO.textRenderer.text = nextLevel.name
        
        textGO.OnMouseEnter = function(go)
            go.textRenderer.text = "Play     "
        end
        textGO.OnMouseExit = function(go)
            go.textRenderer.text = nextLevel.name
        end
        
        textGO.OnClick = function()
            Game.selectedLevel = nextLevel
            Scene.Load("Level")
        end
    end
end
