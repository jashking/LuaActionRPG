local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local BlueluaLibrary = LoadClass('BlueluaLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local KismetMathLibrary = LoadClass('KismetMathLibrary')

-- world context object
local WorldContextObject = BlueluaLibrary:GetWorldContext()

function m:PlaySkippableCutscene(SequencePlayer)
    Super.SequencePlayer = SequencePlayer

    SequencePlayer.OnFinished:Add(self, self.StopPlayingSkippableCutscene)
    SequencePlayer:Play()

    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBSkipIntroClass = LoadClass('/Game/Blueprints/WidgetBP/WB_SkipIntro.WB_SkipIntro_C')
    self.SkipIntroWidget = WidgetBlueprintLibrary:Create(WorldContextObject, WBSkipIntroClass, Super)
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

    local GameMode = GameplayStatics:GetGameMode(WorldContextObject)
    GameMode:ToLuaObject():StartGame()

    self.SkipIntroWidget:RemoveFromParent()
    self.SkipIntroWidget = nil
end

function m:ShowHUD(bShow)
    local bRunningOnMobile = self:IsRunningOnMobile()
    Super:SetVirtualJoystickVisibility(bShow and bRunningOnMobile)

    --TODO: move to common lua
    local ESlateVisibility = {
        Visible = 0,
        Collapsed = 1,
        Hidden = 2,
        HitTestInvisible = 3,
        SelfHitTestInvisible = 4,
    }

    if Super.OnScreenControls then
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
    Super.OnScreenControls = WidgetBlueprintLibrary:Create(WorldContextObject, WBOnScreenControlsClass, Super)
    Super.OnScreenControls:AddToViewport(0)
    Super.OnScreenControls:UpdateCurrentIcons()
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

    KismetSystemLibrary:Delay(WorldContextObject, 0.025, LatentActionInfo)
end

-- bool bAdded, URPGItem* Item
function m:OnInventoryItemChanged(bAdded, Item)
    Super:HandleInventoryItemChanged(bAdded, Item)
end

--TODO: move to common lua
function m:IsRunningOnMobile()
    local PlatformName = GameplayStatics:GetPlatformName()
    if PlatformName == 'Android' or PlatformName == 'IOS' then
        return true, PlatformName
    end

    return false, PlatformName
end

function m:ReceiveTick(DeltaSeconds)
    local GameMode = GameplayStatics:GetGameMode(WorldContextObject)
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
    Super:BindAxisAction('MoveForward', nil)
    Super:BindAxisAction('MoveRight', nil)
    Super:BindAxisAction('RotateCamera', CreateDelegate(Super, function(AxisValue) Super:AddYawInput(AxisValue) end))

    --TODO: move to common lua
    local EInputEvent = {
        IE_Pressed = 0,
        IE_Released = 1,
        IE_Repeat = 2,
        IE_DoubleClick = 3,
        IE_Axis = 4,
        IE_MAX = 5,
    }

    Super:BindTouchAction(EInputEvent.IE_Pressed, CreateDelegate(Super, self, self.OnTouchPressed))
    Super:BindTouchAction(EInputEvent.IE_Repeat, CreateDelegate(Super, self, self.OnTouchRepeated))
    Super:BindTouchAction(EInputEvent.IE_Released, CreateDelegate(Super, self, self.OnTouchReleased))
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

return m