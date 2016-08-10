--[[PublicProperties
variableName string ""
value string ""
/PublicProperties]]



local function SetValueFromName( name, value )
    --print("setvaluefomname", name, value )
    if name:find( ".", 1, true ) == nil then
        _G[ name ] = value
    
    else
        local subNames = name:split( "." )
        local varName = table.remove( subNames, 1)
        
        local var = _G[ varName ]
        
        for i, varName in ipairs( subNames ) do
            if i == #subNames then
                var[ varName ] = value
            else
                var = var[ varName ]
            end
        end
    end
end

function Behavior:Awake()
    if self.variableName:trim() ~= "" then
        local value = self
        if self.value ~= "self" then
            value = self[self.value]
        end
        SetValueFromName( self.variableName, value )
    end
end