--[[PublicProperties
text string ""
value string ""
/PublicProperties]]

GUI.Label = {}

GUI.Config.componentObjects.Label = GUI.Label

function GUI.Label.New( gameObject, params)
    local label = setmetatable( {}, GUI.Label ) 
    label._value = ""
    label._text = ""
    label._replaceValueInText = false
    label.gameObject = gameObject
    gameObject.label = label
    
    if gameObject.textRenderer == nil then
        gameObject:CreateComponent( "TextRenderer" )
    end
    
    if params then
        label:Set(params)
    end
    return label
end

function GUI.Label.Set( label, params )
    local value = params.value
    params.value = nil
    
    for k, v in pairs( params ) do
        label[ k ] = v
    end
    if value ~= nil then
        label:SetValue( value )
    end
end

function GUI.Label.SetValue( label, value )
    label._value = value
    label:UpdateText()
end

function GUI.Label.SetText( label, text )
    label._text = text
    if text:find( ":value", 1, true ) then
        label._replaceValueInText = true
    else 
        label._replaceValueInText = false
    end
    label:UpdateText()
end

function GUI.Label.UpdateText( label )
    local text = label._text..label._value
    if label._replaceValueInText == true then
        text = Daneel.Utilities.ReplaceInString( label._text, { value = label._value } )
    end
    label.gameObject.textRenderer:SetText( text )
end

function Behavior:Awake()
    local text = self.text
    if text == "" then
        text = self.gameObject.textRenderer.text
    end
    
    GUI.Label.New( self.gameObject, {
        text = text ,
        value = self.value
    } )
end
