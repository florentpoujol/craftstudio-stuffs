
function Behavior:Awake(a)
    if Daneel.Config.debug.enableDebug == true and a ~= true then
        self:Awake(true)
        return
    end
    
    PauseGame(true)
    
    Event.Listen( "OnGroundBuild", self.gameObject ) -- fired from [Ground Builder/Biuld]
    Event.Listen( "OnPlayerDead", self.gameObject ) -- fired from [Player]
    
    Game.entitiesParentGO = GameObject.Get("Entities Parent")
    
    self.spawnEnemies = false
    self.maxEnemyCount = Game.maxEnemyCount
    self.enemySpawnCooldown = 0
    self.maxEnemySpawnCooldown = Game.enemySpawnCooldown
    
    Game.textGO = GameObject.Get("Respawn Text")
    Game.textGO.textRenderer.text = "Spawning..."
end


function PauseGame(pause)
    Game.isPaused = pause or not Game.isPaused
    
    if Game.isPaused then
        Daneel.Time.timeScale = 0
    else
        Daneel.Time.timeScale = 1
    end
end


-- called from [Ground Builder]
function Behavior:OnGroundBuild()
    Tween.Timer( 1, function()
        SpawnPlayer( Vector3(0,0.51,0) )
        
        Tween.Timer( 2, function()
            self.spawnEnemies = true
         end )
    end )
end

-- called from [Player]
function Behavior:OnPlayerDead( data )
    local reason = data[1]
    
    Tween.Timer( 2, function()
        SpawnPlayer()
    end )
end


function Behavior:Update()
    if not Game.isPaused and self.spawnEnemies == true then
        self.enemySpawnCooldown = self.enemySpawnCooldown - 1
        if self.enemySpawnCooldown <= 0 then
            self.enemySpawnCooldown = self.maxEnemySpawnCooldown
            
            self:SpawnEnemy()
        end
    end
    
    
end


function SpawnPlayer( spawnPos )
    
    if spawnPos == nil then
        local enemies = GameObject.GetWithTag("enemy")
        local enemiesPos = {}
        for i=1, #enemies do
            table.insert( enemiesPos, enemies[i].transform.position )
        end
    
        local minPlayerSpawnDistanceFromEnemy = Game.minPlayerSpawnDistanceFromEnemy
        local minSqrDist = 9999
        for j=1, 100 do
            spawnPos = Vector2( math.random(Game.levelSize.x-5),  math.random(Game.levelSize.y-5) ) - Game.levelHalfSize
            spawnPos = Vector3( spawnPos.x, 0.51, spawnPos.y )
            
            if j > 50 then
                minPlayerSpawnDistanceFromEnemy = minPlayerSpawnDistanceFromEnemy / 2
            end
            minSqrDist = 9999
            
            for k=1, #enemiesPos do
                local sqrDist = (enemiesPos[k] - spawnPos):GetSqrLength()
                if sqrDist < minPlayerSpawnDistanceFromEnemy then
                    minSqrDist = 0
                    k=999
                end
                minSqrDist = math.min( minSqrDist, sqrDist )
            end
            
            if
                minSqrDist > minPlayerSpawnDistanceFromEnemy and
                Game.cameraGO.camera:IsPositionInFrustum( spawnPos ) 
            then
                break
            end
            if j == 100 then
                print("SpawnPlayer(): No suitable spawn point found for player !")
            end
        end
    end
    
    local shaft = Scene.Append("Entities/Shaft", Game.entitiesParentGO )
    Game.textGO.textRenderer.text = ""
    
    shaft.transform.position = spawnPos
    shaft.s:Init( function()
        PlaySound("Spawn", 0.3, 1, 1)
        local playerGO = Scene.Append( "Entities/Player", Game.entitiesParentGO )
        playerGO.transform.position = spawnPos
    end ) 
end
Daneel.Debug.functionArgumentsInfo.SpawnPlayer = {}


function Behavior:SpawnEnemy(atMousePos)
    local enemies = GameObject.GetWithTag("enemy")
    if #enemies >= self.maxEnemyCount then
        return
    end
      
    local spawnPos = Game.worldMousePosition
    if not atMousePos then
        local player = GameObject.GetWithTag("player")[1]
        local playerPos = nil
        if player ~= nil then
            playerPos = player.transform.position        
        end

        for i=1, 100 do
            spawnPos = Vector2( math.random(Game.levelSize.x-5),  math.random(Game.levelSize.y-5) ) - Game.levelHalfSize
            spawnPos = Vector3( spawnPos.x, 0.501, spawnPos.y )
            
            if playerPos ~= nil then
                if (playerPos - spawnPos):GetSqrLength() > Game.minEnemySpawnDistanceFromPlayer then
                    break                    
                end
            else
                break
            end
        end
    end

    local shaft = Scene.Append("Entities/Shaft", Game.entitiesParentGO )
    shaft.transform.position = spawnPos
    shaft.s:Init( function()
        PlaySound("Spawn", 0.2, 1, 1)
        local enemy = Scene.Append("Entities/Enemy", Game.entitiesParentGO)
        enemy.transform.localPosition = spawnPos

    end )
end

Daneel.Debug.RegisterScript(Behavior)
