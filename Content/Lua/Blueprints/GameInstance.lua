local m = {}

-- parent UObject
local Super = Super

-- global functions
local LoadClass = LoadClass
local CreateDelegate = CreateDelegate
local CreateLatentAction = CreateLatentAction

-- C++ library
local GameplayStatics = LoadClass('GameplayStatics')
local BlueluaLibrary = LoadClass('BlueluaLibrary')
local KismetSystemLibrary = LoadClass('KismetSystemLibrary')
local KismetMathLibrary = LoadClass('KismetMathLibrary')

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
    for k, _ in pairs(Super.ItemSlotsPerType) do
        local OutPrimaryAssetIdList = KismetSystemLibrary:GetPrimaryAssetIdList(k)

        local AsyncLoader = AsyncActionLoadPrimaryAssetListClass:AsyncLoadPrimaryAssetList(Super, OutPrimaryAssetIdList, nil)
        AsyncLoaders[tostring(AsyncLoader)] = AsyncLoader

        AsyncLoader.Completed:Add(function(Loaded)
                local CurrentLoader = AsyncLoader

                for _, Item in ipairs(Loaded) do
                    table.insert(self.StoreItems, Item)
                end
                
                AsyncLoaders[tostring(CurrentLoader)] = nil
            end)
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

return m