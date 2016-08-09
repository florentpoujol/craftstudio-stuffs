--[[PublicProperties
key string ""
registerForUpdate boolean False
/PublicProperties]]
--[[

The lang objet allows you to easly localize any strings in your game.

    -----
    Setup
    -----

Change the values of the variables in the Lang.config table accordingly to your desired setup.

Each of the localized strings (the lines) are identified by a key, unique accross all languages. Ideally, the keys should not contains dot and the first-level keys should not be any of the languages name.
The key/line pairs for each languages must be set in a table returned by a global function which name follow the template : "Lang[Languagename]".

    -- see below
    Lang = {
        config = {
            current = "french",
            default = "english",
        }
    }
     
    -- anywhere :
    function LangEnglish()
        return {
            key = "value",
             
            greetings = { -- you may nest the key/line pairs.
                welcome = "Welcome !",
            }
        }
    end
     
    function LangFrench()
        return {
            greetings = {
                welcome = "Bienvenu !",
            }
        }
    end


    -----
    Retrieving a line
    -----

Use the Lang.Get(key[, replacements]) function. By default it returns the line in the current language (the value of the 'current' variable in the config).

    Lang.Get( "key" ) -- returns "value" when the default language is "english"

Chain the keys with dots when the key/line pairs are nested :

    Lang.Get( "greetings.welcome" ) -- returns "Welcome !" 

Prefix the key with the language name (with a dot after it) to get a line in any language :

    Lang.Get( "french.greetings.welcome" ) -- returns "Bienvenu !" even if the current language is not french

If a key is not found in a particular language, Get() search for it in the default language (the value of language.default in the config) before returning the value of the 'keyNotFound' variable in the config. 
To prevent Get() to search for a missing key in the default language, set the value of the 'searchInDefault' variable in the config to false.


    -----
    Placeholders and replacements
    -----

Your localized strings may contains placeholders that are meant to be replaced with other values before being displayed.
A paceholder is a sequence of any characters prefixed with a semicolon.
You may pass a placeholder/replacement table as the second parameter of Get().

    function LangEnglish()
        return {
            welcome = "Welcome :playername, have a nice play !",
        }
    end
     
    Lang.Get( "welcome" ) -- returns "Welcome :playername, have a nice play !"
    Lang.Get( "welcome", { playername = "John" } ) -- returns "Welcome John, have a nice play !"

When the placeholder is an integer, you may omit it during the call to Get() :

    function LangEnglish()
        return {
            welcome = "Welcome :1, have a nice play !",
        }
    end
     
    Lang.Get( "welcome", { "John" } ) -- Welcome John, have a nice play !


    -----
    Updating the language
    -----

You may register the game objects that display a text via a TextRenderer with Lang.RegisterForUpdate(gameObject, key[, replacements]) or listen to the "OnLangUpdate" event in order to automatically update the languages lines when the current language is modified.
The "OnLangUpdate" event is fired only if the Event object is found in the project.

Just call Lang.Update(language) with the new current language as argument to update the current language (and fire the OnLangUpdate event).

    gameObject.textRenderer.text = Lang.Get( "welcome" )
    Lang.RegisterForUpdate( gameObject, "welcome" )
     
    print( gameObject.textRenderer.text ) -- "Welcome :playername, have a nice play !"
    Lang.Update( "french" )
    print( gameObject.textRenderer.text ) -- "Bienvenu :playername, bon jeu !"


    -----
    In the scene
    -----

This file also be added as a scripted behavior in the scene on game objects that have TextRenerer components.

]]

Lang = {   
    config = {        
        current = nil, -- Current language
        default = nil, -- Default language
        searchInDefault = true, -- Tell wether Lang.Get() search a line key in the default language 
        -- when it is not found in the current language before returning the value of keyNotFound
        keyNotFound = "langkeynotfound", -- Value returned when a language key is not found
    },

    isLoaded = false,
    lines = {},
    gameObjectsToUpdate = {},
    cache = {},
    fireEventOnUpdate = false,
}

function Lang.Load()
    if Lang.isLoaded then return end
    Lang.isLoaded = true

    local defaultLanguage = nil

    for key, value in pairs( _G ) do
        if key:find( "^Lang%u" ) ~= nil and type( value ) == "function" then
            local language = (key:gsub( "Lang", "" )):lower()
            Lang.lines[ language ] = value()

            if defaultLanguage == nil then
                defaultLanguage = language
            end
        end
    end

    if defaultLanguage == nil then -- no language function found
        return
    end
    
    if Lang.config.default == nil then
        Lang.config.default = defaultLanguage
    end
    Lang.config.default = Lang.config.default:lower()

    if Lang.config.current == nil then
        Lang.config.current = Lang.config.default
    end
    Lang.config.current = Lang.config.current:lower()

    for k, v in pairs( _G ) do
        if k == "Event" then
            Lang.fireEventOnUpdate = true
            break
        end
    end

    Lang.Update( Lang.config.current )
