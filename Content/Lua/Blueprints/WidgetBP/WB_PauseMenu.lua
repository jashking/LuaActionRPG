local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

-- world context object
local WorldContextObject = BlueluaLibrary:GetWorldContext()

--TODO: move to common lua
local EUMGSequencePlayMode = {
    Forward = 0,
    Reverse = 1,
    PingPong = 2,
}

function m:Construct()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, EUMGSequencePlayMode.Forward, 1)
    Super.CloseButton.OnClicked:Add(self, self.OnCloseButtonClicked)
    Super.OptionsButton.OnClicked:Add(self, self.OnOptionsButtonClicked)
    Super.MainMenuButton.OnClicked:Add(self, self.OnMainMenuButtonClicked)
end

function m:OnCloseButtonClicked()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, EUMGSequencePlayMode.Reverse, 1)

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            local GameMode = GameplayStatics:GetGameMode(WorldContextObject)
            GameMode:PauseGame()
            
            Super:RemoveFromParent()
        end))

    KismetSystemLibrary:Delay(WorldContextObject, Super.FadeAnimation:GetEndTime(), LatentActionInfo)
end

function m:OnOptionsButtonClicked()
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBOptionsScreenClass = LoadClass('/Game/Blueprints/WidgetBP/WB_OptionsScreen.WB_OptionsScreen_C')
    local OptionsScreen = WidgetBlueprintLibrary:Create(WorldContextObject, WBOptionsScreenClass, nil)
    OptionsScreen:AddToViewport(0)
end

function m:OnMainMenuButtonClicked()
    GameplayStatics:OpenLevel(WorldContextObject, 'ActionRPG_Main', true, nil)
end

return m