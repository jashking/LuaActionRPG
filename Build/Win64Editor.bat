@echo off

set CurrentPath=%~dp0

call "D:\Workspace\UnrealEngine\Engine\Build\BatchFiles\RunUAT.bat" BuildGraph -Script="%CurrentPath%AllBuild.xml" -Target="Build Editor Win64" -set:ProjectDir=%CurrentPath%.. -set:ProjectName=LuaActionRPG

pause