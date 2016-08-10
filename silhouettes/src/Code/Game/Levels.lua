
Levels = {
    {
        id = 0,
        name = "ALevel1",
        silhouettes = {
            { "", "", "", "", "", "     x ", "     x " },
            { "", "", "", "", "", "    xx ", "    xx " }
        },
        creatorId = "",
    },

    {
        id = 1,
        name = "BLevel 2",
        silhouettes = {
            { " xxxxx ", " x     ", " xxxxx ", "     x ", " xxxxx " },
            { " xxxxx ", "     x ", " xxxxx ", " x     ", " xxxxx " },
        }
    },

    {
        id = 2,
        name = "CLevel 3",
        silhouettes = {
            { "xx   ", "x    ", "xx   ", " xxx ", "  x  " },
            { " xxx ", "  x  ", "xxx  ", "x    ", "xx   " },
        },
        creatorId = "",
    },

    {
        id = 3,
        name = "DLevel 4",
        silhouettes = {
            { "  xxx ", " xx    ", " x     ", " xxxx  ", "    x  " },
            { "  xxx ", "   x   ", " xxx   ", "   xx  ", "    xx " },
        }
    },

    {
        id = 4,
        name = "ELevel 5",
        silhouettes = {
            { "   x   ", "   xxx ", "     x ", " x xxx ", " xxx   " },
            { "    xx ", " xx x  ", "  x xx ", " xx x  ", " x  x  " },
        }
    },
}

for i, level in ipairs( Levels ) do
    level.creatorName = "Florent Poujol"
    level.creatorUrl = "FlorentPoujol"
end

table.mergein( Levels, table.copy(Levels, true), table.copy(Levels, true), table.copy(Levels, true) )
--table.mergein( Levels, table.copy( Levels, true ), table.copy(Levels, true), table.copy(Levels, true) )
--table.mergein( Levels, table.copy( Levels, true ) )
--table.insert(Levels, table.copy(Levels[1]))
--table.insert(Levels, table.copy(Levels[2]))

for i, level in ipairs( Levels ) do
    level.name = "Level "..i
end

function GetLevel( nameOrId )
    local field = "name"
    if type( nameOrId ) == "number" then
        field = "id"
    end
    
    for i=1, #Levels do
        local level = Levels[i]
        if level[ field ] == nameOrId then
            return level
        end
    end
end


-- Load all levels from the online repository
function LoadLevelsFromRepo( callback )
    CS.Web.Get( Game.levelRepositoryUrl.."?getlevels", nil, CS.Web.ResponseType.JSON, 
        function( error, data )
            if error then
                print("Error getting levels : ", error.message)
            end
            
            if data then
                local oldLevelsCount = #Levels
                for i, level in pairs( data.levels ) do
                    level.id = tonumber(level.id)
                    
                    if GetLevel( level.id ) == nil then
                        table.insert( Levels, level )
                    end
                end
                local newLevelsCount = #Levels - oldLevelsCount
            end
            
            if callback then 
                callback( error, data )
            end
        end
    )
end

