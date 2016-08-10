function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("uibutton")
    self.levelIndex = -1
end

function Behavior:Select()
    self.gameObject.textRenderer.text = "*"
end
