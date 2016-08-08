Ray = {
  __tostring = function( e )
    return "{ position=" .. tostring( e.position ) .. ", direction=" .. tostring( e.direction ) .. " }"
  end
}
Ray.__index = Ray

function Ray:New( position, direction )
  return setmetatable( { position=position, direction=direction }, Ray )
end

function Ray:IntersectsPlane( plane )
  local d = plane.normal.x * self.direction.x +
            plane.normal.y * self.direction.y +
            plane.normal.z * self.direction.z
  
  if math.abs(d) > 0 then
      local p = plane.normal.x * self.position.x +
                plane.normal.y * self.position.y +
                plane.normal.z * self.position.z
      
      local d = ( -plane.distance - p ) / d
      
      if d < 0 then
        return nil
      end
      
      return d
  else
    return nil
  end
end