
local oSetBlockAt = Map.SetBlockAt

local mapMockModel = CS.FindAsset("Map Mock", "Model")

function Map.SetBlockAt( map, x, y, z, id, orientation, gameObject )
    if orientation == nil then 
        orientation = Map.BlockOrientation.North
    end

    oSetBlockAt( map, x, y, z, id, orientation )
    
    if gameObject ~= nil then
    
        if gameObject.mapMocks == nil then -- a map mock is a game object with a model that "mock" the map block
            gameObject.mapMocks = {}
        end
        if gameObject.maxBlockY == nil then
            gameObject.maxBlockY = 0
         end

        local sPos = Vector3(x, y, z):ToString()
        
        if y > gameObject.maxBlockY then
            gameObject.maxBlockY = y
        end
    
        if id == Map.EmptyBlockID then
            if gameObject.mapMocks[ sPos ] ~= nil then
                gameObject.mapMocks[ sPos ]:Destroy()
                gameObject.mapMocks[ sPos ] = nil
            end
        else
            local go = gameObject.mapMocks[ sPos ]
            if go == nil then
                go = GameObject.New("")
                go.parent = gameObject
                go.location = Vector3(x, y, z)
                go.transform.localPosition = go.location * (64/16)
                go.transform.localEulerAngles = Vector3(0)
                go.transform.localScale = 64/16 -- 128 is the tile size
                go:AddComponent("ModelRenderer", {model = "Map Mock", opacity = 0})
                gameObject.mapMocks[ sPos ] = go
                print("model created", go.transform.localPosition)
            end
        end
    end
end

local daneelIntersectsMapRenderer = Ray.IntersectsMapRenderer

function Ray.IntersectsMapRenderer( ray, mapRenderer, returnRaycastHit )
    local mockGOs = mapRenderer.gameObject.mapMocks

    if mockGOs ~= nil then
        local hit = ray:Cast( table.copy( mockGOs ), true )[1]
        local distance, normal, hitBlockLocation, adjacentBlockLocation
         
        if hit ~= nil then
            distance = hit.distance
            normal = hit.normal
            hitBlockLocation = hit.gameObject.location
        end
        
        if hitBlockLocation ~= nil then
            setmetatable( hitBlockLocation, Vector3 )
        end
        if adjacentBlockLocation ~= nil then
            setmetatable( adjacentBlockLocation, Vector3 )
        end
        if returnRaycastHit and distance ~= nil then
            return RaycastHit.New({
                distance = distance,
                normal = normal,
                hitBlockLocation = hitBlockLocation,
                adjacentBlockLocation = adjacentBlockLocation,
                hitLocation = ray.position + ray.direction * distance,
                hitObject = mapRenderer,
                gameObject = mapRenderer.gameObject,
            })
        end
       
        return distance, normal, hitBlockLocation, adjacentBlockLocation
    else
        return daneelIntersectsMapRenderer( ray, mapRenderer, returnRaycastHit )
    end
end
