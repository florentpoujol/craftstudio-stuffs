function Behavior:Awake()
    self.gameObject.s = self -- used in [Player/OnDead]
    self.gameObject:AddTag("cross")
    local angles = Vector3(0)
    angles.x = math.randomrange(-10,10)
    angles.y = math.randomrange(-30,30)
    angles.z = math.randomrange(-10,10)
    self.gameObject.transform.eulerAngles = angles
    

end

function Behavior:Start()
    local pos = self.gameObject.transform.position
    Game.groundMap:SetBlockAt( pos - Vector3(0,0.5,0), BlockIds.darkDirt )
    
    Game.cameraGO.s:UpdateScore(1, pos )
    
    if self.isTombstone == true then
        self.gameObject.modelRenderer.model = "Tombstone"
    end
end

-- called by "OnDestroy" event fired from [Enemy/Explode]
function Behavior:OnDestroy()
    self.gameObject:RemoveTag()
    Game.cameraGO.s:UpdateScore( -1, self.gameObject.transform.position )
end

