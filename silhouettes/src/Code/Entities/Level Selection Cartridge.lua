function Behavior:Awake()
    self.gameObject.s = self
    
    self.silhouetteGOs = {
        self.gameObject:GetChild("1", true),
        self.gameObject:GetChild("2", true),
    } 
    self.silhouetteGOs[1]:AddTag("uibutton")
    self.silhouetteGOs[2]:AddTag("uibutton")
    
    Map.LoadFromPackage( "Silhouette", function( map )       
        self.silhouetteGOs[1].mapRenderer.map = map
        self.silhouette1Ready = true
        if self.silhouettesData ~= nil and self.silhouette2Ready then
            self:SetSilhouettes( self.silhouettesData )
        end
    end )
    
    Map.LoadFromPackage( "Silhouette", function( map )       
        self.silhouetteGOs[2].mapRenderer.map = map
        self.silhouette2Ready = true
        if self.silhouettesData ~= nil and self.silhouette1Ready then
            self:SetSilhouettes( self.silhouettesData )
        end
    end )
    
    ----------
    
    self.levelNameIconGO = self.gameObject:GetChild("Level Name.Icon")
    self.levelNameGO = self.gameObject:GetChild("Level Name.Text")
    local cartridgeGO = self.gameObject:GetChild("Mouse Over Cartridge")
    self.mouseOverCartridgeGO = cartridgeGO
    
    local cartridgeBG = cartridgeGO:GetChild("Background")
    
    self.creatorIconGO = cartridgeGO:GetChild("Creator.Icon")
    self.creatorNameGO = cartridgeGO:GetChild("Creator.Text")

    self.dateGO = cartridgeGO:GetChild("Date")
    self.editButtonGO = cartridgeGO:GetChild("Edit")
            
    --
    self.levelNameGO.OnMouseEnter = function( go )
        go.levelName = go.textRenderer.text
        go.textRenderer.text = "Play          "
    end
    cartridgeBG.OnMouseEnter = function()
        cartridgeGO.transform.localPosition = Vector3(0)
    end
    
    --
    self.levelNameGO.OnMouseExit = function( go )
        go.textRenderer.text = go.levelName
    end
    cartridgeBG.OnMouseExit = function()
        cartridgeGO.transform.localPosition = Vector3(0,0,-50)
    end
    cartridgeBG.OnMouseExit()
    
    --
    self.levelNameGO.OnClick = function( go )
        Game.selectedLevel = go.levelToLoad -- set in [Select Level]
        Scene.Load("Level")
    end
end


-- Note : make sure it work in the webplayer, that the map get swapped before SetSilhouettes() gets called
-- called from
-- * Map.LoadFromPackage() callback above
-- * SetData() below
-- * [Silhouette/EndLevel]
function Behavior:SetSilhouettes( silhouettesData )
    if not self.silhouette1Ready or not self.silhouette2Ready then
        self.silhouettesData = silhouettesData
    end

    for silId, silData in ipairs( silhouettesData ) do
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
                
                local blockID = BlockIdsByColor.levelSelectionSilhouetteBase
                --blockID = 255
                if char == "x" then
                    blockID = BlockIdsByColor.levelSelectionSilhouetteGoal
                end
                self.silhouetteGOs[ silId ].mapRenderer.map:SetBlockAt( x, y, 0, blockID )
            end
        end
    end
end

local fontAwesome = CS.FindAsset("Font Awesome")

-- called from [Select Level/BuildLevelList]
function Behavior:SetData( level, allowEdit )
    self.levelNameGO.levelToLoad = level
    self.levelNameGO.textRenderer.text = level.name
            
    if allowEdit then
        self.editButtonGO:AddTag("uibutton")
        self.editButtonGO.OnClick = function()
            Game.levelToEdit = level
            Scene.Load( "Editor" )
        end
    else
        self.creatorNameGO.textRenderer.text = level.creatorName
        if level.isCompleted then
            self.levelNameIconGO.textRenderer.text = "2" -- green check mark
        end
        
        local target = level.creatorUrl
        if target ~= nil and target ~= "" then
            local displayedTarget = target
            if string.find( target, "http", nil , true ) == nil then
                -- target is a twitter handle -- 20/08/14 creatorUrl shouldn't be anything else...
                displayedTarget = "@"..target                
                target = "https://twitter.com/"..target                   
            end
            
            self.creatorNameGO:AddTag("uibutton")
            self.creatorNameGO.OnClick = function() 
                CS.Web.Open( target )
            end
            
            self.creatorNameGO.OnMouseEnter = function(go)
                go.textRenderer.text = displayedTarget
                self.creatorIconGO.textRenderer.text = fontAwesome.textByIconName.link
            end
            self.creatorNameGO.OnMouseExit = function(go)
                go.textRenderer.text = level.creatorName
                self.creatorIconGO.textRenderer.text = fontAwesome.textByIconName.user                
            end
        end
        
        self.editButtonGO.textRenderer.text = ""
    end
    
    self:SetSilhouettes( level.silhouettes )
end

