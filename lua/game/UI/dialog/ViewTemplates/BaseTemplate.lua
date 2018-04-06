local LG = GMethod.loadScript("game.GameLogic.LogicTemplates.Init")

local _Impls = {}
local Base = {}

function Base.registerImplement(key, impl)
    _Impls[key] = impl
end

function Base.setImplements(interface, implKey, implParams)
    local impl = _Impls[implKey]
    if impl then
        LG.setImplements(interface, impl)
        impl._static_load(interface, implParams)
    end
end

-- 加入英雄通用cell
function Base.updateSimpleHeroCell(reuseCell, layout, info)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    GameUI.refreshHeroHead(reuseCell.heroHead, info[1], {level=info[3], starUp=info[2]}, {isLv=true})
    return reuseCell
end

return Base
