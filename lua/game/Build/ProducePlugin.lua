local const = GMethod.loadScript("game.GameLogic.Const")

local ProducerPlugin = {}
function ProducerPlugin:onInit(stime)
    self.extData = {0,stime}
end
function ProducerPlugin:onReload(stime)
    if stime then
        self.extData[1] = 0
        self.extData[2] = stime
    end
end

function ProducerPlugin:getResource(useInt)
    if self.worklist then
        return 0
    end
    local ed = self.extData
    local stime = useInt and GameLogic.getSTime() or GameLogic.getSFloatTime()
    local et = stime - ed[2]
    if et<0 then
        et = 0
    end
    if self.boostlist then
        local sb, eb = self.boostlist[3], self.boostlist[4]
        if sb<ed[2] then
            sb = ed[2]
        end
        if eb>stime then
            eb = stime
        end
        if eb>sb then
            local c, r, t = self:getBoostParam()
            et = et+(eb-sb)*(r-1)
        end
    end
    local ev = math.floor(et*self.data.produce/3600)+ed[1]
    if ev>self.data.max then
        ev = self.data.max
    end
    return ev
end

function ProducerPlugin:collectResource(silence)
    local canGet = self:getResource(true)
    local buffInfo = self.context.activeData:getBuffInfo(const.ActTypeBuffHuiGui)
    canGet = canGet*(buffInfo[4]+1)
    local max = self.context:getResMax(self.extSetting)
    local value = self.context:getRes(self.extSetting)
    local realGet = canGet
    if value+canGet>max then
        realGet = max-value
        if not silence then
            display.pushNotice(StringManager.getFormatString("noticeStorageFull",{name=BU.getBuildName(12)}))
        end
    end
    if realGet>0 then
        local stime = GameLogic.getSTime()
        local oldExt1 = self.extData[1]
        local oldExt2 = self.extData[2]
        self.extData[1] = canGet-realGet
        self.extData[2] = stime
        self.context.buildData:collectResource(self, stime, realGet, oldExt1, oldExt2)
        local num = math.ceil(realGet/100)
        if num>10 then
            num = 10
        end
        local effect = ResourceCollectionEffect.new(num)
        local vstate = self.vstate
        display.adapt(effect, vstate.view:getPositionX(), vstate.view:getPositionY()+vstate.view:getContentSize().height/2+60)
        vstate.upNode:getParent():addChild(effect, 10000)
        if buffInfo[4]>0 then
            effect:displayNumber(math.floor(realGet/(buffInfo[4]+1)),buffInfo[4]+1)
        else
            effect:displayNumber(realGet)
        end
    else
        music.play("sounds/goldCannotGet.mp3")
    end
    self:updateOperation(0)
    return realGet
end

function ProducerPlugin:beforeUpgrade()
    self:collectResource(true)
end

function ProducerPlugin:getBoostParam()
    return self.data.boostCost, const.ProduceBoostRate, const.ProduceBoostTime/3600
end

function ProducerPlugin:addMenuButs(buts, item)
    local wl = self.worklist
    if not wl then
        if item=="boost" then
            local c, r, t = self:getBoostParam()
            if c then
                local cbut = {key="boost", callback=self.onBoostBuild, cp1=self, exts={text={},upText={}, ricon={alpha=255}, rcost={text=c, alpha=255}, bicon = {alpha=255}}}
                self:updateBoostBut(cbut)
                cbut.update = Handler(self.updateBoostBut, self, cbut)
                table.insert(buts, cbut)
            end
        elseif item=="collect" then
            local cbut = {key="collect", callback=self.onCollect, cp1=self, exts={ricon={alpha = 255, icon=self.extSetting}}}
            local canGet = self:getResource()
            if canGet<10 then
                cbut.back = "images/autoBattleBack2.png"
                cbut.exts.ricon.alpha=128
            end
            cbut.update = Handler(self.updateCollectBut, self, cbut)
            table.insert(buts, cbut)
        end
    end
end

function ProducerPlugin:onBoostBuild(force)
    if self.boostlist then
        return
    end
    local cost,rate,time = self:getBoostParam()
    local context = GameLogic.getUserContext()
    local num = context:getVipPermission("accres")[2]
    if num>0 then
        cost = 0
    end
    if not force then
        local title,des = Localize("alertTitleSpeedupBuild"),Localizef("alertTextSpeedupBuild",{rate=rate, time=time})
        if num>0 then
            title = Localize("labelVipFrenAcc")
            des = Localizef("labelTodayRemainTimes",{a = num})
        end
        display.showDialog(AlertDialog.new(1,title,des,{callback=Handler(self.onBoostBuild, self, true), ctype=const.ResCrystal, cvalue=cost}))
    else
        if cost>self.context:getRes(const.ResCrystal) then
            display.showDialog(AlertDialog.new({ctype=const.ResCrystal}))
        else
            self:addBoostEffect()
            self.context.buildData:beginBoostBuild(self, GameLogic.getSTime(), time*3600, cost)
            self:reloadEffectShadow()
        end

        if num>0 then
            context.vips[2][2] = GameLogic.getSTime()
            context.vips[2][3] = context.vips[2][3]+1
        end
    end
