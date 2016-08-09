
function Behavior:Awake()
    self.gameObject.buildingType = "node"
    self.gameObject.nearbyBuildings = {}
    self.gameObject.nearbyNodes = {}
    
    
end

function Behavior:Start()
    self.position = self.gameObject.transform.position
    self.gameObject.trigger.range = Game.node.range
    self.lineRenderers = {}
    
    -- get nearby buildings
    self.gameObject.trigger.tags = { "buildings" }
    self.gameObject.nearbyBuildings = self.gameObject.trigger:GetGameObjectsInRange()
    for i, building in pairs(self.gameObject.nearbyBuildings) do
        building.buildingScript:DrawLine( self.gameObject )
    end
    Daneel.Event.Listen("OnNewBuilding", self.gameObject)
    
    -- get nearby nodes
    self.gameObject.trigger.tags = { "nodes" }
    self.gameObject.nearbyNodes = self.gameObject.trigger:GetGameObjectsInRange()

    for i, node in ipairs(self.gameObject.nearbyNodes) do
        if node == self.gameObject then
            table.remove(self.gameObject.nearbyNodes, i)
            break
        else
            self.gameObject.buildingScript:DrawLine( node )
        end
    end
    
    Daneel.Event.Fire("OnNewNode", self.gameObject) -- Alert other nodes and power stations that a new node has been built
    Daneel.Event.Listen("OnNewNode", self.gameObject)
end





-- called when a new building (not a node) is created (in Building:Start())
function Behavior:OnNewBuilding(data)
    local building = data[1]
    if Vector3.Distance(self.position, building.transform.position) <= Game.node.range then
        table.insert(self.gameObject.nearbyBuildings, building)
        building.buildingScript:DrawLine( self.gameObject )
    end
end


-- OnNewNode event is fired when a new node is created (in Start() above)
-- If this new node is close enough to this node, add it to the nearby nodes list
-- The new node is never itself since the scriptedBehavior start to listen to the event only after firing it
function Behavior:OnNewNode(data)
    local node = data[1]
    if 
        Vector3.Distance(self.position, node.transform.position) <= Game.node.range and
        not table.containsvalue(self.gameObject.nearbyNodes, node) 
        -- the check is not needed anymore since the nearbyNodes is filled in awake (with the trigger) only with the existing nodes that already fired the OnNewNode event.
    then
        table.insert(self.gameObject.nearbyNodes, node)
        
    end
end
