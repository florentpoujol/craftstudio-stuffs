
function Behavior:Start()
    self.rangeGO = GameObject.New("Range", {
        parent = self.gameObject,
        transform = { position = self.gameObject.transform.position },
        modelRenderer = { model = "Range" },
    })
end


-- Hide/Show the range and updte its radius based on the building's range
function Behavior:UpdateRange(showRange, buildingType)
    if showRange == true then
        local range = Game[buildingType].range * 2
        self.rangeGO.transform.localScale = Vector3:New(range, 1, range)
        self.rangeGO.modelRenderer.opacity = 0.5
    else
        self.rangeGO.modelRenderer.opacity = 0
    end
end
