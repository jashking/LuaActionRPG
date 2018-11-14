// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#include "ActionRPG.h"
#include "RPGGameModeBase.h"
#include "RPGGameStateBase.h"
#include "RPGPlayerControllerBase.h"

ARPGGameModeBase::ARPGGameModeBase()
{
	GameStateClass = ARPGGameStateBase::StaticClass();
	PlayerControllerClass = ARPGPlayerControllerBase::StaticClass();
}

void ARPGGameModeBase::PostInitProperties()
{
	Super::PostInitProperties();

	PreRegisterLua(LuaFilePath);
}

void ARPGGameModeBase::BeginPlay()
{
	OnInit(LuaFilePath);

	Super::BeginPlay();
}

void ARPGGameModeBase::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);

	OnRelease();
}

void ARPGGameModeBase::ProcessEvent(UFunction* Function, void* Parameters)
{
	if (!OnProcessEvent(Function, Parameters))
	{
		Super::ProcessEvent(Function, Parameters);
	}
}
