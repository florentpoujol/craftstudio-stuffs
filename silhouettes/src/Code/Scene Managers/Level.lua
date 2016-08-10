
function Behavior:Awake()    
    GameObject.New("Background")
    
    local go = GameObject.Get("Structure Fixed")
    for x=-4, 4 do
        for y=-2, 0 do
            for z=-4, 4 do
                local blockID = go.mapRenderer.map:GetBlockIDAt(x, y,z)
                if blockID ~= Map.EmptyBlockID then
                    go.mapRenderer.map:SetBlockAt(x, y,z,49 )
                end
            end
        end
    end
    
    ----------
    -- buttons and tooltip
    
    --[[
    local homeGO = GameObject.Get("Home")
    homeGO:AddTag("uibutton")
    homeGO.OnClick = function()
        Scene.Load("Title")
    end
    homeGO:EnableTooltip()
    
    local selectGO = GameObject.Get("Level Editor")
    selectGO:AddTag("uibutton")
    selectGO.OnClick = function()
        Scene.Load("Editor")
    end
    selectGO:EnableTooltip()
    
    local editorGO = GameObject.Get("Level Editor")
    editorGO:AddTag("uibutton")
    editorGO.OnClick = function()
        Scene.Load("Editor")
    end
    editorGO:EnableTooltip()
    ]]
    
end



