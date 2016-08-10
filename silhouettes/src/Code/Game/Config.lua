
CS.Screen.SetSize(900, 506) -- 1.78 = 16:9   840x470

Game = {
    selectedLevel = nil, -- table, one entry on the Levels object   Set in level selection
    
    structureGO = nil, -- set in Structure script
    silhouetteGOs = {},
    
    locationToPosition = 64 / 16, -- 64 is the tile set size (size in texture pixel of each cubes)
    
    structureSize = 3, -- 7*7
    
    isLevelEditor = false, -- tell whether the current level is the level editor, or not
    
    levelToEdit = nil, -- is set to the level to edit before loading the level editor in [Select Level]. Set back to nil from [Level Editor]
    
    levelRepositoryUrl = "http://silhouettes.com/level.php",
    
    mockWebPlayer = false,
    
    canAccessInternet = false, -- set to true in [Title/TestInternet]
}


Player = {   
    id = "", -- twitter ID
    name = "",
    screen_name = "",
    secret_key = "",
    
    GetPlayerDataFromSecretKey = function( secret_key, callback )
        CS.Web.Get( Game.levelRepositoryUrl.."?getplayerdata="..secret_key, nil, CS.Web.ResponseType.JSON, 
            function( error, data )
                if error then
                    print("Player.GetPlayerDataFromSecretKey(): Error with secret key '"..secret_key.."': ", error.message)
                end
                
                if callback then
                     callback( error, data )
                end
            end
        )
    end
}

-- JavaScript
JS = {
    -- "js_" prefix means they will be replaced by actual JS functions
    -- "lua_" prefix means they will be JS functions that expect Lua arguments (this makes a difference when passing objects/tables)
    
    js_OnGameStarts = nil, -- called from [Log In/Start] when in webplayer only. Is used to do struff from JS on start
    
    lua_SetPlayerData = nil, -- set in [Log In]
}


BlockIdsByColor = {
    none = Map.EmptyBlockID,
    yellow = 41, --0
    orange = 33, --1
    gray110 = 40, --2
    gray110Outlined = 3,
    red = 43, --4
    green = 37, --32 5
    white = 6,
    black = 7,
    white230Outlined = 8,
    black50 = 9,
    white230 = 10, 
}


BlockIdsByColor.structureBase =     BlockIdsByColor.white230Outlined
BlockIdsByColor.silhouetteBase =    BlockIdsByColor.structureBase

BlockIdsByColor.structure =         BlockIdsByColor.orange

BlockIdsByColor.structureMouseOver = BlockIdsByColor.black50

BlockIdsByColor.silhouetteGoal =    BlockIdsByColor.yellow

BlockIdsByColor.structureShadow =   BlockIdsByColor.gray110--black50

BlockIdsByColor.shadowMatch =       BlockIdsByColor.green
BlockIdsByColor.shadowNoMatch =     BlockIdsByColor.structureShadow

-- test 11/08/14

BlockIdsByColor.structure =         48 --  blue

BlockIdsByColor.structureMouseOver = 48

BlockIdsByColor.silhouetteGoal =    52 -- yellow

BlockIdsByColor.structureShadow =   49 -- brown

BlockIdsByColor.shadowMatch =       53 -- green
BlockIdsByColor.shadowNoMatch =     50 -- red

BlockIdsByColor.levelSelectionSilhouetteGoal = 51 -- orange
BlockIdsByColor.levelSelectionSilhouetteBase = BlockIdsByColor.white230Outlined



function SetClickables( tag )
    tag = tag or "worldbutton"
    local scaleMultiplier = 1.2
    
    local gos = GameObject.GetWithTag( tag )
    for i, go in pairs( gos ) do
        local bg = go:GetChild("Background")
        --bg.mapRenderer.map:SetBlockAt(0,0,0,BlockIdsByColor.black)
        
        go.OnMouseEnter = function()
            if bg then
                bg.modelRenderer.opacity = 1
            else
                local scale = go.transform.localScale
                go.transform.localScale = scale * scaleMultiplier
            end
        end
        go.OnMouseExit = function()       
            if bg then
                bg.modelRenderer.opacity = 0.7
            else
                local scale = go.transform.localScale
                go.transform.localScale = scale / scaleMultiplier
            end
        end
        if bg then
            go.OnMouseExit()
        end
    end
end


Daneel.UserConfig = {
    debug = {
        enableDebug = true,
        enableStackTrace = true,
    }
}

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

local o = Map.LoadFromPackage
function Map.LoadFromPackage( pathOrAsset, callback )
    if type( pathOrAsset ) == "table" then -- 05/08/14 when is that the case ?
        pathOrAsset = pathOrAsset.path
    end
    --print(pathOrAsset )
    o( pathOrAsset, callback )
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

-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
ot( tr, tostring(t) )
end


local oSetBlockAt = Map.SetBlockAt
function Map.SetBlockAt( map, x, y, z, id, orientation )
    if type( x ) == "table" then
        id = y
        orientation = z
        y = x.y
        z = x.z
        x = x.x
    end
    orientation = orientation or Map.BlockOrientation.North
    oSetBlockAt( map, x, y, z, id, orientation )
end

local oGetBlockIDAt = Map.GetBlockIDAt
function Map.GetBlockIDAt( map, x, y, z )
    if type( x ) == "table" then
        y = x.y
        z = x.z
        x = x.x
    end
    return oGetBlockIDAt( map, x, y, z )
end


function GameObject.Show( go, opacity )
    local comp = go.textRenderer or go.modelRenderer or go.mapRenderer
    if comp ~= nil then
        comp.opacity = opacity or 1
    end
end

function GameObject.Hide( go, opacity )
    local comp = go.textRenderer or go.modelRenderer or go.mapRenderer
    if comp ~= nil then
        comp.opacity = opacity or 0
    end
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
