
local Behavior = Behavior
local gameObject = nil

-- Tell wether the provided button name exits amongst the Game Controls, or not.
-- WARNING : It will kill the game, if it is called from an Awake() function, and the second argument is 'self.gameObject'.
-- @param buttonName (string) The button name.
-- @return (boolean) True if the button name exists, false otherwise.
function ButtonExists( buttonName )
    if gameObject == nil or gameObject.transform == nil then
        gameObject = CS.CreateGameObject( "ButtonExists" )
    end

    local buttonExists = false
    gameObject:CreateScriptedBehavior( Behavior, { 
        buttonName = buttonName, 
        success = function() buttonExists = true end  
    } )
    return buttonExists
end

function Behavior:Awake()
    CS.Destroy( self )
    CS.Input.WasButtonJustPressed( self.buttonName )
    -- this function will throw an error, kill the script and not call the callback if the button name is unknow
    self.success()
end
