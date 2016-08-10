-- Initialize random number generator
-- (See http://lua-users.org/wiki/MathLibraryTutorial)
math.randomseed( os.time() )
math.random(); math.random(); math.random()

function math.randomrange( lower, upper )
	return lower + math.random() * ( upper - lower )
end

function math.clamp( value, min, max )
	if value < min then return min end
	if value > max then return max end
	return value
end

function math.round( value )
  return math.floor( value + 0.5 )
end
