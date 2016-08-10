
function Behavior:Awake()
    GameObject.New("Background")
    
    ----------
    -- buttons and tooltip
    
    local homeGO = GameObject.Get("Home")
    homeGO:AddTag("uibutton")
    homeGO.OnClick = function()
        Scene.Load("Title")
    end
    homeGO:EnableTooltip()
    
    local editorGO = GameObject.Get("Level Editor")
    editorGO:AddTag("uibutton")
    editorGO.OnClick = function()
        Scene.Load("Editor")
    end
    editorGO:EnableTooltip()
    
    --
    local sortGOs = GameObject.Get("Sort Icons").childrenByName
    table.mergein( sortGOs, sortGOs["Order Group"].childrenByName )
    sortGOs["Order Group"] = nil
    
    for name, go in pairs( sortGOs ) do
        if go.name ~= "Refresh" then
            go.backgroundGO = go:GetChild("Background")
            
            go:AddTag("uibutton")
            GUI.Toggle.New(go)
            go:EnableTooltip()
        end
    end
    
    --
    self.sortLevelsBy = "Level Name"
    local onUpdate = function(toggle) -- when the toggle is checked/unchecked
        if toggle.isChecked then
            toggle.gameObject.backgroundGO:Show()
            self.sortLevelsBy = toggle.gameObject.name
            self:SortLevels()
            self:BuildLevelGrid()
        else
            toggle.gameObject.backgroundGO:Hide()
        end
    end
        
    sortGOs["Creator Name"].toggle.group = "sortby"
    sortGOs["Creator Name"].toggle.OnUpdate = onUpdate
    
    sortGOs["Date"].toggle.group = "sortby"
    sortGOs["Date"].toggle.OnUpdate = onUpdate

    sortGOs["Level Name"].toggle.group = "sortby"
    sortGOs["Level Name"].toggle.OnUpdate = onUpdate
    sortGOs["Level Name"].toggle:Check()
    
    --
    self.orderLevels = "Asc"
    local onUpdate = function(toggle) -- when the toggle is checked/unchecked
        if toggle.isChecked then
            toggle.gameObject.backgroundGO:Show()
            self.orderLevels = toggle.gameObject.name
            self:SortLevels()
            self:BuildLevelGrid()
        else
            toggle.gameObject.backgroundGO:Hide()
        end
    end
    
    sortGOs["Desc"].toggle.group = "order"
    sortGOs["Desc"].toggle.OnUpdate = onUpdate
    
    sortGOs["Asc"].toggle.group = "order"
    sortGOs["Asc"].toggle.OnUpdate = onUpdate
    sortGOs["Asc"].toggle:Check()
    
    ----------
    -- grid 
    
    self.gridGO = GameObject.Get("Levels Grid Origin")
    self.gridLayout = { x = 4, y = 4 }
    self.gridElemCount = self.gridLayout.x * self.gridLayout.y
      
    local screenSize = CS.Screen.GetSize()
    local pixelsToUnits = GameObject.Get("UI Camera").camera.pixelsToUnits 
    self.cartridgeWidth = ( (screenSize.x - 30) / self.gridLayout.x) * pixelsToUnits - 0.1   -- width of a cartridge in pixels
    self.cartridgeHeight = ( (screenSize.y - 70) / self.gridLayout.y) * pixelsToUnits -0.05
    
    ----------
    -- scroll bar
    
    self.scrollBarGO = GameObject.Get("Scroll Bar")
    self.barGO = self.scrollBarGO:GetChild("Bar")
    self.pointsGO = self.scrollBarGO:GetChild("Points")
    
    self.scrollBarLength = self.barGO.transform.localScale.y 
    self.firstLevelIndex = 1
    self.lastFirstLevelIndex = -999

    ----------
    self.allowBuildLevelGrid = true
    self.sortedLevels = Levels
    
    self:SortLevels()
    self:BuildLevelGrid()
end


function Behavior:SortLevels()
    if not self.allowBuildLevelGrid then
        return
    end
    
    local property = "name"
    if self.sortLevelsBy == "Creator Name" then
        property = "creatorName"
    elseif self.sortLevelsBy == "Date" then
        property = "timestamp"
    end
    
    local direction = "asc"
    if self.orderLevels == "Desc" then
        direction = "desc"
    end
    
    self.sortedLevels = table.sortby( Levels, property, direction )
    self.lastFirstLevelIndex = -99 -- allow the level grid to be rebuild
end


function Behavior:BuildLevelGrid()
    if not self.allowBuildLevelGrid then
        return
    end
    
    if self.firstLevelIndex < 1 then
        self.firstLevelIndex = 1
    end
    
    self.lastFirstLevelIndex = self.firstLevelIndex
    
    ---------
    
    for i, go in pairs( self.gridGO.children ) do
        go:Destroy()
    end
    for i, go in pairs( self.pointsGO.children ) do
        go:Destroy()
    end

    ----------
    -- place points on the scroll bar
    
    if #Levels <= self.gridElemCount then
        self.scrollBarGO.transform.localScale = Vector3(0)
    
    else
        self.scrollBarGO.transform.localScale = Vector3(1)
        
        local scrollPointsCount = math.ceil( #Levels / self.gridElemCount)
        
        -- this length is divided in scrollPointsCount segments, each points being at the center of its segment
        local segmentLength = self.scrollBarLength / scrollPointsCount
    
        --     scrollIndex = (levelIndex - 1) / self.gridElemCount + 1               
        -- <=> levelIndex  = scrollIndex * self.gridElemCount - self.gridElemCount.x + 1        
       
        local selectedScrollPointIndex = (self.firstLevelIndex - 1) / self.gridElemCount + 1
        
        for i = 1, scrollPointsCount do
            local point = GameObject.New("ScrollBar Point")
            point.parent = self.pointsGO
            point.transform.localPosition = Vector3(0, -(segmentLength * i - segmentLength / 2), 0)
            
            if i == selectedScrollPointIndex then
                point.s:Select()
            end
            
            point.s.levelIndex = i * self.gridElemCount - self.gridElemCount + 1
            point.OnClick = function(go)
                self.firstLevelIndex = go.s.levelIndex
                self:BuildLevelGrid()
            end
        end
    end
    
    -- resize the bar so that it doesn't go over or below the first and last points
    local scale = self.barGO.transform.localScale
    local firstPointGO = self.pointsGO.children[1]
    if firstPointGO ~= nil then
        scale.y = self.scrollBarLength - (-firstPointGO.transform.localPosition.y * 2)
    else
        scale.y = 0
    end
    self.barGO.transform.localScale = scale
    
    ----------
    -- build the level grid
    local x = 0
    local y = 0
    
    for index, level in ipairs( self.sortedLevels ) do
        if index >= self.firstLevelIndex then
        
            local cartridgeGO = GameObject.New("Level Selection Cartridge") --append scene
            cartridgeGO.parent = self.gridGO
            cartridgeGO.transform.localPosition = Vector3( self.cartridgeWidth * x, -self.cartridgeHeight * y, 0 )
            cartridgeGO.transform.localScale = 1.4
            
            cartridgeGO.s:SetData( level, Player.id == level.creatorId )
            
            x = x + 1
            if x >= self.gridLayout.x then
                x = 0
                y = y + 1
            end
            
            if y >= self.gridLayout.y then
                break
            end
        end
    end
end
