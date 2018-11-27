-- global functions
local LoadClass = LoadClass
local CreateDelegate = CreateDelegate

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

    local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')
    local PlayerController = GameplayStatics:GetPlayerController(self.Super, 0)
    RPGBlueprintLibrary:BindAction(PlayerController, 'NormalAttack', Common.EInputEvent.IE_Pressed, CreateDelegate(self.Super, self, self.OnNormalAttack))
    RPGBlueprintLibrary:BindAction(PlayerController, 'SpecialAttack', Common.EInputEvent.IE_Pressed, CreateDelegate(self.Super, self, self.OnSpecialAttack))
    RPGBlueprintLibrary:BindAction(PlayerController, 'Roll', Common.EInputEvent.IE_Pressed, CreateDelegate(self.Super, self, self.OnRoll))
    RPGBlueprintLibrary:BindAction(PlayerController, 'ChangeWeapon', Common.EInputEvent.IE_Pressed, CreateDelegate(self.Super, self, self.OnChangeWeapon))
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
        local GameMode = GameplayStatics:GetGameMode(self.Super):ToLuaObject()
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
    self.Super:DoRoll()
end

function m:OnChangeWeapon()
    self.Super:SwitchWeapon()
end

function m:DoMeleeAttack()
    if not self:CanUseAnyAbility() then
        return
    end

    if self:IsUsingMelee() then
        return self.Super:JumpSectionForCombo()
    else
        return self.Super:ActivateAbilitiesWithItemSlot(self.Super.CurrentWeaponSlot, true)
    end
end

return m