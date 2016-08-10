function Behavior:Awake()
    GameObject.New("Background")
    
    local cameraGO = GameObject.Get("Camera")
    
    ----------
    -- Splash screen
    
    self.splashGO = cameraGO:GetChild("Splash")
    self.splashGO.transform.localPosition = Vector3(0,0,-2.5)
    
    local CSLogo = self.splashGO:GetChild("CS Logo")
    CSLogo:AddTag("uibutton")
    CSLogo:AddTag("splash_logo")    
    CSLogo.OnClick = function()
        CS.Web.Open("http://craftstud.io")
    end
    
    local logo = self.splashGO:GetChild("Florent Logo")
    logo:AddTag("uibutton")
    logo:AddTag("splash_logo")
    logo.OnClick = function()
        CS.Web.Open("http://florentpoujol.fr")
    end
    
    SetClickables( "splash_logo" ) -- make the object scale up/down on mouse enter/exit
    
    self.spinGO = self.splashGO:GetChild("Spin") -- is rotated in Update()
    
    self.maskGO = self.splashGO:GetChild("Mask")
    self.maskGO.modelRenderer.opacity = 1
    
    ----------
    -- Icons
    
    local iconsGO = cameraGO:GetChild("Icons")
    
    self.creditsGO = iconsGO:GetChild("Credits")
    self.creditsGO.OnClick = function(go)
        print("credits")
    end
    
    self.paramGO = iconsGO:GetChild("Parameters")
    self.paramGO:AddTag( "uibutton" )
    self.paramGO.OnClick = function(go)
        print("paramGO")
    end
    
    self.selectGO = iconsGO:GetChild("Select level")
    self.selectGO.OnClick = function(go)
        Scene.Load("Select Level")
    end
    
    self.editorGO = iconsGO:GetChild("Level editor")
    self.editorGO.OnClick = function(go)
        Scene.Load("Editor")
    end
       
    local iconGOs = { self.creditsGO, self.paramGO, self.selectGO, self.editorGO }
    for i, go in pairs( iconGOs ) do
        go:AddTag( "uibutton" )
        
        go.tooltipArrowGO = go:GetChild("Tooltip Arrow")
        go.tooltipArrowGO:Hide()
        
        go.OnMouseEnter = function( go )
            self.tooltipGO:Show( go )
        end
        go.OnMouseExit = function( go )
            self.tooltipGO:Hide( go )
        end        
    end
    
    self.tooltipGO = iconsGO:GetChild("Tooltip")
    self.tooltipGO.Show = function(tooltipGO, iconGO)
        if tooltipGO.anim ~= nil then
            tooltipGO.anim:Destroy()
        end
        tooltipGO.anim = tooltipGO:Animate("localScale", Vector3(0.2), 0.1,function()
            iconGO.tooltipArrowGO:Show()
        end)
        
        tooltipGO.textRenderer.text = iconGO.name
    end
    self.tooltipGO.Hide = function(tooltipGO, iconGO)
        iconGO.tooltipArrowGO:Hide()
        
        if tooltipGO.anim ~= nil then
            tooltipGO.anim:Destroy()
        end
        tooltipGO.anim = tooltipGO:Animate("localScale", Vector3(0), 0.1)
    end
    self.tooltipGO.transform.localScale = Vector3(0)
    
    ----
    -- editor log in tooltip
    
    local editorLogInTipGO = self.editorGO:GetChild("Log In Tooltip")
    local textGO = editorLogInTipGO:GetChild("Text", true)
    
    editorLogInTipGO.Show = function(go)
        if go.anim ~= nil then
            go.anim:Destroy()
        end
        go.anim = go:Animate("localScale", Vector3(1), 0.1)
        
        if Player.id == "" then
            textGO.textRenderer.text = "You must log in in the parameters window in order to save levels !"
        else
            textGO.textRenderer.text = "You will save levels as @"..Player.screen_name
        end
    end
    editorLogInTipGO.Hide = function(go)
        if go.anim ~= nil then
            go.anim:Destroy()
        end
        go.anim = go:Animate("localScale", Vector3(0), 0.1)
    end
    editorLogInTipGO:Hide()

    self.editorGO.OnMouseEnter = function(go)
        self.tooltipGO:Show( go )
        editorLogInTipGO:Show()
    end
    self.editorGO.OnMouseExit = function(go)
        self.tooltipGO:Hide( go )
        editorLogInTipGO:Hide()
    end

        
    ----------
    -- icon window
    local iconWindowGOs = {}
    
    for i, go in pairs( { self.creditsGO, self.paramGO } ) do
        local windowOriginGO = go:GetChild("Window Origin")
        table.insert( iconWindowGOs, windowOriginGO )
        windowOriginGO.transform.localPosition = Vector3(0)
        
        windowOriginGO.Show = function(go)
            for i, go in pairs( iconWindowGOs ) do
                if go.isDisplayed then
                    go:Hide()
                end
            end
            
            if go.anim ~= nil then
                go.anim:Destroy()
            end
            go.anim = go:Animate("localScale", Vector3(1), 0.2)
            
            --go.transform.localPosition = Vector3(0)
            go.isDisplayed = true
        end
        
        windowOriginGO.Hide = function(go)
            if go.anim ~= nil then
                go.anim:Destroy()
            end
            go.anim = go:Animate("localScale", Vector3(0), 0.2)
            
            --go.transform.localPosition = Vector3(0,0,100)
            go.isDisplayed = false
        end
        
        go.OnClick = function(go)
            if windowOriginGO.isDisplayed then
                windowOriginGO:Hide()
            else
                windowOriginGO:Show()
            end
        end
        windowOriginGO:Hide()
    end
    
    local textGO = self.creditsGO:GetChild("Text", true)
    textGO:AddComponent("TextArea", {
        newLine = "\n",
        font = "Calibri White",
        alignment = "left",
        text = "test  text",
        lineHeight = 11,
        areaWidth = 250,
        wordWrap = true,
    } )

