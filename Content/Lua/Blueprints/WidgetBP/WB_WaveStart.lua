local m = {}

-- parent UObject
local Super = Super

local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    local GameMode = GameplayStatics:GetGameMode(Super)

    Super.WaveText:SetText(string.format('WAVE %d', GameMode.CurrentWave))

    Super:PlayAnimation(Super.NewWaveAppear, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    BlueluaLibrary:Delay(Super, Super.NewWaveAppear:GetEndTime(), -1, CreateFunctionDelegate(Super, function() Super:RemoveFromParent() end))
end

return m