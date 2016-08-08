
function Behavior:Awake()
    IsHost = false
    IsMultiPlayer = false
    IpToConnectTo = nil
    
    local hostGO = GameObject.Get( "Host Button" )
    hostGO:AddTag( "button" )
    hostGO.OnClick = function() 
        IsHost = true
        IpToConnectTo = "127.0.0.1"
        Scene.Load( "Game Room" )
    end
        
    self.inputGO = GameObject.Get( "Join Input" )
    local bg = self.inputGO.child
    local initialText = self.inputGO.textRenderer.text
    
    self.inputGO.input.OnFocus = function( input ) 
        if input.isFocused then
            bg.modelRenderer.opacity = 0.8
            if input.gameObject.textRenderer.text == initialText then
                input.gameObject.textRenderer.text = ""
            end
        else
            bg.modelRenderer.opacity = 0.5
            if input.gameObject.textRenderer.text == "" then
                input.gameObject.textRenderer.text = initialText
            end
        end
    end
    
    
    self.joinGO = GameObject.Get( "Join Button" )
    self.joinGO:AddTag( "button" )
    self.joinGO.OnClick = function() 
        IpToConnectTo = self.inputGO.textRenderer.text
        Scene.Load( "Game Room" )
    end
    
    
    local LoadLevel = GameObject.Get( "Load Level" )
    LoadLevel:AddTag( "button" )
    LoadLevel.OnClick = function()
        Scene.Load( "Level" )
    end
end

function Behavior:Update()
    if CS.Input.WasButtonJustReleased( "Enter" ) and self.inputGO.input.isFocused then
        self.joinGO.OnClick()
    end
end
