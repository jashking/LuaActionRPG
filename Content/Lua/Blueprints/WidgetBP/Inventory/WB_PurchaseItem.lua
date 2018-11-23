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
    Super.ItemIcon:SetBrush(Super.ItemClass.ItemIcon)
    Super.ItemNameLabel:SetText(Super.ItemClass.ItemName)
    Super.DescriptionLabel:SetText(Super.ItemClass.ItemDescription)
    Super.PriceLabel:SetText(string.format('%d souls', Super.ItemClass.Price))

    Super.InventoryButton.OnClicked:Add(self, self.OnInventoryButtonClicked)
end

function m:OnInventoryButtonClicked()
    local WBPurchaseConfirmClass = LoadClass('/Game/Blueprints/WidgetBP/Inventory/WB_PurchaseConfirm.WB_PurchaseConfirm_C')
    local OriginalItemType = WBPurchaseConfirmClass.ItemType

    WBPurchaseConfirmClass.ItemType = Super.ItemClass

    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBPurchaseConfirm = WidgetBlueprintLibrary:Create(Super, WBPurchaseConfirmClass, nil)
    WBPurchaseConfirmClass.ItemType = OriginalItemType
    WBPurchaseConfirm:AddToViewport(0)

    WBPurchaseConfirm:ToLuaObject().OnClickedConfirm = self.OnClickedConfirm
end

function m:OnClickedConfirm()
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    local bPurchaseResult = PlayerController:PurchaseItem(Super.ItemClass)
    if bPurchaseResult then
        print('Purchase: Purchase was sucesfull')

        local OwningList = Super.OwningList
        OwningList.EquipmentButton:UpdateEquipmentSlot(Super.ItemClass)
        OwningList:CloseList()
    else
        print("Can't touch this...")
    end
end

return m