local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadStruct = LoadStruct
local CreateFunctionDelegate = CreateFunctionDelegate

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetMathLibrary = LoadClass('KismetMathLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local AbilitySystemBlueprintLibrary = LoadClass('AbilitySystemBlueprintLibrary')
local BlueluaLibrary = LoadClass('BlueluaLibrary')

-- Structures
local FGameplayEventData = LoadStruct('GameplayEventData')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:ReceiveBeginPlay()
    Super.CapsuleCollision:IgnoreActorWhenMoving(nil, true)

    Super.OnActorBeginOverlap:Add(CreateFunctionDelegate(Super, self, self.OnActorBeginOverlap))
    Super.OnActorEndOverlap:Add(CreateFunctionDelegate(Super, self, self.OnActorEndOverlap))
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
    self.EndOverlapDelayDelegate = self.EndOverlapDelayDelegate or CreateFunctionDelegate(Super, self,
        function(self)
            if self.ActorOverlapOnce then
                self.ActorOverlapOnce = nil
            end
        end)

    BlueluaLibrary:Delay(Super, 0.2, -1, self.EndOverlapDelayDelegate)
end

function m:HitPause()
    if not Super.EnableAttackDelay or Super.AttackDelayCount <= 0 then
        return
    end

    Super.AttackDelayCount = Super.AttackDelayCount - 1

    self.HitPauseEndDelayDelegate = self.HitPauseEndDelayDelegate or CreateFunctionDelegate(Super,
        function()
            GameplayStatics:SetGlobalTimeDilation(Super, 1)
        end)

    self.HitPauseStartDelayDelegate = self.HitPauseStartDelayDelegate or CreateFunctionDelegate(Super, self,
        function(self)
            GameplayStatics:SetGlobalTimeDilation(Super, 0.1)
            BlueluaLibrary:Delay(Super, 0.01, -1, self.HitPauseEndDelayDelegate)
        end)

    BlueluaLibrary:Delay(Super, 0.1, -1, self.HitPauseStartDelayDelegate)
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