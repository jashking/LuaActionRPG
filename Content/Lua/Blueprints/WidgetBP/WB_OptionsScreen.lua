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

    local GameInstance = GameplayStatics:GetGameInstance(Super)
    Super.CurrentOptions = GameInstance:GetGlobalOptions(nil)

    Super.ClearSaveButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnClearSaveButtonClicked))
    Super.DocsButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnDocsButtonClicked))
    Super.RateButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnRateButtonClicked))
    Super.CloseButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnCloseButtonClicked))

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

    local FadeOutDelegate = CreateFunctionDelegate(Super,
        function()
            Super.CurrentOptions.bMusic = Super.Music_Checkbox:IsChecked()
            Super.CurrentOptions.bSoundFX = Super.SFX_Checkbox:IsChecked()
            Super.CurrentOptions.bVibration = true
            Super.CurrentOptions.bCameraShake = true

            local GameInstance = GameplayStatics:GetGameInstance(Super)
            GameInstance:SetGlobalOptions(Super.CurrentOptions, false)

            Super:RemoveFromParent()
        end)

    BlueluaLibrary:Delay(Super, Super.FadeAnimation:GetEndTime(), -1, FadeOutDelegate)
end

return m