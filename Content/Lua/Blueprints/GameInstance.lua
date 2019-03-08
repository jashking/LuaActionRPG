local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local BlueluaLibrary = LoadClass('BlueluaLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local KismetMathLibrary = LoadClass('KismetMathLibrary')

if SupportLuaPanda then
    require('LuaPanda').start('127.0.0.1', 8018)
end

function m:ReceiveInit()
    self.StoreItems = {}

    self:InitializeStoreItems()
    Super:SetSavingEnabled(true)
    local bLoad = Super:LoadOrCreateSaveGame()
    if bLoad then
        print('Loaded Save Game')
    else
        Super:WriteSaveGame()
        print('New Save Game')
    end
end

function m:InitializeStoreItems()
    local AsyncActionLoadPrimaryAssetListClass = LoadClass('AsyncActionLoadPrimaryAssetList')
    
    local AsyncLoaders = {}
    
    self.CompletedDelegates = {}

    for k, _ in pairs(Super.ItemSlotsPerType) do
        local OutPrimaryAssetIdList = KismetSystemLibrary:GetPrimaryAssetIdList(k)

        local AsyncLoader = AsyncActionLoadPrimaryAssetListClass:AsyncLoadPrimaryAssetList(Super, OutPrimaryAssetIdList, nil)
        AsyncLoaders[tostring(AsyncLoader)] = AsyncLoader

        self.CompletedDelegates[tostring(AsyncLoader)] = CreateFunctionDelegate(Super,
            function(Loaded)
                local CurrentLoader = AsyncLoader

                for _, Item in ipairs(Loaded) do
                    table.insert(self.StoreItems, Item)
                end
                
                AsyncLoaders[tostring(CurrentLoader)] = nil

                self.CompletedDelegates[tostring(CurrentLoader)]:Clear()
                self.CompletedDelegates[tostring(CurrentLoader)] = nil
            end)

        AsyncLoader.Completed:Add(self.CompletedDelegates[tostring(AsyncLoader)])
        AsyncLoader:Activate()
    end
end

function m:GetStoreItems(ItemType)
    local FilterItems = {}
    for _, Item in ipairs(self.StoreItems) do
        local PrimaryAssetId = KismetSystemLibrary:GetPrimaryAssetIdFromObject(Item)
        if KismetSystemLibrary:EqualEqual_PrimaryAssetType(ItemType, PrimaryAssetId.PrimaryAssetType) then
            table.insert(FilterItems, Item)
        end
    end

    return FilterItems
end

function m:FadeInAndShowLoadingScreen()
    local RPGBlueprintLibrary = LoadClass('RPGBlueprintLibrary')
    RPGBlueprintLibrary:PlayLoadingScreen(true, 3)
end

function m:LoadGameLevel()
    local WidgetLayoutLibrary = LoadClass('WidgetLayoutLibrary')
    WidgetLayoutLibrary:RemoveAllWidgets(Super)

    self:FadeInAndShowLoadingScreen()

    GameplayStatics:OpenLevel(Super, 'ActionRPG_P', false, nil)
end

function m:RestartGameLevel()
    self:FadeInAndShowLoadingScreen()
    self:LoadGameLevel()
end

return m