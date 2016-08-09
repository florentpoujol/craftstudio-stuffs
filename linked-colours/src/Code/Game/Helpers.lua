

-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
ot( tr, tostring(t) )
end

function GetSelectedDot()
    return GameObject.GetWithTag( "selected_dot" )[1]
end


function GameObject.Show( go, opacity )
    local comp = go.textRenderer or go.modelRenderer or go.mapRenderer
    if comp ~= nil then
        comp.opacity = opacity or 1
    else
        local scale = go.originalScale or Vector3(1)
        go.transform.localScale = scale
    end
    go.isDisplayed = true
end

function GameObject.Hide( go, opacity )
    local comp = go.textRenderer or go.modelRenderer or go.mapRenderer
    if comp ~= nil then
        comp.opacity = opacity or 0
    else
        go.originalScale = go.transform.localScale
        go.transform.localScale = Vector3(0)
    end
    go.isDisplayed = false
end


function MapRenderer.LoadNewMap( mapRenderer, callback )
    local map = mapRenderer.map
    Map.LoadFromPackage( map.path, function(map)
        mapRenderer.map = map
        if callback then
            callback( map )
        end
    end )
end


function GameObject.EnableTooltip( go )
    local tooltipGO = go:GetChild("Tooltip")
    tooltipGO.transform.localPosition = Vector3(0)
    
    local contentGO = tooltipGO:GetChild("Content")
    
    --go:AddTag("uibutton")
    go.OnMouseEnter = function()
        contentGO:Show()
    end
    go.OnMouseExit = function()
        contentGO:Hide()
    end

    contentGO.Show = function( go )
        if go.tooltipAnim ~= nil then
            go.tooltipAnim:Destroy()
        end
        --go.tooltipAnim = tooltipGO:Animate("localScale", Vector3(1), 0.1)
        tooltipGO.transform.localScale = 1
    end
    
    contentGO.Hide = function( go )
        if go.tooltipAnim ~= nil then
            go.tooltipAnim:Destroy()
        end
        --go.tooltipAnim = tooltipGO:Animate("localScale", Vector3(0), 0.1)
        tooltipGO.transform.localScale = 0
    end
    contentGO:Hide()
end


function GameObject.SetRender( go, value )
    local comp = go.label or go.textArea or go.mapRenderer or go.modelRenderer or go.textRenderer
    
    local mt = getmetatable( comp )
    if mt == GUI.Label then
        comp.value = value
          
    elseif mt == ModelRenderer then
        comp.model = value
    
    elseif mt == TextRenderer then
        comp.text = value
    end
end



function Vector3.ToVector( sPosition )
    local vector = Vector3:New(0)
    local keys = { "z", "y", "x" }
    for match in string.gmatch( sPosition, "[0-9.-]+" ) do
        vector[ table.remove( keys ) ] = tonumber(match)
    end
    if table.remove( keys ) == "z" then
        setmetatable( vector, Vector2 )
    end
    return vector
end

function Vector3.ToString( vector )
    return vector.x.." "..vector.y.." "..vector.z
end
