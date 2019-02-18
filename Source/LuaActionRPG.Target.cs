// Copyright 1998-2018 Epic Games, Inc. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class LuaActionRPGTarget : TargetRules
{
	public LuaActionRPGTarget(TargetInfo Target)
		: base(Target)
	{
		Type = TargetType.Game;
		ExtraModuleNames.AddRange(new string[] { "ActionRPG" });

		bUseLoggingInShipping = true;
	}
}
