// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#include "ActionRPG.h"
#include "RPGAnimNotifyState.h"

#include "Misc/Paths.h"

void URPGAnimNotifyState::ProcessEvent(UFunction* Function, void* Parameters)
{
	if (!bHasInit && !LuaFilePath.IsEmpty())
	{
		OnInitLuaBinding();
	}

	LuaProcessEvent<Super>(Function, Parameters);
}

void URPGAnimNotifyState::BeginDestroy()
{
	Super::BeginDestroy();

	OnReleaseLuaBinding();
}

bool URPGAnimNotifyState::OnInitLuaBinding()
{
	bHasInit = ILuaImplementableInterface::OnInitLuaBinding();

	return bHasInit;
}

void URPGAnimNotifyState::OnReleaseLuaBinding()
{
	ILuaImplementableInterface::OnReleaseLuaBinding();
	bHasInit = false;
}

FString URPGAnimNotifyState::OnInitBindingLuaPath_Implementation()
{
	return FPaths::ProjectContentDir() / LuaFilePath;
}

bool URPGAnimNotifyState::ShouldEnableLuaBinding_Implementation()
{
	return !LuaFilePath.IsEmpty();
}
