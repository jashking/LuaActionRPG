local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadStruct = LoadStruct
local LoadObject = LoadObject
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local MobilePatchingLibrary = LoadClass('MobilePatchingLibrary')
local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:Construct()
    Super.PlayerCharacter = Super:GetOwningPlayer():K2_GetPawn()
    self:SetSafemargins()

    Super.NormalAttack_Button.OnClicked:Add(self, self.OnNormalAttackButtonClicked)
    Super.Rolling_Button.OnClicked:Add(self, self.OnRollingButtonClicked)
    Super.PotionButton.OnClicked:Add(self, self.OnPotionButtonClicked)
    Super.Inventory_Button.OnClicked:Add(self, self.OnInventoryButtonClicked)
    Super.PauseButton.OnClicked:Add(self, self.OnPauseButtonClicked)
    Super.UseSkillButton.OnClicked:Add(self, self.OnUseSkillButtonClicked)
    Super.WeaponChange_Button.OnClicked:Add(self, self.OnWeaponChangeButtonClicked)
    Super.AutoPlayButton.OnCheckStateChanged:Add(self, self.OnAutoPlayButtonStateChanged)
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
    Super.PlayerCharacter:ToLuaObject():DoMeleeAttack()
end

function m:OnRollingButtonClicked()
    Super.PlayerCharacter:ToLuaObject():DoRoll()
end

function m:OnPotionButtonClicked()
    Super.PlayerCharacter:ToLuaObject():UseEquippedPotion()
end

function m:OnInventoryButtonClicked()
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0):ToLuaObject()
    PlayerController:ShowInventoryUI()
end

function m:OnPauseButtonClicked()
    local GameMode = GameplayStatics:GetGameMode(Super):ToLuaObject()
    if GameMode then
        GameMode:PauseGame()
    end
end

function m:OnUseSkillButtonClicked()
    Super.PlayerCharacter:ToLuaObject():DoSkillAttack()

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

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            Super.UseSkillButton:SetIsEnabled(true)
            Super:PlayAnimation(Super.SkillReadyEffect, 0, 0, Common.EUMGSequencePlayMode.PingPong, 1)
        end))

    KismetSystemLibrary:Delay(Super, TimeRemaining, LatentActionInfo)
end

function m:OnWeaponChangeButtonClicked()
    Super.PlayerCharacter:ToLuaObject():SwitchWeapon()

    if not self.Hammer_Impact then
        self.Hammer_Impact = LoadObject(Super, '/Game/Assets/Sounds/Weapons/Hammer/A_Hammer_Impact_Cue.A_Hammer_Impact_Cue')
    end

    GameplayStatics:PlaySound2D(Super, self.Hammer_Impact, 1, 1, 0, nil, nil)
    self:UpdateCurrentIcons_lua()
end

function m:UpdateCurrentIcons_lua()
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