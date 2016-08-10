Plane = {
  __tostring = function( e )
    return "{ normal=" .. tostring(e.normal) .. ", distance=" .. e.distance .. " }"
  end
}
Plane.__index = Plane

function Plane:New( normal, distance )
  return setmetatable( { normal=normal, distance=distance }, Plane )
end
