--[[
Vector2.New( x[, y] )  or  Vector2( x[, y] )
Vector2.Copy( vector2 )
Vector2.GetLength( vector2 )
Vector2.GetSqrLength( vector2 )
Vector2.Normalize( vector2 )
Vector2.Normalized( vector2 )

Operations :

vector2 + vector2
vector2 - vector2
vector2 * number, number * vector2 , vector2 * vector2
vector2 / number (number ~= 0 !), number / vector2 , vector2 / vector2
-vector2
vector2 ^ number
vector2 == vector2, vector2 ~= vector2
]]

Vector2 = {}
Vector2.__index = Vector2
setmetatable( Vector2, { __call = function(Object, ...) return Object.New(...) end } )

function Vector2.__tostring( vector2 )
    return "Vector2: { x=" .. vector2.x .. ", y=" .. vector2.y .. " }"
end

--- Creates a new Vector2 intance.
-- @param x (number or string) The vector's x component.
-- @param y [optional] (number or string) The vector's y component. If nil, will be equal to x. 
-- @return (Vector2) The new instance.
function Vector2.New( x, y )
    if y == nil then y = x end
    return setmetatable( { x = x, y = y }, Vector2 )
end

--- Copy the provided vector.
-- @param vector (Vector2) The vector.
-- @return (Vector2) The new vector.
function Vector2.Copy( vector )
    return Vector2.New( vector.x, vector.y )
end

--- Return the length of the vector.
-- @param vector (Vector2) The vector.
-- @return (number) The length.
function Vector2.GetLength( vector )
    return math.sqrt( vector.x^2 + vector.y^2 )
end

--- Return the squared length of the vector.
-- @param vector (Vector2) The vector.
-- @return (number) The squared length.
function Vector2.GetSqrLength( vector )
    return ( vector.x^2 + vector.y^2 )
end

-- Normalize the provided vector in place (makes its length equal to 1).
-- @param vector2 (Vector2) The vector2 to normalize.
function Vector2.Normalize( vector )
    local length = vector:GetLength()
    if length ~= 0 then
        vector = vector / length
    end
end

-- Return a copy of the provided vector, normalized.
-- @param vector2 (Vector2) The vector2 to normalize.
-- @return (Vector2) A copy of the vector, normalized
function Vector2.Normalized( vector )
    return Vector2.New( vector.x, vector.y ):Normalize()
end

--- Allow to add two Vector2 by using the + operator.
-- Ie : vector1 + vector2
-- @param a (Vector2) The left member.
-- @param b (Vector2) The right member.
-- @return (Vector2) The new vector.
function Vector2.__add( a, b )
    return Vector2.New( a.x + b.x, a.y + b.y )
end

--- Allow to substract two Vector2 by using the - operator.
-- Ie : vector1 - vector2
-- @param a (Vector2) The left member.
-- @param b (Vector2) The right member.
-- @return (Vector2) The new vector.
function Vector2.__sub( a, b )
    return Vector2.New( a.x - b.x, a.y - b.y )
end

--- Allow to multiply two Vector2 or a Vector2 and a number by using the * operator.
-- @param a (Vector2 or number) The left member.
-- @param b (Vector2 or number) The right member.
-- @return (Vector2) The new vector.
function Vector2.__mul( a, b )
    local newVector = 0
    if type( a ) == "number" then
        newVector = Vector2.New( a * b.x, a * b.y )
    elseif type( b ) == "number" then
        newVector = Vector2.New( a.x * b, a.y * b )
    else -- both Vector2
        newVector = Vector2.New( a.x * b.x, a.y * b.y )
    end

    return newVector
end

--- Allow to divide two Vector2 or a Vector2 and a number by using the / operator.
-- @param a (Vector2 or number) The numerator.
-- @param b (Vector2 or number) The denominator. Can't be equal to 0.
-- @return (Vector2) The new vector.
function Vector2.__div( a, b )
    local errorHead = "Vector2.__div( a, b ) : "
    local newVector = 0
    
    if type( a ) == "number" then
        if b.x == 0 or b.y == 0 then
            error( errorHead .. "One of the components of the denominator is equal to 0. Can't divide by 0 ! b.x=" .. b.x .. " b.y=" .. b.y )
        end
        newVector = Vector2.New( a / b.x, a / b.y )
    
    elseif type( b ) == "number" then
        if b == 0 then
            error( errorHead .. "The denominator is equal to 0 !" )
        end
        newVector = Vector2.New( a.x / b, a.y / b )
    
    else
        if b.x == 0 or b.y == 0 then
            error( errorHead .. "One of the components of the denominator is equal to 0. Can't divide by 0 ! b.x=" .. b.x .. " b.y=" .. b.y )
        end
        newVector = Vector2.New( a.x / b.x, a.y / b.y )
    end
    
    return newVector
end

--- Allow to inverse a vector2 using the - operator.
-- @param vector (Vector2) The vector.
-- @return (Vector2) The new vector.
function Vector2.__unm( vector )
    return Vector2.New( -vector.x, -vector.y )
end

--- Allow to raise a Vector2 to a power using the ^ operator.
-- @param vector (Vector2) The vector.
-- @param exp (number) The power to raise the vector to.
-- @return (Vector2) The new vector.
function Vector2.__pow( vector, exp )
    return Vector2.New( vector.x ^ exp, vector.y ^ exp )
end

--- Allow to check for the equality between two Vector2 using the == comparison operator.
-- @param a (Vector2) The left member.
-- @param b (Vector2) The right member.
-- @return (boolean) True if the same components of the two vectors are equal (a.x=b.x and a.y=b.y)
function Vector2.__eq(a, b)
    return ( a.x == b.x and a.y == b.y )
end
