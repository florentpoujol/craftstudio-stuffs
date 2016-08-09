
function Behavior:Awake()
    self.splashGO = self.gameObject:GetChild("Random Mask")
--    self.splashGO.parent = "Dots Parent"
    --self.splashGO.transform.localPosition = Vector3(0)
    --self.splashGO.transform.local
    self.frameCount = 0
end


function Behavior:Update()
    self.frameCount = self.frameCount + 1
    if self.frameCount == 5 then
        self:Generate()
    end
end

function Behavior:Generate()
    Game.randomLevelGenerationInProgress = true    
    
    local nodesBySPosition = {}
    local allGOs = self.gameObject:GetChildren(true)
    table.removevalue(allGOs, self.splashGO)
    
    for i, go in pairs(allGOs) do
        if go.name =="Node" then
            go.parent = self.gameObject
            
            local node = GameObject.New("Entities/Node")
            node.parent = self.gameObject
            local pos = go.transform.localPosition
            node.transform.localPosition = pos
            
            nodesBySPosition[ pos:ToString() ] = node
            
            node.s:SetColor( "Green" )
            go:Destroy()
            
        end
    end
    
    -- take one node
    -- set random color
    
    --loop
        -- take a reachable neighbor
        -- set same or linked color (higher proba for linked color) (can't set same more than twice)
    
    -- when reaching dead end, find a free node
        -- loop
        
    -- then   ----------
    -- find all nodes with 3 or more connection
        -- pick some at random and make them fixed
    
    local nodes = GameObject.GetWithTag( "dot")
    local nodeModels = GameObject.GetWithTag( "dot_model")    
    local previousNode = nil
    local previousColor = "White"
    
    
    local pick = function( set )
        if #set == 0 then return nil end
        return set[ math.random( #set ) ]
    end
    
    local findNearByNodes = function( node, condFunction )
        if condFunction == nil then
            condFunction = function() return true end
        end
        local nearByNodes = {}
        
        local offset = 4
        local position = node.transform.position
        local sPosition = position:ToString()
        
        for x = position.x - offset, position.x + offset do
            for y = position.y - offset, position.y + offset do
                local _node = nodesBySPosition[ Vector3(x,y,0):ToString() ] 
                if 
                        _node ~= nil 
                    and _node ~= node
                    and not table.containsvalue( node.s.dotGOs, _node )
                    and node.s:CanConnect( _node )
                    and condFunction( node )
                then
                    table.insert( nearByNodes, _node )
                end
            end
        end
        
        return nearByNodes
    end
    
    local function findNotSetNodes()
        local _nodes = {}
        for i, node in pairs( nodes ) do
            if not node.isSet then
                table.insert( _nodes, node )
                
            end
        end
        return _nodes
    end
    
    --print("#nodes", #nodes)
    
    local i = 1
    local lastI = i
    while i <= 25 do
        i = i + 1
        --local pickColorAndConnect = function()
            local nodeSet = {}
            if previousNode == nil then
                nodeSet = findNotSetNodes()
            else
                nodeSet = findNearByNodes( previousNode, function(_node) return not _node.isSet end )
            end
            local node = pick( nodeSet )
            --print("#nodeSet, node", #nodeSet, node)
            
            if node ~= nil then
                
            
                local igo = GameObject.New("", {
                    parent = node,
                    transform= { 
                        localPosition = Vector3(0,0, 5 ) ,
                        localScale = 0.2
                    },
                    --textRenderer = { text = i, font = "Calibri" }
                    
                } )
                
                
                local colorSet = table.merge( table.copy( AllowedConnectionsByColor[ previousColor ] ), table.copy( AllowedConnectionsByColor[ previousColor ] ) )
                table.removevalue( colorSet, previousColor, 1 )
                table.removevalue( colorSet, "White" )
                -- now if previousColor was Yellow, colorSet contains Yellow, Green, Green, Blue, Blue
                
                local color = pick( colorSet )
                
                node.s:SetColor( color )
                node.isSet = true
                if previousNode ~= nil then
                    previousNode.s:Connect( node )
                end
                
                previousColor = color
                previousNode = node
            
            else 
                -- if node == nil
                --[[local notSetNodes = findNotSetNodes()
                if #notSetNodes > 0 then
                    previousNode = nil
                    previousColor = 
                end]]
                -- restart the loop
                previousNode = nil
                previousColor = "White"
            end
        --end
    end -- end while
    
    
    -- Find isolated nodes and change color to make sure they can connect to nearby nodes
    for i, node in pairs( nodes ) do
        if #node.s.connectionGOs == 0 then
            
            local nearByNodes = findNearByNodes( node )
            local n = pick( nearByNodes )
            
            if n ~= nil then -- n == nil somethimes ??
                local color = n.s.color
                local colorSet = table.merge( table.copy( AllowedConnectionsByColor[ color ] ), table.copy( AllowedConnectionsByColor[ color ] ) )
                table.removevalue( colorSet, color, 1 )
                table.removevalue( colorSet, "White" )
                
                node.s:SetColor( pick( colorSet ) )
                node.s:Connect( n )
            end
        end
    end
    
    
    -- Find nodes with more than connections, pick one or two and set fixed connections
    local heavyNodes = {}
    for i, node in pairs( nodes ) do
        if #node.s.connectionGOs >= 3 then
            table.insert( heavyNodes, node )
        end
    end
    --print("heavyNodes", #heavyNodes)
    
    if #heavyNodes >= 2 then
        local count = math.ceil( #heavyNodes / 2 )
        for i=1, count do
            local node = pick( heavyNodes )
            table.removevalue( heavyNodes, node )
            
            node.s.connectionCount = #node.s.connectionGOs
            node.s:SetLinksCount()
        end        
    end
    
    
    -- hide connections
    for i, node in pairs(nodes) do
        for j, go in pairs( node.s.connectionGOs ) do
            go:Destroy()
        end
        node.s.connectionGOs = {}
        node.s.dotGOs = {}
    end
    
    Game.randomLevelGenerationInProgress = false
    
    self.splashGO:Destroy()
    Daneel.Event.Fire("RandomLevelGenerated")
end