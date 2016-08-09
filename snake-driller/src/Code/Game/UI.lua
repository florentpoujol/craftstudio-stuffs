
UI = {}

function Behavior:Awake()
    local show = function( gameObject )
        gameObject.transform.localPosition = Vector3(0,0,0)
        gameObject.isDisplayed = true
    end
    
    local hide = function( gameObject )
        gameObject.transform.localPosition = Vector3(0,0,100)
        gameObject.isDisplayed = false
    end
    
    -- Hud
    UI.hud = GameObject.Get("Player HUD")
    
    
    -- gold
    local goldGO = GameObject.Get("Player HUD.Gold")
    goldGO.amount = 0
    goldGO.textGO = GameObject.Get("Player HUD.Gold.Text")
    
    goldGO.UpdateGoldAmount = function( amount )
        goldGO.amount = goldGO.amount + amount
        goldGO.textGO.textRenderer.text = goldGO.amount
        UI.storeGoldTextGO.textRenderer.text = goldGO.amount
        
        if goldGO.tweener ~= nil then
            goldGO.tweener:Destroy()
        end
        goldGO.tweener = Tween.Tweener( {
            target = goldGO.textGO.transform,
            property = "scale",
            startValue = Vector3(0.5),
            endValue = Vector3(0.15),
            duration = 1, -- second
        } )
    end
    UI.hud.goldGO = goldGO
    
    -- depth
    local depthGO = GameObject.Get("Depth")
    depthGO.textGO = GameObject.Get("Depth.Text")
    depthGO.depth = 0
    depthGO.UpdateDepth = function( depth )
        depthGO.depth = depth
        depthGO.textGO.textRenderer.text = depth
        if PlayerScore == nil or depth > PlayerScore then
            PlayerScore = depth
        end
    end
    UI.hud.depthGO = depthGO
    
    -- time
    local timeGO = GameObject.Get("Time")
    timeGO.textGO = GameObject.Get("Time.Text")
    timeGO.Update = function( time )
        local minutes = math.floor( time/60 )
        if minutes < 10 then
            minutes = "0"..minutes
        end
        local seconds = math.round( time % 60 )
        if seconds < 10 then
            seconds = "0"..seconds
        end
        timeGO.textGO.textRenderer.text = minutes..":"..seconds    
    end
    timeGO.tweener = Tween.Tweener( {
        startValue = TimeLimit,
        endValue = 0,
        duration = TimeLimit,
        
        OnUpdate = function( tweener ) 
            timeGO.Update( tweener.value )
        end,
        OnComplete = function(t)
            PlayerGO.s:EndGame(true)
        end,
        isPaused = true
    } )
    UI.hud.timeGO = timeGO -- used in Blocks.oil.drillEffect()
    
    
    UI.hud.Show = function(go)
        if not UI.endGame.isDisplayed then
            timeGO.tweener.isPaused = false
            show(go)
        end
    end
    UI.hud.Hide = function(go)
        hide(go)
        timeGO.tweener.isPaused = true
    end
    
    ------------------------
    -- menu
    
    UI.menu = GameObject.Get("Menu")
    UI.menu.Show = function(go)
        if not UI.endGame.isDisplayed then
            show(go)
        end
        Daneel.Event.Fire("MenuToggleDisplay")        
    end
    UI.menu.Hide = function(go)
        hide(go)
        Daneel.Event.Fire("MenuToggleDisplay")        
    end
    
    local backGO = UI.menu:GetChild("Back Main Menu")
    backGO.OnClick = function()
        Scene.Load("Main Menu")
    end
    
    local continueGO = UI.menu:GetChild("Continue")
    continueGO.OnClick = function()
        UI.hud:Show()
        UI.menu:Hide()
    end
    
    
    --------------------------
    -- store
    
    -- gold
    local goldGO = GameObject.Get("Store.Gold")
    goldGO.textGO = goldGO:GetChild("Text")
    
    Daneel.Event.Listen("MenuToggleDisplay", goldGO)
    goldGO.MenuToggleDisplay = function()
        if UI.menu.isDisplayed then
            goldGO.textGO.textRenderer.text = UI.hud.goldGO.amount
        end
    end
    UI.storeGoldTextGO = goldGO.textGO -- used in tools
    
    -- items/tools
    local itemsGO = GameObject.Get("Store.Items")
    local offset = 0
    for name, data in pairs( Tools ) do
        if type(data) == "table" then
            local itemGO = GameObject.New("Item", { 
                parent = itemsGO,
                transform = {
                    localPosition = Vector3( offset, 0, 0 )
                }
            } ) -- append "Item" scene
            offset = offset + 90
            
            local nameGO = itemGO:GetChild("Name")
            nameGO.textRenderer.text = data.name
            itemGO.s.effect = data.effectText ..";; Cost: "..data.cost
            local effectGO = itemGO:GetChild("Effect")
            
            nameGO.OnClick = function()
                if UI.hud.goldGO.amount >= data.cost then
                    data.OnPurchase()
                    
                    if data.purchaseCount == nil then
                        nameGO:RemoveTag("clickable")
                        nameGO.textRenderer.opacity = 0.7
                        effectGO.textArea.text = "Purchased !"
                    else
                        data.purchaseCount = data.purchaseCount + 1
                        effectGO.textArea.text = data.effectText ..";; Cost: "..data.cost..";Purchased: "..data.purchaseCount
                    end
                end
            end
        end
    end
    
    
    -----------------------------
    -- end game screen 
    UI.endGame = GameObject.Get("End Game")
    UI.endGame.Show = show
    UI.endGame.Hide = hide   
    
    local retryGO = GameObject.Get("Retry")
    retryGO.OnClick = function()
        Scene.Load("Level")
    end
    
    local backGO = UI.endGame:GetChild("Back Main Menu")
    backGO.OnClick = function()
        Scene.Load("Main Menu")
    end
    
    UI.endGame.scoreGO = GameObject.Get("End Game.Score.Value")
    UI.endGame.bestScoreGO = GameObject.Get("End Game.Best Score.Value")
    
    
    UI.menu:Hide()
    UI.endGame:Hide()
    UI.hud:Show()
end

function Behavior:Start()
    local endTextGO = UI.endGame:GetChild("End Text")
    endTextGO.textArea.text = ""
    UI.endGame.endTextGO = endTextGO -- used by Player:EndGame()

    SetupClickables()
end


function Behavior:Update()
    if CS.Input.WasButtonJustPressed("Escape") then
        if UI.endGame.isDisplayed then
            return
        end
        
        if UI.hud.isDisplayed then
            UI.hud:Hide()
            UI.menu:Show()
        else
            UI.hud:Show()
            UI.menu:Hide()
        end
    end
end

