local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadObject = LoadObject
local CreateFunctionDelegate = CreateFunctionDelegate
local DeleteFunctionDelegate = DeleteFunctionDelegate

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

function m:ReceiveBeginPlay()
    self:PlayDefaultIntroCutscene()
end

function m:PlayDefaultIntroCutscene()
    OutActors = GameplayStatics:GetAllActorsOfClass(Super, LoadClass('LevelSequenceActor'), {})
    if OutActors[1] then
        local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
        PlayerController:CastToLua():PlaySkippableCutscene(OutActors[1].SequencePlayer)
    else
        self:StartGame()
    end
end

function m:StartGame()
    if not Super.bGameInProgress then
        Super.bGameInProgress = true
        Super:RestartPlayer(GameplayStatics:GetPlayerController(Super, 0))
        self:StartPlayTimer()
        Super:StartEnemySpawn()
    end
end

function m:StartPlayTimer()
    self.PlayTimerDelegate = self.PlayTimerDelegate or CreateFunctionDelegate(Super, self, self.UpdatePlayTime)
    KismetSystemLibrary:K2_SetTimerDelegate(self.PlayTimerDelegate, 1, true)
    Super.StartTime = GameplayStatics:GetTimeSeconds(Super)
end

function m:UpdatePlayTime()
    Super.BattleTime = Super.BattleTime - 1

    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    PlayerController.OnScreenControls:UpdateTimer(Super.BattleTime)

    if Super.BattleTime <= 0 then
        self:GameOver()
    end
end

--[[
function m:StartEnemySpawn()
    BlueluaLibrary:Delay(Super, 1, -1, CreateFunctionDelegate(Super, self, self.StartNewWave))
end

function m:StartNewWave()
    local DataTableFunctionLibrary = LoadClass('DataTableFunctionLibrary')

    local WavesStruct = loadStruct('/Game/Blueprints/Progression/WavesStruct.WavesStruct')
    local WavesProgression = LoadObject(Super, '/Game/Blueprints/Progression/WavesProgression.WavesProgression')

    local wave = WavesStruct()
    result, row = BlueluaLibrary:GetDataTableRowFromName(WavesProgression, 'Wave_' .. Super.CurrentWave, wave)
end
--]]

function m:PauseGame()
    if GameplayStatics:IsGamePaused(Super) then
        GameplayStatics:SetGamePaused(Super, false)
    else
        local WBPauseMenuClass = LoadClass('/Game/Blueprints/WidgetBP/WB_PauseMenu.WB_PauseMenu_C')
        local PauseMenu = WidgetBlueprintLibrary:Create(Super, WBPauseMenuClass, GameplayStatics:GetPlayerController(Super, 0))
        PauseMenu:AddToViewport(0)
        GameplayStatics:SetGamePaused(Super, true)
    end
end

function m:GameOver()
    GameplayStatics:SetGlobalTimeDilation(Super, 0.25)
    
    if self.PlayTimerDelegate then
        KismetSystemLibrary:K2_ClearTimerDelegate(self.PlayTimerDelegate)
        DeleteFunctionDelegate(self.PlayTimerDelegate)
        self.PlayTimerDelegate = nil
    end

    local ShowResultUIDelegate = CreateFunctionDelegate(Super,
        function()
            GameplayStatics:SetGlobalTimeDilation(Super, 1)
            GameplayStatics:SetGamePaused(Super, true)

            if not Super.ResultUI then
                local WBInGameFinishClass = LoadClass('/Game/Blueprints/WidgetBP/WB_InGame_Finish.WB_InGame_Finish_C')
                Super.ResultUI = WidgetBlueprintLibrary:Create(Super, WBInGameFinishClass, nil)
            end

            Super.ResultUI:AddToViewport(0)
        end)

    BlueluaLibrary:Delay(Super, 0.5, -1, ShowResultUIDelegate)
end

function m:GoHome()
    GameplayStatics:OpenLevel(Super, 'ActionRPG_Main', true, nil)
end

return m