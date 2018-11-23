local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super.ItemImage:SetBrush(Super.ItemClass.ItemIcon)
    Super.ItemName:SetText(Super.ItemClass.ItemName)
    Super.LongDescription:SetText(Super.ItemClass.ItemDescription)

    Super.InventoryButton.OnClicked:Add(self, self.OnInventoryButtonClicked)
end

function m:OnInventoryButtonClicked()
    local OwningList = Super.OwningList
    OwningList.EquipmentButton:ToLuaObject():UpdateEquipmentSlot(Super.ItemClass)
    OwningList:ToLuaObject():CloseList()

    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    PlayerController:SaveInventory()
end

return m