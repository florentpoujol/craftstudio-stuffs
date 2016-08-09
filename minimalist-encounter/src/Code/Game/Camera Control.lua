
function Behavior:Start()   
    Daneel.Event.Listen("OnLeftArrowButtonDown", self.gameObject)
    Daneel.Event.Listen("OnRightArrowButtonDown", self.gameObject)
    Daneel.Event.Listen("OnUpArrowButtonDown", self.gameObject)
    Daneel.Event.Listen("OnDownArrowButtonDown", self.gameObject)
    self.speed = 2
    self.vectorLeft = Vector3:Left()
    self.vectorForward = Vector3:Forward()
end


function Behavior:OnLeftArrowButtonDown()
    self.gameObject.transform:MoveLocal(self.vectorLeft * 0.1 * self.speed)
end


function Behavior:OnRightArrowButtonDown()
    self.gameObject.transform:MoveLocal(self.vectorLeft * -0.1 * self.speed)
end


function Behavior:OnUpArrowButtonDown()
    self.gameObject.transform:MoveLocal(self.vectorForward * 0.1 * self.speed)
end


function Behavior:OnDownArrowButtonDown()
    self.gameObject.transform:MoveLocal(self.vectorForward * -0.1 * self.speed)
end
