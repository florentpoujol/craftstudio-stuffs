----------------------------------------------------------------------------------
-- Game Analytics SDK for CraftStudio

-- This code for the Game Analytics SDK is open source - feel free to create 
-- your own fork or rewrite it for your own needs.
--
-- For documentation see: http://support.gameanalytics.com/forums
-- Sign up and get your keys here: http://www.gameanalytics.com
--
-- By Florent Poujol - http://florentpoujol.fr
-- Based on the Game Analtytics SDK for Corona by Jacob Nielsen
----------------------------------------------------------------------------------

GameAnalytics = {}
GA = GameAnalytics

local sdk_version = "0.1.0"

-----------------------------------------------
-- Default public configuration

-- Name of the build of the game.
GA.build = nil

-- URL of the relay script that actually perform the POST request to GameAnalytics.
GA.relayUrl = nil

-- Is created or loaded from storage if nil by the time GA.Init() is called.
-- Is saved in storage with the "GameAnalyticsUserId" identifier.
-- Set before GA.Init() is called to use a custom user id.
GA.user_id = nil

-- Tell whether to show debug messages is the Runtime Report (true) or not (false).
GA.isDebug = true

-- Tell whether to automatically call GA.Init() on Awake when the script is used as scripted behavior (true) or not (false).
-- GA.Init() is never called automatically when the script isn't used as a scripted behavior.
GA.InitOnAwake = true 

-- Time in second between two automatic reconnection attempts when the connection
-- either to the GameAnalytics website or to the relay script (or both) can't be established.
GA.checkConnectionInterval = 60 -- seconds

-- Tell whether to archive in storage ("GameAnalyticsArchivedEvents" identifier) events that weren't submitted (true) or not (false).
GA.archiveEvents = true

-- Tell whether to automatically track scene transitions.
-- Tracking scene transitions will automatically sends "SceneStartTime" and "SceneEndTime" design events with the timestamp as value.
-- It will also automatically set the GA.currentScenePath property and fill out the area field of design, business and error events when it isn't.
GA.trackSceneTransitions = false

-- Fully qualified path of the current scene.
-- Write here the path of the initial scene, in which the SDK is initialized.
GA.currentScenePath = "initial_scene"


-----------------------------------------------
-- Default values for private properties

local requiredString = { isRequired = true, type = "string" }
local optionalString = { type = "string" }
local optionalNumber = { type = "number" }
local fieldsByCategory = { 
    design = { 
        event_id    = requiredString,
        value       = optionalNumber, -- float
        area        = optionalString,
        x           = optionalNumber, -- float
        y           = optionalNumber,
        z           = optionalNumber
    },
    business = { 
        event_id    = requiredString,
        currency    = requiredString,
        amount      = { isRequired = true, type = "number" }, -- integer
        area        = optionalString,
        x           = optionalNumber, -- float
        y           = optionalNumber,
        z           = optionalNumber
    },
    error = { 
        message = requiredString,
        severity= requiredString,
        area    = optionalString,
        x       = optionalNumber, -- float
        y       = optionalNumber,
        z       = optionalNumber
    },
    user = {
        gender          = optionalString,
        birth_year      = optionalNumber, -- integer
        friend_count    = optionalNumber, -- integer
        facebook_id     = optionalString,
        googleplus_id   = optionalString,
        ios_id          = optionalString,
        android_id      = optionalString,
        adtruth_id      = optionalString,
        platform        = optionalString,
        device          = optionalString,
        os_major        = optionalString,
        os_minor        = optionalString,
        install_publisher= optionalString,
        install_site    = optionalString,
        install_campaign= optionalString,
        install_adgroup = optionalString,
        install_ad      = optionalString,
        install_keyword = optionalString,
    }
}

local initialized, session_id = false


-- connection
local checkingConnectionTo = {} -- key is url, value is true or nil. Url is gaUrl or GA.relayUrl
local gaUrl = "http://www.gameanalytics.com" -- "http://api.gameanalytics.com/1" returns 404
local canConnectTo = {} -- key is url, value is true or false. 

local function hasConnection()
    if canConnectTo[gaUrl] and GA.relayUrl and canConnectTo[GA.relayUrl] then
        return true
    end
    return false
