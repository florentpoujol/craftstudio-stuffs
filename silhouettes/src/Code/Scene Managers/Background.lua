
function Behavior:Awake()
    self.maskGO = self.gameObject:GetChild("Mask")
    --self.maskGO.transform.localScale = Vector3(200,200,0)
    
    self.backGO = self.gameObject:GetChild("Back")
    self.backGO.mapRenderer:LoadNewMap( function( map )
        self.backMap = map
        self:Init()
    end )
end

--local backgroundBlockIds = { 32,33,34,35,36,37,38,39 }
local backgroundBlockIds = { 48,49,50,51,52,53 }
local backgroundSize = 25 -- half-width of the background, in number of map block
--22*22=484
--25*25=625

function Behavior:Init()
    -- position the backgrounds at the center of the screen
    local camGO = GameObject.Get( "Background Camera" )
    self.gameObject.parent = camGO
    self.gameObject.transform.localPosition = Vector3(0,0,-50)
    
    self.gameObject.transform.eulerAngles = Vector3(0,0, math.randomrange(-90, 90))
    
    --
    for x=-backgroundSize, backgroundSize do
        for y=-backgroundSize, backgroundSize do
            local blockID = backgroundBlockIds[ math.random( #backgroundBlockIds ) ]
            self.backMap:SetBlockAt(x,y,0, blockID)
        end
    end
end
