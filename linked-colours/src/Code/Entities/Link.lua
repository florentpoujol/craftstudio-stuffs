--[[PublicProperties
color string "Red"
/PublicProperties]]

local soundLinkBroken = CS.FindAsset("Link Broken", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("connection")
    
    self.startGradient = self.gameObject:GetChild("Start Gradient")
    self.endGradient = self.gameObject:GetChild("End Gradient")
    
    --self:SetColor( self.color )
    
    self.dotGOs = {} -- filled in [Dot/Connect]
end


function Behavior:SetColor( color, endColor )
    self.gameObject:RemoveTag(self.color)
    
    self.gameObject.modelRenderer.model = "Bars/"..color

    if Asset("Gradients/"..color) ~= nil and Asset("Gradients/"..endColor) ~= nil then
        self.startGradient.modelRenderer.model = "Gradients/"..color
        self.endGradient.modelRenderer.model = "Gradients/"..endColor
        self.gameObject.modelRenderer.model = "Bars/Crystal White"
        self.gameObject.modelRenderer.opacity = 0
    end
    
    self.color = color
    
    self.gameObject:AddTag(color)
end


function Behavior:OnClick()
    local dot1 = self.dotGOs[1]  
    local dot2 = self.dotGOs[2]
    
    table.removevalue( dot1.s.dotGOs, dot2 )
    table.removevalue( dot2.s.dotGOs, dot1 )
    
    table.removevalue( dot1.s.connectionGOs, self.gameObject )
    table.removevalue( dot2.s.connectionGOs, self.gameObject )
    
    soundLinkBroken:Play()
    Game.deletedLinkCount = Game.deletedLinkCount + 1
    self.gameObject:Destroy()
end
