
function PlaySound( name, volume, pitch, pan )
    volume = volume or 1
    pitch = pitch or math.randomrange(-0.5,0.5)
    pan = pan or math.randomrange(-0.5,0.5)
    CS.FindAsset(name, "Sound"):Play(volume, pitch, pan)
end
-----------------

-- quick fix for webplayer 
local ot = TextRenderer.SetText
function TextRenderer.SetText( tr, t )
    ot( tr, tostring(t) )
end
