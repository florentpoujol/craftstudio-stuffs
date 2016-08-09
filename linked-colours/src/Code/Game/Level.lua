
Levels = {
    -- original level
    
    {
        id = 1,
        name = "Tuto 1: Colors",
        scenePath = "Levels/Tuto 1",
        tutoText = 
[[Link all the nodes together !

Red can connect to Red, Orange, Purple or White
Yellow can connect to Yellow, Orange, Green or White
Blue can connect to Blue, Green or Purple
And so on...

Click on a node to select it (Echap or click again to unselect).
Click on a node while one is selected to link the two together.]]
    },
    
    {
    
        id = 2,
        name = "Tuto 2: Links",
        scenePath = "Levels/Tuto 2",
        tutoText = 
[[Some nodes are required to have a specified number of links.

Two links can not cross each other.
Click on a link to remove it.

White nodes can connect to everyone.]]
    },
    
    {
        name = "Random",
        scenePath = "Levels/Random",
        isRandom = true,
        tutoText = 
[[Random generation MAY produce unsolvable level.]]        
    },
}




function GetLevel( nameOrId )
    local field = "name"
    if type( nameOrId ) == "number" then
        field = "id"
    end
    --print(field, nameOrId)
    for i, level in pairs( Levels ) do
        --print(level[ field ] == nameOrId
        if level[ field ] == nameOrId then
            return level
        end
    end
end
