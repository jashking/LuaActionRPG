local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass

-- C++ library
KismetSystemLibrary = LoadClass('KismetSystemLibrary')

function m:Received_NotifyBegin(MeshComp, Animation, TotalDuration)
    if not KismetSystemLibrary:IsValid(MeshComp) then
        return false
    end

    local Owner = MeshComp:GetOwner()
    if not KismetSystemLibrary:IsValid(Owner) then
        return false
    end

    local CurrentWeapon = MeshComp:GetOwner().CurrentWeapon
    if not KismetSystemLibrary:IsValid(CurrentWeapon) then
        return false
    end

    CurrentWeapon:CastToLua():BeginWeaponAttack(Super.EventTag, Super.AttackDelayTime, Super.MaxAttackDelayCount)
    return true
end

function m:Received_NotifyEnd(MeshComp, Animation)
    if not KismetSystemLibrary:IsValid(MeshComp) then
        return false
    end

    local Owner = MeshComp:GetOwner()
    if not KismetSystemLibrary:IsValid(Owner) then
        return false
    end

    local CurrentWeapon = MeshComp:GetOwner().CurrentWeapon
    if not KismetSystemLibrary:IsValid(CurrentWeapon) then
        return false
    end

    CurrentWeapon:CastToLua():EndWeaponAttack()
    return true
end

return m