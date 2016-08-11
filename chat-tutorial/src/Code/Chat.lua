
Chat = nil

function Behavior:Awake()
    Chat = self
    self.gameObject.networkSync:Setup( 0 )
end


function Behavior:Start()
    -- This code is in Start() to wait for the input component to be created
    
    -- The input component is on the Input game object which is in our case a child of "Chat"
    self.input = self.gameObject:GetChild("Input").input
    
    -- When the player press the "ValidateInput" button (Enter key) to send the text he wrote, 
    -- the OnValidate event is fired at the input
    self.input.OnValidate = function( input )      
        -- Take the input's text and make sure it is not empty
            -- string.trim() remove the trailing whitespace.
        local text = input.gameObject.textRenderer.text:trim()
        if text ~= "" then
            self:SendTextToServer( text )
        end
        
        -- empty the input's text
        input.gameObject.textRenderer.text = ""
    end
    
    -- The OnFocus event is fired at the input when it gain or loose focus
    -- Change the background opacity to give a visual feedback on the input's focused state.
    self.input.OnFocus = function( input )      
        if input.isFocused then
            -- input.backgroundGO is the game object named "Background" as the child of the input's game object
            input.backgroundGO.modelRenderer.opacity = 0.3
        else
            input.backgroundGO.modelRenderer.opacity = 1        
        end
    end
end


-- Send a new piece of text over the network
function Behavior:SendTextToServer( text )
    if IsConnected then
        self.gameObject.networkSync:SendMessageToServer( "BroadcastText", { text = text } )
    else -- client offline
        self.gameObject.textRenderer.text = text
    end
end


-- Called by a client to broadcast the text to all clients
-- "data.text" is the text
function Behavior:BroadcastText( data, playerId )
    -- send the playerId along the text so that ReceiveText() can display it with the message
    data.senderId = playerId
    self.gameObject.networkSync:SendMessageToPlayers( "ReceiveText", data, PlayerIds )
end
CS.Network.RegisterMessageHandler( Behavior.BroadcastText, CS.Network.MessageSide.Server )


-- Called by the server on all clients
-- Updates the chat's text renderer with the new text
function Behavior:ReceiveText( data )  
    local playerName = ""
    if data.senderId ~= nil then
        playerName = "[Player "..data.senderId.."] "
    end
    
    self.gameObject.textRenderer.text = playerName..data.text
end
CS.Network.RegisterMessageHandler( Behavior.ReceiveText, CS.Network.MessageSide.Players )
