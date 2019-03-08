local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadObject = LoadObject
local CreateFunctionDelegate = CreateFunctionDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super.QuitGameButton:SetVisibility(Common:IsRunningOnMobile() and Common.ESlateVisibility.Collapsed or Common.ESlateVisibility.Visible)
    Super:PlayAnimation(Super.TitleAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    self.PlaySoundDelegate = self.PlaySoundDelegate or CreateFunctionDelegate(Super, self,
        function()
            if not self.BossBattle or not self.BossBattle:IsValid() then
                self.BossBattle = LoadObject(Super, '/Game/Assets/Sounds/Music/Ice_BossBattle01_Cue.Ice_BossBattle01_Cue')
            end

            GameplayStatics:PlaySound2D(Super, self.BossBattle, 1, 1, 0, nil, nil)
        end)

    KismetSystemLibrary:Delay(Super, 3, CreateLatentAction(self.PlaySoundDelegate))

    self.QuitGameButtonClickedDelegate = self.QuitGameButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnQuitGameButtonClicked)
    self.StartGameButtonClickedDelegate = self.StartGameButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnStartGameButtonClicked)
    self.OptionsButtonClickedDelegate = self.OptionsButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnOptionsButtonClicked)

    Super.QuitGameButton.OnClicked:Add(self.QuitGameButtonClickedDelegate)
    Super.StartGameButton.OnClicked:Add(self.StartGameButtonClickedDelegate)
    Super.OptionsButton.OnClicked:Add(self.OptionsButtonClickedDelegate)
end

function m:OnStartGameButtonClicked()
    if not self.UI_Select or not self.UI_Select:IsValid() then
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