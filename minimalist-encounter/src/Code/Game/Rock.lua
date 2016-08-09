
function Behavior:Awake()
    -- pick a random orientation
    local newAngle = math.randomrange(0, 360)
    local currentAngles = self.gameObject.transform.localEulerAngles
    self.gameObject.transform.localEulerAngles = Vector3(currentAngles.x, newAngle, currentAngles.z)
        
    -- pick a random scale
    self.gameObject.transform.localScale = Vector3( math.randomrange(0.5, 1.5) )
    
    self.gameObject.isDestroyed = false
end


-- called by the harvester
function Behavior:Harvest(amount)
    if self.gameObject == nil then return 0 end -- prevent a bug 
    
    local scale = self.gameObject.transform.localScale.x
    local ressources = scale * Game.rock.scaleToRessourceRatio

    -- not enough ressource on the rock
    -- return the ressources left and destroy the rock
    if ressources < amount then
        self.gameObject:Destroy()
        return ressources
    end
    
    ressources = ressources - amount
    self.gameObject.transform.localScale = Vector3:New(ressources / Game.rock.scaleToRessourceRatio)
    return amount
end
