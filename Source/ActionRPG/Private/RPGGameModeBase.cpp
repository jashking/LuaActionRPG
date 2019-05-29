// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#include "ActionRPG.h"
#include "RPGGameModeBase.h"
#include "RPGGameStateBase.h"
#include "RPGPlayerControllerBase.h"
#include "Misc/Paths.h"

ARPGGameModeBase::ARPGGameModeBase()
{
	GameStateClass = ARPGGameStateBase::StaticClass();
	PlayerControllerClass = ARPGPlayerControllerBase::StaticClass();
}

void ARPGGameModeBase::BeginPlay()
{
	OnInitLuaBinding();

	Super::BeginPlay();
}

void ARPGGameModeBase::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
	Super::EndPlay(EndPlayReason);

	OnReleaseLuaBinding();
}

void ARPGGameModeBase::BeginDestroy()
{
	Super::BeginDestroy();

	OnReleaseLuaBinding();
}

void ARPGGameModeBase::ProcessEvent(UFunction* Function, void* Parameters)
{
	LuaProcessEvent<Super>(Function, Parameters);
}

FString ARPGGameModeBase::OnInitBindingLuaPath_Implementation()
{
	return FPaths::ProjectContentDir() / LuaFilePath;
}

bool ARPGGameModeBase::ShouldEnableLuaBinding_Implementation()
{
	return !LuaFilePath.IsEmpty();
}
