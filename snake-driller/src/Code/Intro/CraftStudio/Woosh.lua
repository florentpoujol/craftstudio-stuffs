--[[PublicProperties
Delay number 1
/PublicProperties]]
local wooshSFX = CraftStudio.FindAsset( "CraftStudio Intro/Woosh", "Sound" )

function Behavior:Awake()
    self.time = 0
    
    self.hasPlayed = false
end

function Behavior:Update()
    self.time = self.time + 1 / 60
    
    if self.time >= self.Delay and not self.hasPlayed then
        self.hasPlayed = true
        wooshSFX:Play()
    end
end
