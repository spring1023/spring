local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local StoragePlugin = {}
--
function StoragePlugin:onInit()
    if self.level==0 then
        self.extData = {0, 0}
    else
        self.extData = {self.extSetting[2], self.data.max}
        self.context:changeResMax(self.extSetting[1], self.extData[2])
        if self.extData[1]>0 then
            self.context:changeRes(self.extSetting[1], self.extData[1])
        end
    end
    self.context.resData:addStorage(self.extSetting[1], self)
end
function StoragePlugin:onReload()
    if not self.extData then
        return
    end
    if self.data.max~=self.extData[2] then
        self.context:changeResMax(self.extSetting[1], self.data.max-self.extData[2])
    end
    self.extData[2] = self.data.max
    self.context.resData:addStorage(self.extSetting[1], self)
    if self.bid == const.BuilderRoom and not BU.getPlanDelegate() and (self.vstate.scene.sceneType == "operation" or self.vstate.scene.sceneType == "visit")then
        self:initBuilderRoom()
    end
end
function StoragePlugin:onRemove()
    if not self.extData then
        return
    end
    self.context.resData:removeStorage(self.extSetting[1], self)
    if self.extData[1]>0 then
        self.context:changeRes(self.extSetting[1], -self.extData[1])
    end
    self.context:changeResMax(self.extSetting[1], -self.extData[2])
end
function StoragePlugin:getResource()
    return self.extData[1]
end

function StoragePlugin:onClean()
    if self.roles then
        local roles = self.roles
        for _, troop in ipairs(roles) do
            troop:removeFromScene()
        end
    end
    self.roles = nil
end

function StoragePlugin:showPlanDialog()
    local scene = self.vstate.scene
    if scene and scene.menu and scene.menu.inCount then
        local dialog = PlanDialog.new(scene)
        display.showDialog(dialog, false)
    end
end

function StoragePlugin:addMenuButs(buts, item)
    if item=="plan" then
        table.insert(buts, {key="plan", callback=self.showPlanDialog, cp1=self})
    elseif item=="rename" then
        if not self.worklist then
            table.insert(buts, {key="rename", callback=GameLogic.doComicJump})
        end
    end
end

function StoragePlugin:readyToBattle()
    local scene = self.vstate.scene
    self.update = nil
    --僵尸主城加僵尸逻辑
    if self.bid == 1 and (scene.battleType == const.BattleTypePve or scene.battleType == const.BattleTypeUPve) then
        self.useZombieUpdate = true
        self.update = self.updateBattle
        self.zbConfig = {}
        for k,v in pairs(SData.getData("zbTown",self.level)) do
            for i=1,v.num do
                table.insert(self.zbConfig,{k,v.zblv})
            end
        end
        self.rd = RdUtil.new(self.vstate.gx*100+self.vstate.gy)
        self.coldTime = 0.5
    end
    if self.extSetting[1]==const.ResGold then
        if scene.battleType==1 then
            local percent = self.id==const.Town and scene.battleParams.resPercents[1] or scene.battleParams.resPercents[2]
            self.resInfo = {math.ceil(self:getResource()*percent/100), 0, 0, 0}
            if self.resInfo[1]==0 then
                return
            end
            self.update = self.updateBattle
            self.useResUpdate = true
            scene.battleParams.cget = scene.battleParams.cget + self.resInfo[1]
        end
    end
end

function StoragePlugin:updateAddZombie(diff)
    local vstate = self.vstate
    --警戒范围
    if not vstate.openAdd then
        self.coldTime = self.coldTime - diff
        if self.coldTime < 0 then
            local cx, cy = vstate.gx+vstate.gsize/2, vstate.gy+vstate.gsize/2
            for i, v in ipairs(self.battleMap.battler) do
                local tx, ty = v.V.gx, v.V.gy
                if (tx-cx)^2 + (ty-cy)^2 <= 100 then
                    vstate.openAdd = true
                    self.coldTime = 0
                    break
                end
            end
            self.coldTime = self.coldTime + 0.5
        end
        return
    end

    if not self.zbConfig[1] then
        return
    end
    self.coldTime = self.coldTime - diff
    if self.coldTime <= 0 then
        self.coldTime = self.coldTime + 0.15

        local idx = self.rd:randomInt(#self.zbConfig)
        local cf = table.remove(self.zbConfig, idx)
        local sinfo, sdata = self.context.heroData:getSoldierData(cf[1], cf[2])
        local person = PersonUtil.newPersonData(sinfo,sdata,{id=cf[1], level=cf[2]})

        local gx, gy = self.battleMap:getMoveArroundPosition(self)
        local px, py = vstate.scene.map.convertToPosition(gx, gy)
        local animateSp = ui.animateSprite(0.5,"addZbEffect_",12,{plist="images/addZbEffect.plist", autoRemove=true})
        display.adapt(animateSp, px, py, GConst.Anchor.Center)
        vstate.scene.bottom:addChild(animateSp, 10)
        vstate.scene.replay:addDelay(function()
            local newSoldier = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=2})
            newSoldier.noLengthLimit = true
            newSoldier:addToScene(vstate.scene, gx, gy)
        end,0.26)
    end
