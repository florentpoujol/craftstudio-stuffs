--[[
Events are a way to call functions or send messages, whenever something happens during runtime, with or without the need for the script that fires an event to be aware of all the receivers.

'Function' refers in this page to any kind of functions : anonymous, local, global, 'Behavior' (scripted behaviors public functions) as well as 'userdata' (CraftStudio's functions).


    -----
    Global events
    -----

Global events are fired to any function or object that listen to it. Make a function or an object listen to one or several events with Event.Listen(eventName, functionOrObject).

    local function Foo() end
    function Behavior:Bar() end
     
    Event.Listen( "eventName", function() end ) -- anonymous
    Event.Listen( "eventName", Foo ) -- local or global function
    Event.Listen( "eventName", self.Bar ) -- 'Behavior'. Note that in this case, the 'self' variable will not exists automatically (like with messages) in the function
    -- in this case it is best to make the game object listen to the event
    Event.Listen( "eventName", CraftStudio.Exit ) -- userdata
     
    Event.Listen( "eventName", self.gameObject ) -- object. Works with any objects (or tables), not just game objects or components

Use Event.StopListen(eventNames, functionOrObject) to stop a function or object from listening to one, several or every global events.

Fire a global event with Event.Fire(eventName[, ...]). Any subsequent arguments to the event name are passed along to the listeners.

    local function Foo( arg1, arg2 )
        print( arg1.." | "..arg2 )
    end
     
    Event.Listen( "FooBar", Foo )
    Event.Fire( "FooBar", "first arg", 2 )
    -- will prints "first arg | 2"


    -----
    Local events (aka callbacks)
    -----

Local events are fired only to a single listener with Event.Fire(listener, eventName[, ...]).


    -----
    Objects as listener
    -----

The default behavior when an event is fired at an object is to send the message of the same name as the event on the object.

This behavior may be modified when the object as a property (non-nil) of the same name as the event. (ie : object.OnFoobar for an event named "OnFooBar").
If such property has a function as value, this function is called (in addition to the message being sent).
If such property has a string as value, the string is used as the message name (instead of the event name).

Sending a message only happens when the object is a game object.

    
    -- Example 1 : default behavior
    Event.Fire( self.gameObject, "OnLeftClick" )
    -- this sends the message OnLeftClick on this game object
    
    -- Example 2 : same event, but sends another message
    self.gameObject.OnLeftClick = "OnOtherMessage"
    Event.Fire( self.gameObject, "OnLeftClick" )
    -- this sends the message OnOtherMessage
    
    -- Example 3 : calls a function (and sends a message)
    self.gameObject.OnLeftClick = function(text) print(text) end
     
    Event.Fire( self.gameObject, "OnLeftClick" ) -- prints "nil"
    Event.Fire( self.gameObject, "OnLeftClick", "Click !" ) -- prints "Click !"
     
    -- Example 4 : Objects can be anything
    local object = { OnLeftClick = function() print("Click !") end }
    Event.Fire( object, "OnLeftClick" ) -- prints "Click !"
]]

Event = { 
    events = {},
}

--- Make the provided function or object listen to the provided event.
-- The function will be called whenever the provided event is fired.
-- @param eventName (string) The event name.
-- @param functionOrObject (function, userdata or table) The function (not the function name) or the object.
function Event.Listen( eventName, functionOrObject )
    if Event.events[ eventName ] == nil then
        Event.events[ eventName ] = {}
    end
    
    for eventName, value in pairs( Event.events[ eventName ] ) do
        if value == functionOrObject then
            return
        end
    end
    
    table.insert( Event.events[ eventName ], functionOrObject )
end

--- Make the provided function or object to stop listen to the provided event, or all event if no event name is provided.
-- @param eventName (string) [optional] The event name.
-- @param functionOrObject (function, uerdata or table) The function or the object.
function Event.StopListen( eventName, functionOrObject )
    if type( eventName ) ~= "string" then
        functionOrObject = eventName
        eventName = nil 
    end

    for _eventName, listeners in pairs( Event.events ) do
        if eventName == nil or eventName == _eventName then
            local listeners = Event.events[ _eventName ]
            if listeners ~= nil then
                for i, value in pairs( listeners ) do
                    if value == functionOrObject then
                        table.remove( listeners, i )
                    end
                end
            end
        end
    end
end

--- Fire the provided event at the provided object or the one that listen to it,
-- transmitting along all subsequent arguments if some exists. <br>
-- Allowed set of arguments are : <br>
-- (eventName[, ...]) <br>
-- (object, eventName[, ...]) <br>
-- @param object (table) [optional] The object to which fire the event at. If nil or abscent, will send the event to the listeners registered with Event.Listen().
-- @param eventName (string) The event name.
-- @param ... [optional] Some arguments to pass along.
function Event.Fire( object, eventName,  ... )
    local arg = { ... } -- for webplayer
    local argType = type( object )
    if argType == "string" --[[or argType == "nil"]] then -- 17/09/13 why checking for nil ?
        -- no object provided, fire on the listeners
        if eventName ~= nil then
            table.insert( arg, 1, eventName )
        end
        eventName = object
        object = nil
    end

    local listeners = { object }
    if object == nil and Event.events[ eventName ] ~= nil then
        listeners = Event.events[ eventName ]
    end

    for i, listener in ipairs( listeners ) do
        
        local listenerType = type( listener )
        if listenerType == "function" or listenerType == "userdata" then
            listener( unpack( arg ) )

        else -- an object
            local message = eventName

            -- look for the value of the EventName property on the object
            local funcOrMessage = rawget( listener, eventName )
            -- Using rawget() prevent a 'Behavior function' to be called as a regular function when the listener is a ScriptedBehavior
            -- because the function exists on the Script object and not on the ScriptedBehavior (the listener),
            -- in which case rawget() returns nil

            local _type = type( funcOrMessage )
            if _type == "function" or _type == "userdata" then
                funcOrMessage( unpack( arg ) )

            elseif _type == "string" then
                message = funcOrMessage
            end

            -- always try to send the message, even when funcOrMessage was a function
            if getmetatable( listener ) == GameObject and listener.inner ~= nil then
                listener:SendMessage( message, arg )
            end
        end
    end -- end for listeners
end
