// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#include "ActionRPG.h"
#include "RPGAnimNotifyState.h"

void URPGAnimNotifyState::ProcessEvent(UFunction* Function, void* Parameters)
{
	if (!bHasInit && !LuaFilePath.IsEmpty())
	{
		OnInit(LuaFilePath);
	}

	if (!OnProcessEvent(Function, Parameters))
	{
		Super::ProcessEvent(Function, Parameters);
	}
}

void URPGAnimNotifyState::PostInitProperties()
{
	Super::PostInitProperties();

	PreRegisterLua(LuaFilePath);
}

void URPGAnimNotifyState::BeginDestroy()
{
	Super::BeginDestroy();

	OnRelease();
}

bool URPGAnimNotifyState::OnInit(const FString& InLuaFilePath, TSharedPtr<FLuaState> InLuaState /*= nullptr*/)
{
	bHasInit = ILuaImplementableInterface::OnInit(InLuaFilePath, InLuaState);

	return bHasInit;
}

void URPGAnimNotifyState::OnRelease()
{
	ILuaImplementableInterface::OnRelease();
	bHasInit = false;
}
