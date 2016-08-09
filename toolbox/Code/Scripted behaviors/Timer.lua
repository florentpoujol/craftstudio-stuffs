--[[PublicProperties
duration number 0
durationUnit string "second"
loop boolean False
time number 0
isPaused boolean False
callback string ""
/PublicProperties]]
--[[
A scripted behavior that act as a timer.
Calls a function and/or sends a message on the game object after a certain duration.
Set itself as the value of the 'timer' property on the game object.

Properties :

    duration (number) The duration before the timer completes.
    durationUnit (string) The unit of the duration : "frame" or "second" (any other value than "second" default back to "frame")
    loop (boolean) Tell wether to stop the timer when it has completed or to reset it and let it run again.
    time (number) The current progression of the timer. Usually between 0 and 'duration'.
    isPaused (boolean) Tell wether the timer is paused or not.
    callback (string) See below.
    isCompleted (boolean) Is 'false' while the timer runs, becomes 'true' when is has completed (time >= duration ).
    
callback property :

  - When the callback property as a string as value, the timer will send the message of the provided name on the game object and 
    try to call the function (or userdata) which may have been set as the value of a property of the provided name on the game object.
    "OnTimerComplete" is the default value when nothing else is set.

    Ie :
    self.callback = "OnTimerComplete" 
    When the timer completes, it will send the "OnTimerComplete" message on the game object and tries to call the function set in the 'gameObject.OnTimerComplete' property (if any).

  - When the callback property has a function as value, it will just be called. The function may be of type 'function' or 'userdata'.
  If the function is of type 'function', the timer (the scripted behavior instance) is passed as first and only argument.


You may reset the timer at any time by setting the 'time' property to zero.
If the timer had already completed you also need to set the 'isCompleted' property back to 'false'

Function :
    timer:Complete() Sends the message and/or call the callback function without actually completing or stopping the timer.

----------------

Create a timer by adding the script as a scripted behavior on any game object.

Ie :
self.gameObject:CreateScriptedBehavior( CS.FindAsset( "Timer", "Script" ), {
    duration = 5,
    loop = true,
    callback = function( timer ) print( "Hellow world !") end
} )

This will print "hellow world !" every 5 seconds until the game object is destroyed.


For convenience, you can also create a timer via the global Timer() function :
- Timer( [params] )
- Timer( duration, callback[, params] )
This function creates a game object (nammed "Timer"), adds this script as a scriped behavior and returns the scripted behavior instance.

Ie :
local timer = Timer()
    Creates a default timer. What happens (if the timer runs or not) depens on the default values of the script's public properties.

local timer = Timer( {
    duration = 5,
    loop = true,
    callback = function( timer ) print( "Hellow world !") end
} )
    Creates a timer with the exact same behavior as in the first example.

Timer( 5, CS.Exit )
    Creates a timer that will exit the game in 5 seconds.
]]

--[[PublicProperties
duration number 0
durationUnit string "time"
loop boolean false
time number 0
isPaused boolean false
callback string ""
/PublicProperties]]

function Behavior:Awake()
    self.isCompleted = false
    self.lastTime = os.clock()
    self.gameObject.timer = self
end

function Behavior:Update()
    if not self.isCompleted and not self.isPaused and self.duration > 0 then
        if self.durationUnit == "second" then
            local currentTime = os.clock()
            local deltaTime = currentTime - self.lastTime
            self.lastTime = currentTime
            self.time = self.time + deltaTime
        
        else
            self.time = self.time + 1
        end

        if self.time >= self.duration then
            self:Complete()

            if self.loop then
                self.time = 0
            else
                self.isCompleted = true
            end
        end
    end
end

function Behavior:Complete()
    local callbackType = type( self.callback )
    
    if callbackType == "function" then
        self.callback( self )
    
    elseif callbackType == "userdata" then
        self.callback()

    else
        if self.callback == "" then
            self.callback = "OnTimerComplete"
        end

        local _type = type( self.gameObject[ self.callback ] )
        if _type == "function" then
            self.gameObject[ self.callback ]( self )
        
        elseif _type == "userdata" then
            self.gameObject[ self.callback ]()
        end

        self.gameObject:SendMessage( self.callback )
    end
end

----------------------------------------------------------------------------------

local script = Behavior -- Behavior is not accessibe from within a function

--- Creates a new timer via one of the two allowed constructors : <br>
-- Timer.New( [params] ) <br>
-- Timer.New( duration, callback[, params] ) <br>
-- @param duration (number) The time or frame it should take for the timer to complete.
-- @param callback (function, userdata or string) The function that gets called, and/or message name that gets sent when the timer completes.
-- @param params [optional] (table) A table of parameters.
-- @return (Timer) The timer.
function Timer( duration, callback, params )
    if type( duration ) == "table" then
        params = duration
        duration = nil
    end
    if params == nil then
        params = {}
    end
    if duration ~= nil and callback ~= nil then
        params.duration = duration
        params.callback = callback
    end

    return CS.CreateGameObject( "Timer" ):CreateScriptedBehavior( script, params ) 
end
