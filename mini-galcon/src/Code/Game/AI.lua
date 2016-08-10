
function Behavior:Awake()
    self.frameCount = 0
    
    self.decisionInterval = 10 -- nb of frames between any decision it take
    self.shipsThreshold = 5
    
    self.allPlanets = {}
    
    self.selectedPlanet = nil
    self.targettedPlanet = nil
    
    Daneel.Event.Listen( "AI_Init", self.gameObject )
end


function Behavior:AI_Init()
    self.decisionInterval = Game.difficulty * 1.5
    self.shipsThreshold = Game.difficulty


    -- loop through the planets and make the list of all other planets ordered by distance
    self.allPlanets = table.copy( GameObject.Tags.planet )
    
    for i, planet in ipairs( GameObject.Tags.planet ) do
        planet.otherPlanetsByDistances = {}
        planet.otherPlanetsOrdered = {}
        
        for j, otherPlanet in ipairs( self.allPlanets ) do
            if planet ~= otherPlanet then
                planet.otherPlanetsByDistances[ Vector3.Distance( planet.transform.position, otherPlanet.transform.position ) ] = otherPlanet
            end
        end
        
        local distances = table.getkeys( planet.otherPlanetsByDistances ) 
        table.sort( distances ) -- small distances first
        for j, distance in ipairs( distances ) do
            table.insert( planet.otherPlanetsOrdered, planet.otherPlanetsByDistances[ distance ] ) 
        end
    end
    
    --print( "AI initialized", Game.difficulty, self.decisionInterval, self.shipsThreshold )
end


function Behavior:Update()
    self.frameCount = self.frameCount + 1
    
    if self.frameCount % self.decisionInterval == 0 then
        local capturedPlanets = {}
        -- get all captured planets
        for i, planet in ipairs( self.allPlanets ) do
            if planet:GetTeam() == Game.enemyTeam then
                table.insert( capturedPlanets, planet )
            end
        end
        
        -- find a random captured planet
        local iteration = 0
        while iteration < 1000 and self.selectedPlanet == nil do
            self.selectedPlanet = capturedPlanets[ math.floor( math.randomrange( 1, #capturedPlanets+0.1 ) ) ]
            
            if self.selectedPlanet ~= nil and self.selectedPlanet.shipCount < self.shipsThreshold then
                self.selectedPlanet = nil
            end
            
            iteration = iteration + 1
        end
        
        
        if self.selectedPlanet == nil then return end
        
        -- find the closest neutral or player planet
        for i, planet in ipairs( self.selectedPlanet.otherPlanetsOrdered ) do
            if planet:GetTeam() ~= Game.enemyTeam then
                self.targettedPlanet = planet
                break
            end
        end
        
        
        if self.selectedPlanet ~= nil and self.targettedPlanet ~= nil then
            -- send ships
            self.selectedPlanet:SpawnShips( self.targettedPlanet )
            
            self.selectedPlanet = nil
            self.targettedPlanet = nil
        end
        
    end
end
