local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)
    Super.BackButton.OnClicked:Add(self, self.OnBackButtonClicked)
end

function m:OnBackButtonClicked()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Reverse, 1)

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            local PlayerController = GameplayStatics:GetPlayerController(Super, 0):CastToLua()
            if PlayerController then
                PlayerController:ShowInventoryUI()
            end
        end))

    KismetSystemLibrary:Delay(Super, 0.5, LatentActionInfo)
end

return m