// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Animation/AnimNotifies/AnimNotifyState.h"
#include "LuaImplementableInterface.h"
#include "RPGAnimNotifyState.generated.h"

/**
 * 
 */
UCLASS()
class ACTIONRPG_API URPGAnimNotifyState : public UAnimNotifyState, public ILuaImplementableInterface
{
	GENERATED_BODY()

protected:
	virtual void ProcessEvent(UFunction* Function, void* Parameters) override;
	virtual void BeginDestroy() override;

	virtual bool OnInitLuaBinding() override;
	virtual void OnReleaseLuaBinding() override;
	virtual FString OnInitBindingLuaPath_Implementation() override;
	virtual bool ShouldEnableLuaBinding_Implementation() override;

protected:
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "LuaImplementable", meta = (AllowPrivateAccess = "true"))
	FString LuaFilePath;

	bool bHasInit = false;
};
