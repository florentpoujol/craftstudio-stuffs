function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject.modelRenderer.opacity = 0
end

function Behavior:Init( callback )
    local animTime = 0.3
    
    self.gameObject:Animate("opacity", 0.5, animTime)
    self.gameObject:Animate("localScale", Vector3(2,100,2), animTime, function()
        
        callback()
        
        self.gameObject:Animate("opacity", 0, animTime)
        self.gameObject:Animate("localScale", Vector3(0,100,0), animTime, {
            OnComplete = function() self.gameObject:Destroy() end
        } )
    end )
end
