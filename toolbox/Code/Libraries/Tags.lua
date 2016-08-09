--[[PublicProperties
tags string ""
/PublicProperties]]
--[[
Tags are a way to group game objects.
Manage tags on game objects with gameObject:AddTag(), gameObject:RemoveTag() and gameObject:HasTag().
Get all game objets that have one or several particular tag(s) with GameObject.GetWithTag().

A game object may have several tags and a same tag may be used by several game objects. You can get the tags via the tags property on each game object (will be nil if no tags has been set yet).

Game objects that have tags are referenced in the GameObject.Tags[tagName] table.
Get all game object(s) that have all of the provided tag(s) with GameObject.GetWithTag(tag).


Add this file as a scripted behavior to game objects to add tags while in the scene editor (concatenate several tags with a coma).
]]

GameObject.Tags = {}

--- Returns the game object(s) that have all the provided tag(s).
-- @param tag (string or table) One or several tag(s) (as a string or table of strings).
-- @return (table) The game object(s) (empty if none is found).
function GameObject.GetWithTag( tag )
    local tags = tag
    if type( tags ) == "string" then
        tags = { tags }
    end

    local gameObjectsWithTag = {}

    for i, tag in pairs( tags ) do
        local gameObjects = GameObject.Tags[ tag ]
        if gameObjects ~= nil then
            for j, gameObject in pairs( gameObjects ) do
                if gameObject.inner ~= nil then
                    if gameObject:HasTag( tags ) and not table.containsvalue( gameObjectsWithTag, gameObject ) then
                        table.insert( gameObjectsWithTag, gameObject )
                    end
                else
                    table.remove( gameObjects, j )
                end
            end
        end
    end

    return gameObjectsWithTag
end

--- Returns the tag(s) of the provided game object.
-- @param gameObject (GameObject) The game object.
-- @return (table) The tag(s) (empty if the game object has no tag).
function GameObject.GetTags( gameObject )
    local tags = {}
    for tag, gameObjects in pairs( GameObject.Tags ) do
        if table.containsvalue( gameObjects, gameObject ) then
            table.insert( tags, tag )
        end
    end
    return tags
end

--- Add the provided tag(s) to the provided game object.
-- @param gameObject (GameObject) The game object.
-- @param tag (string or table) One or several tag(s) (as a string or table of strings).
function GameObject.AddTag( gameObject, tag )
    local tags = tag
    if type( tags ) == "string" then
        tags = { tags }
    end

    for i, tag in pairs( tags ) do
        if GameObject.Tags[ tag ] == nil then
            GameObject.Tags[ tag ] = { gameObject }
        elseif not table.containsvalue( GameObject.Tags[ tag ], gameObject ) then
            table.insert( GameObject.Tags[ tag ], gameObject )
        end
    end
end

--- Remove the provided tag(s) from the provided game object.
-- If the 'tag' argument is not provided, all tag of the game object will be removed.
-- @param gameObject (GameObject) The game object.
-- @param tag [optional] (string or table) One or several tag(s) (as a string or table of strings).
function GameObject.RemoveTag( gameObject, tag )   
    local tags = tag
    if type( tags ) == "string" then
        tags = { tags }
    end

    for tag, gameObjects in pairs( GameObject.Tags ) do
        if tags == nil or table.containsvalue( tags, tag ) then
            for i, _gameObject in pairs( GameObject.Tags[ tag ] ) do
                if _gameObject == gameObject then
                    table.remove( GameObject.Tags[ tag ], i )
                end
            end
        end
    end
end

--- Tell whether the provided game object has all (or at least one of) the provided tag(s).
-- @param gameObject (GameObject) The game object.
-- @param tag (string or table) One or several tag (as a string or table of strings).
-- @param atLeastOneTag [default=false] (boolean) If true, returns true if the game object has AT LEAST one of the tag (instead of ALL the tag).
-- @return (boolean) True
function GameObject.HasTag( gameObject, tag, atLeastOneTag )
    local tags = tag
    if type(tags) == "string" then
        tags = { tags }
    end
    local hasTags = false
    if atLeastOneTag == true then
        for i, tag in pairs( tags ) do
            if GameObject.Tags[ tag ] ~= nil and table.containsvalue( GameObject.Tags[ tag ], gameObject ) then
                hasTags = true
                break
            end
        end
    else
        hasTags = true
        for i, tag in pairs( tags ) do
            if GameObject.Tags[ tag ] == nil or not table.containsvalue( GameObject.Tags[ tag ], gameObject ) then
                hasTags = false
                break
            end
        end
    end

    return hasTags
end


if table.containsvalue == nil then
    function table.containsvalue( t, p_value, ignoreCase )
        if p_value == nil then
            error( "table.containsvalue() : Argument 2 'p_value' is nil." )
        end
        
        if ignoreCase then
            p_value = p_value:lower()
        end

        for key, value in pairs( t ) do
            if ignoreCase then
                value = value:lower()
            end

            if p_value == value then
                return true
            end
        end
        
        return false
    end
end


----------------------------------------------------------------------------------

--[[PublicProperties
tags string ""
/PublicProperties]]

function Behavior:Awake()
    if self.tags ~= "" then
        self.tags = self.tags:split( "," )
        for i, tag in pairs( self.tags ) do
            self.tags[ i ] = tag:gsub( "^%s+", "" ):gsub( "%s+$", "" ) -- trim
        end
        self.gameObject:AddTag( self.tags )
    end
end

if string.split == nil then
    --- Split the provided string in several chunks, using the provided delimiter.
    -- The delimiter can be a pattern and can be several characters long.
    -- If the string does not contain the delimiter, a table containing only the whole string is returned.
    -- @param s (string) The string.
    -- @param delimiter (string) The delimiter.
    -- @return (table) The chunks.
    function string.split( s, delimiter )
        local chunks = {}
        if delimiterIsPattern == nil and #delimiter == 1 then
            delimiterIsPattern = false
        end
        
        if s:find( delimiter, 1, true ) ~= nil then
            if string.startswith( s, delimiter ) then
                s = s:sub( #delimiter+1, #s )
            end
            if not s:endswith( delimiter ) then
                s = s .. delimiter
            end

            local chunk = ""
            local ts = string.totable( s )
            local i = 1

            while i <= #ts do
                local char = ts[i]
                if char == delimiter or s:sub( i, i-1 + #delimiter ) == delimiter then
                    table.insert( chunks, chunk )
                    chunk = ""
                    i = i + #delimiter
                else
                    chunk = chunk..char
                    i = i + 1
                end
            end

            if #chunk > 0 then
                table.insert( chunks, chunk )
            end
        end

        if #chunks == 0 then
            chunks = { s }
        end

        return chunks
    end
end
