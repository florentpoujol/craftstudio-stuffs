--[[PublicProperties
SceneToLoadName string ""
Delay number 3
/PublicProperties]]

function Behavior:Awake()
    self.wheel = CS.FindGameObject( "Wheel" )
    self.camera = CS.FindGameObject( "Camera" )
    self.fadeOut = CS.FindGameObject( "FadeOut" )
    self.timer = 0
end

function Behavior:Update()
    if CS.Input.WasButtonJustPressed( "Escape" ) then
        CS.LoadScene("Main Menu")
        return
    end

    --if self.timer > self.Delay then return end
    
    self.timer = self.timer + 1 / 60
       
    self.wheel.transform:RotateEulerAngles( Vector3:New( 0, 0, -1 )  )
    
    if self.timer < 1 then
        self.camera.transform:Move( Vector3:New( 0, 0, 2 ))
    end
    
    if self.timer > self.Delay - 0.5 then
        self.fadeOut.modelRenderer:SetOpacity( self.fadeOut.modelRenderer:GetOpacity() + 1/30 )
    end
    
    if self.timer > self.Delay then
        local scene = CS.FindAsset( self.SceneToLoadName, "Scene" )
        if scene ~= nil then
            CS.LoadScene( scene )
        else
            print( "Scene '" .. self.SceneToLoadName .. "' was not found !" )
        end
    end
end
