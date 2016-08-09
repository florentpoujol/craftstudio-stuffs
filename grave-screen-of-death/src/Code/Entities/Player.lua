function Behavior:Awake(a)
    if Daneel.Config.debug.enableDebug == true and a ~= true then
        self:Awake(true)
        return
    end
    
    self.gameObject.s = self
    self.gameObject:AddTag("player")
    
    self.rendererGO = self.gameObject:GetChild("Renderer")
    self.rendererGO:AddTag( "player_renderer" ) -- Player/Renderer/Model
    self.rendererGO.modelRenderer.animation = "Player Move"
    self.rendererGO.modelRenderer:StopAnimationPlayback()
    
    self.hitOverlayGO = self.rendererGO:GetChild("Hit Overlay")
    self.hitOverlayGO.modelRenderer.opacity = 0
    self.hitOverlayGO.modelRenderer.animation = "Player Move"
    self.hitOverlayGO.modelRenderer:StopAnimationPlayback()
    
    self.weaponGO = self.rendererGO:GetChild("Weapon")
    self.weaponModelGO = self.weaponGO:GetChild("Model")
    self.muzzleGO =  self.weaponGO:GetChild("Muzzle")
    
    self.dashGO = self.gameObject:GetChild("Dash", true)
    local scale = self.dashGO.transform.localScale 
    scale.z = 0
    self.dashGO.transform.localScale = scale
       
    --
    self.shootRay = Ray.New(Vector3(0),Vector3(0))
    self.shootDamage = Game.playerShootDamage
    self.maxShootCoolDown = Game.playerShootCooldown -- frames between each shoot
    self.shootCoolDown = 0
    self.walkSpeed = Game.playerMoveSpeed -- per second
    self.health = Game.playerHealth  
    
    self.isMoving = false
    --
    self.frameCount = 0
    self.dashDuration = 15 -- frames
    self.dashCooldown = 0
    self.dashDirection = Vector3(0)
    self.dashSpeed = self.walkSpeed * 3
    
    Event.Listen("OnPlayerDead", self.gameObject)
end


function Behavior:Update()
    if Game.isPaused then
        return
    end
    
    local playerPosition = self.gameObject.transform.position
--print(playerPosition)
    -- Moving around
    local vertical = CS.Input.GetAxisValue( "Vertical" )
    local horizontal = CS.Input.GetAxisValue( "Horizontal" )
    
    local offset = Vector3( horizontal, 0, vertical )
    if horizontal ~= 0 or vertical ~= 0 then
        self.isMoving = true
        
        if not self.rendererGO.modelRenderer:IsAnimationPlaying() then
            self.rendererGO.modelRenderer:StartAnimationPlayback(true)
        end
        if not self.hitOverlayGO.modelRenderer:IsAnimationPlaying() then
            self.hitOverlayGO.modelRenderer:StartAnimationPlayback(true)
        end
    
        offset = offset:Normalized() * self.walkSpeed * Daneel.Time.deltaTime
    else
        self.isMoving = false
        -- player not moving
        
        if self.rendererGO.modelRenderer:IsAnimationPlaying() then
            self.rendererGO.modelRenderer:StartAnimationPlayback(false)
        end
        if self.hitOverlayGO.modelRenderer:IsAnimationPlaying() then
            self.hitOverlayGO.modelRenderer:StartAnimationPlayback(false)
        end
    end
    
    -- dash
    if self.dashCooldown > 0 then
        offset = self.dashDirection * self.dashSpeed * Daneel.Time.deltaTime
        self.dashCooldown = self.dashCooldown - 1
    end
    
    if self.dashCooldown <= 0 and CS.Input.WasButtonJustPressed( "Space" ) then
        self.dashCooldown = self.dashDuration
        self.dashDirection = (Game.worldMousePosition - playerPosition):Normalized()
        
        PlaySound("Dash", 0.7)
        
        self.dashGO.transform.localScale = Vector3(0.8,0.8,0)
        local scale = Vector3(0.8,0.8,5)
        self.dashGO:Animate("localScale", scale, 0.3)
        self.dashGO.modelRenderer.opacity = 1
        self.dashGO:Animate("opacity", 0, 0.1, {delay = 0.1})
        
    end
    
    -- apply offset
    offset.y = 0
    self.gameObject.transform:Move( offset )
    
    -- orient character
    if self.dashCooldown <= 0 then
        --don't turn the charazcter when the dash is in progress
        self.rendererGO.transform:LookAt( Game.worldMousePosition )
        -- correct orientation of the character
        local angles = self.rendererGO.transform.localEulerAngles
        angles.x = 0
        angles.z = 0
        self.rendererGO.transform.localEulerAngles = angles
    end
    
    
    -- shoot  
    self.shootCoolDown = self.shootCoolDown - 1
    
    if 
        self.shootCoolDown <= 0 and
        CS.Input.IsButtonDown("LeftMouse")
    then
        self.shootCoolDown = self.maxShootCoolDown
        self:Shoot()
    end
    
    if not Game.cameraGO.camera:IsPositionInFrustum( playerPosition ) then
        Game.textGO.textRenderer.text = "Respawning..."
        Tween.Timer( 2, function() SpawnPlayer() end )
        self.gameObject:Destroy()
    end
