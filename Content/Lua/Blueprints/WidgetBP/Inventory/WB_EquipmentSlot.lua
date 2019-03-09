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
    self:RefreshItem()

    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    PlayerController.OnSlottedItemChanged:Add(CreateFunctionDelegate(Super, self, self.OnSlottedItemChanged))

    Super.SlotTypeLabel:SetText(Super.EquipSlot.ItemType.Name)
    Super.EquipButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnEquipButtonClicked))
end

function m:RefreshItem()
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    local Item = PlayerController:GetSlottedItem(Super.EquipSlot)

    Super.ItemImage:SetBrush(Item and Item.ItemIcon or Super.DefaultBrush)
end

function m:OnSlottedItemChanged(ItemSlot, Item)
    local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')
    if RPGBlueprintLibrary:EqualEqual_RPGItemSlot(ItemSlot, Super.EquipSlot) then
        self:RefreshItem()
    end
end

function m:OnEquipButtonClicked()
    local WBInventoryListClass = LoadClass('/Game/Blueprints/WidgetBP/Inventory/WB_InventoryList.WB_InventoryList_C')
    local OriginalEquipmentButton = WBInventoryListClass.EquipmentButton
    local OriginalItemType = WBInventoryListClass.ItemType

    WBInventoryListClass.EquipmentButton = Super
    WBInventoryListClass.ItemType = Super.EquipSlot.ItemType

    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBInventoryList = WidgetBlueprintLibrary:Create(Super, WBInventoryListClass, nil)
    WBInventoryList:AddToViewport(0)

    WBInventoryListClass.EquipmentButton = OriginalEquipmentButton
    WBInventoryListClass.ItemType = OriginalItemType
end

function m:UpdateEquipmentSlot(Item)
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    PlayerController:SetSlottedItem(Super.EquipSlot, Item)

    self:RefreshItem()

    local GameInstance = GameplayStatics:GetGameInstance(Super)
    GameInstance:WriteSaveGame()
end

return m