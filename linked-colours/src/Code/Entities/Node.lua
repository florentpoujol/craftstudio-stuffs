--[[PublicProperties
color string "Default"
connectionCount number 0
/PublicProperties]]

local soundLinkSuccess = CS.FindAsset("Link Success", "Sound")
local soundNoAction = CS.FindAsset("No Action", "Sound")

function Behavior:Awake()
    self.gameObject.s = self
    self.gameObject:AddTag("dot")
    self.childrenByName = self.gameObject.childrenByName
    
    --local origin = GameObject.New("Origin") -- origin of the overlay ?
    --print("origin", origin)
    --origin.parent = self.gameObject
    --origin.transform.localPosition = Vector3(0)
    
    --
    self.overlayGO = self.gameObject:GetChild("Overlay")
    if self.overlayGO == nil then
        self.overlayGO = GameObject.New("Overlay", {
            parent = self.gameObject, -- was origin instead of self.gameObejct
            transform = {
                localPosition = Vector3(0),
                localScale = Vector3(1.2,1.2,0.1)
            },
            modelRenderer = { model = "Cubes/White" } 
        } )
    end
    
    ----------
    -- links
    
    self:SetLinksCount()

    --
    self.isSelected = false
    self:Select(false)
    
    if (self.color == "" or self.color == "Default") and self.gameObject.modelRenderer then
        self.color = self.gameObject.modelRenderer.model.name
    end
    if self.color ~= "" and self.color ~= "Default" then
        self:SetColor( self.color )
    end
    
    self.dotGOs = {} -- dots this dot is connected to -- filled in Connect()
    self.connectionGOs = {}
end


function Behavior:Start()
    
end

function Behavior:SetLinksCount()
    local linkGO = self.gameObject:GetChild("Links")
    
    if self.connectionCount > 0 then
        if linkGO == nil then
            linkGO = GameObject.New("Entities/Links")
            linkGO.parent = self.gameObject
            linkGO.transform.localPosition = Vector3(0)
        end
        linkGO.transform.localScale = 1
        
        local children = linkGO.childrenByName

        for i=self.connectionCount+1, 5 do
            children[tostring(i)].modelRenderer.opacity = 0
        end

        if self.connectionCount % 2 == 0 then
            linkGO.transform.localPosition = Vector3(0,-0.085,0)
        end
    
    elseif linkGO ~= nil then
        linkGO.transform.localScale = 0
    end
end

function Behavior:SetColor( color )
    self.gameObject:RemoveTag(self.color)
    
    local colorGO = self.gameObject:GetChild("Color")
    
    if colorGO == nil then
        colorGO = GameObject.New("Color", {
            parent = self.gameObject,
            transform = {
                localPosition = Vector3(0),
            },
            modelRenderer = {
                model = "Dots/"..color
            },
        })
        
        self.gameObject.modelRenderer:Destroy()
    else

        colorGO.modelRenderer.model = "Dots/"..color
    end
    colorGO:AddTag("dot_model")
    colorGO.OnClick = function() self:OnClick() end
    self.colorGO = colorGO
    self.color = color
    
    self.gameObject:AddTag(color)
end


