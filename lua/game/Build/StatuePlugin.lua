local const = GMethod.loadScript("game.GameLogic.Const")

local StatuePlugin = {}
function StatuePlugin:onInit()
    local context = self.context
    if self.vstate.scene.sceneType == "visit" then
        context = GameLogic.getCurrentContext()
    end
    local etime, rank, name
    if self.bid == 186 or self.bid == 187 then 
        etime = context.rankList[self.bid][2]
        rank = context.rankList[self.bid][1]
    else
        etime = context.rankList[self.bid][2]
        rank = context.rankList[self.bid][1]+1
    end
    self.extData = {rank,etime}
end

function StatuePlugin:isStatue()
    return true
end

-- 神像属性实装比例
local _statuePercent = 1

function StatuePlugin:addDefBuff(defBuff)
    local _hpRate = (self.data.hpRate or 0)/100
    local _atkRate = (self.data.atkRate or 0)/100
    local bdid = self.bsetting.bdid
    if bdid == 50107 then --英雄角逐
        defBuff.defenseParam = 1 - _hpRate * _statuePercent
    elseif bdid == 50104 then --联盟副本榜
        defBuff.defBuildHp = (defBuff.defBuildHp or 0) + _hpRate * _statuePercent
        defBuff.defBuildAtk = (defBuff.defBuildAtk or 0) + _atkRate * _statuePercent
    elseif bdid == 50102 then --个人竞技榜
        defBuff.defBuildHp = (defBuff.defBuildHp or 0) + _hpRate * _statuePercent
    elseif bdid == 50101 then --顶级玩家榜
        defBuff.defBuildAtk = (defBuff.defBuildAtk or 0) + _atkRate * _statuePercent
    end
end

function StatuePlugin:addAtkBuff(atkBuff)
    local _hpRate = (self.data.hpRate or 0)/100
    local _atkRate = (self.data.atkRate or 0)/100
    local bdid = self.bsetting.bdid
    if bdid == 50106 then --末日争霸
        atkBuff.atkPct = (atkBuff.atkPct or 0) + _hpRate * _statuePercent
    elseif bdid == 50105 then --联盟金杯榜
        atkBuff.soldierAtk = (atkBuff.soldierAtk or 0) + _atkRate * _statuePercent
        atkBuff.soldierHp = (atkBuff.soldierHp or 0) + _hpRate * _statuePercent
    elseif bdid == 50103 then --英雄试炼榜
        atkBuff.heroHp = (atkBuff.heroHp or 0) + _hpRate * _statuePercent
    end
end

function StatuePlugin:updateOperation(diff)
    local context = self.context
    local vstate = self.vstate
    if self.extData and not vstate.remainTime then
        local rank = self.extData[1]
        local name
        local statueName
        local rankNameH = 60
        local statueNameH = -90
        local remainTimeH = -30
        if self.bid == 186 then 
            local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
            -- local kind = KnockMatchData:getStatueKind(self.bid)
            local kind = self.level
            name = Localizef("dataRankNeed"..self.bid.."_"..kind)
            statueName = context.rankList[self.bid] and (context.rankList[self.bid][3] or "") or ""
        elseif self.bid == 187 then
            local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
            -- local kind = KnockMatchData:getStatueKind(self.bid)
            local kind = self.level
            name = Localizef("dataRankNeed"..self.bid.."_"..kind)
            statueName = Localize(BU.getBuildName(self.bid, kind))
        else
            name = Localizef("dataRankNeed" .. self.bid,{a = rank})
            statueName = Localizef(BU.getBuildName(self.bid,self.level))
        end
        vstate.rankName = ui.label(name, General.font1,45)
        local view = vstate.upNode
        local x = view:getContentSize().width/2
        local y = self:getHeight()
        display.adapt(vstate.rankName,x,y+rankNameH,GConst.Anchor.Center)
        view:addChild(vstate.rankName)

        vstate.statueName = ui.label(statueName, General.font1,60)
        display.adapt(vstate.statueName,x,y+statueNameH,GConst.Anchor.Center)
        view:addChild(vstate.statueName)

        vstate.remainTime = ui.label(Localize(""),General.font1,35)
        display.adapt(vstate.remainTime,x,y+remainTimeH,GConst.Anchor.Center)
        view:addChild(vstate.remainTime)
        vstate.remainTime:setVisible(false)
    end
    if General.language == "DE" or General.language == "FR" then
        vstate.rankName:setVisible(false)
    end
    if vstate.remainTime then
        local etime =  self.extData[2]
        local rtime = etime-GameLogic.getSTime()
        vstate.remainTime:setString(Localizet(rtime) .. Localize("labelMiss"))
        if self.vstate.focus then
            vstate.statueName:setVisible(true)
            vstate.remainTime:setVisible(true)
        else
            vstate.statueName:setVisible(false)
            vstate.remainTime:setVisible(false)
        end
        if rtime<=0 then
            if context.buildData then
                context.buildData:removeStatue(self)
            end
            self:removeFromScene()
        end
    end
end

return StatuePlugin