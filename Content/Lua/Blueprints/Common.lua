local m = {}

m.ESlateVisibility = {
    Visible = 0,
    Collapsed = 1,
    Hidden = 2,
    HitTestInvisible = 3,
    SelfHitTestInvisible = 4,
}

m.EInputEvent = {
    IE_Pressed = 0,
    IE_Released = 1,
    IE_Repeat = 2,
    IE_DoubleClick = 3,
    IE_Axis = 4,
    IE_MAX = 5,
}

m.EUMGSequencePlayMode = {
    Forward = 0,
    Reverse = 1,
    PingPong = 2,
}

function m:IsRunningOnMobile()
    local LoadClass = LoadClass
    local GameplayStatics = LoadClass('GameplayStatics')

    local PlatformName = GameplayStatics:GetPlatformName()
    if PlatformName == 'Android' or PlatformName == 'IOS' then
        return true, PlatformName
    end

    return false, PlatformName
end

return m