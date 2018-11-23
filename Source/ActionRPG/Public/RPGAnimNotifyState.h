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

public:
	virtual void ProcessEvent(UFunction* Function, void* Parameters) override;
	virtual void PostInitProperties() override;
	virtual void BeginDestroy() override;

protected:
	virtual bool OnInit(const FString& InLuaFilePath, TSharedPtr<FLuaState> InLuaState = nullptr) override;
	virtual void OnRelease() override;

protected:
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "LuaImplementable", meta = (AllowPrivateAccess = "true"))
	FString LuaFilePath;

	bool bHasInit = false;
};
