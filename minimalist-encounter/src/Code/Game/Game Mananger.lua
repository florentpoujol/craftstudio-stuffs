
CraftStudio.Screen.SetSize(800, 600)


---------------------------------------------------------------
-- Menu

local function ToggleMenu(show)
    if show == nil then
        Game.showMenu = not Game.showMenu
    else
        Game.showMenu = show
    end
    
    if Game.showMenu then
        Daneel.Time.timeScale = 0
        Game.menuGO.hud.layer = 5
        Game.hudGO.hud.layer = -5
    else
        Daneel.Time.timeScale = 1
        Game.menuGO.hud.layer = -5
        Game.hudGO.hud.layer = 5
    end
    
    Daneel.Event.Fire("ToggleMenu") -- just there to be catched by BuildingCreation and hide the placeholder when the menu is displayed
end


local function CreateMenu()
    Game.menuGO = GameObject.Get("Menu")
    local menuGO = Game.menuGO
    local menuTextScale = Vector3(0.2)
    
    -- Play button
    local menuPlay = GameObject("MenuPlay", {
        parent = menuGO,
        textRenderer = {
            text = Lang.Get("menu.play"),
            alignment = "right"
        },
        hud = { position = Vector2(780, 420) },
        transform = { scale = Vector3(0.3) },
        tags = { "mouseInteractive" },
        
        -- Events
        OnClick = function() ToggleMenu(false) end,
        
        OnMouseEnter = function(gameObject)
            Tween.Tweener(gameObject.hud, "position", Vector2(-20,0), 0.2, { 
                isRelative = true,
                durationType = "realTime",
            })
        end,
    })
    Lang.RegisterForUpdate(menuPlay, "menu.play")
    
    local endPosition = menuPlay.hud.position
    menuPlay.OnMouseExit = function(gameObject) 
        Tween.Tweener(gameObject.hud, "position", endPosition, 0.2, { 
            durationType = "realTime", 
            startValue = gameObject.hud.position
        })
    end
    
    -- Exit button
    local menuExit = GameObject("MenuExit", {
        parent = menuGO,
        textRenderer = {
            text = Lang.Get("menu.exit"),
            alignment = "right"
        },
        hud = { position = Vector2(780, 470) },
        transform = { scale = menuTextScale },
        tags = { "mouseInteractive" },
        
        -- events
        OnClick = function() CS.Exit() end,
        
        OnMouseEnter = function(gameObject)
            Tween.Tweener(gameObject.hud, "position", Vector2(-20,0), 0.2, { 
                isRelative = true,
                durationType = "realTime",
            })
        end
    })
    Lang.RegisterForUpdate(menuExit, "menu.exit")
    
    local endPosition = menuExit.hud.position
    menuExit.OnMouseExit = function(gameObject) 
        Tween.Tweener(gameObject.hud, "position", endPosition, 0.2, { 
            durationType = "realTime", 
            startPosition = gameObject.hud.position,
        })
    end
    
    
    -- Tutorial
    -- Done in Start below    
    
    -- language
    local chooseLang = GameObject.Get("ChooseLanguage")
    chooseLang.textRenderer.text = Lang.Get("chooselang")
    Lang.RegisterForUpdate(chooseLang, "chooselang")
    
    -- english
    local english = GameObject.Get("English")
    english.textRenderer.text = Lang.Get("languages.english")
    Lang.RegisterForUpdate(english, "languages.english")
    -- set the background (a progressBar)
    english.backBar = english.child.progressBar   
    english.backBar.height = "150px"
    english.backBar.gameObject.modelRenderer.opacity = 0
    english.oldOpacity = 0
    -- update the background length when a new text is set (when the language changes)
    Daneel.Event.Listen("OnLangUpdate", function()
        english.backBar.maxLength = english.textRenderer.textWidth + 1
        english.backBar.progress = "100%"
    end)
   
    -- french
    local french = GameObject.Get("French")
    french.textRenderer.text = Lang.Get("languages.french")
    Lang.RegisterForUpdate(french, "languages.french")
    -- set the background (a progressBar)
    french.backBar = french.child.progressBar   
    french.backBar.height = "150px"
    french.backBar.gameObject.modelRenderer.opacity = 0
    french.oldOpacity = 0
    -- update the background length when a new text is set (when the language changes)
    Daneel.Event.Listen("OnLangUpdate", function()
        french.backBar.maxLength = french.textRenderer.textWidth + 1
        french.backBar.progress = "100%"
    end)
    
    -- events
    local enter = function(gameObject) 
        gameObject.backBar.gameObject.modelRenderer.opacity = 1
    end
    english.OnMouseEnter = enter
    french.OnMouseEnter = enter
    
    local exit = function(gameObject)
        gameObject.backBar.gameObject.modelRenderer.opacity = gameObject.oldOpacity
    end
    english.OnMouseExit = exit
    french.OnMouseExit = exit
    
    -- update, when one of the button is checked
    local update = function( toggle )
        local go = toggle.gameObject
        if toggle.isChecked then
            go.backBar.gameObject.modelRenderer.opacity = 1
            go.oldOpacity = 1
            Lang.Update(go.name)
        else
            go.backBar.gameObject.modelRenderer.opacity = 0
            go.oldOpacity = 0
        end
    end
    english.toggle.OnUpdate = update
    french.toggle.OnUpdate = update

    -- init
    if Lang.Config.current == "english" then
        english.toggle:Check(true)
    else
        french.toggle:Check(true)
    end
