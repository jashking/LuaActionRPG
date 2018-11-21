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

function m:ReceiveBeginPlay()
    self:PlayDefaultIntroCutscene()
end

function m:PlayDefaultIntroCutscene()
    OutActors = GameplayStatics:GetAllActorsOfClass(Super, LoadClass('LevelSequenceActor'), {})
    if OutActors[1] then
        local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
        PlayerController:ToLuaObject():PlaySkippableCutscene(OutActors[1].SequencePlayer)
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
    KismetSystemLibrary:K2_SetTimerDelegate(CreateDelegate(Super, self, self.UpdatePlayTime), 1, true)
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
    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super, self, self.StartNewWave))

    KismetSystemLibrary:Delay(Super, 1, LatentActionInfo)
end

function m:StartNewWave()
    local DataTableFunctionLibrary = LoadClass('DataTableFunctionLibrary')

    local WavesStruct = loadStruct('/Game/Blueprints/Progression/WavesStruct.WavesStruct')
    local WavesProgression = LoadObject(Super, '/Game/Blueprints/Progression/WavesProgression.WavesProgression')

    local wave = WavesStruct()
    result, row = BlueluaLibrary:GetDataTableRowFromName(WavesProgression, 'Wave_' .. Super.CurrentWave, wave)
end
--]]

function m:GameOver()
    GameplayStatics:SetGlobalTimeDilation(Super, 0.25)
    
    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            GameplayStatics:SetGlobalTimeDilation(Super, 1)
            GameplayStatics:SetGamePaused(Super, true)

            if not Super.ResultUI then
                local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
                local WBInGameFinishClass = LoadClass('/Game/Blueprints/WidgetBP/WB_InGame_Finish.WB_InGame_Finish_C')
                Super.ResultUI = WidgetBlueprintLibrary:Create(Super, WBInGameFinishClass, nil)
            end

            Super.ResultUI:AddToViewport(0)
        end))

    KismetSystemLibrary:Delay(Super, 0.5, LatentActionInfo)
end

function m:GoHome()
    GameplayStatics:OpenLevel(Super, 'ActionRPG_Main', true, nil)
end

return m