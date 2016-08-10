
function Behavior:Awake()
    self.planetCounter = CS.FindGameObject( "PlanetCounter" )
    self.planets = CS.FindGameOBject( "Planets" ):GetChildren()
    
    
    for i, planet in ipairs( self.planets ) do
        local go = CS.CreateGameObject("target")
        go.transform.position = planet.transform.position + Vector3( 5000, 0, 0 )
        
    end
end

function Behavior:Update()
    
end
