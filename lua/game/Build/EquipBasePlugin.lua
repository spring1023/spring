local EquipBasePlugin = {}

function EquipBasePlugin:addMenuButs(buts, item)
    if item=="forge" then
        table.insert(buts, {key="forge", callback=display.showDialog, cp1=EquipDialog})
    elseif item=="store" then
        table.insert(buts, {key="store", callback=StoreDialog.new, cp1={stype="equip",idx=1}})
    elseif item=="challenge" then
        table.insert(buts, {key="challenge", callback=function()
            zombieIncomingDialog.new()
            local context = GameLogic.getUserContext()
            local step = context.guideOr:getStep()
            if step == 45 then
                context.guideOr:setStep(step+1)
                context.guideHand:removeHand("guideOrBuildBtn")
            end
        end})
    end
end

return EquipBasePlugin
