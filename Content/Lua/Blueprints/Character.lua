-- global functions
local LoadStruct = LoadStruct
local LoadClass = LoadClass

-- C++ library
local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')

local m = { Super = Super }

function m:New(obj)
    obj = obj or {}
    self.__index = self
    return setmetatable(obj, self)
end

function m:DelayedDestroy()
    if self.Super then
        self.Super:K2_DestroyActor()
    end
end

function m:IsAlive()
    if self.Super and self.Super:GetHealth() > 0 then
        return true
    else
        return false
    end
end

function m:DoMeleeAttack()
    if not self:CanUseAnyAbility() or self:IsUsingMelee() then
        return
    end

    return self.Super:ActivateAbilitiesWithItemSlot(self.Super.CurrentWeaponSlot, true)
end

function m:MakeTagContainer(Tag)
    if not m.tags then
        m.tags = {}
    end

    if not m.tags[Tag] then
        local FGameplayTagContainer = LoadStruct('GameplayTagContainer')
        m.tags[Tag] = FGameplayTagContainer()
        m.tags[Tag] = RPGBlueprintLibrary:AddGameplayTagToContainer(TagContainer, RPGBlueprintLibrary:MakeGameplayTag(Tag))
    end

    return m.tags[Tag]
end

function m:DoSkillAttack()
    if not self:CanUseAnyAbility() then
        return
    end

    return self.Super:ActivateAbilitiesWithTags(self:MakeTagContainer('Ability.Skill'), true)
end

function m:IsUsingMelee()
    local ActiveAbilities = self.Super:GetActiveAbilitiesWithTags(self:MakeTagContainer('Ability.Melee'), nil)
    return #ActiveAbilities > 0
end

function m:IsUsingSkill()
    local ActiveAbilities = self.Super:GetActiveAbilitiesWithTags(self:MakeTagContainer('Ability.Skill'), nil)
    return #ActiveAbilities > 0
end

function m:CanUseAnyAbility()
    local GameplayStatics = LoadClass('GameplayStatics')
    local bPaused = GameplayStatics:IsGamePaused(self.Super)
    local bAlive = self:IsAlive()
    local bUsingSkill = self:IsUsingSkill()

    return bAlive and not bPaused and not bUsingSkill
end

return m