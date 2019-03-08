local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    self.CloseButtonClickedDelegate = self.CloseButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnCloseButtonClicked)
    self.OptionsButtonClickedDelegate = self.OptionsButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnOptionsButtonClicked)
    self.MainMenuButtonClickedDelegate = self.MainMenuButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnMainMenuButtonClicked)

    Super.CloseButton.OnClicked:Add(self.CloseButtonClickedDelegate)
    Super.OptionsButton.OnClicked:Add(self.OptionsButtonClickedDelegate)
    Super.MainMenuButton.OnClicked:Add(self.MainMenuButtonClickedDelegate)
end

function m:OnCloseButtonClicked()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Reverse, 1)

    self.FadeOutDelegate = self.FadeOutDelegate or CreateFunctionDelegate(Super,
        function()
            local GameMode = GameplayStatics:GetGameMode(Super):CastToLua()
            GameMode:PauseGame()
            
            Super:RemoveFromParent()
        end)

    BlueluaLibrary:Delay(Super, Super.FadeAnimation:GetEndTime(), -1, self.FadeOutDelegate)
end

function m:OnOptionsButtonClicked()
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBOptionsScreenClass = LoadClass('/Game/Blueprints/WidgetBP/WB_OptionsScreen.WB_OptionsScreen_C')
    local OptionsScreen = WidgetBlueprintLibrary:Create(Super, WBOptionsScreenClass, nil)
    OptionsScreen:AddToViewport(0)
end

function m:OnMainMenuButtonClicked()
    GameplayStatics:OpenLevel(Super, 'ActionRPG_Main', true, nil)
end

return m