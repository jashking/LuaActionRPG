local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    local GameInstance = GameplayStatics:GetGameInstance(Super)
    Super.CurrentOptions = GameInstance:GetGlobalOptions(nil)

    self.ClearSaveButtonClickedDelegate = self.ClearSaveButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnClearSaveButtonClicked)
    self.DocsButtonClickedDelegate = self.DocsButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnDocsButtonClicked)
    self.RateButtonClickedDelegate = self.RateButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnRateButtonClicked)
    self.CloseButtonClickedDelegate = self.CloseButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnCloseButtonClicked)

    Super.ClearSaveButton.OnClicked:Add(self.ClearSaveButtonClickedDelegate)
    Super.DocsButton.OnClicked:Add(self.DocsButtonClickedDelegate)
    Super.RateButton.OnClicked:Add(self.RateButtonClickedDelegate)
    Super.CloseButton.OnClicked:Add(self.CloseButtonClickedDelegate)

    self:SetupUI()
end

function m:SetupUI()
    Super.Music_Checkbox:SetIsChecked(Super.CurrentOptions.bMusic)
    Super.SFX_Checkbox:SetIsChecked(Super.CurrentOptions.bSoundFX)
    --Super.Vibration_Checkbox:SetIsChecked(Super.CurrentOptions.bVibration)
    --Super.Shake_Checkbox:SetIsChecked(Super.CurrentOptions.bCameraShake)

    local PlayerController = GameplayStatics:GetPlayerController(Super, 0):CastToLua()
    Super.ClearSaveButton:SetIsEnabled((PlayerController == nil) and true or false)
end

function m:OnClearSaveButtonClicked()
    local GameInstance = GameplayStatics:GetGameInstance(Super)
    GameInstance:ClearSaveData()
end

function m:OnDocsButtonClicked()
    KismetSystemLibrary:LaunchURL('https://docs.unrealengine.com/en-US/Resources/SampleGames/ARPG')
end

function m:OnRateButtonClicked()
    local PlatformName = GameplayStatics:GetPlatformName()
    if PlatformName == 'IOS' then
        KismetSystemLibrary:LaunchURL('https://itunes.apple.com/us/developer/unreal-engine/id382856483?mt=8')
    elseif PlatformName == 'Android' then
        KismetSystemLibrary:LaunchURL('https://play.google.com/store/apps/developer?id=Unreal+Engine')
    elseif PlatformName == 'Windows' then
        KismetSystemLibrary:LaunchURL('https://docs.unrealengine.com/en-US/Resources/SampleGames/ARPG')
    end
end

function m:OnCloseButtonClicked()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Reverse, 1)

    self.FadeOutDelegate = self.FadeOutDelegate or CreateFunctionDelegate(Super,
        function()
            Super.CurrentOptions.bMusic = Super.Music_Checkbox:IsChecked()
            Super.CurrentOptions.bSoundFX = Super.SFX_Checkbox:IsChecked()
            Super.CurrentOptions.bVibration = true
            Super.CurrentOptions.bCameraShake = true

            local GameInstance = GameplayStatics:GetGameInstance(Super)
            GameInstance:SetGlobalOptions(Super.CurrentOptions, false)

            Super:RemoveFromParent()
        end)

    KismetSystemLibrary:Delay(Super, Super.FadeAnimation:GetEndTime(), CreateLatentAction(self.FadeOutDelegate))
end

return m