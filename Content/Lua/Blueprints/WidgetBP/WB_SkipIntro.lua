local m = {}

-- parent UObject
local Super = Super

function m:Construct()
    Super.SkipButton.OnClicked:Add(
        function ()
            local GameplayStatics = LoadClass('GameplayStatics')
            local PlayerController = GameplayStatics:GetPlayerController(Super, 0):ToLuaObject()
            
            PlayerController:StopPlayingSkippableCutscene()
            Super:RemoveFromParent()
        end)

    --TODO: move to common lua
    local EUMGSequencePlayMode = {
        Forward = 0,
        Reverse = 1,
        PingPong = 2,
    }
    
    Super:PlayAnimation(Super.SkipTextAnim, 0, 0, EUMGSequencePlayMode.Forward, 0.5)
end

return m