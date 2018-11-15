local m = {}

local Super = Super
local LoadClass = LoadClass

local GameplayStatics = LoadClass('GameplayStatics')
local BlueluaLibrary = LoadClass('BlueluaLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

local WorldContextObject = BlueluaLibrary:GetWorldContext()

function m:PlaySkippableCutscene(SequencePlayer)
    Super.SequencePlayer = SequencePlayer

    SequencePlayer.OnFinished:Add(self, self.StopPlayingSkippableCutscene)
    SequencePlayer:Play()

    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBSkipIntroClass = LoadClass('/Game/Blueprints/WidgetBP/WB_SkipIntro.WB_SkipIntro_C')
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