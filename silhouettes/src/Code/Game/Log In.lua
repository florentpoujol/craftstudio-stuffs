
function Behavior:Start()   
    local logInGroupGO = GameObject.Get("Log In Group")
    self.playerNameGO = logInGroupGO:GetChild("Player Name")
        
    --
    local go = logInGroupGO:GetChild("Secret Key Input")
    
    if CS.IsWebPlayer then
        go:Destroy()
        self.playerNameGO.textRenderer.text = "Click the 'Log In with twitter' button on the web page to log in and reload the game."
        
        -- called from index.php, after the player and the game have loaded
        JS.lua_SetPlayerData = function( id, name, screen_name, secret_key )
            if Player.id ~= "" then
                Player.id = id
                Player.name = name
                Player.screen_name = screen_name
                Player.secret_key = secret_key
                
                self.playerNameGO.textRenderer.text = "Logged in as @"..screen_name
            end
        end
        
        if JS.js_OnGameStarts ~= nil then
            JS.js_OnGameStarts() -- notify JS that the game as loaded and is ready to receive player data via JS.luaSetPlayerData
            JS.js_OnGameStarts = nil
        end
        
    else
    
        -- when inside CS's editor
        -- "log in" by entering its secret_key
        
        -- "go" variable is the "Secret Key Input" game object with input component
        
        go.input.OnFocus = function( input )           
            if input.isFocused then
                input.backgroundGO.modelRenderer.opacity = 1
            else
                input.backgroundGO.modelRenderer.opacity = 0.5        
            end
        end
    
        go.input.OnValidate = function( input )
            -- "wait" animation while player data is queried
            self.playerNameGO.tweener = self.playerNameGO:Animate( "text", "...", 2, {
                startValue = "",
                loops = -1,
            } ) 
            
            local inputSecretKey = input.gameObject.textRenderer.text
            
            Player.GetPlayerDataFromSecretKey( inputSecretKey, function( e, player )
                if self.playerNameGO.tweener then
                    -- ends the "wait" animation
                    self.playerNameGO.tweener:Destroy()
                end
                
                if e then               
                    self.playerNameGO.textRenderer.text = "Error: Unknow secret key or repo unreachable."
                    print("Player.GetPlayerDataFromSecretKey() callback: Error with secret key '"..inputSecretKey.."': ", e.message)
                    return
                end

                if player then
                    
                    if player.error then
                        self.playerNameGO.textRenderer.text = "Error: "..player.error
                        print("Player.GetPlayerDataFromSecretKey() callback: Error with secret key '"..inputSecretKey.."': ", player.error)
                        return
                    end
                    
                    Player.id = tostring(player.id) -- Twitter id
                    Player.name = player.name
                    Player.screen_name = player.screen_name
                    Player.secret_key = player.secret_key
                    
                    CS.Storage.Save( "twitter_secret_key", { secret_key = player.secret_key }, function(e)
                        if e then
                            print("Player.GetPlayerDataFromSecretKey() callback: Error saving secret key in storage: ", e.message) 
                        end
                    end )
                    
                    self.playerNameGO.textRenderer.text = "Logged in as @"..player.screen_name
                    go:Destroy()
                else
                    print("Player.GetPlayerDataFromSecretKey() callback: No error but also no data")
                end
            end )
        end
        
        -- Load the secret key from storage, and the player name from the level repo
        CS.Storage.Load( "twitter_secret_key", function( e, data )
            if e then
                print("Error getting twitter secret key from storage: ", e.message)
                return
            end

            if data then
                if data.secret_key ~= nil and data.secret_key ~= "" then
                    go.textRenderer.text = data.secret_key
                    go.input:OnValidate() -- Load the player name
                end
            end
        end )
    end -- end if CS.IsWebPlayer    
end