function Behavior:OnClick()
    local selectedDot = GameObject.GetWithTag("selected_dot")[1]
    if selectedDot ~= nil and selectedDot ~= self.gameObject then -- there is a selected dot and it's not this one
        --print(selectedDot, self.gameObject)
        --print((self.connectionCount <= 0 or (self.connectionCount > 0 and #self.dotGOs < self.connectionCount) ))
        --print( table.containsvalue( AllowedConnectionsByColor[ selectedDot.s.color ], self.color ) )
        --print(not table.containsvalue( selectedDot.s.dotGOs, self.gameObject ))
        
        if 
            (self.connectionCount <= 0 
            or (self.connectionCount > 0 and #self.dotGOs < self.connectionCount) ) -- prevent the dot to be connected if it has no more connoction to make
            and
            
            table.containsvalue( AllowedConnectionsByColor[ selectedDot.s.color ], self.color ) -- colors of the dots can connect
            and
            
            not table.containsvalue( selectedDot.s.dotGOs, self.gameObject ) -- if they are not already connected
        then
            
            -- check there isn't a bar in between
            if selectedDot.s:CanConnect( self.gameObject ) then
                selectedDot.s:Connect( self.gameObject )
            else
                if not Game.randomLevelGenerationInProgress then
                    soundNoAction:Play()
                end
            end
        else
            if not Game.randomLevelGenerationInProgress then
                soundNoAction:Play()
            end
        end
        
    end
    
    self:Select()
end


function Behavior:Select( select )
    if select == nil then
        select = not self.isSelected
        -- false if true (un select if already selected)
        -- true if false (select if not already selected)
    end
    
    if select then
        -- prevent the dot to be selected if it has no more connection to make
        if self.connectionCount > 0 and #self.dotGOs >= self.connectionCount then
            return
        end
        
        self.overlayGO:Show()
        
        self.isSelected = true
        
        local selectedDot = GameObject.GetWithTag("selected_dot")[1]
        if selectedDot ~= nil then
            selectedDot.s:Select(false)
        end
        self.gameObject:AddTag("selected_dot")
        
    else
        self.overlayGO:Hide()
        
        self.isSelected = false
        self.gameObject:RemoveTag("selected_dot")
    end
end


-- check there isn't a bar in between
function Behavior:CanConnect( targetGO )
    -- check there isn't a bar in between
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    local ray = Ray:New(otherPosition, (selfPosition - otherPosition):Normalized() )
    
    local barGOs = GameObject.GetWithTag( "connection" )
    -- remove from barGOs the connections of the selected node
    for i, go in pairs(self.connectionGOs) do
        table.removevalue( barGOs, go )
    end
    for i, go in pairs(targetGO.s.connectionGOs) do
        table.removevalue( barGOs, go )
    end
    
    table.mergein( barGOs, GameObject.GetWithTag( "dot_model" ) )
    if self.colorGO then
        table.removevalue( barGOs, self.colorGO )
    end
    if targetGO.s.colorGO then
        table.removevalue( barGOs, targetGO.s.colorGO )
    end

    
    local hit = ray:Cast( barGOs, true )[1]

    if hit == nil or hit.distance > (selfPosition - otherPosition):GetLength() then
        return true
    end
    return false
end


function Behavior:Connect( targetGO )
    local barGO = GameObject.New("Entities/Link")
    barGO.parent = self.gameObject
    barGO.transform.localPosition = Vector3(0,0,0)
    
    local selfPosition = self.gameObject.transform.position
    local otherPosition = targetGO.transform.position 
    local direction = otherPosition - selfPosition
    local linkLength = direction:Length()
    
    barGO.transform:Move( direction:Normalized() * 0.5 )
    
    barGO.transform:LookAt( otherPosition )
    local angles = barGO.transform.localEulerAngles
    local y = math.round( angles.y )
    
    if y == 90 then
        -- links that goes upward
        angles.z = -180
        barGO.transform.localEulerAngles = angles
    elseif y == 0 then
        -- totally vertical link
        angles.z = 90 -- totally wild guess
        barGO.transform.localEulerAngles = angles
    end
    
    barGO.transform.localScale = Vector3(0.3,0.3, linkLength-1 )

    barGO.s:SetColor( self.color, targetGO.s.color )
    
    --
       
    barGO.s.dotGOs = { self.gameObject, targetGO }
    
    table.insert( self.dotGOs, targetGO )
    table.insert( targetGO.s.dotGOs, self.gameObject )
    
    table.insert( self.connectionGOs, barGO )
    table.insert( targetGO.s.connectionGOs, barGO )
    
    --
    if self.connectionCount > 0 and #self.dotGOs >= self.connectionCount then
        self:Select(false)
    end
    
    if not Game.randomLevelGenerationInProgress then
        soundLinkSuccess:Play()
    end
    
    self:CheckVictory()
end


function Behavior:CheckAllDotsConnected()
    local dots = GameObject.GetWithTag( "dot" )
    
    -- quick-search for dots without connections
    for i, dot in pairs( dots ) do
        if #dot.s.connectionGOs == 0 then
            return false
        end
    end
    
    -- using simplified BFS (breadth-first search), check that all dots are actually connected together
    -- if all dots are connected, the algo must find as many dots as they are
    
    local visited = {}
    local toBeVisited = { dots[1] }
    
    while #toBeVisited > 0 do
        local dot = table.remove( toBeVisited, 1 )
        table.insert( visited, dot )
        dot.wasVisited = true
        
        for i, connectedDot in pairs( dot.s.dotGOs ) do
            if not connectedDot.wasVisited and not connectedDot.willBeVisited then
                table.insert( toBeVisited, connectedDot )
                connectedDot.willBeVisited = true
            end
        end
    end
    
    for i, dot in pairs(dots) do
        dot.wasVisited = nil
        dot.willBeVisited = nil        
    end
    
    if #visited == #dots then
        return true
    end
    return false
end


function Behavior:CheckVictory()
    local dots = GameObject.GetWithTag( "dot" )
    
    -- check that all dots have all their connection
    for i, dot in pairs(dots) do
        if dot.s.connectionCount > 0 and #dot.s.dotGOs < dot.s.connectionCount then
            return false
        end
    end

    local allDotsConnected = self:CheckAllDotsConnected()
    
    if allDotsConnected then
        Daneel.Event.Fire("EndLevel")
    end
end
