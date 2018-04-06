-- 青年节活动创建的特殊神像：由完成活动触发，永久性存在
local const = GMethod.loadScript("game.GameLogic.Const")
local StatuePlugin = {}
function StatuePlugin:updateOperation(diff)
    local rankNameH = 22.5
    local vstate = self.vstate
    if not vstate.rankName then
        local name = BU.getBuildName(self.bid)

        vstate.rankName = ui.label(name, General.font1,45)
        local view = vstate.upNode
        local x = view:getContentSize().width/2
        local y = self:getHeight()
        display.adapt(vstate.rankName,x,y+rankNameH,GConst.Anchor.Center)
        view:addChild(vstate.rankName)
    end
end

function StatuePlugin:addDefBuff(defBuff)
    local _hpRate = (self.data.hpRate or 0)/100
    local _atkRate = (self.data.atkRate or 0)/100
    defBuff.defBuildHp = (defBuff.defBuildHp or 0) + _hpRate
    defBuff.defBuildAtk = (defBuff.defBuildAtk or 0) + _atkRate
end

return StatuePlugin