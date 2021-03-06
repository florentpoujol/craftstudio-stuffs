--[[PublicProperties
minValue number 0
maxValue number 100
length string "5"
axis string "x"
value string "0%"
/PublicProperties]]
-- Slider.lua
-- Scripted behavior for GUI.Slider component.
--
-- Last modified for v1.3.0
-- Copyright © 2013-2014 Florent POUJOL, published under the MIT license.



function Behavior:Awake()
    if self.gameObject.slider == nil then
        if string.trim( self.axis ) == "" then
            self.axis = "x"
        end
        if string.trim( self.value ) == "" then
            self.value = "0%"
        end

        GUI.Slider.New( self.gameObject, { 
            minValue = self.minValue,
            maxValue = self.maxValue,
            length = self.length,
            axis = self.axis,
            value = self.value,
        } )
    end
end
