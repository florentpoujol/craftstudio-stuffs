CS.Screen.SetSize( 1000, 600 )

function Behavior:Awake()
    Game.selectionPlane = Plane( Vector3( 0, 0, 1 ), 0 )
    
    -- generate planets
    local mapSize = 1.5 * Game.planetCount
    local topMostPlanet = { go = nil, y = -999999 }
    local bottomMostPlanet = { go = nil, y = 999999 }
    GameObject.Tags.planet = {}
    
    for iteration=0, 1000 do
        local posX = math.randomrange( -mapSize, mapSize )
        local posY = math.randomrange( -mapSize, mapSize )
        local planetPosition = Vector3( posX, posY, -10 )
        local scale = math.randomrange( 0.5, 1.5 )
        local isNewPlanetTooClose = false
        
        for i, planet in ipairs( GameObject.Tags.planet ) do
            if Vector3.Distance( planet.transform.position, planetPosition ) < (scale + planet.transform.localScale.x) * Game.planetSafeZoneModifier then
                isNewPlanetTooClose = true
                break
            end
        end
        
        if not isNewPlanetTooClose then
            local schipCount = math.randomrange( 10, 50 )
            
            local planet = GameObject.New( "Prefabs/Planet", {
                transform = {
                    position = planetPosition,
                    localScale = Vector3( scale )
                }
            } )
            planet:UpdateShipCount( schipCount )
            
            if posY > topMostPlanet.y then
                topMostPlanet.y = posY
                topMostPlanet.go = planet
            elseif posY < bottomMostPlanet.y then
                bottomMostPlanet.y = posY
                bottomMostPlanet.go = planet
            end
            
            if #GameObject.Tags.planet >= Game.planetCount then break end
        end
    end
    
    topMostPlanet.go:UpdateTeam( Game.playerTeam )
    self.playerFirstPlanetPosition = topMostPlanet.go.transform.position
    
    Game.enemyTeam = Game.playerTeam + 1
    if Game.enemyTeam > 4 then
        Game.enemyTeam = 2
    end  
    bottomMostPlanet.go:UpdateTeam( Game.enemyTeam )
    
    -- make both stating planet equal
    bottomMostPlanet.go.transform.localScale = topMostPlanet.go.transform.localScale
    bottomMostPlanet.go.shipCount = 0
    bottomMostPlanet.go:UpdateShipCount( topMostPlanet.go.shipCount )
end


function Behavior:Start()
    Game.camera.transform.position = self.playerFirstPlanetPosition + Vector3( 0, 0, 20 )
    
    --Game.selectionBox = GameObject.New( "Prefabs/SelectionBox", { hud = { layer = 1 }, modelRenderer = { opacity = 0 } } )
    Game.selectionBox = GameObject.New( "Prefabs/SelectionBox", { 
        transform = { position = Vector3( 0, 0, -5 ) }, 
        modelRenderer = { opacity = 0 }
    } )
    -- need to create the selection box here, after the planets so that they are visible through the box, 
    -- which isn't the case if it's created before the planets, event if it has an opacity inferior to 1
    self.selectionBoxStartPosition = Vector3(0)
    
    Daneel.Event.Listen( "CheckVictory", self.gameObject )
    
    Daneel.Event.Fire( "AI_Init" )
end


function Behavior:Update()

    if CS.Input.WasButtonJustPressed( "LeftMouse" ) then
        -- Unselect all planets but the one who has the mouse over
        -- Register the start position for the selection box
        
        for i, planet in ipairs( GameObject.Tags.planet ) do
            if planet.isMouseOver and planet:GetTeam() == Game.playerTeam then
                Daneel.Event.Fire( planet, "OnSelected" )
            else
                Daneel.Event.Fire( planet, "OnUnSelected" )
            end
        end
        
        self.selectionBoxStartPosition = self:GetMousePositionOnSelectionPlane()
    end
    
    
    if CS.Input.WasButtonJustReleased( "LeftMouse" ) then
        -- Get all planets inside the selection box when the left mouse button is released
        Game.selectionBox.modelRenderer.opacity = 0
        local cameraPosition = Game.camera.transform.position
        
        for i, planet in ipairs( GameObject.Tags.planet ) do
            if planet:GetTeam() == Game.playerTeam then
                local ray = Ray( cameraPosition, planet.transform.position - cameraPosition )
                
                if ray:IntersectsModelRenderer( Game.selectionBox.modelRenderer ) then
                    Daneel.Event.Fire( planet, "OnSelected" )
                end
            end
        end
    end


    if CS.Input.IsButtonDown( "LeftMouse" ) then
        -- Update the selection Box
        Game.selectionBox.modelRenderer.opacity = 0.2
        
        local startPos = self.selectionBoxStartPosition
        Game.selectionBox.transform.position = startPos
        
        local endPos = self:GetMousePositionOnSelectionPlane()
        local length = endPos- startPos
        Game.selectionBox.transform.scale = Vector3( length.x, -length.y, 1 )
    end
    
end -- end Update()


function Behavior:GetMousePositionOnSelectionPlane()
    local ray = Game.camera.camera:CreateRay( CS.Input.GetMousePosition() )
    --print( Game.selectionPlane )
    local distance = ray:IntersectsPlane( Game.selectionPlane )
    
    if distance ~= nil then
        return (ray.position + ray.direction * distance)
    end
    
    return Vector3(0)
end


-- count how many planets own each players
-- called from planet:UpdateTeam() via event "CheckVictory"
function Behavior:CheckVictory()
    local playerPlanetCount = 0
    local enemyPlanetCount = 0
    for i, planet in ipairs( GameObject.Tags.planet ) do
        local team = planet:GetTeam()
        if team == Game.playerTeam then
            playerPlanetCount = playerPlanetCount + 1
        elseif team == Game.enemyTeam then
            enemyPlanetCount = enemyPlanetCount + 1
        end
    end
    
    if enemyPlanetCount == 0 then
        self:EndGame("win")
    elseif playerPlanetCount == 0 then
        self:EndGame("lost")
    end
end


function Behavior:EndGame( status )
    local timer = Tween.Timer( 3.9, function() Scene.Load( "MainMenu" ) end )
    
    local endGameGO = GameObject.Get( "EndGame" )
    endGameGO.transform.localPosition = Vector3( 0, 0, -10 )
    
    timer.OnUpdate =  function()
        endGameGO.textArea.text = "You " .. status .. " ! <br> Return to the main menu in: " .. math.round( timer.value )
   end
end
