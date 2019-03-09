local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local LoadObject = LoadObject

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local KismetMathLibrary = LoadClass('KismetMathLibrary')

-- Common
local Common = require 'Lua.Blueprints.Common'

function m:ReceiveBeginPlay()
    Super.OnActorBeginOverlap:Add(CreateFunctionDelegate(Super, self, self.OnActorBeginOverlap))
end

function m:ReceiveTick(DeltaSeconds)
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    local NewLocation = KismetMathLibrary:VInterpTo_Constant(Super:K2_GetActorLocation(), PlayerController.PlayerCharacter:K2_GetActorLocation(), DeltaSeconds, 2500)
    Super:K2_SetActorLocation(NewLocation, false, nil, false)
end

function m:OnActorBeginOverlap(OverlappedActor, OtherActor)
    local PlayerController = GameplayStatics:GetPlayerController(Super, 0)
    local PlayerCharacter = PlayerController.PlayerCharacter

    if not KismetMathLibrary:EqualEqual_ObjectObject(OtherActor, PlayerCharacter) then
        return
    end

    if not self.DestroyEffect or not self.DestroyEffect:IsValid() then
        self.DestroyEffect = LoadObject(nil, '/Game/Effects/FX_Skill_Whirlwind/P_Whirlwind_Lightning_Start_01.P_Whirlwind_Lightning_Start_01')
    end

    GameplayStatics:SpawnEmitterAtLocation(Super, self.DestroyEffect, PlayerCharacter:K2_GetActorLocation(),
        KismetMathLibrary:MakeRotator(0, 0, 0), KismetMathLibrary:MakeVector(1, 1, 1), true, Common.EPSCPoolMethod.None)

    Super:K2_DestroyActor()
    PlayerController:CastToLua():AddSouls(1)
end

return m