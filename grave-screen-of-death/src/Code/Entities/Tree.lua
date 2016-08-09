
local startAnimTimes = {}
for i=0.1, 2, 0.1 do
    table.insert( startAnimTimes, i )
end

function Behavior:Awake()
    self.shadowGO = self.gameObject.child
    self.pivotGO = self.gameObject:GetChild("Pivot")
    self.rendererGO = self.gameObject:GetChild("Renderer", true)
    
    local angles = Vector3(0, math.random(360), 0)   
    self.pivotGO.transform.localEulerAngles = angles
    
    local scale = Vector3( math.randomrange(0.5, 2), math.randomrange(2, 4), math.randomrange(0.5, 2) )
    self.pivotGO.transform.localScale = scale
    
    self.rendererGO.modelRenderer.animation = "Tree Hover"
    self.rendererGO.modelRenderer:StopAnimationPlayback()
    self.shadowGO.modelRenderer.animation = "Shadow"
    self.shadowGO.modelRenderer:StopAnimationPlayback()
    
    local time = math.randomrange(0.1, 2)
    if #startAnimTimes > 0 then
        time = table.remove( startAnimTimes, math.random(#startAnimTimes) )
    end
    
    Tween.Timer( time, function()
        self.rendererGO.modelRenderer:StartAnimationPlayback(true)
        self.shadowGO.modelRenderer:StartAnimationPlayback(true)
    end)
end