textGO.textArea.text = 
[[Silhouettes, by Florent Poujol
is an extended version for the web of 
Umbragram, by Stephen Altamirano (evilrobotstuff).

Made with CraftStudio, by Sparklin Labs.
Icons by Font Awesome.]]
    
    
    
    ----------
    -- console
    
    self.consoleGO = cameraGO:GetChild("Console")
    self.consoleGO.backgroundGO = self.consoleGO.child
    self.consoleGO.SetText = function( go, text )
        text = text or ""
        go.textRenderer.text = text
        if text == "" then
            go.backgroundGO:Hide()
        else
            go.backgroundGO:Show( 0.8 )
        end    
    end
    self.consoleGO:SetText( "" )
    
    self.frameCount = 0
        
    --
    self.frontGO = GameObject.Get("Front")
    self.frontGO.mapRenderer:LoadNewMap( function( map )
        self.frontMap = map
        self:Init()        
    end )
        
    self.backGO = GameObject.Get("Back")
    self.backGO.mapRenderer:LoadNewMap(function( map )
        self.backMap = map
        self:Init()
    end)
    
    --

end


-- Build front and back map text over time
function Behavior:Init()
    if self.frontMap == nil or self.backMap == nil then
        return
    end

     self.textBlockLocations = {} -- array of Vector3
    
    for x = -1, 40 do
        for y = -1, 5 do
            local backBlockID = self.backMap:GetBlockIDAt( x, y, 0 )
            if backBlockID ~= Map.EmptyBlockID then
                table.insert( self.textBlockLocations, Vector3( x,y, 0) )
            end

            self.frontMap:SetBlockAt( x, y, 0, Map.EmptyBlockID )            
            self.backMap:SetBlockAt( x, y, 0, BlockIdsByColor.silhouetteBase )
        end
        
        -- add a ground to the front map
        for z = -1, 1 do
            self.frontMap:SetBlockAt( x, -1, z, BlockIdsByColor.silhouetteBase )
        end
    end
    
    
    --
    self:TestInternet( function()
        self.testInternetOK = true
        self:HideSplashScreenAndContinue()
    end )
    
    Tween.Timer(3, function()
        self.splashTimerCompleted = true
        self:HideSplashScreenAndContinue()
    end )
end


function Behavior:TestInternet( callback )
    local url = "http://craftstud.io/ip"
    
    CS.Web.Get( url, nil, CS.Web.ResponseType.Text, function( e, data )
        if e then
            self.consoleGO:SetText( "Can't access Internet." )
            if callback then
                callback()
            end
            
        elseif data then
            Game.canAccessInternet = true
            
            LoadLevelsFromRepo( function( e, data )
                if e then
                    self.consoleGO:SetText( "Can't access level repository: "..e.message )
                end
                
                if callback then
                    callback()
                end
            end )
        end
    end )
end


function Behavior:HideSplashScreenAndContinue()
    if not self.splashTimerCompleted or not self.testInternetOK then
        return
    end

    self.spinGO = nil        
    self.splashGO:Destroy()

    self.buildTitle = true -- done in Update()
    self.maskGO:Animate("opacity", 0, 1)
end


function Behavior:Update()
    if self.spinGO ~= nil then
        self.spinGO.transform:RotateLocalEulerAngles( Vector3(0,0,-2) )
    end

    if self.buildTitle then
        self.frameCount = self.frameCount + 1
        
        if self.frameCount % 2 == 0 then -- one block every 2 frames  (101 blocks for 1.6 sec)
            local location = table.remove( self.textBlockLocations, 1 )
            if location ~= nil then
                self.frontMap:SetBlockAt( location, BlockIdsByColor.structure )
                self.backMap:SetBlockAt( location, BlockIdsByColor.black50 )
            else
                self.buildTitle = false
            end
        end
    end
end
