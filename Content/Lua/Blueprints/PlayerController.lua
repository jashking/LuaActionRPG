local m = {}

local Super = Super
local LoadClass = LoadClass
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

local GameplayStatics = LoadClass('GameplayStatics')
local BlueluaLibrary = LoadClass('BlueluaLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')

local WorldContextObject = BlueluaLibrary:GetWorldContext()

function m:PlaySkippableCutscene(SequencePlayer)
    Super.SequencePlayer = SequencePlayer

    SequencePlayer.OnFinished:Add(self, self.StopPlayingSkippableCutscene)
    SequencePlayer:Play()

    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBSkipIntroClass = LoadClass('/Game/Blueprints/WidgetBP/WB_SkipIntro.WB_SkipIntro_C')
    self.SkipIntroWidget = WidgetBlueprintLibrary:Create(WorldContextObject, WBSkipIntroClass, Super)
    self.SkipIntroWidget:AddToViewport(0)
    self:ShowHUD(false)
end

function m:StopPlayingSkippableCutscene()
    if self.StopPlayingSkippableCutsceneOnce then
        return
    end
    self.StopPlayingSkippableCutsceneOnce = true

    Super.SequencePlayer:Stop()
    self:ShowHUD(true)

    local GameMode = GameplayStatics:GetGameMode(WorldContextObject)
    GameMode:ToLuaObject():StartGame()

    self.SkipIntroWidget:RemoveFromParent()
    self.SkipIntroWidget = nil
end

function m:ShowHUD(bShow)
    local bRunningOnMobile = self:IsRunningOnMobile()
    Super:SetVirtualJoystickVisibility(bShow and bRunningOnMobile)

    --TODO: move to common lua
    local ESlateVisibility = {
        Visible = 0,
        Collapsed = 1,
        Hidden = 2,
        HitTestInvisible = 3,
        SelfHitTestInvisible = 4,
    }

    if Super.OnScreenControls then
        Super.OnScreenControls:SetVisibility(bShow and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Hidden)
    end
end

function m:CreateHUD()
    if Super.OnScreenControls then
        self:ShowHUD(true)
        return
    end
    
    local WidgetBlueprintLibrary = LoadClass('WidgetBlueprintLibrary')
    local WBOnScreenControlsClass = LoadClass('/Game/Blueprints/WidgetBP/WB_OnScreenControls.WB_OnScreenControls_C')
    Super.OnScreenControls = WidgetBlueprintLibrary:Create(WorldContextObject, WBOnScreenControlsClass, Super)
    Super.OnScreenControls:AddToViewport(0)
    Super.OnScreenControls:UpdateCurrentIcons()
end

function m:ReceivePossess(NewPawn)
    if self.ReceivePossessOnce then
        return
    end
    self.ReceivePossessOnce = true

    Super.PlayerCharacter = NewPawn
    self:CreateHUD()

    Super.OnInventoryItemChanged:Add(self, self.OnInventoryItemChanged)

    local LatentActionInfo = CreateLatentAction(CreateDelegate(Super,
        function()
            Super.PlayerCharacter:CreateAllWeapons()
        end))

    KismetSystemLibrary:Delay(WorldContextObject, 0.025, LatentActionInfo)
end

-- bool bAdded, URPGItem* Item
function m:OnInventoryItemChanged(bAdded, Item)
    Super:HandleInventoryItemChanged(bAdded, Item)
end

--TODO: move to common lua
function m:IsRunningOnMobile()
    local PlatformName = GameplayStatics:GetPlatformName()
    if PlatformName == 'Android' or PlatformName == 'IOS' then
        return true, PlatformName
    end

    return false, PlatformName
end

return m