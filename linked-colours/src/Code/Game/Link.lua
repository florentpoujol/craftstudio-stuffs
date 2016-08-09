--[[PublicProperties
target string ""
tag string ""
/PublicProperties]]
function Behavior:Awake()
    self.gameObject:AddTag(self.tag)
    
    local target = self.target
    if target == "" then
        target = self.gameObject.textRenderer.text
    end
    if not string.startswith( target, "http://" ) and not string.startswith( target, "https://" ) then
        target = "http://"..target
    end
    self.gameObject.OnClick = function()
        CS.Web.Open( target )
    end
end
