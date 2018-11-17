local m = {}

-- parent UObject
local Super = Super

function m:Construct()
    Super.SkipButton.OnClicked:Add(
        function ()
            local BlueluaLibrary = LoadClass('BlueluaLibrary')
            local GameplayStatics = LoadClass('GameplayStatics')
            
            local WorldContextObject = BlueluaLibrary:GetWorldContext()
            local PlayerController = GameplayStatics:GetPlayerController(WorldContextObject, 0):ToLuaObject()
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