
function Behavior:Awake()
    local bg = GameObject.New("Background")
    local mask = bg:GetChild("Mask", true)
    --mask.modelRenderer.model = "Cubes/White"
    mask.modelRenderer.opacity = 0.6
    
    
    local dotsParent = GameObject.Get("Dots Parent")
    -- spawn level content
    local level = Game.levelToLoad or Levels[1]
    local dots = GameObject.New( level.scenePath )
    
    dots.parent = dotsParent
    dots.transform.localPosition = Vector3(0)
    
    --
    if level.tutoText ~= nil then
        self:SetupTuto( level )
    end
    
    self:UpdateLevelCamera()
    Daneel.Event.Listen("RandomLevelGenerated", function() self:UpdateLevelCamera() end )
    
    -- update the orthographic scale of the world camera so that the whole level but not more is visible
    
    
    ----------
    -- end level
    
    Daneel.Event.Listen( "EndLevel", self.gameObject ) -- fired from [Dot/CheckVictory]
    self.levelStartTime = os.clock()
    Game.deletedLinkCount = 0 -- updated in [Connection/OnClick], used in EndLevel() below
    
    self.endLevelGO = GameObject.Get("End Level")
    self.endLevelGO.transform.localPosition = Vector3(0,-40,0)
end


function Behavior:UpdateLevelCamera()
   local dots = GameObject.GetWithTag("dot")
    local maxY = 0
    for i, dot in pairs(dots) do
        local y = math.abs( dot.transform.position.y )
        if y > maxY then
            maxY = y
        end
    end

    GameObject.Get("World Camera").camera.orthographicScale = math.ceil(maxY + 1) * 2
    
    if Game.levelToLoad.name == "Random" then
        GameObject.Get("World Camera").camera.orthographicScale = 20
        --print("set camera")
    end
end

function Behavior:Update()
    if CS.Input.WasButtonJustReleased( "Escape" ) then
        local sd = GetSelectedDot()
        if sd then
            sd.s:Select(false)
        end
    end
end


-- called when EndLevel event is Fired from [Dot/CheckVictory]
function Behavior:EndLevel()
    --self.endLevelGO.transform.localPosition = Vector3(0)
    Tween.Tweener(self.endLevelGO.transform, "localPosition", Vector3(0), 1.5, {
        easeType = "outElastic",
    } )
    
    --[[self.endLevelGO:Animate("localPosition", Vector3(0), 1, {
        easeType = "outElastic",
    } )]] 
    -- Animate doesn't work with "localPosition"
    
    local gos = self.endLevelGO:GetChild("Content").childrenByName
    
    --
    local timeGO = gos.Time.child
    local time = os.clock() - self.levelStartTime
    local minutes = math.floor( time/60 )
    if minutes < 10 then
        minutes = "0"..minutes
    end
    local seconds = math.round( time % 60 )
    if seconds < 10 then
        seconds = "0"..seconds
    end
    if time < 60 then
        timeGO.textRenderer.text = seconds.."s"
    else
        timeGO.textRenderer.text = minutes.."m "..seconds.."s"
    end
    
    gos.Link.child.textRenderer.text = #GameObject.GetWithTag( "connection" )
    gos["Broken Link"].child.textRenderer.text = Game.deletedLinkCount
    
    -- next level
    if Game.levelToLoad.name == "Random" then
        gos["Next Level Help"].textRenderer.text = ""
        gos["Next Level"].textRenderer.text = ""
        
        local playGO = gos.Play
        playGO.textRenderer.text = "0" -- refresh
        local textGO = playGO:GetChild("Text", true)
        textGO.textRenderer.text = "Generate again"

    else
        local currentLevel = GetLevel( Game.levelToLoad.name )
        currentLevel.isCompleted = true
        
        local nextLevel = nil
        for i, level in ipairs( Levels ) do
            if not level.isCompleted then
                nextLevel = level
                break
            end
        end
        if nextLevel == nil then
            nextLevel = Levels[ math.random( #Levels ) ]
        end
        Game.levelToLoad = nextLevel
        gos["Next Level"].textRenderer.text = nextLevel.name
    end
end


function Behavior:SetupTuto( level )
    local tutoUICameraGO = GameObject.New("Levels/Tuto UI")
    tutoUICameraGO.transform.position = Vector3(-500,0,0)
    
    local uiGO = tutoUICameraGO:GetChild("Tuto UI")
    local infoGO = uiGO:GetChild("Info")
    local iconGO = infoGO:GetChild("Icon")
    iconGO:AddTag("tutoui")
    iconGO:EnableTooltip()
    
    --[[local window = infoGO:GetChild("Window Origin")
    window:Hide()
    iconGO.OnClick = function(go)
        if window.isDisplayed then
            window:Hide()
        else
            window:Show()
        end
    end]]
    
    local textGO = infoGO:GetChild("Text Area", true)
    textGO:AddComponent("TextArea", {
        font = "Calibri",
        newLine = "\n",
        alignment = "left",
        lineHeight = 2.5/0.2,
        areaWidth = 57/0.2,
        wordWrap = true,
        text = level.tutoText    
    })
    
    if level.scenePath == "Levels/Tuto 1" then
        -- put the fdots in a perfect circle
        local radius = 5
        local dots = GameObject.Get("Tuto 1 Dots").children
        
        -- equation of a circle
        -- x=rcosθ, y=rsinθ
        local angle = 0
        local angleOffset = 360/#dots

        for i, go in ipairs( dots ) do
            go.transform.localPosition = Vector3(
                radius * math.cos( math.rad( angle ) ),
                radius * math.sin( math.rad( angle ) ),
                0
            )
            angle = angle + angleOffset
        end
    
    elseif level.scenePath == "Levels/Tuto 2" then
        -- put the fdots in a perfect circle
        local radius = 5
        local dots = GameObject.Get("Tuto 2 Dots").children
        table.remove( dots ) -- remove "Others" game object
        
        -- equation of a circle
        -- x=rcosθ, y=rsinθ
        local angle = 75
        local angleOffset = 360/#dots

        for i, go in ipairs( dots ) do
            go.transform.localPosition = Vector3(
                radius * math.cos( math.rad( angle ) ),
                radius * math.sin( math.rad( angle ) ),
                0
            )
            angle = angle + angleOffset
        end
    end
end

