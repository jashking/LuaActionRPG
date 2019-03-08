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
local KismetMathLibrary = LoadClass('KismetMathLibrary')
local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:PlaySkippableCutscene(SequencePlayer)
    Super.SequencePlayer = SequencePlayer

    self.PlayFinishedDelegate = self.PlayFinishedDelegate or CreateFunctionDelegate(Super, self, self.StopPlayingSkippableCutscene)

    SequencePlayer.OnFinished:Add(self.PlayFinishedDelegate)
    SequencePlayer:Play()

    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBSkipIntroClass = LoadClass('/Game/Blueprints/WidgetBP/WB_SkipIntro.WB_SkipIntro_C')
    self.SkipIntroWidget = WidgetBlueprintLibrary:Create(Super, WBSkipIntroClass, Super)
    self.SkipIntroWidget:AddToViewport(0)
    self:ShowHUD(false)
end

function m:StopPlayingSkippableCutscene()
    if self.StopPlayingSkippableCutsceneOnce then
        return
    end
    self.StopPlayingSkippableCutsceneOnce = true

    Super.SequencePlayer:Stop()
    self:ShowHUD(true)

    local GameMode = GameplayStatics:GetGameMode(Super)
    GameMode:CastToLua():StartGame()

    self.SkipIntroWidget:RemoveFromParent()
    self.SkipIntroWidget = nil
end

function m:ShowHUD(bShow)
    local bRunningOnMobile = Common:IsRunningOnMobile()
    Super:SetVirtualJoystickVisibility(bShow and bRunningOnMobile)

    if Super.OnScreenControls then
        local ESlateVisibility = Common.ESlateVisibility
        Super.OnScreenControls:SetVisibility(bShow and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Hidden)
    end
end

function m:CreateHUD()
    if Super.OnScreenControls then
        self:ShowHUD(true)
        return
    end
    
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBOnScreenControlsClass = LoadClass('/Game/Blueprints/WidgetBP/WB_OnScreenControls.WB_OnScreenControls_C')
    Super.OnScreenControls = WidgetBlueprintLibrary:Create(Super, WBOnScreenControlsClass, Super)
    Super.OnScreenControls:AddToViewport(0)
    Super.OnScreenControls:CastToLua():UpdateCurrentIcons()
end

function m:ReceivePossess(NewPawn)
    if self.ReceivePossessOnce then
        return
    end
    self.ReceivePossessOnce = true

    Super.PlayerCharacter = NewPawn
    self:CreateHUD()

    self.InventoryItemChangedDelegate = self.InventoryItemChangedDelegate or CreateFunctionDelegate(Super, self, self.OnInventoryItemChanged)
    Super.OnInventoryItemChanged:Add(self.InventoryItemChangedDelegate)

    self.CreateAllWeaponsDelegate = self.CreateAllWeaponsDelegate or CreateFunctionDelegate(Super,
        function()
            Super.PlayerCharacter:CastToLua():CreateAllWeapons()
        end)

    KismetSystemLibrary:Delay(Super, 0.025, CreateLatentAction(self.CreateAllWeaponsDelegate))
end

function m:OnInventoryItemChanged(bAdded, Item)
    if KismetMathLibrary:EqualEqual_ObjectObject(Super.SoulsItem, Item) and self.OnSoulsUpdated then
        self.OnSoulsUpdated(nil, Super:GetInventoryItemCount(Super.SoulsItem))
    end
end

function m:ReceiveTick(DeltaSeconds)
    local GameMode = GameplayStatics:GetGameMode(Super)
    local ControlledPawn = Super:K2_GetPawn()
    if GameMode.bAutoBattleMode or not ControlledPawn or Super.bBlockedMovement then
        return
    end

    if ControlledPawn.Mesh:GetAnimInstance():IsAnyMontagePlaying() then
        local MovingVector = KismetMathLibrary:MakeVector(Super:GetInputAxisValue('MoveForward'), Super:GetInputAxisValue('MoveRight'), 0)

        if KismetMathLibrary:VSize(MovingVector) > 0 then
            local CameraRotation = Super.PlayerCameraManager:GetCameraRotation()
            local NewRotation = KismetMathLibrary:NormalizedDeltaRotator(KismetMathLibrary:MakeRotFromX(MovingVector), KismetMathLibrary:MakeRotator(0, 0, CameraRotation.Yaw - 1))
            ControlledPawn:K2_SetActorRotation(NewRotation, false)
        end
    else
        local CameraRotation = Super.PlayerCameraManager:GetCameraRotation()

        ControlledPawn:AddMovementInput(KismetMathLibrary:GetForwardVector(CameraRotation), Super:GetInputAxisValue('MoveForward'), false)
        ControlledPawn:AddMovementInput(KismetMathLibrary:GetRightVector(CameraRotation), Super:GetInputAxisValue('MoveRight'), false)
    end
