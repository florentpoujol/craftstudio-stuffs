# Game Analytics SDK for CraftStudio

This repository hosts the [Game Analytics](http://www.gameanalytics.com) SDK you can use in [CraftStudio](http://craftstud.io) projects.

Features (v0.1.0) :

- Store (in memory) and archive (in storage) events when not connected.
- Automatically attempt to reconnect when disconnected.
- Automatically generate/save/load user id, or use custom user id.
- Automatically generate session id.
- Automatically track scene transitions.

---

- [Relay script](#relay)
- [Setup](#setup)
- [Usage](#usage)
- [Options](#options)


<a name="relay"></a>
# Relay script

CraftStudio's `CS.Web.Post()` function can't communicate with Game Analytics because the header of the request can't be modified and it doesn't transmit tables as values in the request's data.

That's why a "relay" has to be used. CraftStudio sends events to the relay which perform the actual request to Game Analytics and communicate the response back.

A relay written in PHP is provided (the `Relay/index.php` file). It requires a web server running PHP (>= 4.0.2) with the `cURL` extension active.

If you feel to create another one, the relay has these general requirements :

- Accept and send HTTP-POST request with a modified header.
- Works with JSON and md5.

The POST data sent by CraftStudio is a single table containing the following keys :

- category
- session_id
- user_id
- build
- eventsCount: the number (and also the last event id) of events submitted in this request.
- all events' fields. All fields are appended with an underscore and the event's id.

Ie :
    
    {
        category = "design",
        session_id = "0fa0cf12d98ecccc7deb734d75cf5831",
        user_id = "e4517eba61349ca00bo8b42099683c61",
        build = "TestBuild",

        event_id_1 = "FirstEvent",
        value_1 = "1",
        
        event_id_2 = "OtherEvent",
        area_2 = "Level1"
    }


The SDK always expect a response from the relay script in JSON.  

The GameAnalytics server also respond with a JSON message when the request was successful.  

    { "status": "ok" }

But if the request wasn't successful, it just respond with the error message as a string.  
In this case, the relay script must put the error message as the value of the `error` key in the response.

    { "error": "[The error message from GA]" }

For debugging purpose and in case of error, the provided relay also puts the request URL and the JSON message transmitted to GA as value of the `request_url` and `json_message` keys in the response to the SDK.

Still for debugging purpose but whatever the status of the request to GA, the provided relay also adds the category and the events array back in the response as values of the `category` and `events` keys.


Example of response when the request was successful :

    {
        "status": "ok",
        "category": "design",
        "events": [
            {
                "session_id": "0fa0cf12d98ecccc7deb734d75cf5831",
                "user_id": "e4517eba61349ca00bo8b42099683c61",
                "build": "TestBuild,"
                "event_id": "FirstEvent",
                "value": 1
            },
            {
                "session_id": "0fa0cf12d98ecccc7deb734d75cf5831",
                "user_id": "e4517eba61349ca00bo8b42099683c61",
                "build": "TestBuild,"
                "event_id": "OtherEvent",
                "area": "Level1"
            }
        ]
    }

Example of response when the request wasn't successful :

    {
        "error": "[The error message from GA]",

        "request_url": "http://api.gameanalytics.com/1/[game key]/design"
        "json_message": "[{"session_id":"0fa0cf12d98ecccc7deb734d75cf5831","user_id":"e4517eba61349ca00bo8b42099683c61","build":"TestBuild,""event_id":"FirstEvent","value":1},{"session_id":"0fa0cf12d98ecccc7deb734d75cf5831","user_id":9ca00bo8b42099683c61","build":"TestBuild,""event_id":"OtherEvent","area":"Level1"}]",

        "category": "design",
        "events": [
            {
                "session_id": "0fa0cf12d98ecccc7deb734d75cf5831",
                "user_id": "e4517eba61349ca00bo8b42099683c61",
                "build": "TestBuild,"
                "event_id": "FirstEvent",
                "value": 1
            },
            {
                "session_id": "0fa0cf12d98ecccc7deb734d75cf5831",
                "user_id": "e4517eba61349ca00bo8b42099683c61",
                "build": "TestBuild,"
                "event_id": "OtherEvent",
                "area": "Level1"
            }
        ]
    }

<a name="setup"></a>
# Setup

Create an account then a game on [Game Analytics](http://www.gameanalytics.com) to obtain your game key and secret key.

Setup your relay script then set the `$game_key` and `$secret_key` variables.

Copy and paste both scripts `md5.lua` and `GameAnalytics.lua` inside your CraftStudio project.  
You can access Game Analytics' object via the `GameAnalytics` or `GA` global variables.

In another script, setup at least the following public properties :

- `GA.relayUrl` is the absolute URL of the relay script (must ends by a trailing slash or the name of the file)
- `GA.build` is the name of the build of the game.


<a name="usage"></a>
# Usage

## Initialization

Call `GA.Init( [onInitializedCallback] )` to initialize the SDK.  
The `GA.relayUrl` and `GA.build` properties must have been set before that.

Initialization will generate or load the user id (unless you have set a custom user id, see below), generate a session id and check the connection to the relay script.  
Initialization is required to submit or archive events, but not to creates new ones.

Since the initialization is probably not instantaneous (because it tries to load the user id from storage, which is asynchronous) you can pass a callback function as the first and only parameter of `GA.Init()`.  
This function is called when the initialization is completed, that is when the user id has been created/loaded and the session id generated.

Once initialized, the `GA.user_id` property is set to the user id and you can get the session id with the `GA.GetSessionId()` function.

Note that you still may not be able to submit events because the connection checks to GA's website and the relay script still haven't completed.  
Once the connection is established, the SDK will automatically submit any stored or archived events.

## Creating events

Create new events with the `GA.NewEvent( category, ... )` function.

The first argument is the event's category : "design", "user", "error" or "business".

Subsequent argument(s) are one or more event(s) data as table.

Ie :
    
    -- creating two events of the design category
    GA.NewEvent( "design", { event_id = "FirstEvent", value = 1 }, { event_id = "OtherEvent", area = "Level1" } )


<a name="options"></a>
# Options

## Custom user id

You can set the `GA.user_id` property to a string if you want to use a custom user id.  
In the case it is `nil` by the time `GA.Init()` is called, a user id will be loaded from storage or generated (and saved in storage).  

You can set the property at any time, but you should set it before `GA.Init()` is called to make sure events are sent with your custom user id.  
Custom user id are not saved in storage.

## Debug

Debugging prints all errors, actions as well as submitted, stored and archived events in the Runtime Report.  
Set the `GA.isDebug` property to `false` to disable debugging (`true` by default).

## Init on Awake

When the `GameAnalytics` script is added as a scripted behavior, `GA.Init()` is called automatically from the script's `Awake()` function so that you don't have to call it yourself.  
Set the `GA.InitOnAwake` property to `false` to disable this behavior (`true` by default). 

## Automatic reconnection attempts

When the SDK can't connect to the GA's website and/or the relay script, it tries to reconnect periodically.  
Set the `GA.checkConnectionInterval` property to the time (number) in seconds between two automatic reconnection attempts (default is 60 seconds, set to `nil`, `0` or a negative value to disable).  
The `GameAnalytics` script also must have been added as a scripted behavior in the scene to enable this feature.  

## Event archiving

When the SDK can't connect to the GA's website and/or the relay script, events are stored in memory. 

Events can also be archived in storage with the "GameAnalyticsArchivedEvents" identifier when the stored events count reach its limit (500 events), or the game is exited by calling `CS.Exit()`.
Archived events are automatically submitted whenever the connection is established during any other play session.

Set the `GA.archiveEvents` property to `false` to disable archiving of events (`true` by default).  
If archiving is turned off, events are still stored in memory but will be lost of they reach their maximum count or the game exits.

## Tracking scene transitions

Set the `GA.trackSceneTransitions` property to `true` to enable the SDK to automatically track scene transitions (`false` by default).  
You can also set the `GA.currentScenePath` propertie to the path of the initial scene, in which the SDK is initialized.  

Tracking scene transitions will automatically send design events with `SceneStartTime` and `SceneEndTime` event id and the current timestamp as value.  
It will also automatically set the `GA.currentScenePath` property and fill out the area field of design, business and error events when it isn't.
