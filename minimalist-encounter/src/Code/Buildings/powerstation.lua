
function Behavior:Awake()
    self.gameObject.buildingType = "powerstation"
    self.gameObject.nearbyNodes = {}
  
    self.timer = Tween.Timer(Game.powerstation.actionInterval, function() self:SpawnEnergy() end, true)
    -- every Game.powerstation.actionInterval seconds, the OnLoopComplete event is fired an call in turn Behavior:SpawnEnergy
end

function Behavior:Start()
    -- this is done here in Start because the position of the building is set after Awake is called
    -- (via the params argument of GameObject.NewFromScene() in the BuildingCreation:OnLeftMouseButtonJustPressed())
    self.position = self.gameObject.transform.position
    self.gameObject.trigger.range = Game.powerstation.range
    self.gameObject.trigger.tags = { "nodes" }
    self.gameObject.nearbyNodes = self.gameObject.trigger:GetGameObjectsInRange()
    Daneel.Event.Listen("OnNewNode", self.gameObject)
end


function Behavior:OnDestroy()
    -- OnDestroy is called 4 times ??
    if not self.timer.isDestroyed then
        self.timer:Destroy()
   end
end


function Behavior:OnNewNode(data)
    local node = data[1]
    if 
        Vector3.Distance(self.position, node.transform.position) <=  Game.powerstation.range and
        not table.containsvalue(self.gameObject.nearbyNodes, node)
        -- the check is not needed anymore since the nearbyNodes is filled in Start (with the trigger) only with the existing nodes that already fired the OnNewNode event.
    then
        table.insert(self.gameObject.nearbyNodes, node)
    end
end


function Behavior:SpawnEnergy()
    if self.gameObject == nil then
        self.timer:Destroy()
        self.timer = nil
        return
    end
    
    if self.gameObject.isDestroyed or not self.gameObject.isBuilt or not self.gameObject.isAlive or #self.gameObject.nearbyNodes <= 0 then
        return
    end
    
    -- spawn an energy
    local energy = GameObject.New("Prefabs/Energy")
    energy.transform.position = self.position
    
    -- choose a target at random amongst the nearby nodes
    local randomTargetNode = math.round(math.randomrange(1, #self.gameObject.nearbyNodes)) 
    local targetNode = self.gameObject.nearbyNodes[randomTargetNode]
    --print("spawn energy", targetNode, targetNode.transform, #self.gameObject.nearbyNodes)
    energy.energyScript.target = targetNode
    energy.energyScript.targetPosition = targetNode.transform.position
end
