// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#include "ActionRPG.h"
#include "RPGBlueprintLibrary.h"
#include "ActionRPGLoadingScreen.h"


URPGBlueprintLibrary::URPGBlueprintLibrary(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
}

void URPGBlueprintLibrary::PlayLoadingScreen(bool bPlayUntilStopped, float PlayTime)
{
	IActionRPGLoadingScreenModule& LoadingScreenModule = IActionRPGLoadingScreenModule::Get();
	LoadingScreenModule.StartInGameLoadingScreen(bPlayUntilStopped, PlayTime);
}

void URPGBlueprintLibrary::StopLoadingScreen()
{
	IActionRPGLoadingScreenModule& LoadingScreenModule = IActionRPGLoadingScreenModule::Get();
	LoadingScreenModule.StopInGameLoadingScreen();
}

bool URPGBlueprintLibrary::IsInEditor()
{
	return GIsEditor;
}

bool URPGBlueprintLibrary::EqualEqual_RPGItemSlot(const FRPGItemSlot& A, const FRPGItemSlot& B)
{
	return A == B;
}

bool URPGBlueprintLibrary::NotEqual_RPGItemSlot(const FRPGItemSlot& A, const FRPGItemSlot& B)
{
	return A != B;
}

bool URPGBlueprintLibrary::IsValidItemSlot(const FRPGItemSlot& ItemSlot)
{
	return ItemSlot.IsValid();
}

bool URPGBlueprintLibrary::DoesEffectContainerSpecHaveEffects(const FRPGGameplayEffectContainerSpec& ContainerSpec)
{
	return ContainerSpec.HasValidEffects();
}

bool URPGBlueprintLibrary::DoesEffectContainerSpecHaveTargets(const FRPGGameplayEffectContainerSpec& ContainerSpec)
{
	return ContainerSpec.HasValidTargets();
}

FRPGGameplayEffectContainerSpec URPGBlueprintLibrary::AddTargetsToEffectContainerSpec(const FRPGGameplayEffectContainerSpec& ContainerSpec, const TArray<FHitResult>& HitResults, const TArray<AActor*>& TargetActors)
{
	FRPGGameplayEffectContainerSpec NewSpec = ContainerSpec;
	NewSpec.AddTargets(HitResults, TargetActors);
	return NewSpec;
}

TArray<FActiveGameplayEffectHandle> URPGBlueprintLibrary::ApplyExternalEffectContainerSpec(const FRPGGameplayEffectContainerSpec& ContainerSpec)
{
	TArray<FActiveGameplayEffectHandle> AllEffects;

	// Iterate list of gameplay effects
	for (const FGameplayEffectSpecHandle& SpecHandle : ContainerSpec.TargetGameplayEffectSpecs)
	{
		if (SpecHandle.IsValid())
		{
			// If effect is valid, iterate list of targets and apply to all
			for (TSharedPtr<FGameplayAbilityTargetData> Data : ContainerSpec.TargetData.Data)
			{
				AllEffects.Append(Data->ApplyGameplayEffectSpec(*SpecHandle.Data.Get()));
			}
		}
	}
	return AllEffects;
}

FGameplayTag URPGBlueprintLibrary::MakeGameplayTag(FName TagName)
{
	return FGameplayTag::RequestGameplayTag(TagName);
}

void URPGBlueprintLibrary::AddGameplayTagToContainer(FGameplayTagContainer& TagContainer, const FGameplayTag& Tag)
{
	TagContainer.AddTag(Tag);
}

FRPGItemSlot URPGBlueprintLibrary::MakeRPGItemSlot(FName PrimaryAssetTypeName, int32 InSlotNumber)
{
	return FRPGItemSlot(FPrimaryAssetType(PrimaryAssetTypeName), InSlotNumber);
}

void URPGBlueprintLibrary::BindAction(AActor* TargetActor, FName ActionName, EInputEvent KeyEvent, FInputActionHandlerDynamicSignature Action)
{
	if (!TargetActor || !TargetActor->InputComponent)
	{
		return;
	}

	FInputActionBinding AB(ActionName, KeyEvent);
	AB.ActionDelegate.BindDelegate(Action.GetUObject(), Action.GetFunctionName());
	TargetActor->InputComponent->AddActionBinding(AB);
}

void URPGBlueprintLibrary::BindAxisAction(AActor* TargetActor, FName AxisName, FInputAxisHandlerDynamicSignature Action)
{
	if (!TargetActor || !TargetActor->InputComponent)
	{
		return;
	}

	FInputAxisBinding AxisBinding(AxisName);
	AxisBinding.AxisDelegate.BindDelegate(Action.GetUObject(), Action.GetFunctionName());

	TargetActor->InputComponent->AxisBindings.Emplace(AxisBinding);
}

void URPGBlueprintLibrary::BindTouchAction(AActor* TargetActor, EInputEvent InputEvent, FInputTouchHandlerDynamicSignature Action)
{
	if (!TargetActor || !TargetActor->InputComponent)
	{
		return;
	}

	FInputTouchBinding TouchBinding(InputEvent);
	TouchBinding.TouchDelegate.BindDelegate(Action.GetUObject(), Action.GetFunctionName());

	TargetActor->InputComponent->TouchBindings.Emplace(TouchBinding);
}
