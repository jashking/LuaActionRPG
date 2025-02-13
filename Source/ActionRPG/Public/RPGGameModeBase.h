// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "GameFramework/GameModeBase.h"
#include "LuaImplementableInterface.h"
#include "RPGGameModeBase.generated.h"

/** Base class for GameMode, should be blueprinted */
UCLASS()
class ACTIONRPG_API ARPGGameModeBase : public AGameModeBase, public ILuaImplementableInterface
{
	GENERATED_BODY()

public:
	/** Constructor */
	ARPGGameModeBase();

protected:
	virtual void BeginPlay() override;
	virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
	virtual void BeginDestroy() override;
	virtual void ProcessEvent(UFunction* Function, void* Parameters) override;
	virtual FString OnInitBindingLuaPath_Implementation() override;
	virtual bool ShouldEnableLuaBinding_Implementation() override;

protected:
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "LuaImplementable", meta = (AllowPrivateAccess = "true"))
	FString LuaFilePath;
};

