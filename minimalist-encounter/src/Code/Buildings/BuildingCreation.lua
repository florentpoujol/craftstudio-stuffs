-- ScriptedBehavior on the player Camera
-- Handle the building placeholder

function Behavior:Start()
    Daneel.Event.Listen("OnLeftMouseButtonJustPressed", self.gameObject)
    Daneel.Event.Listen("OnRightMouseButtonJustPressed", self.gameObject)
    Daneel.Event.Listen("OnPlayerSelectedHudBuilding", self.gameObject)
    Daneel.Event.Listen("ToggleMenu", function() self:HidePlaceholderGO() end)
    
    self.placeholderGO = GameObject.New("PlaceholderBuilding", { 
        modelRenderer = {},
        rangeScript = {}
    })
    
    self.displayPlaceholder = false
    self.buildingType = ""
end


function Behavior:Update()
    if not self.displayPlaceholder or Game.showMenu then
        return
    end
    
    local ray = self.gameObject.camera:CreateRay(CS.Input.GetMousePosition())
    local distance = ray:IntersectsPlane(Game.mapPlane)
    if distance ~= nil then
        local newPosition = ray.position + ray.direction * distance
        newPosition.y = 2
        self.placeholderGO.transform.position = newPosition
    end
end


-- When the player clicked on a building model on the HUD
function Behavior:OnPlayerSelectedHudBuilding(data)
    self.buildingType = data[1]
    self.placeholderGO.modelRenderer.model = "Buildings/" .. self.buildingType
    self.placeholderGO.modelRenderer.opacity = 1
    self.placeholderGO.rangeScript:UpdateRange(true, self.buildingType)
    self.displayPlaceholder = true
end


-- Player clicked the left mouse button to place the building
function Behavior:OnLeftMouseButtonJustPressed()
    if 
        self.displayPlaceholder and
        not Game.showMenu and
        not Game.hudBackground.isMouseOver
    then
        GameObject.New( "Prefabs/" .. self.buildingType, {
            transform = { 
                position = self.placeholderGO.transform.position
            }
        })
    end
end


-- Player clicked the right mouse button to discard the placeholder
function Behavior:OnRightMouseButtonJustPressed()
    self:HidePlaceholderGO()
end


function Behavior:HidePlaceholderGO()
    self.displayPlaceholder = false
    self.placeholderGO.modelRenderer.opacity = 0
    self.placeholderGO.rangeScript:UpdateRange(false)
end
