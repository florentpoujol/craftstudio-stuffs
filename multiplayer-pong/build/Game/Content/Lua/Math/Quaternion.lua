Quaternion = {
  __add = function( a, b )
    return Quaternion:New( a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w )
  end,
  
  __sub = function( a, b )
    return Quaternion:New( a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w )
  end,
  
  __mul = function( a, b )
    return Quaternion:New(
      a.x * b.w + b.x * a.w + a.y * b.z - a.z * b.y,
      a.y * b.w + b.y * a.w + a.z * b.x - a.x * b.z,
      a.z * b.w + b.z * a.w + a.x * b.y - a.y * b.x,
      a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z )
  end,
  
  __unm = function ( e )
    return Quaternion:New( -e.x, -e.y, -e.z, -e.w )
  end,
  
  __eq = function ( a, b )
    return ( a.x == b.x ) and ( a.y == b.y ) and ( a.z == b.z ) and ( a.w == b.w )
  end,
  
  __tostring = function( e )
    return "{ x=" .. e.x .. ", y=" .. e.y .. ", z=" .. e.z .. ", w=" .. e.w .. " }"
  end
}
Quaternion.__index = Quaternion

function Quaternion:New( x, y, z, w )
  return setmetatable( { x=x, y=y, z=z, w=w }, Quaternion )
end

function Quaternion:Identity()
  return Quaternion:New( 0, 0, 0, 1 )
end

function Quaternion:FromAxisAngle( axis, angle )
  local sin = math.sin( math.rad( angle ) * 0.5 )
  return Quaternion:New( axis.x * sin, axis.y * sin, axis.z * sin, math.cos( math.rad( angle ) * 0.5 ) )
end

function Quaternion:Length()
  return math.sqrt( self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2 )
end

function Quaternion:SqrLength()
  return self.x ^ 2 + self.y ^ 2 + self.z ^ 2 + self.w ^ 2
end

function Quaternion.Slerp( quaternion1, quaternion2, amount )
  local magnitude = quaternion1.x * quaternion2.x + quaternion1.y * quaternion2.y + quaternion1.z * quaternion2.z + quaternion1.w * quaternion2.w
  
  local negative = false
  if magnitude < 0 then
    negative = true
    magnitude = -magnitude
  end
  
  local factor1, factor2
  if magnitude <= 0.999999 then
    -- Spherical interpolation is possible
    local angle1 = math.acos(magnitude)
    local inv = (1 / math.sin(angle1))
    
    factor1 = math.sin(((1 - amount) * angle1)) * inv
    
    if negative then
        factor2 = (-math.sin(((amount * angle1)))) * inv
    else
        factor2 = math.sin((amount * angle1)) * inv
    end
  else
    -- Revert back to linear
    factor1 = 1 - amount
    if negative then
        factor2 = -amount
    else
        factor2 = amount
    end
  end
  
  return Quaternion:New(
    factor1 * quaternion1.x + factor2 * quaternion2.x,
    factor1 * quaternion1.y + factor2 * quaternion2.y,
    factor1 * quaternion1.z + factor2 * quaternion2.z,
    factor1 * quaternion1.w + factor2 * quaternion2.w )
end