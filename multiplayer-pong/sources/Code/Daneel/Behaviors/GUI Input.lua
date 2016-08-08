--[[PublicProperties
isFocused boolean False
maxLength number 999999
characterRange string ""
/PublicProperties]]
-- Input.lua
-- Scripted behavior for Daneel.GUI.Input component.
--
-- Last modified for v1.2.0
-- Copyright © 2013 Florent POUJOL, published under the MIT licence.



function Behavior:Awake()
    if self.gameObject.input == nil then
        local params = { 
            isFocused = self.isFocused,
            maxLength = self.maxLength
        }
        if self.characterRange:trim() ~= "" then
            params.characterRange = self.characterRange
        end

        self.gameObject:AddComponent( "Input", params )
    end
end
