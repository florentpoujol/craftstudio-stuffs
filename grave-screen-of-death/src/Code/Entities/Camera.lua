function Behavior:Awake()   
    self.gameObject.s = self
    Game.cameraGO = self.gameObject
    self.gameObject.transform:MoveOriented( Vector3(0,0,25) )
    
    -- shake
    self.frameCount = 0
    self.shakeDuration = 10
    self.shakeCooldown = 0 
    
    -- tuto
    self.tutoGO = self.gameObject:GetChild("Tuto", true)
    self.tutoGO.isDisplayed = true
    
    self.scoreGO = GameObject.Get("Score.Text")
    
    self.livesGO = GameObject.Get("Lives")
    self.livesGOs = self.livesGO.children
end


function Behavior:Start()
    self.originalPosition = self.gameObject.transform.position
    
    local textArea = self.tutoGO:GetChild("TextArea").textArea
    textArea.newLine = "\n"
    textArea.text =     
[[Fill the screen with the grave of your enemies !
But beware ! They will explode and destroy everything when you let them get too close to you !

Move: WASD.
Shoot: Left mouse button.
Dash in the direction of the mouse: Space.

Toggle menu/Pause: Escape]]


    local title = GameObject.Get("Title")
    title.textRenderer.text = "GSOD: Grave Screen Of Death"
    
    local credits = GameObject.Get("Credits") 
    credits.textRenderer.text = "Made by Florent Poujol for the Ludum Dare 31 Jam.        @FlorentPoujol        florentpoujol.fr        craftstud.io"
end


function Behavior:Update()
    if CS.Input.GetMouseDelta() == Vector2(0) then
        -- force the update of the Game.worldMousePosition even when the mouse cursor doesn't move
        self.gameObject.mouseInput:Update()
    end
    
    self.frameCount = self.frameCount + 1
    
    if self.shakeCooldown > 0 and self.frameCount % 2 == 0 then
        local offset = Vector3(0)
        
        self.shakeCooldown = self.shakeCooldown - 1
        if self.shakeCooldown > 0 then
            local shakeRange = 1
            offset = Vector3( math.randomrange(-shakeRange,shakeRange), math.randomrange(-shakeRange,shakeRange), math.randomrange(-shakeRange,shakeRange) )
        end
        
        self.gameObject.transform.position = self.originalPosition + offset
    end
    
    
    if Game.lives > 0 and CS.Input.WasButtonJustPressed("Escape") then
        local state = not self.tutoGO.isDisplayed
        self.tutoGO:Display( state )
        PauseGame(state)
    end
end


function Behavior:Shake()
    self.shakeCooldown = self.shakeDuration
end


-- Called from [Cross/Start]
function Behavior:UpdateScore( offset, position )
    
    
    Game.score = Game.score + offset
    self.scoreGO.textRenderer.text = Game.score
    
    if offset > 0 then
        offset = "+"..tostring(offset)
    else
        offset = tostring(offset)    
    end
    
    local line = GameObject.New("ScoreLine", {
        transform = { 
            position = position + Vector3(0,2,0),
            localScale = Vector3(0.2)
        },
        textRenderer = {
            font = "Calibri",
            alignment = "left",
            text = offset
        }
    } )
    local angles = line.transform.localEulerAngles
    angles.x = -45
    line.transform.localEulerAngles = angles
            
    line:Animate("opacity", 0, 1)
    line:Animate("position", position + Vector3(0,8,0), 1.2, function() line:Destroy() end)
end


function Behavior:UpdateLives()
    
    for i=1, #self.livesGOs do
        if i <= Game.lives then
            
        else
            self.livesGOs[i].modelRenderer.opacity = 0.2
        end
    end
    
    if Game.lives <= 0 then
        
        local crosses = GameObject.GetWithTag("cross")        
        
        local text = "Game Over !\n\nToo bad, you ran out of tombstone...\n\n"
        text = text.."But well done, "..#crosses.." crosses remains in your cementery ! \n"
        text = text.."\n Thanks for playing ! \n Reload the game/page to retry."
        
        local textArea = self.tutoGO:GetChild("TextArea").textArea
        textArea.text = text

        PauseGame(true)
        self.tutoGO:Display(true)
    end
end


Daneel.Debug.RegisterScript(Behavior)
