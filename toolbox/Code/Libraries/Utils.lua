--[[
Utils.CaseProof( name, set )
Utils.ReplaceInString( string, replacements )
Utils.GetValueFromName( name )
Utils.GetNameFromValue( object )
Utils.GetType( object[, luaTypeOnly] )
Utils.GlobalExists( name )
Utils.ToNumber( data )
Utils.ToRawString( data )
]]

Utils = {}

--- Make sure that the case of the provided name is correct by checking (and correcting) it against the values in the provided set.
-- @param name (string) The name to check the case of.
-- @param set (string or table) A single value or a table of values to check the name against.
function Utils.CaseProof( name, set )
    if type( set ) == "string" then
        set = { set }
    end
    local lname = name:lower()
    for i, item in pairs( set ) do
        if lname == item:lower() then
            name = item
            break
        end
    end
    return name
end

--- Replace placeholders in the provided string with their corresponding provided replacements.
-- @param s (string) The string.
-- @param replacements (table) The placeholders as keys and their replacements as values. Ie : { placeholder = "replacement", ... }
-- @return (string) The string.
function Utils.ReplaceInString( string, replacements )
    for placeholder, replacement in pairs( replacements ) do
        string = string:gsub( placeholder, replacement )
    end
    return string
end

--- Returns the value of any global variable (including nested tables) from its name as a string.
-- When the variable is nested in one or several tables (like CS.Input), put a dot between the names.
-- @param name (string) The variable name.
-- @return (mixed) The variable value, or nil.
function Utils.GetValueFromName( name )
    if name:find( ".", 1, true ) ~= nil then
        name = name .. "."
        local subNames = { name:match( (name:gsub( "([^.]*).", "(%1)." )) ) } -- string.split( s, delimiter ) LEAVE the parenthesis around gsub()
        local varName = table.remove( subNames, 1 )

        local value = nil 
        for k, v in pairs( _G ) do
            if k == varName then
                value = v
                break
            end
        end
        if value == nil then
            return nil
        end
        
        for i, _key in ipairs( subNames ) do
            varName = varName .. "." .. _key
            if value[ _key ] == nil then
                return nil
            else
                value = value[ _key ]
            end
        end
        return value
    end
    for k, v in pairs( _G ) do
        if k == name then
            return v
        end
    end
    return nil
end

--- Returns the name as a string of the global variable (including nested tables) whose value is provided.
-- This only works if the value of the variable is a table or a function.
-- When the variable is nested in one or several tables (like GUI.Hud), it must have been set in the 'userObject' table in the config if not already part of CraftStudio or Daneel.
-- @param value (table or function) Any global variable, any object from CraftStudio or Daneel or objects whose name is set in 'userObjects' in the Daneel.Config.
-- @return (string) The name, or nil.
function Utils.GetNameFromValue( value )
    if value == nil then
        error( "Utils.GetNameFromValue() : Argument 1 'value' is nil.")
    end
    for k, v in pairs( _G ) do
        if value == v then
            return k
        end
    end
    return nil
end

--- Return the Lua or CraftStudio type of the provided argument.
-- For instances of objects, the type is the name of the metatable of the provided object, if the metatable is a first-level global variable. 
-- Will return "ScriptedBehavior" when the provided object is a scripted behavior instance (yet ScriptedBehavior is not its metatable).
-- @param object (mixed) The argument to get the type of.
-- @param luaTypeOnly (boolean) [optional default=false] Tell whether to return only Lua's built-in types (string, number, boolean, table, function, userdata or thread).
-- @return (string) The type.
function Utils.GetType( object, luaTypeOnly )
    local argType = type( object )
    if not luaTypeOnly and argType == "table" then
        -- the type is defined by the object's metatable
        local mt = getmetatable( object )
        if mt ~= nil then
            -- the metatable of the scripted behaviors is the corresponding script asset ('Behavior' in the script)
            -- the metatable of all script assets is the Script object
            if getmetatable( mt ) == Script then
                return "ScriptedBehavior"
            else
                for key, value in pairs( _G ) do
                    if mt == value then
                        return key
                    end
                end
            end
        end
    end
    return argType
end

--- Tell wether the provided global variable name exists (is non-nil).
-- Since CraftStudio uses Strict.lua, you can not write (variable == nil), nor (_G[variable] == nil).
-- Only works for first-level global variables. Check if Daneel.Utils.GetValueFromName() returns nil for the same effect with nested tables.
-- @param name (string) The variable name.
-- @return (boolean) True if it exists, false otherwise.
function Utils.GlobalExists( name )
    -- doesn't work : return (_G[variable] ~= nil)
    for k, v in pairs( _G ) do
        if k == name then
            return true
        end
    end
    return false
end

--- A more flexible version of Lua's built-in tonumber() function.
-- Returns the first continuous series of numbers found in the text version of the provided data even if it is prefixed or suffied by other characters.
-- @param data (mixed) The data (usually a string).
-- @return (number) The number, or nil.
function Utils.ToNumber( data )
    if data == nil then
        error( "Utils.ToNumber( data ) : Argument 1 'data' is nil." )
    end
    local number = tonumber( data )
    if number == nil then
        data = tostring( data )
        number = data:match( (data:gsub( "(%d+)", "(%1)" )) )
        number = tonumber( number )
    end
    return number
end

--- Bypass the __tostring() function that may exists on the data's metatable.
-- @param data (mixed) The data to be converted to string.
-- @return (string) The string.
function Utils.ToRawString( data )
    local text = nil
    local mt = getmetatable( data )
    if mt ~= nil and mt.__tostring ~= nil then
        local mttostring = mt.__tostring
        mt.__tostring = nil
        text = tostring(data)
        mt.__tostring = mttostring
    end
    if text == nil then 
        text = tostring( data )
    end
    return text
end
