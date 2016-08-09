--[[PublicProperties
FunctionName string ""
Argument string ""
EnableTooltip boolean False
tag string ""
/PublicProperties]]

function Behavior:Awake()
    if self.EnableTooltip then
        self.gameObject:EnableTooltip()
    end
    
    self.func = table.getvalue( _G, self.FunctionName )
    
    if self.tag ~= "" then
        self.gameObject:AddTag(self.tag)
    end
end

function Behavior:OnClick()
    if self.func ~= nil then
        self.func( self.Argument )
    end
end
