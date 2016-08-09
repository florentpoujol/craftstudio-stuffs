
CS.Screen.SetSize(1000, 560) -- 1.78 = 16:9   840x470

Event = Daneel.Event

Game = {
    isPaused = true,

    levelSize = Vector2(65,50),
    
    -- "position of the mouse cursor in the 3D world"
    -- set by [Ground Builder/OnMouseOver]
    -- used to orient the player
    worldMousePosition = Vector3(0),
    
    groundMap = nil, -- set in [Ground Builder/Awake]
    
    maxEnemyCount = 5,
    enemySpawnCooldown = 80, -- frames
    
    minEnemySpawnDistanceFromPlayer = 150, -- SQR distance !
    minPlayerSpawnDistanceFromEnemy = 225, -- SQR distance !
    
    bulletSpeed = 80, -- /second
    
    playerHealth = 3,
    playerShootDamage = 1,
    playerShootCooldown = 13, -- frames
    playerMoveSpeed = 10, -- / sec
    
    enemyHealth = 3,
    enemyMoveSpeed = 7, -- / sec
    enemyStopSqrDistance = 4, -- SQR
    enemyExplosionActivationSqrRange = 40,
    enemyExplosionSqrRange = 35,
    enemyExplosionDamage = 5,
    
    score = 0,
    lives = 4,
}

Game.levelHalfSize = Game.levelSize / 2


BlockIds = {
    none = Map.EmptyBlockID,
    temp = 0,
    ground = 1,
    lightGrass = 7,
    darkGrass = 6,
    lightDirt = 9,
    darkDirt = 8,
}


function Daneel.UserConfig()
    return {
        debug = {
            enableDebug = false,
            enableStackTrace = false
        }
    }    
end