end


-----------------------------------------------------
-- HUD

local function CreateHUD()
    Game.hudGO = GameObject.Get("HUD")
    Game.hudBackground = Game.hudGO.child
    
    local buildings = {
        "Harvester",
        "PowerStation",
        "Node",
        "Tower",
        "Enemy",
    }
    
    for i, buildingType in ipairs(buildings) do
        local buildingGO = GameObject.Get("HUD" .. buildingType)
        
        local textGO = buildingGO:GetChild("Text")
        local langKey = "hud."..buildingType:lower()
        textGO.textRenderer.text = Lang.Get(langKey)
        Lang.RegisterForUpdate(textGO, langKey)
        
        local modelGO = buildingGO:GetChild("Model")
        local tweener = Tween.Tweener(modelGO.transform, "localEulerAngles", Vector3(0, 360, 0), 3, {
            isRelative = true,
            loops = -1,
            isPaused = true,
        })
        modelGO.OnMouseEnter = function() tweener:Play() end
        modelGO.OnMouseExit = function() tweener:Pause() end
        if buildingType ~= "Enemy" then
            modelGO.OnClick = function() Daneel.Event.Fire("OnPlayerSelectedHudBuilding", buildingType:lower()) end
        else
            modelGO.OnClick = function()
                local spawns = Game.enemySpawns
                local rand = math.round(math.randomrange(1, #spawns))
                
                GameObject.New("Prefabs/Enemy", {
                    transform = { position = spawns[rand].transform.position },
                })
            end
        end
    end
end


-----------------------------------------------------
-- Awake

function Behavior:Awake()
    Game.mapPlane = Plane(Vector3:Up(), -1.5)
    
    Game.cameraGO = GameObject.Get("Camera")
    Game.enemySpawns = GameObject.Get("EnemySpawns").children
    
    -- game score
    local function UpdateGameScore(amount)
        if amount == nil then amount = 0 end -- happens when the language is updated
        Game.score = Game.score + amount
        Game.scoreGO.textRenderer.text = Lang.Get("hud.score", { score = math.round(Game.score) })
    end
    Daneel.Event.Listen("OnLangUpdate", UpdateGameScore)
    Daneel.Event.Listen("UpdateGameScore", UpdateGameScore)
    Game.scoreGO = GameObject.Get("Score")
    UpdateGameScore(0)
    
    -- rock reserve
    local function UpdateRockScore(amount)
        if amount == nil then amount = 0 end
        Game.rockReserve = Game.rockReserve + amount
        Game.rockGO.textRenderer.text = Lang.Get("hud.rocks", { rocks = math.round(Game.rockReserve) })
        if amount > 0 then
            UpdateGameScore(amount * Game.rock.scoreModifier)
        end
    end
    Daneel.Event.Listen("OnLangUpdate", UpdateRockScore)
    Daneel.Event.Listen("UpdateRockScore", UpdateRockScore)
    Game.rockGO = GameObject.Get("Rocks")
    UpdateRockScore(0)
    
    -- menu - hud
    CreateMenu()
    CreateHUD()
    
    Daneel.Event.Listen("OnEscapeButtonJustPressed", ToggleMenu)
    ToggleMenu(true)
    
    
    -- OnGameOver  happens when all buildings are destroyed, fired from Game/Energy script
    Daneel.Event.Listen("OnGameOver", function()
        Game.score = 0
        Game.rockReserve = 0
        Scene.Load("Main")
    end)
end


function Behavior:Start()
    -- need to be done here since TextArea component are added in Start() and not in Awake()
    local tutoGO = GameObject.Get( "Menu.Tuto" )
    
    local function BuildText()
        local text = ""
        local langItems = { "produce", "harvest", "build", "unleash", "survive", "_repeat", "move", "toggleMenu" }
        
        for i, item in ipairs( langItems ) do
            if item == "move" then
                text = text .. "<br>"
            end
            text = text .. Lang.Get( "tuto." .. item ) .. "<br>"
        end
        --print("buil text", text)
        tutoGO.textArea.text = text
    end
    
    BuildText()
    Daneel.Event.Listen( "OnLangUpdate", BuildText )
end
