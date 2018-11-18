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
local BlueluaLibrary = LoadClass('BlueluaLibrary')

--TODO: move to common lua
local EUMGSequencePlayMode = {
    Forward = 0,
    Reverse = 1,
    PingPong = 2,
}

function m:Construct()
    self:SetupItemsList()
    Super:PlayAnimation(Super.SwipeInAnimation, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function m:SetupItemsList()
    Super:AddInventoryItemsToList()
    self:AddStoreItemsToList()
    Super.ListTypeLabel:SetText(Super.ItemType.Name)
end

function m:AddInventoryItemsToList_todo()
end

function m:AddStoreItemsToList()
    local GameInstance = GameplayStatics:GetGameInstance(Super):ToLuaObject()
    if not GameInstance then
        return
    end

    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBPurchaseItemClass = LoadClass('/Game/Blueprints/WidgetBP/Inventory/WB_PurchaseItem.WB_PurchaseItem_C')
    local OriginalDefaultItemClass = WBPurchaseItemClass.ItemClass
    local OriginalDefaultOwningList = WBPurchaseItemClass.OwningList

    local Items = GameInstance:GetStoreItems(Super.ItemType)
    for _, Item in ipairs(Items) do
        if PlayerController:GetInventoryItemCount(Item) <= 0 then
            WBPurchaseItemClass.ItemClass = Item
            WBPurchaseItemClass.OwningList = Super
            local PurchaseItem = WidgetBlueprintLibrary:Create(Super, WBPurchaseItemClass, nil)
            Super.ItemsBox:AddChild(PurchaseItem)
        end
    end

    WBPurchaseItemClass.ItemClass = OriginalDefaultItemClass
    WBPurchaseItemClass.OwningList = OriginalDefaultOwningList
end

return m