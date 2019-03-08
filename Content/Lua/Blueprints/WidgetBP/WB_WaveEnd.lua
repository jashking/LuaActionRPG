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

    Super.WaveText:SetText(string.format('WAVE %d COMPLETE', GameMode.CurrentWave))

    Super:PlayAnimation(Super.Anim_WaveComplete, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    self.FadeOutDelegate = self.FadeOutDelegate or CreateFunctionDelegate(Super,
        function()
            Super:RemoveFromParent()
        end)

    BlueluaLibrary:Delay(Super, Super.Anim_WaveComplete:GetEndTime(), -1, self.FadeOutDelegate)
end

return m