local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadStruct = LoadStruct
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetMathLibrary = LoadClass('KismetMathLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local AbilitySystemBlueprintLibrary = LoadClass('AbilitySystemBlueprintLibrary')

-- Structures
local FGameplayEventData = LoadStruct('GameplayEventData')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:ReceiveBeginPlay()
    Super.CapsuleCollision:IgnoreActorWhenMoving(nil, true)

    Super.OnActorBeginOverlap:Add(self, self.OnActorBeginOverlap)
    Super.OnActorEndOverlap:Add(self, self.OnActorEndOverlap)
end

function m:OnActorBeginOverlap(OverlappedActor, OtherActor)
    local Instigator = Super:GetInstigator()
    local OtherActorClass = GameplayStatics:GetObjectClass(OtherActor)
    local InstigatorClass = GameplayStatics:GetObjectClass(Instigator)

    if KismetMathLibrary:NotEqual_ClassClass(OtherActorClass, InstigatorClass) and Super.IsAttacking then
        if self.ActorOverlapOnce then
            return
        end
        self.ActorOverlapOnce = true

        local GameplayEventData = FGameplayEventData()
        GameplayEventData.Instigator = Instigator
        GameplayEventData.Target = OtherActor
        AbilitySystemBlueprintLibrary:SendGameplayEventToActor(Instigator, Super.AttackEventTag, GameplayEventData)
        self:HitPause()
    end
end

function m:OnActorEndOverlap(OverlappedActor, OtherActor)
    if not self.EndOverlapLatentAction then
        self.EndOverlapLatentAction = CreateLatentAction(CreateDelegate(Super, self,
            function(self)
                if self.ActorOverlapOnce then
                    self.ActorOverlapOnce = nil
                end
            end))
    end

    KismetSystemLibrary:Delay(Super, 0.2, self.EndOverlapLatentAction)
end

function m:HitPause()
    if not Super.EnableAttackDelay or Super.AttackDelayCount <= 0 then
        return
    end

    Super.AttackDelayCount = Super.AttackDelayCount - 1

    if not self.HitPauseEndLatentAction then
        self.HitPauseEndLatentAction = CreateLatentAction(CreateDelegate(Super,
            function()
                GameplayStatics:SetGlobalTimeDilation(Super, 1)
            end))
    end

    if not self.HitPauseStartLatentAction then
        self.HitPauseStartLatentAction = CreateLatentAction(CreateDelegate(Super, self,
            function(self)
                GameplayStatics:SetGlobalTimeDilation(Super, 0.1)
                KismetSystemLibrary:Delay(Super, 0.01, self.HitPauseEndLatentAction)
            end))
    end

    KismetSystemLibrary:Delay(Super, 0.1, self.HitPauseStartLatentAction)
end

function m:BeginWeaponAttack(EventTag, AttackDelayTime, MaxAttackDelayCount)
    Super.AttackEventTag = EventTag
    Super.AttackDelayTime = AttackDelayTime
    Super.AttackDelayCount = MaxAttackDelayCount
    Super.IsAttacking = true
    Super.CapsuleCollision:SetCollisionEnabled(Common.ECollisionEnabled.QueryOnly)
end

function m:EndWeaponAttack()
    Super.IsAttacking = false
    Super.CapsuleCollision:SetCollisionEnabled(Common.ECollisionEnabled.NoCollision)
end

return m