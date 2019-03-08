local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)

    self.BackButtonClickedDelegate = self.BackButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnBackButtonClicked)
    Super.BackButton.OnClicked:Add(self.BackButtonClickedDelegate)
end

function m:OnBackButtonClicked()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Reverse, 1)

    self.ShowInventoryUIDelegate = self.ShowInventoryUIDelegate or CreateFunctionDelegate(Super,
        function()
            local PlayerController = GameplayStatics:GetPlayerController(Super, 0):CastToLua()
            if PlayerController then
                PlayerController:ShowInventoryUI()
            end
        end)

    KismetSystemLibrary:Delay(Super, 0.5, CreateLatentAction(self.ShowInventoryUIDelegate))
end

return m