end

function ProducerPlugin:boostOver(stime)
    local ed = self.extData
    ed[1] = self:getResource(true)
    ed[2] = stime
    self.context.buildData:boostOverBuild(self, stime)
    self:reloadEffectShadow()
end

function ProducerPlugin:onCollect()
    local canGet = self:getResource()
    local buffInfo = self.context.activeData:getBuffInfo(const.ActTypeBuffHuiGui)
    canGet = canGet*(buffInfo[4]+1)
    if canGet>=10 then
        self:collectResource()
    end
end

function ProducerPlugin:updateCollectBut(butInfo)
    local canGet = self:getResource()
    local image, alpha = nil, 255
    if canGet<10 then
        image = "images/autoBattleBack2.png"
        alpha = 128
    end
    if alpha~=butInfo.exts.ricon.alpha then
        butInfo.exts.ricon.alpha = alpha
        butInfo.back = image
        BU.reloadMenuBut(butInfo, butInfo.but)
    end
end

function ProducerPlugin:updateBoostBut(butInfo)
    local image, alpha, alpha2, text, color ,upText= nil, 255, 255, Localize("wordBoost"), nil,Localize("")
    local bc,_,_ = self:getBoostParam()

    --vip免费加速
    local context = GameLogic.getUserContext()
    local num = context:getVipPermission("accres")[2]
    if num>0 then
        bc = 0
    end
    if self.boostlist then
        image = "images/autoBattleBack2.png"
        alpha = 128
        alpha2 = 0
        text = Localizet(self.boostlist[4]-GameLogic.getSTime())
        color = {219,249,168}
        upText=Localize("labelBoostSurplus")
    end
    if text~=butInfo.exts.text.text or bc~=butInfo.exts.rcost.text then
        butInfo.exts.bicon.alpha = alpha
        butInfo.exts.ricon.alpha = alpha2
        butInfo.exts.rcost.alpha = alpha2
        butInfo.exts.rcost.text = bc
        butInfo.back = image
        butInfo.exts.text.text = text
        butInfo.exts.text.color = color

        butInfo.exts.upText.text = upText
        if butInfo.but then
            BU.reloadMenuBut(butInfo, butInfo.but)
        end
    end
end

function ProducerPlugin:updateOperation(diff)
    if self.context.guide:getStep().type ~= "finish" then
        return
    end
    local backType = 0
    local rtype = self.extSetting
    if not self.worklist and not BU.getPlanDelegate() and self:getResource()>=self.data.max/200 then
        if self.context:getResMax(rtype)<=self.context:getRes(rtype) then
            backType = 2
        else
            backType = 1
        end
    end
    self:reloadUpIcon(backType, rtype)
    self:addMoneyView(self:getResource()/self.data.max)
end

function ProducerPlugin:onUpTouch()
    return self:collectResource() > 0
end

function ProducerPlugin:readyToBattle()
    if self.extSetting==const.ResGold then
        local scene = self.vstate.scene
        if scene.battleType==1 then
            local percent = scene.battleParams.resPercents[3]
            self.resInfo = {math.ceil(self:getResource()*percent/100), 0, 0, 0}
            if self.resInfo[1]==0 then
                return
            end
            self.update = self.updateBattle
            scene.battleParams.cget = scene.battleParams.cget + self.resInfo[1]
        end
    end
end

function ProducerPlugin:showEffect()
    local resInfo = self.resInfo
    if not resInfo then
        return
    end
    local cv = resInfo[1]-math.floor(resInfo[1]*self.avtInfo.nowHp/self.avtInfo.maxHp)
    if cv~=resInfo[4] then
        local bp = self.vstate.scene.battleParams
        bp.get = bp.get+cv-resInfo[4]
        resInfo[2] = resInfo[2]+cv-resInfo[4]
        resInfo[4] = cv
    end
    self:updateBattle(0)
end

function ProducerPlugin:updateBattle(diff)
    BuffUtil.updateBuff(self, diff)
    if self.deleted then
        return false
    end
    local resInfo = self.resInfo
    if resInfo[2]>=1 then
        resInfo[3] = resInfo[3]-diff
        if resInfo[3]<=0 then
            local num = math.ceil(resInfo[2]/500)
            if num>3 then
                num = 3
            end
            local effect = ResourceCollectionEffect.new(num)
            local vstate = self.vstate
            display.adapt(effect, vstate.view:getPositionX(), vstate.view:getPositionY()+vstate.view:getContentSize().height/2+60)
            vstate.view:getParent():addChild(effect, vstate.cpz)
            effect:displayNumber(resInfo[2])
            resInfo[2] = 0
            resInfo[3] = 0.1
        end
    end
    return true
end

return ProducerPlugin
