-- Thanks to @3DReMix for contributing some of those methods

Vector3 = {
  __add = function( a, b )
    return Vector3:New( a.x + b.x, a.y + b.y, a.z + b.z )
  end,
  
  __sub = function( a, b )
    return Vector3:New( a.x - b.x, a.y - b.y, a.z - b.z )
  end,
  
 __mul = function( a, b )
    if type(a) == "table" and type(b) == "number" then
      return Vector3:New( a.x * b, a.y * b, a.z * b )
    elseif type(a) == "number" and type(b) == "table" then
      return Vector3:New( a * b.x, a * b.y, a * b.z )
    elseif type(a) == "table" and type(b) == "table" then
      return Vector3:New( a.x * b.x, a.y * b.y, a.z * b.z )
    end
  end,
  
  __div = function( a, b )
    if type(a) == "table" and type(b) == "number" then
      return Vector3:New( a.x / b, a.y / b, a.z / b )
    elseif type(a) == "number" and type(b) == "table" then
      return Vector3:New( a / b.x, a / b.y, a / b.z )
    elseif type(a) == "table" and type(b) == "table" then
      return Vector3:New( a.x / b.x, a.y / b.y, a.z / b.z )
    end
  end,
  
  __unm = function ( e )
    return Vector3:New( -e.x, -e.y, -e.z )
  end,
  
  __pow = function ( a, b )
    if type(a) == "table" and type(b) == "number" then
      return Vector3:New( a.x ^ b, a.y ^ b, a.z ^ b )
    end
  end,
  
  __eq = function ( a, b )
    return ( a.x == b.x ) and ( a.y == b.y ) and ( a.z == b.z )
  end,
  
  __tostring = function( e )
    return "{ x=" .. e.x .. ", y=" .. e.y .. ", z=" .. e.z .. " }"
  end
}
Vector3.__index = Vector3

function Vector3:New( x, y, z )
  if y == nil and z == nil then
    if type(x) == "table" then
      y = x.y
      z = x.z
      x = x.x
    else
      y = x
      z = x
    end
  end
  
  return setmetatable( { x=x, y=y, z=z }, Vector3 )
end

function Vector3:Left()
	return Vector3:New( -1, 0, 0 )
end

function Vector3:Up()
	return Vector3:New( 0, 1, 0 )
end

function Vector3:Forward()
	return Vector3:New( 0, 0, -1 )
end

function Vector3:UnitX()
	return Vector3:New( 1, 0, 0 )
end

function Vector3:UnitY()
	return Vector3:New( 0, 1, 0 )
end

function Vector3:UnitZ()
	return Vector3:New( 0, 0, 1 )
end

function Vector3:Add( v )
  self.x = self.x + v.x
  self.y = self.y + v.y
  self.z = self.z + v.z
end

function Vector3:Subtract( v )
  self.x = self.x - v.x
  self.y = self.y - v.y
  self.z = self.z - v.z
end

function Vector3:Length()
  return math.sqrt( self.x ^ 2 + self.y ^ 2 + self.z ^ 2 )
end

function Vector3:SqrLength()
  return self.x ^ 2 + self.y ^ 2 + self.z ^ 2
end

function Vector3:Normalized()
  local nv = Vector3:New( self.x, self.y, self.z )
  nv:Normalize()
  return nv
end

function Vector3:Normalize()
  local len = self:Length()
  self.x = self.x / len
  self.y = self.y / len
  self.z = self.z / len
end

function Vector3.Lerp( a, b, v )
	if ( v > 1 ) then v = 1 end
	if ( v < 0 ) then v = 0 end
	
	local out = Vector3:New(0)
	out.x = a.x * ( 1 - v ) + b.x * v
	out.y = a.y * ( 1 - v ) + b.y * v
	out.z = a.z * ( 1 - v ) + b.z * v
	return out
end

function Vector3.Slerp( a, b, v )
	if ( v > 1 ) then v = 1 end
	if ( v < 0 ) then v = 0 end
	
	local out = Vector3.Lerp( a, b, v )
	
	return ( out:Normalized() * ( a:Length() * ( 1 - v ) + b:Length() * v ) )
end

function Vector3.Cross( a, b )
	return Vector3:New(
    a.y * b.z - a.z * b.y,
    a.z * b.x - a.x * b.z,
    a.x * b.y - a.y * b.x )
end

function Vector3.Dot( a, b )
	return a.x * b.x + a.y * b.y + a.z * b.z
end

function Vector3.Angle( a, b )
	local sinA = Vector3.Cross( a, b ):Length() / a:Length() / b:Length()
	local cosA = Vector3.Dot( a, b ) / a:Length() / b:Length()
	
	return math.atan2( sinA, cosA )
end

function Vector3.Distance( a, b )
	return ( b - a ):Length()
end

function Vector3.Rotate( v, q )
    local x = q.x * 2
    local y = q.y * 2
    local z = q.z * 2
    local w = q.w * x
    
    return Vector3:New(
      v.x * (1 - q.y * y - q.z * z) + v.y * (q.x * y - q.w * z)     + v.z * (q.x * z + q.w * y),
      v.x * (q.x * y + q.w * z)     + v.y * (1 - q.x * x - q.z * z) + v.z * (q.y * z - w),
      v.x * (q.x * z - q.w * y)     + v.y * (q.y * z + w)           + v.z * (1 - q.x * x - q.y * y) )
end

Vector3.Transform = Vector3.Rotate