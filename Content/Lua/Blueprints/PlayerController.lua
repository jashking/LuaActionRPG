local m = {}

local Super = Super
local loadClass = loadClass
local loadObject = loadObject
local createDelegate = createDelegate
local createLatentAction = createLatentAction

local GameplayStatics = loadClass('GameplayStatics')
local BlueluaLibrary = loadClass('BlueluaLibrary')
local KismetSystemLibrary = loadClass('KismetSystemLibrary')

local WorldContextObject = BlueluaLibrary:GetWorldContext()

function m:PlaySkippableCutscene(SequencePlayer)
    Super.SequencePlayer = SequencePlayer

    SequencePlayer.OnFinished:Add(self, self.StopPlayingSkippableCutscene)
    SequencePlayer:Play()

    local WidgetBlueprintLibrary = loadClass('WidgetBlueprintLibrary')
    local WBSkipIntroClass = loadClass('/Game/Blueprints/WidgetBP/WB_SkipIntro.WB_SkipIntro_C')
    self.SkipIntroWidget = WidgetBlueprintLibrary:Create(WorldContextObject, WBSkipIntroClass, Super)
    self.SkipIntroWidget:AddToViewport(0)
    Super:ShowHUD(false)
end

function m:StopPlayingSkippableCutscene()
    if self.StopPlayingSkippableCutsceneOnce then
        return
    end
    self.StopPlayingSkippableCutsceneOnce = true

    Super.SequencePlayer:Stop()
    Super:ShowHUD(true)

    local GameMode = GameplayStatics:GetGameMode(WorldContextObject)
    GameMode:ToLuaObject():StartGame()

    self.SkipIntroWidget:RemoveFromParent()
    self.SkipIntroWidget = nil
end

return m