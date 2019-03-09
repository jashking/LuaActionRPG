local m = {}

-- parent UObject
local Super = Super

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    local SkipButtonClickedDelegate = CreateFunctionDelegate(Super,
        function ()
            local GameplayStatics = LoadClass('GameplayStatics')
            local PlayerController = GameplayStatics:GetPlayerController(Super, 0):CastToLua()
            
            PlayerController:StopPlayingSkippableCutscene()
            Super:RemoveFromParent()
        end)
    
    Super.SkipButton.OnClicked:Add(SkipButtonClickedDelegate)

    Super:PlayAnimation(Super.SkipTextAnim, 0, 0, Common.EUMGSequencePlayMode.Forward, 0.5)
end

return m