end

--- Get the localized line identified by the provided key.
-- @param key (string) The language key.
-- @param replacements [optional] (table) The placeholders and their replacements.
-- @return (string) The line.
function Lang.Get( key, replacements )
    if not Lang.isLoaded then Lang.Load() end

    if replacements == nil and Lang.cache[ key ] ~= nil then
        return Lang.cache[ key ]
    end

    local errorHead = "Lang.Get( key[, replacements] ) : "

    key = key.."."
    local keys = { key:match( (key:gsub( "([^.]+).", "(%1)." )) ) } -- string.split( key, "." ) LEAVE THE PARENTHESIS AROUND GSUB
    local language = Lang.config.current
    if Lang.lines[ keys[1]:lower() ] then
        language = table.remove( keys, 1 )
        language = language:lower()
    end

    local noLangKey = table.concat( keys, "." ) -- rebuilt the key, but without the language
    local fullKey = language .. "." .. noLangKey 
    if replacements == nil and Lang.cache[ fullKey ] ~= nil then
        return Lang.cache[ fullKey ]
    end

    local lines = Lang.lines[ language ]
    if lines == nil then
        error( errorHead.."Language '"..language.."' does not exists" )
    end

    local cache = true
    for i, _key in ipairs( keys ) do
        if lines[ _key ] == nil then
            -- key was not found
            -- search for it in the default language
            if language ~= Lang.config.default and Lang.config.searchInDefault then
                cache = false
                lines = Lang.Get( Lang.config.default.."."..noLangKey, replacements )
            else -- already default language or don't want to search in
                lines = Lang.config.keyNotFound
            end

            break
        end
        lines = lines[ _key ]
    end

    -- lines should be the searched string by now
    local line = lines
    if type( line ) ~= "string" then
        error( errorHead.."Localization key '"..key:sub( 1, #key-1 ).."' does not lead to a string but to : '"..tostring(line).."'." )
    end

    -- process replacements
    if replacements ~= nil then
        for placeholder, replacement in pairs( replacements ) do
            line = line:gsub( ":"..placeholder, replacement )
        end
    elseif cache and line ~= Lang.config.keyNotFound then
        Lang.cache[ key ] = line -- ie: "greetings.welcome"
        Lang.cache[ fullKey ] = line -- ie: "English.greetings.welcome"
    end

    return line
end

--- Register a gameObject to update its TextRenderer whenever the language will be updated by Lang.Update().
-- @param gameObject (GameObject) The gameObject.
-- @param key (string) The language key.
-- @param replacements [optional] (table) The placeholders and their replacements (has no effect when the 'key' argument is a function).
function Lang.RegisterForUpdate( gameObject, key, replacements )
    Lang.gameObjectsToUpdate[ gameObject ] = {
        key = key,
        replacements = replacements,
    }
end

--- Update the current language and the text of all gameObjects that have registered via Lang.RegisterForUpdate().
-- Updates the TextRenderer component.
-- Fire the OnLangUpdate event.
-- @param language (string) The new current language.
function Lang.Update( language )
    if not Lang.isLoaded then Lang.Load() end

    Lang.cache = {} -- ideally only the items that do not begins by a language name should be deleted
    Lang.config.current = language
    for gameObject, data in pairs( Lang.gameObjectsToUpdate ) do
        if gameObject.transform ~= nil then
            local text = Lang.Get( data.key, data.replacements )
            
            if gameObject.textRenderer ~= nil then
                gameObject.textRenderer:SetText( text )
            else
                print( "Lang.Update( language ) : WARNING : game objet with name '" .. gameObject:GetName() .. "' does not have a TextRenderer component." )
            end
        else
            Lang.gameObjectsToUpdate[ gameObject ] = nil
        end
    end

    if Lang.fireEventOnUpdate then
        Event.Fire( "OnLangUpdate" )
    end
end


----------------------------------------------------------------------------------

--[[PublicProperties
key string ""
registerForUpdate boolean false
/PublicProperties]]

function Behavior:Awake()
    if not Lang.isLoaded then Lang.Load() end

    if self.key ~= "" then
        if self.gameObject.textRenderer ~= nil then
            self.gameObject.textRenderer:SetText( Lang.Get( self.key ) )
        end

        if self.registerForUpdate then
            Lang.RegisterForUpdate( self.gameObject, self.key )
        end
    end
end
