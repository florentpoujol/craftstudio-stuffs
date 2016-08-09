function Behavior:Awake()
    self.gameObject.s = self
    
    self.completedGO = self.gameObject:GetChild("Completed")
end

function Behavior:SetData( level )
    local children = self.gameObject.childrenByName
    local levelNameGO = children["Level Name"]
    levelNameGO.textRenderer.text = level.name
    levelNameGO.levelName = level.name
    
    levelNameGO:AddTag("ui")
    levelNameGO.OnMouseEnter = function(go)
        go.textRenderer.text = "          Play          "
    end
    levelNameGO.OnMouseExit = function(go)
        go.textRenderer.text = go.levelName
    end
    
    levelNameGO.OnClick = function(go)
        Game.levelToLoad = level
        Scene.Load("Master Level")
    end
    
    if not level.isCompleted then
        self.completedGO:Hide()
    end
end
