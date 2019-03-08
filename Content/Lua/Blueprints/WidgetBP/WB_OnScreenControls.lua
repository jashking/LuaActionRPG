local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadStruct = LoadStruct
local LoadObject = LoadObject
local CreateFunctionDelegate = CreateFunctionDelegate

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local MobilePatchingLibrary = LoadClass('MobilePatchingLibrary')
local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super.PlayerCharacter = Super:GetOwningPlayer():K2_GetPawn()
    self:SetSafemargins()

    self.NormalAttackButtonClickedDelegate = self.NormalAttackButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnNormalAttackButtonClicked)
    self.RollingButtonClickedDelegate = self.RollingButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnRollingButtonClicked)
    self.PotionButtonClickedDelegate = self.PotionButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnPotionButtonClicked)
    self.InventoryButtonClickedDelegate = self.InventoryButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnInventoryButtonClicked)
    self.PauseButtonClickedDelegate = self.PauseButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnPauseButtonClicked)
    self.UseSkillButtonClickedDelegate = self.UseSkillButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnUseSkillButtonClicked)
    self.WeaponChangeButtonClickedDelegate = self.WeaponChangeButtonClickedDelegate or CreateFunctionDelegate(Super, self, self.OnWeaponChangeButtonClicked)
    self.AutoPlayButtonStateChangedDelegate = self.AutoPlayButtonStateChangedDelegate or CreateFunctionDelegate(Super, self, self.OnAutoPlayButtonStateChanged)

    Super.NormalAttack_Button.OnClicked:Add(self.NormalAttackButtonClickedDelegate)
    Super.Rolling_Button.OnClicked:Add(self.RollingButtonClickedDelegate)
    Super.PotionButton.OnClicked:Add(self.PotionButtonClickedDelegate)
    Super.Inventory_Button.OnClicked:Add(self.InventoryButtonClickedDelegate)
    Super.PauseButton.OnClicked:Add(self.PauseButtonClickedDelegate)
    Super.UseSkillButton.OnClicked:Add(self.UseSkillButtonClickedDelegate)
    Super.WeaponChange_Button.OnClicked:Add(self.WeaponChangeButtonClickedDelegate)
    Super.AutoPlayButton.OnCheckStateChanged:Add(self.AutoPlayButtonStateChangedDelegate)
end

function m:SetSafemargins()
    if not MobilePatchingLibrary:GetActiveDeviceProfileName() == 'IPhoneX' then
        return
    end

    local FMargin = LoadStruct('Margin')
    local Margin = FMargin()
    Margin.Left = 64
    Margin.Top = 0
    Margin.Right = 64
    Margin.Bottom = 32

    Super:SetPadding(Margin)
end

function m:OnNormalAttackButtonClicked()
    Super.PlayerCharacter:CastToLua():DoMeleeAttack()
end

function m:OnRollingButtonClicked()
    Super.PlayerCharacter:CastToLua():DoRoll()
end

function m:OnPotionButtonClicked()
    Super.PlayerCharacter:CastToLua():UseEquippedPotion()
end

function m:OnInventoryButtonClicked()
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0):CastToLua()
    PlayerController:ShowInventoryUI()
end

function m:OnPauseButtonClicked()
    local GameMode = GameplayStatics:GetGameMode(Super):CastToLua()
    if GameMode then
        GameMode:PauseGame()
    end
end

function m:OnUseSkillButtonClicked()
    Super.PlayerCharacter:CastToLua():DoSkillAttack()

    if not self.CooldownSkillTag then
        local FGameplayTagContainer = LoadStruct('GameplayTagContainer')
        self.CooldownSkillTag = FGameplayTagContainer()
        self.CooldownSkillTag = RPGBlueprintLibrary:AddGameplayTagToContainer(self.CooldownSkillTag, RPGBlueprintLibrary:MakeGameplayTag('Cooldown.Skill'))
    end

    bGet, TimeRemaining, CooldownDuration = Super.PlayerCharacter:GetCooldownRemainingForTag(self.CooldownSkillTag)
    if bGet then
        self:SkillCooldown(TimeRemaining)
    end
end

function m:SkillCooldown(TimeRemaining)
    Super.UseSkillButton:SetIsEnabled(false)
    Super:PlayAnimation(Super.CooldownAnim, 0, 1, Common.EUMGSequencePlayMode.Forward, 1 / TimeRemaining)

    self.CooldownDelegate = self.CooldownDelegate or CreateFunctionDelegate(Super,
        function()
            Super.UseSkillButton:SetIsEnabled(true)
            Super:PlayAnimation(Super.SkillReadyEffect, 0, 0, Common.EUMGSequencePlayMode.PingPong, 1)
        end)

    BlueluaLibrary:Delay(Super, TimeRemaining, -1, self.CooldownDelegate)
end

function m:OnWeaponChangeButtonClicked()
    Super.PlayerCharacter:CastToLua():SwitchWeapon()

    if not self.Hammer_Impact or not self.Hammer_Impact:IsValid() then
        self.Hammer_Impact = LoadObject(Super, '/Game/Assets/Sounds/Weapons/Hammer/A_Hammer_Impact_Cue.A_Hammer_Impact_Cue')
    end

    GameplayStatics:PlaySound2D(Super, self.Hammer_Impact, 1, 1, 0, nil, nil)
    self:UpdateCurrentIcons()
end

function m:UpdateCurrentIcons()
    local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)

    local PotionItem = PlayerController:GetSlottedItem(RPGBlueprintLibrary:MakeRPGItemSlot('Potion', 0))
    Super.PotionButton:SetIsEnabled(PotionItem and true or false)
    Super.PotionIcon:SetBrush(PotionItem and PotionItem.ItemIcon or Super.PotionClearBrush)

    local SkillItem = PlayerController:GetSlottedItem(RPGBlueprintLibrary:MakeRPGItemSlot('Skill', 0))
    Super.UseSkillButton:SetIsEnabled(SkillItem and true or false)
    Super.SkillIcon:SetBrush(SkillItem and SkillItem.ItemIcon or Super.SkillClearBrush)

    local WeaponItem = PlayerController:GetSlottedItem(RPGBlueprintLibrary:MakeRPGItemSlot('Weapon', Super.PlayerCharacter.CurWeaponIndex))
    Super.NormalAttack_Button:SetIsEnabled(WeaponItem and true or false)
    Super.CurrentWeaponImage:SetBrush(WeaponItem and WeaponItem.ItemIcon or Super.WeaponClearBrush)
end

function m:OnAutoPlayButtonStateChanged(bIsChecked)
    local GameMode = GameplayStatics:GetGameMode(Super)
    GameMode:ToggleAutoBattleMode()
end

return m