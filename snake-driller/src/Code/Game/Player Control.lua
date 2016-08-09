     
PlayerGO = nil


function Behavior:Awake()
    PlayerGO = self.gameObject
    self.gameObject.s = self
    
    self.runControls = false
    
    Tween.Timer( 0.5, function()
        self.runControls = true
    end )
    
       
    self.offset = Vector3(0,-1,0)
    self.nextOffset = Vector3(0,-1,0)
    
    self.moveDirection = "down"
    self.nextMoveDirection = "down"
    
    self.frameCount = 0
    self.nextMoveTime = 0
    DrillingTimeModifier = 1

    self.aheadBlockId = 0
    
    local ui = Scene.Append( "UI" )
    ui.transform.position = Vector3( 0, -500, -500 )
    
    
    Daneel.Event.Listen("MenuToggleDisplay", function()
        if UI.menu.isDisplayed then
            self.runControls = false
        else
            self.runControls = true 
        end
    end )
    
    self.map2 = GameObject.Get("Map2").mapRenderer.map
    self:UpdateNextBlock()
end


function Behavior:Update()
    if not self.runControls then
        return
    end
    
    if CS.Input.WasButtonJustPressed( "Up" ) then
        self.nextOffset = Vector3(0,1,0)
        self.nextMoveDirection = "up"
        self:UpdateNextBlock()
    elseif CS.Input.WasButtonJustPressed( "Down" ) then
        self.nextOffset = Vector3(0,-1,0)
        self.nextMoveDirection = "down"
        self:UpdateNextBlock()        
    elseif CS.Input.WasButtonJustPressed( "Left" ) then
        self.nextOffset = Vector3(-1,0,0)
        self.nextMoveDirection = "left"
        self:UpdateNextBlock()        
    elseif CS.Input.WasButtonJustPressed( "Right" ) then
        self.nextOffset = Vector3(1,0,0)
        self.nextMoveDirection = "right"
        self:UpdateNextBlock()        
    end
    
    
    self.frameCount = self.frameCount + 1
    
    if self.frameCount >= self.nextMoveTime then
        self:BlockDrilled( self:GetAheadBlockId() )
        self:Move()
        
        self.offset = self.nextOffset
        self.moveDirection = self.nextMoveDirection
        
        local blockId = self:GetAheadBlockId()
        if self:CanDrill(blockId) then
            self.nextMoveTime = GetBlockById( blockId ).drillingTime * DrillingTimeModifier * 60
            
            self.frameCount = 0
        else
            self.runControls = false
            Tween.Timer( 0.5, function() self:EndGame() end ) -- Let the frame ends and the graphics be updated so that the drill move one last time before the end game
        end
    end
end


function Behavior:UpdateNextBlock()    
    if self.map2.positions ~= nil then
        for i, pos in pairs( self.map2.positions ) do
            self.map2:SetBlockAt( pos.x, pos.y, 0, Map.EmptyBlockID)
        end
    end
    self.map2.positions = {}
    
    local position = self.gameObject.transform.position + self.offset
    --print("position", position, self.gameObject.transform.position,self.offset)
    self.map2:SetBlockAt( position.x, position.y, 0, 32 )
    table.insert( self.map2.positions, position )
    
    position = position + self.nextOffset
    self.map2:SetBlockAt( position.x, position.y, 0, 33 )
    table.insert( self.map2.positions, position )
end


function Behavior:GetAheadBlockId()
    local position = self.gameObject.transform.position + self.offset
    return MapGO.s.map:GetBlockIDAt( position.x, position.y, 0 )
end


function Behavior:Move()
    self.gameObject.transform:Move( self.offset )
    MapGO.s:UpdateMap( self.moveDirection )
    
    local position = self.gameObject.transform.position
    MapGO.s.map:SetBlockAt( position.x, position.y, -1, MapGO.s:GetRandomBlockID() ) -- set a block behind the drll and drill pipes
    
    self.offset = self.nextOffset
    self.moveDirection = self.nextMoveDirection
    
    self:UpdateNextBlock()
end


function Behavior:CanDrill( blockId )
    for name, data in pairs( Blocks ) do
        if data.id == blockId and data.isDrillable == true then
            return true
        end
    end
    return false
end


function Behavior:BlockDrilled( id )
    local position = self.gameObject.transform.position
    local depth = position.y - 1
    
    depth = math.abs( depth )
    if depth > UI.hud.depthGO.depth then
        UI.hud.depthGO.UpdateDepth( depth )
    end
    
    local block = GetBlockById( id )
    if block and block.drillEffect ~= nil then
        block.drillEffect()
    end
end


function Behavior:EndGame( isOutOfTime )
    UI.hud:Hide()
    UI.menu:Hide()
    UI.endGame:Show()
    
    self.runControls = false
    
    if isOutOfTime then
        UI.endGame.endTextGO.textArea.text = "You ran out of time !;You can refine oil or;buy more in the store!"
    else
        UI.endGame.endTextGO.textArea.text = "You destroyed your drill !;You can buy upgrades in the store;to drill more blocks or drill faster !"
    end
    
    UI.endGame.scoreGO.textRenderer.text = UI.hud.depthGO.depth
    UI.endGame.bestScoreGO.textRenderer.text = PlayerScore
    
    UpdateLeaderboard()
    SavePlayerData()
end