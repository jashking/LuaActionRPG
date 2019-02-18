@echo off

rem comment Agenda.DotNetProjects.Add(@"Engine\Source\Programs\IOS\iPhonePackager\iPhonePackager.csproj") in IOSPlatform.Automation.cs if build failed
rem see https://github.com/EpicGames/UnrealEngine/commit/454ac079c3f2bd7eb0b4018e18ff7cf5989e2170

set Target="Build Game iOS"
set IterativeCooking=true
set BuildConfiguration=Development
set WithClean=false

call BaseCommand.bat