--[[
function Behavior:Start()   
    local go = GameObject.Get("Player Name")
    local popGO = GameObject.Get("Pop Up")
    
    self.playerNameGO = go
    go:AddTag( "uibutton" )
    go.OnClick = function()
        popGO:SwitchDisplayedState()
    end
    
    popGO.isDisplayed = true
    local startPos = popGO.transform.localPosition
    popGO.SwitchDisplayedState = function( go )
        if go.isDisplayed then
            go.transform.localPosition = Vector3(0,500,0)
        else
            go.transform.localPosition = startPos
        end
        go.isDisplayed = not go.isDisplayed
    end
    popGO:SwitchDisplayedState()
    
    --
    local editorGO = GameObject.Get("Editor Button")
    local allowEditorAccess = function()
        editorGO:AddTag("uibutton")
        editorGO.OnClick = function()
            Scene.Load("Editor")
        end
        editorGO.textRenderer.text = "Level Editor"
    end
    
    --
    local go = GameObject.Get("Secret Key Input")
    
    if CS.IsWebPlayer then
        go:Destroy()
        
        -- called from index.php, after the player and the game have loaded
        JS.lua_SetPlayerData = function( id, name, screen_name, secret_key )
            if Player.id ~= "" then
                Player.id = id
                Player.name = name
                Player.screen_name = screen_name
                Player.secret_key = secret_key
                
                self.playerNameGO.textRenderer.text = "Logged in as "..name
                
                allowEditorAccess()
            end
        end
        
        
        if JS.js_OnGameStarts ~= nil then
            JS.js_OnGameStarts() -- notify JS that the game loaded and is ready to receive player data via JS.luaSetPlayerData
            JS.js_OnGameStarts = nil
        end
    else
        -- when inside CS's editor
        -- "log in" by entering its secret_key
        
        go.input.OnFocus = function( input )           
            if input.isFocused then
                input.backgroundGO.modelRenderer.opacity = 1
            else
                input.backgroundGO.modelRenderer.opacity = 0.5        
            end
        end
    
        go.input.OnValidate = function( input )
            -- "wait" animation while player data is queried
            self.playerNameGO.tweener = self.playerNameGO:Animate( "text", "...", 2, {
                startValue = "",
                loops = -1,
            } ) 
            
            local inputSecretKey = input.gameObject.textRenderer.text
            
            Player.GetPlayerDataFromSecretKey( inputSecretKey, function( e, player )
                if self.playerNameGO.tweener then
                    -- ends the "wait" animation
                    self.playerNameGO.tweener:Destroy()
                end
                
                if e then               
                    self.playerNameGO.textRenderer.text = "Unknow secret key or repo unreachable."
                    print("Player.GetPlayerDataFromSecretKey() callback: Error with secret key '"..inputSecretKey.."': ", e.message)
                    return
                end

                if player then
                    
                    if player.error then
                        self.playerNameGO.textRenderer.text = "Error: "..player.error
                        print("Player.GetPlayerDataFromSecretKey() callback: Error with secret key '"..inputSecretKey.."': ", player.error)
                        return
                    end
                    Player.id = tostring(player.id) -- Twitter id
                    Player.name = player.name
                    Player.screen_name = player.screen_name
                    Player.secret_key = player.secret_key
                    
                    CS.Storage.Save( "twitter_secret_key", { secret_key = player.secret_key }, function(e)
                        if e then
                            print("Player.GetPlayerDataFromSecretKey() callback: Error saving secret key in storage: ", e.message) 
                        end
                    end )
                    
                    self.playerNameGO.textRenderer.text = "Logged in as "..player.name
                    
                    allowEditorAccess()
                else
                    print("Player.GetPlayerDataFromSecretKey() callback: No error but also no data")
                end
            end )
        end
        
        -- Load the secret key from storage, and the player name from the level repo
        CS.Storage.Load( "twitter_secret_key", function( e, data )
            if e then
                print("Error getting twitter secret key from storage: ", e.message)
                return
            end

            if data then
                if data.secret_key ~= nil and data.secret_key ~= "" then
                    go.textRenderer.text = data.secret_key
                    go.input:OnValidate() -- Load the player name
                end
            end
        end )
    end -- end if CS.IsWebPlayer    
end
]]
