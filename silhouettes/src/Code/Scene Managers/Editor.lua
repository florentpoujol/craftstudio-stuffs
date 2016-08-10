
function Behavior:Awake()
    -- UI
    local go = GameObject.Get("Back To Main Menu")
    go:AddTag("uibutton")
    go.OnClick = function()
        Scene.Load("Main Menu")
    end
    
    local go = GameObject.Get("Save")
    go:AddTag("uibutton")
    go.OnClick = function()
        self:Save()
    end
end


function Behavior:Start()
    -- wait for the input component to be created
    
    self.levelName = ""
    
    local go = GameObject.Get("Level Name Input")
    self.LevelNameInput = go
    go.input.OnFocus = function( input )
        if input.isFocused then
            input.backgroundGO.modelRenderer.opacity = 0.4
        else
            self.levelName = go.textRenderer.text
            input.backgroundGO.modelRenderer.opacity = 0.2        
        end
    end

    go.input.OnValidate = function()
        self.levelName = go.textRenderer.text
    end
    
    
    if Game.levelToEdit ~= nil then
        self.levelName = Game.levelToEdit.name
        go.textRenderer.text = self.levelName
        
        self.levelId = Game.levelToEdit.id
        
        local structureData = Game.levelToEdit.structureData
        if structureData ~= nil then
            for coords, blockID in pairs( structureData ) do 
                local coords = Vector3.ToVector( coords )
                Game.structureGO.s.structureMap:SetBlockAt( coords.x, coords.y, coords.z, blockID )
            end
        end
        
        Game.silhouetteGOs[1].s:UpdateSilhouette()
        Game.silhouetteGOs[2].s:UpdateSilhouette()        
    end
    
    
end


function Behavior:Save()
    -- si level pas publish encore
        -- get id, wait > publish
    
    local level = {
        id = self.levelId,
        name = self.levelName,
        
        creatorId = Player.id,
        creatorName = Player.name,
        creationTimestamp = os.time(),
        
        silhouettes = {
            Game.silhouetteGOs[1].s:GetSilhouetteData(),
            Game.silhouetteGOs[2].s:GetSilhouetteData(),            
        },
        
        structureData = Game.structureGO.s:GetStructureData()
    }
    
    self:PublishLevel( level )
end


function Behavior:PublishLevel( level )
    local webLevel = table.copy( level )
    webLevel.action = "publishlevel"
    
    for i=1, 2 do
        local silhouette = webLevel.silhouettes[i]
        for j, line in ipairs( silhouette ) do
            -- reduce lines with no data to an empty string (#=0 instead of a 7-spaces-long-string)
            -- DO NOT trimm (start or end) the line when it is not empty, it will cause bugs when the silhouettes are reversed
            local trimmedLine = line:trim()
            if trimmedLine == "" then
                line = trimmedLine
            end
            webLevel["s"..i.."l"..j] = line 
        end
    end
    webLevel.silhouettes = nil
    
    table.mergein( webLevel, webLevel.structureData )
    webLevel.structureData = nil
    
    -- now, webLevel has no more embeded tables
    
    CS.Web.Post( Game.levelRepositoryUrl, webLevel, CS.Web.ResponseType.JSON, 
        function( error, data )
            if error then
                print("Error publishing level with id '"..level.id.."': ", error.message)
            end
            if data and data.error then
                 print("Error publishing level with id '"..level.id.."': ", data.error)
            elseif data then
                print("Successfully published a level. Id :", data.id, data.isNewEntry)
                level.id = data.id
                
                if data.isNewEntry == true then
                    table.insert(Level.levelsList, level)
                end
            end
        end
    )

end



--[[
function Behavior:GetLevelId( callback )
    CS.Web.Get( Game.levelRepositoryUrl.."?getnextlevelid", nil, CS.Web.ResponseType.JSON, 
        function( error, data )
            if error then
                print("Error getting next level id", error.message)
            end
            
            if data then
                self.levelId = data.nextLevelId
                
                if callback then
                    callback()            
                end
            end
        end
    )
end
]]