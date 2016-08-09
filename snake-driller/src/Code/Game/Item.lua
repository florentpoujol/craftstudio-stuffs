--[[PublicProperties
effect string ""
/PublicProperties]]

function Behavior:Awake()
    self.gameObject.s = self
end

function Behavior:Start()
    self.gameObject:GetChild("Effect").textArea.text = self.effect
end