end
-- Since the connection to the relay is checked from GA.Init(), hasConnection() will always return false when the SDK is not initialized

local function onHasConnection() -- Reset in GA.Init()
    print( "GameAnalytics has full connection." )
end


-- When offline, store events to be submitted or archived later
-- nil when no stored events
-- Set in storeEvents(), unset in archiveEvents() or submitStoredEvents()
local storedEventsByCategory

-- events will be archived (if allowed) or ignored when getStoredEventsCount() > maxStoredEventsCount
local maxStoredEventsCount = 1000

local function getStoredEventsCount()
    if not storedEventsByCategory then
        return 0
    else
        local count = 0
        for category, events in pairs( storedEventsByCategory ) do
            count = count + #events
        end
        return count
    end
end


-- timer
local frameCount = 0

local GATimer = { tasks = {} }
function GATimer.PerformWithDelay( time, action )
    table.insert( GATimer.tasks, {
        time = frameCount + time,
        action = action
    } )
end


----------------------------------------------------------------------------------
-- debug

local function debugPrint( ... )
    if GA.isDebug then
        print( "GameAnalytics: ", ... )
    end
end

-- Nicely prints the content of one or more events
-- @param category (string) The event category ("user", "design", "business" or "error").
-- @param events (table) One event or an array of events.
local function printEvents( category, events )       
    if GA.isDebug then
        if events == nil then
            debugPrint( "printEvents(): ERROR: 'events' argument is nil." )
            return
        end
        
        if events.session_id then -- events arg is a single event
            events = { events }
        end
        print( "Printing "..#events.." events of '"..category.."' category:" )
        for i=1, #events do
            local msg = "{ "
            for fieldName, value in pairs( events[i] ) do
                msg = msg..fieldName.."="
                if type( value ) == "number" then
                    msg = msg..value
                else
                    msg = msg.."'"..tostring(value).."'"
                end
                msg = msg..", "
            end
            msg = msg:sub(0, msg:len()-2) -- removes the last ", "
            msg = msg.." }"
            print( msg )
        end
    end
end

-- Nicely prints a table. May be recursive.
-- @param t (table) the table to print.
-- @param recursive (boolean) [default=false] Also prints tables found as values.
local function printTable(t, recursive, level)
    if GA.isDebug then
        if t == nil then
            debugPrint("printTable(): Provided table is nil.")
            return
        end
        if not level then
            level = 1
        end
        local slevel = ""
        for i=1, level-1 do slevel = slevel.."|     " end

        print(slevel, "~~~~~ printTable("..tostring(t)..") ~~~~~ Start ~~~~~")
        for key, value in pairs(t) do
            print(slevel, key, value)
            if recursive and type(value) == "table" then
                printTable(value, true, level + 1)
            end
        end
        print(slevel, "~~~~~ printTable("..tostring(t)..") ~~~~~ End ~~~~~")
    end
end


----------------------------------------------------------------------------------

-- Test Internet connectivity.
-- @param url (string) The url.
local function checkConnection( url )
    if checkingConnectionTo[url] then
        return
    end
    checkingConnectionTo[url] = true
    
    if canConnectTo[url] == nil then
        canConnectTo[url] = false
    end

    CS.Web.Get( url, nil, CS.Web.ResponseType.Text, function( e, data )
        checkingConnectionTo[url] = nil
        if e then
            canConnectTo[url] = false
            
            debugPrint( "checkConnection(): ERROR: Can't connect to '"..url.."':"..e.message )
            if GA.checkConnectionInterval and GA.checkConnectionInterval > 0 then
                debugPrint( "Retrying to connect to '"..url.."' in "..GA.checkConnectionInterval.." seconds." )
                GATimer.PerformWithDelay( GA.checkConnectionInterval * 60, function() checkConnection( url ) end ) -- recheck for connection every X frames (default is every 1 minute = 3600 frames)
            end

        elseif data then
            canConnectTo[url] = true
            
            if hasConnection() then
                onHasConnection()
            end
            debugPrint( "Can connect to '"..url.."'." )
        end
        
    end )
end
checkConnection( gaUrl )
-- check connection to GA.relayUrl done from GA.Init()


----------------------------------------------------------------------------------
-- storage

-- Save data in storage.
-- @param identifier (string) The storage identifier.
-- @param data (table) The data to save.
-- @param callback (function) [optional] The callback to call when the data has been saved (or failed to). It is passed the eventual error object.
local function saveData( identifier, data, callback )
    CS.Storage.Save( identifier, data, function( e )
        if e then
            if callback then
                callback( e )
            end
            error( "GameAnalytics: saveData(): Error saving in storage with identifier '"..identifier.."' and data '"..tostring(data).."': "..e.message )
        else
            debugPrint( "saveData(): Successfully saved '"..identifier.."' in storage.", data )
            if callback then
                callback()
            end
        end
    end )
end

-- Load data from storage.
-- @param identifier (string) The storage identifier.
-- @param callback (function) The callback to call when the data has been loaded (or failed to). It is passed the eventual error object and the data as first and second arguments, respectively.
local function loadData( identifier, callback )
    CS.Storage.Load( identifier, function( e, data )
        if e then
            callback( e )
            error( "GameAnalytics: loadData(): ERROR loading identifier '"..identifier.."' from storage : "..e.message )
        else
            debugPrint( "loadData(): Successfully loaded '"..identifier.."' data from storage.", data )
            callback( nil, data )
        end
    end )
end


----------------------------------------------------------------------------------

-- Creates a new unique user id.
-- @return (string) The user id (a md5 hash).
local function createUserId()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local user_id = os.time()
    for i=1, 20 do
        local j = math.random( 1, #chars )
        user_id = user_id..chars:sub( j, j )
    end
    user_id = md5.sumhexa( user_id )
    debugPrint( "createUserId(): New user id: "..user_id )
    return user_id
end

-- Retrieve the user id from storage 
-- or generate a new user id (a md5 hash) and store it.
-- @param callback (function) The callback function to which is passed the user id as first and only argument.
local function getUserId( callback )
    loadData( "GameAnalyticsUserId", function( e, data )
        if e then
            error( "GameAnalytics: getUserId(): ERROR loading user id ('GameAnalyticsUserId' identifier) from storage: "..e.message )
        end
        if data then
            if not data.user_id then
                error( "GameAnalytics: getUserId(): Data successfully loaded from storage but no user id was found." )
            end
        else -- storage file didn't exist yet, create a new user id
            data = { user_id = createUserId() }
            saveData( "GameAnalyticsUserId", data )
        end
        callback( data.user_id )
    end )
end

-- Creates a new unique session id.
-- @return (string) The session id (a md5 hash).
local function createSessionId()
    if not GA.user_id then
        error( "GameAnalytics: createSessionId(): GameAnalytics.user_id is nil !" )
    end 
    local sid = md5.sumhexa( GA.user_id..os.time() )
    debugPrint( "createSessionId(): New session id: "..sid )
    return sid
end


----------------------------------------------------------------------------------
-- Events

local archivingInProgress = false
-- prevent archiveEvents() to works multiple times because it is called multiple times by storeEvents()
-- while the archived events are being loaded and getStoredEventsCount() > maxStoredEventsCount.
-- In that case events continue to pile up in storedEventsByCategory until the archived events are successfully loaded.

-- Save in storage the currently stored events (dump storedEventsByCategory).
-- Called from storeEvent() when getStoredEventsCount() > maxStoredEventsCount.
-- @param archivedEvents (table) [optional] The events that are already archived (loaded from storage).
-- @param callback (function) The callback function to call when the archives have been successfully saved or when an error occurred during load or save. It is passed the eventual error object.
local function archiveEvents( archivedEvents, callback )
    if GA.archiveEvents then
        if storedEventsByCategory then
            if archivedEvents == nil then
                if archivingInProgress then
                    debugPrint( "archiveEvents(): Archiving stored events is already in progress, can't archive now." )
                    return
                end
                archivingInProgress = true

                loadData( "GameAnalyticsArchivedEvents", function( e, data )
                    if e then
                        archivingInProgress = false
                        if callback then
                            callback( e )
                        end
                        error( "GameAnalytics: archivedEvents(): ERROR loading archived events ('GameAnalyticsArchivedEvents' identifier) from storage: "..e.message )
                    end
                    if data == nil then -- first time archiving
                        data = {}
                    end
                    archiveEvents( data, callback )
                end )

            else
                -- storedEventsByCategory is the news events to archive
                -- archivedEvents are the events already archived, with this structure :
                --[[
                {
                    session_id = {
                        user_id
                        build
                        eventsByCategory = {
                            design = { array of events },
                            user = { array of events },
                            ...
                        }
                    },
                    ...
                }
                ]]

                if archivedEvents[ session_id ] == nil then
                    archivedEvents[ session_id ] = {
                        user_id = GA.user_id,
                        build = GA.build,
                        eventsByCategory = storedEventsByCategory
                    }
                else
                    for category, events in pairs( storedEventsByCategory ) do
                        if archivedEvents[session_id].eventsByCategory[category] == nil then
                            archivedEvents[session_id].eventsByCategory[category] = {}
                        end
                        for i, event in pairs( events ) do
                            table.insert( archivedEvents[session_id].eventsByCategory[category], event )
                        end
                    end
                end
                storedEventsByCategory = nil
                saveData( "GameAnalyticsArchivedEvents", archivedEvents, function( e )
                    archivingInProgress = false
                    if callback then
                        callback( e )
                    end
                    if e then
                        error( "GameAnalytics: archivedEvents(): ERROR saving archived events ('GameAnalyticsArchivedEvents' identifier) in storage: "..e.message )
                    end
                end  )
                -- TODO/FIXME (maybe?) : if the save fails, the events are lost for good
            end
        else
            debugPrint( "archiveEvents(): No event to archive." )
        end
    else
        debugPrint( "archiveEvents(): Event archiving is disabled." )
    end
end

-- Store events in storedEventsByCategory while offline.
-- When getStoredEventsCount() > maxStoredEventsCount, dump the stored events by archiving them in archiveEvents().
-- @param category (string) The event category ("user", "design", "business" or "error").
-- @param events (table) An array of events.
local function storeEvents( category, events )
    if getStoredEventsCount() < maxStoredEventsCount then
        if not storedEventsByCategory then storedEventsByCategory = {} end
        if not storedEventsByCategory[category] then storedEventsByCategory[category] = {} end
        
        local eventCount = #events
        for i=1, eventCount do
           table.insert( storedEventsByCategory[category], events[i] )
        end

        debugPrint( "storeEvents(): Storing "..eventCount.." event(s) of '"..category.."' category." )
        printEvents( category, events )
    end

    if getStoredEventsCount() >= maxStoredEventsCount then
        if GA.archiveEvents then
            if initialized then
                archiveEvents()
            else
                debugPrint( "storeEvents(): The stored events count has reached its maximum value of "..maxStoredEventsCount.." events but the SDK is not initialized. Can't archive events. Further events won't be stored until the currently stored events are archived." )
            end
        else
            debugPrint( "storeEvents(): The stored events count has reached its maximum value of "..maxStoredEventsCount.." events but event archiving is disabled. Further events won't be stored." )
        end
    end
end

-- In order to send a batch of events, they all have to be bundled in the same table, each keys being appended by the event's id because CS.Web.Post() don't send table values.
-- Each bundle is specific to a category and a session id.
-- @param category (string) The event category ("user", "design", "business" or "error").
-- @param events (table) An array of events.
-- @param sessionInfo (table) [optional] Must contains the keys "session_id", "user_id" and "build" when the events where not stored during this session (they where loaded from archive).
-- @return (table) The bundle of events.
local function bundleEvents( category, events, sessionInfo )
    if sessionInfo == nil then
        sessionInfo = {
            session_id = session_id,
            user_id = GA.user_id,
            build = GA.build
        }
    end
    local bundle = {
        session_id = sessionInfo.session_id,
        user_id = sessionInfo.user_id,
        build = sessionInfo.build,
        category = category
    } 
    for i, event in pairs( events ) do
        for fieldName, value in pairs( event ) do
            bundle[ fieldName.."_"..i ] = value
        end
        bundle.eventsCount = i -- this data (as well as the category) is for the relay script which reconstruct the array of event before actually sending the request to GA
    end
    return bundle
end

-- Send one or several events.
-- @param category (string) The event category ("user", "design", "business" or "error").
-- @param events (table) An array of events.
-- @param sessionInfo (table) [optional] Must contains the keys "session_id", "user_id" and "build", when the events where not stored during this session (they where loaded from archive).
local function submitEvents( category, events, sessionInfo )
    local idsToRemove = {}
    for i, event in pairs( events ) do
        if type(event) ~= "table" then 
            debugPrint( "submitEvents(): Discard non table event of '"..category.."' category.", i, event )
            table.insert( idsToRemove, i )
        end
    end
    for i=1, #idsToRemove do
        table.remove( events, i )
    end

    if initialized and hasConnection() then
        local bundle = bundleEvents( category, events, sessionInfo )
        CS.Web.Post( GA.relayUrl, bundle, CS.Web.ResponseType.JSON, function( e, data ) 
            if e ~= nil then
                canConnectTo[GA.relayUrl] = false
                checkConnection( GA.relayUrl )
                error( "GameAnalytics: submitEvents(): ERROR contacting the relay: "..e.message )
                -- should only happens if the connection to Internet has been lost
            elseif data then
                if data.status and data.status == "ok" then
                    if data.events and data.category then
                        debugPrint( "submitEvents(): Successfully submitted events to GameAnalytics:" )
                        printEvents( data.category, data.events )
                    else
                        debugPrint( "submitEvents(): No event data returned by the relay." )
                    end
                elseif GA.isDebug then
                    print( "GameAnalytics: submitEvents(): ERROR submitting an event ")
                    printTable(data, true)
                end
            else
                debugPrint( "Event submitted but no success or error returned !")
            end
        end )
    else
        storeEvents( category, events )
    end
end

-- Submit the events stored in storedEventsByCategory or those passed has argument.
-- @param eventsByCategory (table) [optional] Some events by category. Defaults to the content of the storedEventsByCategory variable.
-- @param sessionInfo (table) [optional] Must contains the keys "session_id", "user_id" and "build", when the events where not stored during this session (they where loaded from archive).
local function submitStoredEvents( eventsByCategory, sessionInfo )
    if hasConnection() then
        if eventsByCategory == nil then
            eventsByCategory = storedEventsByCategory
            storedEventsByCategory = nil
        end

        if eventsByCategory then
            for category, events in pairs( eventsByCategory ) do
                submitEvents( category, events, sessionInfo )
            end
        else
            debugPrint( "submitStoredEvents(): No event to submit." )
        end
    else
        debugPrint( "submitStoredEvents(): Can't submit events because there is no connection." )
    end
end

-- Get archived events from storage them submit them when online.
local function submitArchivedEvents()
    if hasConnection() then
        loadData( "GameAnalyticsArchivedEvents", function( e, archivedEventsBySessionId )
            if e then
                error( "GameAnalytics: submitArchivedEvents(): ERROR loading archived events ('GameAnalyticsArchivedEvents' identifier) from storage: "..e.message )
            end
            if archivedEventsBySessionId then
                for _session_id, sessionData in pairs( archivedEventsBySessionId ) do
                    local sessionInfo = {
                        session_id = _session_id,
                        user_id = sessionData.user_id,
                        build = sessionData.build
                    }
                    submitStoredEvents( sessionData.eventsByCategory, sessionInfo )
                end
                saveData( "GameAnalyticsArchivedEvents", nil )
            else
                debugPrint( "submitArchivedEvents(): No event were loaded from storage." ) -- will happen at least once at the beginning of each session
            end
        end )
    else
        debugPrint( "submitArchivedEvents(): Can't submit events because there is no connection." )
    end
end


----------------------------------------------------------------------------------
-- Public

--- Initialize the GameAnalytics SDK (creates or loads user id, generate session id).
-- @param onInitializedCallback (function) [optional] Callback function when GA is initialized.
function GA.Init( onInitializedCallback )
    if not initialized then
        local proceed = true
        local fields = { "build", "relayUrl" }
        for i=1, #fields do
            if GA[ fields[i] ] == nil then
                proceed = false
                print( "GameAnalytics.Init(): ERROR: Property GameAnalytics."..fields[i].." must not be nil !" )
            end
        end

        if not proceed then
            return
        end

        checkConnection( GA.relayUrl )
        onHasConnection = function()
            if storedEventsByCategory then
                submitStoredEvents()
            end
            submitArchivedEvents()
        end

        if GA.archiveEvents then 
            -- archive events before exiting the game
            -- note : there is currently no way to detect when the windows is closed without using CS.Exit()
            local originalExit = CS.Exit
            CS.Exit = function()
                if storedEventsByCategory then
                    if hasConnection() then
                        submitStoredEvents()
                        -- don't wait for answer from relay
                        originalExit()
                    else
                        archiveEvents( nil, function( e )
                            if e then
                                debugPrint( "Failed to archive events before exiting the game: "..e.message )
                            end
                            originalExit()
                        end )
                    end
                else
                    originalExit()
                end
            end
        end

        local onUserIdIsSet = function()
            session_id = createSessionId()
            initialized = true
            debugPrint( "Successfully initialized with user id '"..GA.user_id.."' and session id '"..session_id.."'." )

            if type( onInitializedCallback ) == "function" then
                onInitializedCallback()
            end
        end

        if GA.user_id == nil then
            getUserId( function( user_id )
                GA.user_id = user_id
                onUserIdIsSet()
            end )
        else
            -- custom user id
            -- should it be saved on storage ?
            onUserIdIsSet()
        end

        if GA.trackSceneTransitions then
            if GA.currentScenePath == nil or GA.currentScenePath == "" then
                GA.currentScenePath = "initial_scene"
            end

            local originalLoadScene = CS.LoadScene
            CS.LoadScene = function( scene )
                GA.NewEvent( "design", { event_id = "SceneEndTime", value = os.time() } )
                GA.currentScenePath = Map.GetPathInPackage( scene )
                originalLoadScene( scene )
            end
        end
    else
        debugPrint( "Already initialized." )
    end
end

--- Creates one or more new event(s).
-- If event can't be submitted right away, it will be stored if the GA.archiveEvents property is true.
-- @param category (string) The event category ("user", "design", "business" or "error").
-- @param ... One or more tables, each one containing one event's data.
function GA.NewEvent( category, ... )
    local events = {...}
    local fields = fieldsByCategory[category]
    local proceed = true

    for i, event in pairs( events ) do
        if fields ~= nil then
            for fieldName, fieldData in pairs( fields ) do
                local fieldValue = event[fieldName]
                if fieldValue == nil then
                    if fieldData.isRequired then
                        proceed = false
                        print( "GameAnalytics: NewEvent(): ERROR: Missing event field '"..fieldName.."' from event with category '"..category.."'." ) 
                        -- print() instead of debugPrint() because messages are actual errors the user should be aware of even if debug is turned off
                    end

                    if fieldName == "area" and GA.trackSceneTransitions then
                        event.area = GA.currentScenePath
                    end
                else 
                    local fieldType = type( fieldValue ) 
                    if fieldType ~= fieldData.type then
                        proceed = false
                        print( "GameAnalytics: NewEvent(): ERROR: Event field '"..fieldName.."' with value '"..tostring(fieldValue).."' from event with category '"..category.."' is of type '"..fieldType.."' instead of '"..fieldData.type.."'." )
                    end
                end
            end
        else
            proceed = false
            print( "GameAnalytics: NewEvent(): ERROR: Category '"..category.."' is not a valid category." )
        end
    end

    if not proceed then
        return
    end

    submitEvents( category, events )
end

--- Get the session id (a md5 hash).
-- @return (string) The session id.
function GA.GetSessionId()
    if not initialized then 
        error( "GameAnalytics.GetSessionId(): You have to initialize Game Analytics before you can get the session id." )
    end
    return session_id
end


----------------------------------------------------------------------------------
-- Runtime

function Behavior:Awake()
    if GA.InitOnAwake and not initialized then
        GA.Init()
    end

    if GA.trackSceneTransitions then
        GA.NewEvent( "design", { event_id = "SceneStartTime", value = os.time() } )
        -- GA.currentScenePath is set to the current scene path from CS.LoadScene()
        -- The area field is set to the value of GA.currentScenePath in GA.NewEvent()
    end
end

function Behavior:Update()
    frameCount = frameCount + 1

    local taskIdsToRemove = {}
    for i=1, #GATimer.tasks do
        local task = GATimer.tasks[i]
        if frameCount >= task.time then
            task.action()
            table.insert( taskIdsToRemove, i )
        end
    end 
    for i=1, #taskIdsToRemove do
        table.remove( GATimer.tasks, i )
    end
end
