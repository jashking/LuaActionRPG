local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Forward, 2)

    local WBPurchaseItemClass = LoadClass('/Game/Blueprints/WidgetBP/Inventory/WB_PurchaseItem.WB_PurchaseItem_C')
    local OriginalItemClass = WBPurchaseItemClass.ItemClass

    WBPurchaseItemClass.ItemClass = Super.ItemType
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local PurchaseItem = WidgetBlueprintLibrary:Create(Super, WBPurchaseItemClass, nil)

    WBPurchaseItemClass.ItemClass = OriginalItemClass

    Super.IconSlot:AddChild(PurchaseItem)
    
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    Super.ConfirmButton:SetIsEnabled(PlayerController:CastToLua():CanPurchaseItem(Super.ItemType))

    Super.CancelButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnCancelButtonClicked))
    Super.ConfirmButton.OnClicked:Add(CreateFunctionDelegate(Super, self, self.OnConfirmButtonClicked))
end

function m:OnCancelButtonClicked()
    self:FadeOut()
end

function m:OnConfirmButtonClicked()
    if self.OnClickedConfirm then
        self.OnClickedConfirm()
    end
    self:FadeOut()
end

function m:FadeOut()
    Super:PlayAnimation(Super.FadeAnimation, 0, 1, Common.EUMGSequencePlayMode.Reverse, 2)

    BlueluaLibrary:Delay(Super, Super.FadeAnimation:GetEndTime(), -1, CreateFunctionDelegate(Super, function() Super:RemoveFromParent() end))
end

return m