end

function StoragePlugin:showEffect()
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

function StoragePlugin:initBuilderRoom()
    local view = self.vstate.view
    if self.extData[1] == 1 then       --为1时上面有建造者
        if not self.vstate.builder then
            self.vstate.builder = PersonUtil.C({sid =1, target = self, state=AvtControlerState.BUILDER, group=1})
            self.vstate.builder.home = self
            self.vstate.builder:addToScene(self.vstate.scene)
            self.vstate.builder:setTarget(self)

            local views=self.vstate.bviews
            if self.vstate.scene.sceneType == "visit" then
                views[1]:setVisible(true)
                views[2]:setVisible(true)
                views[3]:setVisible(true)
                views[4]:setVisible(true)
            end
        end
    end
    GameEvent.registerEvent({GameEvent.EventBuilderCome, GameEvent.EventBuilderGo}, self, self.onBuilderAction)
end

function StoragePlugin:onBuilderAction(event, params)
    local vstate = self.vstate
    local pvstate = params.vstate
    if not vstate or not pvstate then
        return
    end
    if event == GameEvent.EventBuilderCome then
        if self.extData[1] == 0 then
            if vstate.builder and vstate.builder.target == self then
                vstate.builder:setTarget(params)
                return true
            end
        end
    elseif event == GameEvent.EventBuilderGo then
        if vstate.builder then
            if vstate.builder == pvstate.builder then
                pvstate.builder:setTarget(self)
                pvstate.builder = nil
                return true
            end
        else
            if pvstate.builder and not pvstate.builder.home then
                pvstate.builder.home = self
                pvstate.builder:setTarget(self)
                pvstate.builder = nil
                return true
            end
        end
    end
end

function StoragePlugin:updateBattle(diff)
    BuffUtil.updateBuff(self, diff)
    if self.deleted then
        return false
    end
    if self.useResUpdate then
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
                display.adapt(effect, vstate.view:getPositionX(), vstate.view:getPositionY()+vstate.view:getContentSize().height/2)
                vstate.view:getParent():addChild(effect, vstate.cpz)
                resInfo[2] = 0
                resInfo[3] = 0.1
            end
        end
    end
    if self.useZombieUpdate then
        self:updateAddZombie(diff)
    end
    return true
end
function StoragePlugin:updateOperation(diff)
    local vstate = self.vstate
    if vstate.bid==12 then
        self:addMoneyView(self:getResource()/self.data.max)
        if self:getResource()>=self.data.max and not vstate.upTextBack and not self.worklist then--已满
            self:reloadUpText(1,StringManager.getString("labelFull"))
        elseif self:getResource()<self.data.max and vstate.upTextBack then
            self:reloadUpText(0,StringManager.getString("labelFull"))
        end
    elseif vstate.bid == 1 then
        if vstate.scene.menu and vstate.scene.menu.inCount then
            local roles = self.roles
            if not roles then
                roles = {}
                self.roles = roles
            end
            local mnum = GEngine.getSetting("maxNpcNums")
            if mnum then
                if mnum[self.level] then
                    mnum = mnum[self.level]
                else
                    mnum = mnum[#mnum]
                end
            end
            if #roles < (mnum or 3) then
                local role =  PersonUtil.C({person=PersonUtil.newPersonData({aspeed=2000, speed=16, utype=1},{id=math.random(4, 5), level=1}), state=AvtControlerState.Npc, group=1})
                role.home = self
                role:addToScene(vstate.scene, vstate.gx + vstate.gsize / 2, vstate.gy, 6)
                table.insert(roles, role)
            end
        end
    end

    if self.bid == const.BuilderRoom then
        local views=vstate.bviews
        if self.extData[1] == 0 or not self.vstate.builder or self.vstate.builder.V.state ~= PersonState.FREE then
            views[1]:setVisible(false)
            views[2]:setVisible(false)
            views[3]:setVisible(false)
            views[4]:setVisible(false)
        elseif self.vstate.builder and self.vstate.builder.V.state == PersonState.FREE then
            views[1]:setVisible(true)
            views[2]:setVisible(true)
            views[3]:setVisible(true)
            views[4]:setVisible(true)
        end
    end
end
return StoragePlugin
