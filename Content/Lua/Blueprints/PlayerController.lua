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
local KismetMathLibrary = LoadClass('KismetMathLibrary')
local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:PlaySkippableCutscene(SequencePlayer)
    Super.SequencePlayer = SequencePlayer

    SequencePlayer.OnFinished:Add(self, self.StopPlayingSkippableCutscene)
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
    GameMode:ToLuaObject():StartGame()

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
    Super.OnScreenControls:ToLuaObject():UpdateCurrentIcons_lua()
end

function m:ReceivePossess(NewPawn)
    if self.ReceivePossessOnce then
        return
    end
    self.ReceivePossessOnce = true

    Super.PlayerCharacter = NewPawn
    self:CreateHUD()

    Super.OnInventoryItemChanged:Add(self, self.OnInventoryItemChanged)

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            Super.PlayerCharacter:CreateAllWeapons()
        end))

    KismetSystemLibrary:Delay(Super, 0.025, LatentActionInfo)
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

    RPGBlueprintLibrary:BindAxisAction(Super, 'MoveForward', nil)
    RPGBlueprintLibrary:BindAxisAction(Super, 'MoveRight', nil)
    RPGBlueprintLibrary:BindAxisAction(Super, 'RotateCamera', CreateDelegate(Super, function(AxisValue) Super:AddYawInput(AxisValue) end))

    local EInputEvent = Common.EInputEvent
    RPGBlueprintLibrary:BindTouchAction(Super, EInputEvent.IE_Pressed, CreateDelegate(Super, self, self.OnTouchPressed))
    RPGBlueprintLibrary:BindTouchAction(Super, EInputEvent.IE_Repeat, CreateDelegate(Super, self, self.OnTouchRepeated))
    RPGBlueprintLibrary:BindTouchAction(Super, EInputEvent.IE_Released, CreateDelegate(Super, self, self.OnTouchReleased))
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
    if not self.UIEquippeditem_Delegate then
        self.UIEquippeditem_Delegate = Super.OnSlottedItemChanged:Add(self, self.UIEquippeditem)
    end

    if Super.InventoryUI then
        Super.InventoryUI:RemoveFromParent()
        GameplayStatics:SetGamePaused(Super, false)
        Super.PlayerCharacter:ActivateInventoryCamera(false)
        Super.InventoryUI = nil
        Super.OnScreenControls:SetVisibility(Common.ESlateVisibility.SelfHitTestInvisible)
    else
        local WBEquipmentClass = LoadClass('/Game/Blueprints/WidgetBP/Inventory/WB_Equipment.WB_Equipment_C')
        Super.InventoryUI = WidgetBlueprintLibrary:Create(Super, WBEquipmentClass, nil)
        Super.InventoryUI:AddToViewport(0)

        GameplayStatics:SetGamePaused(Super, true)
        Super.PlayerCharacter:ActivateInventoryCamera(true)
        Super.OnScreenControls:SetVisibility(Common.ESlateVisibility.Hidden)
    end
end

function m:UIEquippeditem(ItemSlot, Item)
    Super.OnScreenControls:ToLuaObject():UpdateCurrentIcons_lua()
    
    if ItemSlot.ItemType.Name == 'Weapon' then
        Super.PlayerCharacter:CreateAllWeapons()
    end
end

return m