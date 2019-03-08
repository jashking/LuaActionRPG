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
    local GameMode = GameplayStatics:GetGameMode(Super)
    Super.TotalKillsLabel:SetText(tostring(GameMode.NPCKillsCount))
    Super.TimeBonusLabel:SetText(string.format('%ds', math.floor(GameplayStatics:GetTimeSeconds(Super) - GameMode.StartTime)))

    self:PlayAllAnimations()

    self.RestartButtionClickedDelegate = self.RestartButtionClickedDelegate or CreateFunctionDelegate(Super, self, self.OnRestartButtionClicked)
    self.MainMenuButtonClickedDelegate = self.MainMenuButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnMainMenuButtonClicked)

    Super.RestartButton.OnClicked:Add(self.RestartButtionClickedDelegate)
    Super.MainMenuButton.OnClicked:Add(self.MainMenuButtonClickedDelegate)
end

function m:PlayAllAnimations()
    if self.PlayAllAnimationsOnce then
        return
    end
    self.PlayAllAnimationsOnce = true

    if not self.UI_WaveEnd or not not self.UI_WaveEnd:IsValid() then
        self.UI_WaveEnd = LoadObject(Super, '/Game/Assets/Sounds/UI/A_UI_WaveEnd.A_UI_WaveEnd')
    end

    GameplayStatics:PlaySound2D(Super, self.UI_WaveEnd, 1, 1, 0, nil, nil)
    Super:PlayAnimation(Super.IntroAnim, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    self.PlayBonusAnimDelegate = self.PlayBonusAnimDelegate or CreateFunctionDelegate(Super,
        function()
            Super:PlayAnimation(Super.BonusAnim, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)
        end)

    KismetSystemLibrary:Delay(Super, Super.IntroAnim:GetEndTime(), CreateLatentAction(self.PlayBonusAnimDelegate))
end

function m:OnRestartButtionClicked()
    local GameInstance = GameplayStatics:GetGameInstance(Super):CastToLua()
    if GameInstance then
        GameInstance:RestartGameLevel()
    end

    Super:RemoveFromParent()
    GameplayStatics:SetGamePaused(Super, false)
end

function m:OnMainMenuButtonClicked()
    local GameMode = GameplayStatics:GetGameMode(Super):CastToLua()
    if GameMode then
        GameMode:GoHome()
    end
end

return m