end

function m:ReceiveBeginPlay()
    local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')

    self.RotateCameraDelegate = self.RotateCameraDelegate or CreateFunctionDelegate(Super, function(AxisValue) Super:AddYawInput(AxisValue) end)
    self.TouchPressedDelegate = self.TouchPressedDelegate or CreateFunctionDelegate(Super, self, self.OnTouchPressed)
    self.TouchRepeatedDelegate = self.TouchRepeatedDelegate or CreateFunctionDelegate(Super, self, self.OnTouchRepeated)
    self.TouchReleasedDelegate = self.TouchReleasedDelegate or CreateFunctionDelegate(Super, self, self.OnTouchReleased)

    RPGBlueprintLibrary:BindAxisAction(Super, 'MoveForward', nil)
    RPGBlueprintLibrary:BindAxisAction(Super, 'MoveRight', nil)
    RPGBlueprintLibrary:BindAxisAction(Super, 'RotateCamera', self.RotateCameraDelegate)

    local EInputEvent = Common.EInputEvent
    RPGBlueprintLibrary:BindTouchAction(Super, EInputEvent.IE_Pressed, self.TouchPressedDelegate)
    RPGBlueprintLibrary:BindTouchAction(Super, EInputEvent.IE_Repeat, self.TouchRepeatedDelegate)
    RPGBlueprintLibrary:BindTouchAction(Super, EInputEvent.IE_Released, self.TouchReleasedDelegate)
end

function m:OnTouchPressed(FingerIndex, Location)
    Super.XPos = Location.X
    Super.bCanRotate = true
end

function m:OnTouchRepeated(FingerIndex, Location)
    if not Super.bCanRotate then
        return
    end

    local ControlRotation = Super:GetControlRotation()
    Super:SetControlRotation(KismetMathLibrary:MakeRotator(0, 0, (Location.X - Super.XPos) * 0.25 + ControlRotation.Yaw))
    Super.XPos = Location.X
end

function m:OnTouchReleased(FingerIndex, Location)
    Super.bCanRotate = false
end

function m:ShowInventoryUI()
    self.SlottedItemChangedDelegate = self.SlottedItemChangedDelegate or CreateFunctionDelegate(Super, self, self.UIEquippeditem)
    Super.OnSlottedItemChanged:Add(self.SlottedItemChangedDelegate)

    if Super.InventoryUI then
        Super.InventoryUI:RemoveFromParent()
        GameplayStatics:SetGamePaused(Super, false)
        Super.PlayerCharacter:CastToLua():ActivateInventoryCamera(false)
        Super.InventoryUI = nil
        Super.OnScreenControls:SetVisibility(Common.ESlateVisibility.SelfHitTestInvisible)
    else
        local WBEquipmentClass = LoadClass('/Game/Blueprints/WidgetBP/Inventory/WB_Equipment.WB_Equipment_C')
        Super.InventoryUI = WidgetBlueprintLibrary:Create(Super, WBEquipmentClass, nil)
        Super.InventoryUI:AddToViewport(0)

        GameplayStatics:SetGamePaused(Super, true)
        Super.PlayerCharacter:CastToLua():ActivateInventoryCamera(true)
        Super.OnScreenControls:SetVisibility(Common.ESlateVisibility.Hidden)
    end
end

function m:UIEquippeditem(ItemSlot, Item)
    Super.OnScreenControls:CastToLua():UpdateCurrentIcons()
    
    if ItemSlot.ItemType.Name == 'Weapon' then
        Super.PlayerCharacter:CastToLua():CreateAllWeapons()
    end
end

function m:CanPurchaseItem(Item)
    return Super:GetInventoryItemCount(Super.SoulsItem) >= Item.Price
end

function m:PurchaseItem(NewItem)
    if not self:CanPurchaseItem(NewItem) then
        return false
    end

    self:ConsumeSouls(NewItem.Price)
    local bAddResult = Super:AddInventoryItem(NewItem, 1, 1, false)
    local bSaveResult = Super:SaveInventory()

    return bAddResult and bSaveResult
end

function m:ConsumeSouls(Price)
    return Super:RemoveInventoryItem(Super.SoulsItem, Price)
end

function m:UpdateOnScreenControls()
    if not KismetSystemLibrary:IsValid(Super.OnScreenControls) then
        return false
    end

    Super.OnScreenControls:CastToLua():UpdateCurrentIcons()
end

function m:AddSouls(Price)
    Super:AddInventoryItem(Super.SoulsItem, Price, 1, true)
end

return m