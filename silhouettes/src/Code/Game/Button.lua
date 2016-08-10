--[[PublicProperties
FunctionName string ""
Argument string ""
EnableTooltip boolean False
/PublicProperties]]

-- just a test, for fun

function Behavior:Awake()
    if self.EnableTooltip then
        self.gameObject:EnableTooltip()
    end
    
    self.func = table.getvalue( _G, self.FunctionName )
end

function Behavior:OnClick()
    if self.func ~= nil then
        self.func( self.Argument )
    end
end
