
function Behavior:Awake(a)
    if Daneel.Config.debug.enableDebug == true and a ~= true then
        self:Awake(true)
        return
    end
    
    self.gameObject.s = self
    self.gameObject:AddTag("enemy")
    
    self.rendererGO = self.gameObject:GetChild("Renderer")
    self.rendererGO:AddTag( "enemy_renderer" )
    self.rendererGO.modelRenderer.animation = "Player Move"
    self.rendererGO.modelRenderer:StartAnimationPlayback(true)
    
    self.hitOverlayGO = self.rendererGO:GetChild("Hit Overlay")
    self.hitOverlayGO.modelRenderer.opacity = 0
    self.hitOverlayGO.modelRenderer.animation = "Player Move"
    self.hitOverlayGO.modelRenderer:StartAnimationPlayback(true)
    
    --    
    self.walkSpeed = Game.enemyMoveSpeed -- per second
    
    self.moveSqrRange = Game.enemyStopSqrDistance -- 2
    self.activationSqrRange = Game.enemyExplosionActivationSqrRange -- 5
    self.sqrExplosionRange = Game.enemyExplosionSqrRange -- 5
    
    self.health = Game.enemyHealth --player deal 1 per shot
    self.damage = Game.enemyExplosionDamage
    
    --
    
end


function Behavior:Update()
    if Game.isPaused then
        return
    end
    
    local selfPosition = self.gameObject.transform.position
    
    local playerGO = GameObject.GetWithTag( "player" )[1]
    if playerGO ~= nil then
        local playerRndrPosition = playerGO.s.rendererGO.transform.position
        
        -- orient character
        self.rendererGO.transform:LookAt( playerRndrPosition )
        -- correct orientation of the character
        local angles = self.rendererGO.transform.localEulerAngles
        angles.x = 0
        angles.z = 0
        self.rendererGO.transform.localEulerAngles = angles
        
        -- move
        local directionToPlayer = playerRndrPosition - selfPosition
        local playerSqrDistance = directionToPlayer:GetSqrLength()
        
        if playerSqrDistance <= self.moveSqrRange then
            --stop
            if self.rendererGO.modelRenderer:IsAnimationPlaying() then
                self.rendererGO.modelRenderer:StartAnimationPlayback(false)
            end
            if self.hitOverlayGO.modelRenderer:IsAnimationPlaying() then
                self.hitOverlayGO.modelRenderer:StartAnimationPlayback(false)
            end
        else
            local offset = directionToPlayer:Normalized() * self.walkSpeed * Daneel.Time.deltaTime
            
            self.gameObject.transform:Move( offset )
            
            if not self.rendererGO.modelRenderer:IsAnimationPlaying() then
                self.rendererGO.modelRenderer:StartAnimationPlayback(true)
            end
            if not self.hitOverlayGO.modelRenderer:IsAnimationPlaying() then
                self.hitOverlayGO.modelRenderer:StartAnimationPlayback(true)
            end
        end
        
        if playerSqrDistance <= self.activationSqrRange then
            -- start exploding
            self:InitExplosion()
        end
    end    
end


function Behavior:TakeDamage( damage )
    self.health = self.health - damage

    if self.health <= 0 then
        self:Die()
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
    
    PlaySound("Hit", math.randomrange(0.5,1))
end


function Behavior:InitExplosion()
    if self.explosionTweener == nil then
        self.hitOverlayGO.modelRenderer.opacity = 0.1
        self.explosionTweener = Tween.Tweener( self.hitOverlayGO.modelRenderer, "opacity", 1, 0.5, {
            loops = 10,
            loopType = "yoyo",
            OnLoopComplete = function(tweener)
                tweener.duration = tweener.duration / 1.2
                PlaySound("Bip", tweener.completedLoops/10, 0)
                
                if tweener.duration <= 0.1 then
                    self:Explode()
                    self.rendererGO.modelRenderer.opacity = 0
                    tweener:Destroy()
                end
            end
        } )
    end
end


function Behavior:Explode()
    local selfPosition = self.gameObject.transform.position
    
    -- spawn 10 cubes
    for i=1, 5 do
        local go = Scene.Append("Entities/Explosion")
        go.transform.position = selfPosition + Vector3( math.randomrange(-0.9,0.9), math.randomrange(0.2,1.5), math.randomrange(-0.9,0.9) )
        go.modelRenderer.color = Color(255, math.random(255),0)
        go.transform.localScale = math.randomrange(0.4,0.8)
        local angles = Vector3( 0, 0, 0 )
        if i == 1 then
            angles.x = math.randomrange( 0,359 )
        elseif i == 2 then
            angles.y = math.randomrange( 0,359 )
        elseif i == 3 then
            angles.z = math.randomrange( 0,359 )
        end
        go.transform.eulerAngles = angles
        go:Animate("localScale", Vector3(math.randomrange(5, 10)), 0.5)
        go:Animate("opacity", 0, 0.6, function()
            go:Destroy()
        end, { delay = 0.1 } )
    end
    
    PlaySound("Explosion")
    Game.cameraGO.s:Shake()
    
    -- destroy crosses
    self.gameObject.trigger.range = math.sqrt( self.sqrExplosionRange )
    local crosses = self.gameObject.trigger.gameObjectsInRange
    for i=1, #crosses do
        if not crosses[i].s.isTombstone then
            crosses[i]:Destroy()
        end
    end
    
    -- 
    Tween.Timer( 0.1, function() self:Die() end )
    
    --
    -- deal damage to the player
    local player = GameObject.GetWithTag( "player" )[1]
    if player ~= nil then
        local playerPos = player.transform.position
        local sqrDistToPlayer = (playerPos-selfPosition):GetSqrLength()

        if sqrDistToPlayer < self.sqrExplosionRange then
            -- player is in range of explosion
            -- deal damage based on distance
            
            local percentage = 1 - sqrDistToPlayer / self.sqrExplosionRange
            local damage = math.max( 0.5, self.damage * percentage )
            player.s:TakeDamage( damage ) 
        end
    end
end


function Behavior:Die()    
    if self.hitTweener ~= nil then
        self.hitTweener:Destroy()
    end
    if self.explosionTweener ~= nil then
        self.explosionTweener:Destroy()
    end
    
    self.hitOverlayGO.modelRenderer.opacity = 0
    
    local cross = Scene.Append("Entities/Cross", Game.entitiesParentGO )
    cross.transform.position = self.gameObject.transform.position
        
    self.gameObject:Destroy()
end

Daneel.Debug.RegisterScript(Behavior)
