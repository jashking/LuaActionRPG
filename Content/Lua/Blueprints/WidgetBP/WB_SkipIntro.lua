local m = {}

-- parent UObject
local Super = Super

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super.SkipButton.OnClicked:Add(
        function ()
            local GameplayStatics = LoadClass('GameplayStatics')
            local PlayerController = GameplayStatics:GetPlayerController(Super, 0):ToLuaObject()
            
            PlayerController:StopPlayingSkippableCutscene()
            Super:RemoveFromParent()
        end)

    Super:PlayAnimation(Super.SkipTextAnim, 0, 0, Common.EUMGSequencePlayMode.Forward, 0.5)
end

return m