local m = {}

-- parent UObject
local Super = Super
local LoadClass = LoadClass

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    local GameMode = GameplayStatics:GetGameMode(Super)

    Super.WaveText:SetText(string.format('WAVE %d COMPLETE', GameMode.CurrentWave))

    Super:PlayAnimation(Super.Anim_WaveComplete, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            Super:RemoveFromParent()
        end))

    KismetSystemLibrary:Delay(Super, Super.Anim_WaveComplete:GetEndTime(), LatentActionInfo)
end

return m