// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

#include "ActionRPG.h"
#include "RPGSaveGame.h"
#include "RPGGameInstanceBase.h"

void URPGSaveGame::Serialize(FArchive& Ar)
{
	Super::Serialize(Ar);

	if (Ar.IsLoading() && SavedDataVersion != ERPGSaveGameVersion::LatestVersion)
	{
		if (SavedDataVersion < ERPGSaveGameVersion::AddedItemData)
		{
			// Convert from list to item data map
			for (const FPrimaryAssetId& ItemId : InventoryItems_DEPRECATED)
			{
				InventoryData.Add(ItemId, FRPGItemData(1, 1));
			}

			InventoryItems_DEPRECATED.Empty();
		}
		
		SavedDataVersion = ERPGSaveGameVersion::LatestVersion;
	}
}