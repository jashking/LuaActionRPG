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
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0):ToLuaObject()
    PlayerController.OnSoulsUpdated = self.UpdateSoulsLabel
    self:UpdateSoulsLabel()

    Super.AddSoulsButton.OnClicked:Add(self, self.OnAddSoulsButtonClicked)
end

function m:Destruct()
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    PlayerController = PlayerController and PlayerController:ToLuaObject() or nil
    if PlayerController then
        PlayerController.OnSoulsUpdated = nil
    end
end

function m:UpdateSoulsLabel(NewSoulsValue)
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    if not PlayerController then
        return
    end

    Super.SoulsLabel:SetText(string.format('%d', PlayerController:GetInventoryItemCount(Super.SoulsItem)))
    Super:PlayAnimation(Super.UpdateAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 1)
end

function m:OnAddSoulsButtonClicked()
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    PlayerController:AddInventoryItem(Super.SoulsItem, 50, 1, true)
end

return m