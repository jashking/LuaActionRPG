-- global functions
local LoadClass = LoadClass
local CreateFunctionDelegate = CreateFunctionDelegate
local LoadObject = LoadObject
local LoadStruct = LoadStruct

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetMathLibrary = LoadClass('KismetMathLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

-- Parent lua class
local Character = require 'Lua.Blueprints.Character'

local m = Character:New({ Super = Super })

function m:ReceiveBeginPlay()
    self.Super:SetTickableWhenPaused(true)
    local CameraManager = GameplayStatics:GetPlayerCameraManager(self.Super, 0)
    CameraManager:StartCameraFade(1, 0, 1, KismetMathLibrary:MakeColor(0, 0, 0, 1), false, false)
end

function m:OnSetupPlayerInput()
    local BlueluaLibrary = LoadClass('BlueluaLibrary')

    BlueluaLibrary:BindAction(self.Super, 'NormalAttack', Common.EInputEvent.IE_Pressed, true, false, CreateFunctionDelegate(self.Super, self, self.OnNormalAttack))
    BlueluaLibrary:BindAction(self.Super, 'SpecialAttack', Common.EInputEvent.IE_Pressed, true, false, CreateFunctionDelegate(self.Super, self, self.OnSpecialAttack))
    BlueluaLibrary:BindAction(self.Super, 'Roll', Common.EInputEvent.IE_Pressed, true, false, CreateFunctionDelegate(self.Super, self, self.OnRoll))
    BlueluaLibrary:BindAction(self.Super, 'ChangeWeapon', Common.EInputEvent.IE_Pressed, true, false, CreateFunctionDelegate(self.Super, self, self.SwitchWeapon))

    BlueluaLibrary:BindAxisAction(self.Super, 'MoveForward', true, false, nil)
    BlueluaLibrary:BindAxisAction(self.Super, 'MoveRight', true, false, nil)
end

function m:OnManaChanged(DeltaValue, EventTags)
    self:UpdateManaBar()
end

function m:UpdateManaBar()
    local PlayerController = GameplayStatics:GetPlayerController(self.Super, 0)
    PlayerController.OnScreenControls.MP_ProgressBar:SetPercent(self.Super:GetMana() / self.Super:GetMaxMana())
end

function m:OnHealthChanged(DeltaValue, EventTags)
    self:UpdateHealthBar()

    if not self:IsAlive() then
        local GameMode = GameplayStatics:GetGameMode(self.Super):CastToLua()
        GameMode:GameOver()

        self:DebugFinish()
    end
end

function m:UpdateHealthBar()
    local PlayerController = GameplayStatics:GetPlayerController(self.Super, 0)
    PlayerController.OnScreenControls.HP_ProgressBar:SetPercent(self.Super:GetHealth() / self.Super:GetMaxHealth())
end

function m:DebugFinish()
    KismetSystemLibrary:ExecuteConsoleCommand(self.Super, 'stopfpschart', nil)
end

function m:OnNormalAttack()
    self:DoMeleeAttack()
end

function m:OnSpecialAttack()
    self:DoSkillAttack()
end

function m:OnRoll()
    self:DoRoll()
end

function m:SwitchWeapon()
    self:AttachNextWeapon()
end

function m:DoMeleeAttack()
    if not self:CanUseAnyAbility() then
        return
    end

    if self:IsUsingMelee() then
        self:JumpSectionForCombo()
        return
    else
        return self.Super:ActivateAbilitiesWithItemSlot(self.Super.CurrentWeaponSlot, true)
    end
end

function m:DoRoll()
    if not self:CanUseAnyAbility() then
        return
    end

    local MovingVector = KismetMathLibrary:MakeVector(self.Super:GetInputAxisValue('MoveForward'), self.Super:GetInputAxisValue('MoveRight'), 0)
    if KismetMathLibrary:VSize(MovingVector) > 0 then
        self.Super:K2_SetActorRotation(self.Super:GetControlRotation(), true)
    end

    if not self.RollingMontage or not self.RollingMontage:IsValid() then
        self.RollingMontage = LoadObject(self.Super, '/Game/Characters/Animations/AM_Rolling.AM_Rolling')
    end

    self:PlayHighPriorityMontage(self.RollingMontage, 'None')
end

function m:AttachNextWeapon()
    self.Super.CurWeaponIndex = self.Super.CurWeaponIndex + 1
    if self.Super.CurWeaponIndex >= #self.Super.EquippedWeapons then
        self.Super.CurWeaponIndex = 0
    end

    if not self.WeaponPrimaryAssetType then
        local FPrimaryAssetType = LoadStruct('PrimaryAssetType')
        self.WeaponPrimaryAssetType = FPrimaryAssetType()
        self.WeaponPrimaryAssetType.Name = 'Weapon'
    end

    self.Super.CurrentWeaponSlot.ItemType = self.WeaponPrimaryAssetType
    self.Super.CurrentWeaponSlot.SlotNumber = self.Super.CurWeaponIndex

    if KismetSystemLibrary:IsValid(self.Super.CurrentWeapon) then
        self.Super.CurrentWeapon:K2_DetachFromActor(Common.EDetachmentRule.KeepRelative, Common.EDetachmentRule.KeepWorld, Common.EDetachmentRule.KeepWorld)
        self.Super.CurrentWeapon = nil
    end

    self.Super.CurrentWeapon = self.Super.EquippedWeapons[self.Super.CurWeaponIndex + 1]
    if KismetSystemLibrary:IsValid(self.Super.CurrentWeapon) then
        self.Super.CurrentWeapon:K2_AttachToComponent(self.Super.Mesh, 'hand_rSocket', Common.EAttachmentRule.SnapToTarget, Common.EAttachmentRule.SnapToTarget, Common.EAttachmentRule.KeepWorld, true)
    end

    local PlayerController = GameplayStatics:GetPlayerController(self.Super, 0)
    PlayerController:CastToLua():UpdateOnScreenControls()
end

function m:OnDamaged(DamageAmount, HitInfo, DamageTags, InstigatorCharacter, DamageCauser)
    if self.Super.IsProtectedByShield or not self:CanUseAnyAbility() then
        return
    end

    if not self.HitReactAnim or not self.HitReactAnim:IsValid() then
        self.HitReactAnim = LoadObject(self.Super, '/Game/Characters/Animations/AM_React_Hit.AM_React_Hit')
    end

    self.Super:PlayAnimMontage(self.HitReactAnim, 1, tostring(KismetMathLibrary:RandomInteger(2)))
end

function m:CreateAllWeapons()
    local EquippedWeapons = self.Super.EquippedWeapons
    for _, Weapon in ipairs(EquippedWeapons) do
        Weapon:K2_DestroyActor()
    end

    EquippedWeapons = {}

    local Transform = KismetMathLibrary:MakeTransform(
        KismetMathLibrary:MakeVector(0, 0, 0), KismetMathLibrary:MakeRotator(0, 0, 0), KismetMathLibrary:MakeVector(1, 1, 1))

    local PlayerController = GameplayStatics:GetPlayerController(self.Super, 0)

    for RPGItemSlot, RPGItem in pairs(PlayerController.SlottedItems) do
        if KismetSystemLibrary:IsValidClass(RPGItem.WeaponActor) then
            local WeaponActor = GameplayStatics:BeginDeferredActorSpawnFromClass(
                self.Super, RPGItem.WeaponActor, Transform, Common.ESpawnActorCollisionHandlingMethod.Default, self.Super)
            WeaponActor.EnableAttackDelay = true
            GameplayStatics:FinishSpawningActor(WeaponActor, Transform)
    
            EquippedWeapons[RPGItemSlot.SlotNumber + 1] = WeaponActor
        end
    end

    self.Super.EquippedWeapons = EquippedWeapons
    self:AttachNextWeapon()
end

function m:ActivateInventoryCamera(bEnable)
    self.Super.bInventoryCamera = bEnable
    self.Super.InventoryCamera:SetActive(bEnable, false)
    self.Super.ThirdPersonCamera:SetActive(not bEnable, false)
    self.Super.Mesh:SetTickableWhenPaused(bEnable)
end

function m:UseEquippedPotion()
    local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')
    self.Super:ActivateAbilitiesWithItemSlot(RPGBlueprintLibrary:MakeRPGItemSlot('Potion', 0), true)
end

function m:JumpSectionForCombo()
    if not self.Super.bEnableComboPeriod or not self.Super.JumpSectionNotify then
        return
    end

    local AnimInstance = self.Super.Mesh:GetAnimInstance()
    local CurrentActiveMontage = AnimInstance:GetCurrentActiveMontage()
    local JumpSections = self.Super.JumpSectionNotify.JumpSections
    local RandomNextIndex = KismetMathLibrary:RandomInteger(#JumpSections)

    AnimInstance:Montage_SetNextSection(AnimInstance:Montage_GetCurrentSection(CurrentActiveMontage), JumpSections[RandomNextIndex + 1], CurrentActiveMontage)

    self.Super.bEnableComboPeriod = false
end

function m:OnInitBPFunctionOverriding()
    return {
        'JumpSectionForCombo'
    }
end

return m