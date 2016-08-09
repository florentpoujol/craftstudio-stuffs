--[[
This script allows you to test if a piece of code throws some errors whithout killing the script that want to test.

Ie :

local success = Try( function()
    -- code to test
end )

if success then
    print( "That went well" )
else -- catch
    print( "Oh noes, there was an error in the code !" )
end
]]

local Behavior = Behavior
local gameObject = nil

-- @param func (function or userdata) The function or userdata to test.
-- @return (boolean) True if the supplied function didn't throw an error, false otherwise.
function Try( func )
    if gameObject == nil or gameObject.transform == nil then
        gameObject = CS.CreateGameObject( "Try" )
    end
    local success = false
    gameObject:CreateScriptedBehavior( Behavior, {
        try = func,
        success = function() success = true end
    } )
    return success
end

function Behavior:Awake()
    CS.Destroy( self )
    self.try()
    self.success()
end