end



function Behavior:Shoot()
    local weaponPosition = self.weaponGO.transform.position
    local muzzleLocalPosition = self.muzzleGO.transform.localPosition -- LOCAL POS
    
    -- create a spread :
    -- instead of taking the muzzlePosition to calculate the forward direction
    -- create several muzzle pos at random around it
    local spread = 0.09
    if self.isMoving == false then
        spread = 0.05
    end
    
    local spreadPosition = muzzleLocalPosition +
    Vector3( math.randomrange(-spread, spread), 0, 0 ) -- local pos !
    -- should use a circle instead of a square
    
    local muzzlePosition = self.weaponGO.transform:LocalToWorld( spreadPosition )
    local forwardDirection = (muzzlePosition - weaponPosition):Normalized()
    
    local endPosition = muzzlePosition + forwardDirection * 999
    
    self.shootRay.position = muzzlePosition
    self.shootRay.direction = forwardDirection
    
    local enemies = GameObject.GetWithTag( "enemy_renderer" )   
    local hit = self.shootRay:Cast( enemies, true )[1]
    
    local targetGO = nil
    if hit ~= nil and hit.gameObject ~= nil then
        endPosition = hit.hitPosition
        targetGO = hit.gameObject
    end
    
    local bullet = Scene.Append("Entities/Bullet", Game.entitiesParentGO )
    bullet.transform.position = weaponPosition
    bullet.s:SetTarget(endPosition, targetGO)
    
    PlaySound("Shoot1", math.randomrange(0.5,1), math.randomrange(-0.5,0.5), math.randomrange(-0.5,0.5))
end


function Behavior:TakeDamage( damage )
    self.health = math.max( 0, self.health - damage )
     
    if self.health <= 0 then
        Event.Fire("OnPlayerDead", "killed")
    else
        self.hitOverlayGO.modelRenderer.opacity = 1
        
        if self.hitTweener == nil then
            self.hitTweener = self.hitOverlayGO:Animate( "opacity", 0, 0.3, function()
                self.hitTweener = nil
            end, { delay = 0.2 } )
        else
            self.hitTweener:Restart()                
        end
    end
    
    PlaySound("Hit")
end


function Behavior:OnPlayerDead()
    Game.textGO.textRenderer.text = "Spawning..."
    
    if self.hitTweener ~= nil then
        self.hitTweener:Destroy()
    end 
    
    local cross = Scene.Append("Entities/Cross", Game.entitiesParentGO )
    cross.transform.position = self.gameObject.transform.position
    cross.s.isTombstone = true
    
    Game.lives = Game.lives - 1
    Game.cameraGO.s:UpdateLives()
    
    self.gameObject:Destroy()
end

Daneel.Debug.RegisterScript(Behavior)
