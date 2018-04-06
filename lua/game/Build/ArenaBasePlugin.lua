local const = GMethod.loadScript("game.GameLogic.Const")

local ArenaBasePlugin = {}

function ArenaBasePlugin:addMenuButs(buts, item)
    if item=="arena" then
        -- 竞技场添加角标
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffPVC)
        local item = {key="arena", callback=function()
            --这里因为埋点的问题，所以加了一个区别参数
            display.showDialog(ArenaDialog.new({jumpType = 1}))
            local context = GameLogic.getUserContext()
            local step = context.guideOr:getStep()
            if step == 25 then
                context.guideOr:setStep(61)
                context.guideHand:removeHand("guideOrBuildBtn")
            end
        end}
        if buffInfo[4] > 0 then
            item.leftTopText = Localize("activity")
        end
        table.insert(buts, item)
    elseif item=="layout" then
        table.insert(buts, {key="layout", callback=self.showSelectDialog, cp1=self})
    end
end

function ArenaBasePlugin:showSelectDialog()
    SetBattleArrDialog.new(2)
end

function ArenaBasePlugin:updateOperation()
    if BU.getPlanDelegate() then
        return
    end
    local context = GameLogic.getUserContext()
    if context.arena then
        if context.arena:getCurrentChance()>0 and not self.worklist then
            self:reloadUpText(1, Localize("btnChallenge"))
        else
            self:reloadUpText(0, Localize("btnChallenge"))
        end
    end
end

return ArenaBasePlugin
