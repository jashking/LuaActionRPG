local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadObject = LoadObject
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super.QuitGameButton:SetVisibility(Common:IsRunningOnMobile() and Common.ESlateVisibility.Collapsed or Common.ESlateVisibility.Visible)
    Super:PlayAnimation(Super.TitleAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super, self,
        function()
            if not self.BossBattle then
                self.BossBattle = LoadObject(Super, '/Game/Assets/Sounds/Music/Ice_BossBattle01_Cue.Ice_BossBattle01_Cue')
            end

            GameplayStatics:PlaySound2D(Super, self.BossBattle, 1, 1, 0, nil, nil)
        end))

    KismetSystemLibrary:Delay(Super, 3, LatentActionInfo)

    Super.QuitGameButton.OnClicked:Add(self, self.OnQuitGameButtonClicked)
    Super.StartGameButton.OnClicked:Add(self, self.OnStartGameButtonClicked)
    Super.OptionsButton.OnClicked:Add(self, self.OnOptionsButtonClicked)
end

function m:OnStartGameButtonClicked()
    if not self.UI_Select then
        self.UI_Select = LoadObject(Super, '/Game/Assets/Sounds/UI/A_UI_Select01.A_UI_Select01')
    end

    GameplayStatics:PlaySound2D(Super, self.UI_Select, 1, 1, 0, nil, nil)

    local GameInstance = GameplayStatics:GetGameInstance(Super):CastToLua()
    if GameInstance then
        GameInstance:LoadGameLevel()
    end
end

function m:OnOptionsButtonClicked()
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBOptionsScreenClass = LoadClass('/Game/Blueprints/WidgetBP/WB_OptionsScreen.WB_OptionsScreen_C')
    WBOptionsScreen = WidgetBlueprintLibrary:Create(Super, WBOptionsScreenClass, nil)
    WBOptionsScreen:AddToViewport(0)
end

function m:OnQuitGameButtonClicked()
    KismetSystemLibrary:QuitGame(Super, nil, Common.EQuitPreference.Quit)
end

return m