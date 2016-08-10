


-- use a Start() to "wait" for the GUI components to be added 
-- since this script is runs at the very begigging of the scene, before other scripted behaviors (but after DaneelBehavior)
function Behavior:Start()
    -- player colors = team
    local colors = GameObject.Get("Colors").children
    
    for i, colorGO in ipairs( colors ) do
        
        colorGO.toggle.OnUpdate = function( toggle )
            
            --print("toggle", toggle, toggle.group)
            if toggle.isChecked == true then
                toggle.gameObject.transform.localScale = 1.5
                local modelPath = toggle.gameObject.modelRenderer.model.path
                
                Game.playerTeam = tonumber( modelPath:sub( #modelPath ) )
            else
                toggle.gameObject.transform.localScale = 1
            end
        end
        
        if i == (Game.playerTeam - 1) then
            colorGO.toggle:Check( true )
        end
    end
    

    -- level's number of planet
    local planetCountGO = GameObject.Get("PlanetSelection.Input")
    
    planetCountGO.textRenderer.text = Game.planetCount
    
    planetCountGO.input.OnFocus = function( input )
        if input.isFocused then
            input.gameObject.child.modelRenderer.opacity = 0.5
            
        elseif not input.isFocused then
            input.gameObject.child.modelRenderer.opacity = 0.2
            if input.gameObject.textRenderer.text:trim() == "" then
            input.gameObject.textRenderer.text = "10"
            end
        end
    end
     
    -- game difficulty
    local go = GameObject.Get( "AIDifficulty" )
    local sliderGO = go:GetChild( "Handle", true )
    
    sliderGO.slider.OnUpdate = function( slider )
        Game.difficulty = math.floor( slider.value )
        go.child.textRenderer.text = "Difficulty : " .. Game.difficulty
    end
    
    sliderGO.slider.value = Game.difficulty
    
    
    -- play button
    local playButton = GameObject.Get( "PlayButton" )
    local t = Tween.Tweener( playButton.transform, "localScale", Vector3( 0.1 ), 0.8, {
        isRelative = true,
        loops = -1,
        loopType = "yoyo",
        updateInterval = 2,
     } )
     
     playButton:AddTag( "button" )
     playButton.OnClick = function()
        Game.planetCount = tonumber( planetCountGO.textRenderer.text )
        Scene.Load( "Level" )
     end
     
     
     local go1 = GameObject("")
     go1.transform.position = Vector3(2)
     local go2 = GameObject("")
     
     local pos1 = Vector3(0)
     local pos2 = Vector3(2)
     
     --print(Vector3.Distance( pos1, pos2 ), Vector3.Distance( pos1, pos2 ) / 10, ( pos1 - pos2 ):SqrLength() / (10^2), math.sqrt( ( pos1 - pos2 ):SqrLength() / (10^2) ))
     --print( 25, 25*100, 25^2, 25^2 * math.sqrt( 100))
     --print( (10 * 5)^2, 10^2 * 5^2  )
     --print( (pos1 - pos2):SqrLength(), math.sqrt( (pos1 - pos2):SqrLength() ), math.sqrt( (pos1 - pos2):SqrLength() ) ^2, Vector3.Distance( pos1, pos2 ) ^2 )
end -- end Start()

