--[[PublicProperties
backgroundv2 boolean False
/PublicProperties]]
-- code from Silhouette

function Behavior:Awake()
    self.maskGO = self.gameObject:GetChild("Mask")
--    self.gameObject.transform.localScale = Vector3(70,70,1) -- 60 is enought
    
    local camGO = GameObject.Get( "Background Camera" )
    self.gameObject.parent = camGO
    
    
    if self.backgroundv2 then
        self.gameObject.transform.localPosition = Vector3(0,0,-50)
        self.gameObject.transform.localScale = Vector3(60,30,1) 
        
        self.frontGO = self.gameObject:GetChild("Front")
        self.backGO = self.gameObject:GetChild("Back")
        
        -- randomize the starting color
        local backColorId = math.random( 1, #AllowedConnectionsByColor.White )
        local frontColorId = backColorId - 1
        if frontColorId == 0 then
            frontColorId = #AllowedConnectionsByColor.White
        end
        
        self.frontGO.modelRenderer.model = "Dots/"..AllowedConnectionsByColor.White[frontColorId]
        self.backGO.modelRenderer.model = "Dots/"..AllowedConnectionsByColor.White[backColorId]
        
        self.nextColorId = backColorId + 1
        if self.nextColorId > #AllowedConnectionsByColor.White then
            self.nextColorId = 1
        end
        
        self.frontGO:Animate("opacity", 0, 6, {
            loops = -1,
            OnLoopComplete = function(t)
                self.frontGO.modelRenderer.model = self.backGO.modelRenderer.model
                self.backGO.modelRenderer.model = "Dots/"..AllowedConnectionsByColor.White[self.nextColorId]

                self.nextColorId = self.nextColorId + 1
                if self.nextColorId > #AllowedConnectionsByColor.White then
                    self.nextColorId = 1
                end
            end,
        } )

    else
        self.backGO = self.gameObject:GetChild("Map")
        self.backGO.mapRenderer:LoadNewMap( function( map )
            self.backMap = map
            self:Init()
        end )
    end
end


local backgroundBlockIds = { 0,1,2,3,4,5,6 }
local backgroundSize = 30 -- half-width of the background, in number of map block
--22*22=484
--25*25=625

function Behavior:Init()
    -- position the backgrounds at the center of the screen
    
    
    self.gameObject.transform.eulerAngles = Vector3(0,0, math.randomrange(-90, 90))
    
    --
    for x=-backgroundSize, backgroundSize do
        for y=-backgroundSize, backgroundSize do
            local blockID = backgroundBlockIds[ math.random( #backgroundBlockIds ) ]
            self.backMap:SetBlockAt(x,y,0, blockID)
        end
    end
end
