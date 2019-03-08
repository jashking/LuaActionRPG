local m = {}

-- parent UObject
local Super = Super

local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    local GameMode = GameplayStatics:GetGameMode(Super)

    Super.WaveText:SetText(string.format('WAVE %d', GameMode.CurrentWave))

    Super:PlayAnimation(Super.NewWaveAppear, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    self.FadeOutDelegate = self.FadeOutDelegate or CreateFunctionDelegate(Super,
        function()
            Super:RemoveFromParent()
        end)

    KismetSystemLibrary:Delay(Super, Super.NewWaveAppear:GetEndTime(), CreateLatentAction(self.FadeOutDelegate))
end

return m