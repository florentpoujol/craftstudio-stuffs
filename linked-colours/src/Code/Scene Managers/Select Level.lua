
function Behavior:Awake()
    GameObject.New("Background")
    
    self.gridGO = GameObject.Get("Levels Grid Origin")
    self.originalGridPos = self.gridGO.transform.localPosition
    
    local UICamera = GameObject.Get("UI Camera")
    
    ----------
    -- splash screen
    local splashGO = GameObject.New("Splash Screen")
    local gameTitle = splashGO:GetChild("Game Title")
    gameTitle.parent = UICamera.child
    local localPos = gameTitle.transform.localPosition
    localPos.z = -5
    gameTitle.transform.localPosition = localPos
    
    if not Game.splashScreenWasDisplayed then
        Game.splashScreenWasDisplayed = true
        self.gridGO.transform.localPosition = Vector3(0,200,0)
        
        --local splashGO = GameObject.New("Splash Screen")
        self.splashGO = splashGO
        splashGO.parent = "UI"
        splashGO.transform.localPosition = Vector3(0,0,2)
        
        local CSLogo = splashGO:GetChild("CS Logo")
        CSLogo:AddTag("ui")
        CSLogo.OnClick = function()
            CS.Web.Open("http://craftstud.io")
        end
        
        local logo = splashGO:GetChild("Florent Logo")
        logo:AddTag("ui")
        logo.OnClick = function()
            CS.Web.Open("http://florentpoujol.fr")
        end
        
        local logo = splashGO:GetChild("Start")
        --logo:AddTag("ui")
        logo.OnClick = function()
            
        end
        
        logo:Animate("localScale", Vector3(0.35), 1, {
            loops = -1,
            loopType = "yoyo"
        } )
    else
        splashGO.transform.localScale = 0
    end
    
    ----------
    -- creadit
    
     local creditsGO = GameObject.Get("Credits")
     local windowGO = creditsGO:GetChild("Window")
     windowGO:Hide()
     
     creditsGO.OnClick = function()
        if windowGO.isDisplayed then
            windowGO:Hide()
        else
            windowGO:Show()
        end
     end
    
    ----------
    -- grid 
    
    -- NOTE: most of the code to build the grid is obscolete now because there only three level
    -- the code enabled to build a grid of many levels
    
    self.gridLayout = { x = 1, y = 7 }
    self.gridElemCount = self.gridLayout.x * self.gridLayout.y
    
    local screenSize = CS.Screen.GetSize()
    local pixelsToUnits = UICamera.camera.pixelsToUnits 
    self.cartridgeWidth = ( (screenSize.x - 30) / self.gridLayout.x) * pixelsToUnits - 1   -- width of a cartridge in pixels
    self.cartridgeHeight = ( (screenSize.y - 70) / self.gridLayout.y) * pixelsToUnits
    
    self.firstLevelIndex = 1
    self.lastFirstLevelIndex = -999

    ----------
    self.allowBuildLevelGrid = true
    self.sortedLevels = Levels

    self:BuildLevelGrid()
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
    
    ----------
    -- build the level grid
    local x = 0
    local y = 0
    
    for index, level in ipairs( self.sortedLevels ) do
        if index >= self.firstLevelIndex then
        
            local cartridgeGO = GameObject.New("Entities/Level Cartridge") --append scene
            cartridgeGO.parent = self.gridGO
            cartridgeGO.transform.localPosition = Vector3( self.cartridgeWidth * x, -self.cartridgeHeight * y, 0 )
            
            cartridgeGO.s:SetData( level )
            
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


function Behavior:HideSplashScreen()
    self.gridGO.transform.localPosition = self.originalGridPos
    self.splashGO:Destroy()
    self.splashGO = nil
end


function Behavior:Update()
    if CS.Input.WasButtonJustReleased("LeftMouse") and self.splashGO ~= nil then
        self:HideSplashScreen()
    end
end
