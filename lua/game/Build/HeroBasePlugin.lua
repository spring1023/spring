local const = GMethod.loadScript("game.GameLogic.Const")
local AnimaConfigData = GMethod.loadScript('data.AnimaConfigData')
local SData = GMethod.loadScript("data.StaticData")
local HeroBasePlugin = {}

function HeroBasePlugin:addMenuButs(buts, item)
    if item=="select" then
        table.insert(buts,{key="select", callback=self.showSelectDialog, cp1=self})
    elseif not self.worklist and self.context.guide:getStep().type == "finish" then
        if item=="heal" then
            local hero = self.context.heroData:getHeroByLayout(const.LayoutPvp, self.lidx, 1)
            local stime = GameLogic.getSTime()
            if hero and hero.recoverTime>stime then
                table.insert(buts,{key="heal", callback=self.onHealHero, cp1=self, exts={rcost={text=GameLogic.computeCostByTime(hero.recoverTime-stime)}}})
            end
        elseif item=="hero" then
            table.insert(buts,{key="hero", callback=display.showDialog, cp1=HeroMainDialog})
        end
    end
    if GameLogic.getUserContext().guideHand.handArr["guideHeroBaseArrow"] then
        GameLogic.getUserContext().guideHand:removeHand("guideHeroBaseArrow")
    end
end

function HeroBasePlugin:showSelectDialog()
    if self.inHVH then
        if self.vstate.scene.battleType==const.BattleTypePvc then
            local layoutType
            local sign = GameLogic.getUserContext():getProperty(const.ProUseLayout)
            sign = GameLogic.dnumber(sign,3)
            if sign[2]>0 or self.group == 2 then
                layoutType = const.LayoutPvc
            else
                layoutType = const.LayoutPvp
            end
            display.showDialog(HeroMainDialog.new({initTag="fight", dialogParam={pos=self.lidx, lid=layoutType, hasHelp=true}}))
        elseif self.vstate.scene.battleType==const.BattleTypePvh then
            display.showDialog(HeroMainDialog.new({initTag="fight", dialogParam={pos=self.lidx, lid=self.inHVH, forceLayouts=self.context.forceLayouts}}))
        end
    else
        local tag="fight"
        if GameLogic.getUserContext().guideHand.handArr["guideHeroSeleted"] then
            --GameLogic.getUserContext().guideHand:removeHand("guideHeroSeleted")
            tag="help"
        end
        display.showDialog(HeroMainDialog.new({initTag=tag, dialogParam={pos=self.lidx, lid=const.LayoutPvp, hasHelp=true}}))
    end
end

function HeroBasePlugin:onInit()
    if self.inHVH then
        self.lidx = self.id
    else
        self.context.heroData:addBase(self)
    end
end

function HeroBasePlugin:onReload()
    if self.inHVH then
        self.lidx = self.id
    else
        self.context.heroData:addBase(self)
    end
end

function HeroBasePlugin:onRemove()
    if self.inHVH then
        self.lidx = nil
    else
        self.context.heroData:removeBase(self)
    end
end

function HeroBasePlugin:onClean()
    if self.roles then
        local roles = self.roles
        if roles.hero then
            roles.hero:removeFromScene()
            roles.hero = nil
        end
        if roles.troops then
            for _, troop in ipairs(roles.troops) do
                troop:removeFromScene()
            end
            roles.troops = nil
        end
    end
    self.roles = nil
end

function HeroBasePlugin:onHealHero(force)
    local hero = self.context.heroData:getHeroByLayout(const.LayoutPvp, self.lidx, 1)
    local stime = GameLogic.getSTime()
    if hero and hero.recoverTime>stime then
        local cost = GameLogic.computeCostByTime(hero.recoverTime-stime)
        if not force then
            display.showDialog(AlertDialog.new(1,Localize("wordHeal"),Localize("alertTextHealHero"),{ctype=const.ResCrystal, cvalue=cost, callback=Handler(self.onHealHero, self, true)}))
        else
            hero.recoverTime = 0
            self.context.heroData:healHero(hero, stime, cost)
        end
    end
end

function HeroBasePlugin:readyToBattle()
    if self.inHVH then
        return self:readyInPrepare()
    end
    local hero
    if self.group == 1 and self.vstate.scene.battleParams.tryHids then
        hero = self.vstate.scene.battleParams.tryHids[self.lidx]
    else
        hero = self.context.heroData:getHeroByLayout(const.LayoutPvp, self.lidx, 1)
    end
    if hero and hero:isAlive(self.vstate.scene.startTime) then
        local hiLv = 1
        local vstate = self.vstate
        local otherSetting = {inBase=true, atkPercent=self.data.atkRate, hpPercent=self.data.hpRate}

        local setting = self.context:getBattleBuff()
        local defBuff = self.vstate.scene.battleData.preDefBuffs
        otherSetting.atkPercent = (otherSetting.atkPercent or 0) + (defBuff and defBuff.atkPct or 0) * 100
        otherSetting.hpPercent = (otherSetting.hpPercent or 0) + (defBuff and defBuff.hpPct or 0) * 100

        local _person = hero:getControlData(otherSetting)
        if setting then
            _person.atk = _person.atk * (1+(setting.atkPct or 0))
            _person.hp = _person.hp * (1+(setting.hpPct or 0))
        end
        _person.defenseParam = (_person.defenseParam or 1) * (defBuff and defBuff.defenseParam or 1)
        GameLogic.addSpecialBattleBuff(hero, _person, self.group, self.vstate.scene)
        local rhero = PersonUtil.C({person=_person, state=AvtControlerState.BATTLE, group=self.group})
        if self.vstate.scene.replay.defHs then
            local rdata = rhero:getDataDesc()
            table.insert(rdata, self.lidx)
            table.insert(rdata, self.id)
            table.insert(self.vstate.scene.replay.defHs, rdata)
        end
        rhero.targetGrid = {vstate.gx+vstate.gsize/2,vstate.gy+vstate.gsize/2}
        rhero.assistHero = hero.assists
        if rhero.avtInfo.nowHp<=0 then
            return
        end
        rhero:addToScene(vstate.scene, rhero.targetGrid[1], rhero.targetGrid[2])
        rhero.groupData.heros[self.lidx] = rhero
        self.vstate.rhero = rhero
    end
end

--当竞技场/远征/英雄试炼时，不添加建筑，直接添加英雄和士兵
function HeroBasePlugin:onSpecialAdd(scene, gx, gy)
    if (self.inHVH or scene.battleType == const.BattleTypePvb) and scene.isBattle then
        self.lidx = self.lidx or self.id
        local hero
        local tryHids = scene.battleParams.tryHids
        if tryHids and self.group == 1 then
            hero = tryHids[self.lidx]
        elseif self.context.forceLayouts then
            hero = self.context.forceLayouts:getHeroByLayout(self.lidx, 1)
        elseif scene.battleType == const.BattleTypePvb then
            hero = self.context.heroData:getHeroByLayout(const.LayoutUPve, self.lidx, 1)
        elseif self.inHVH==const.LayoutPvc and self.group==1 then
            local sign = self.context:getProperty(const.ProUseLayout)
            sign = GameLogic.dnumber(sign,3)
            if sign[2]>0 then
                hero = self.context.heroData:getHeroByLayout(self.inHVH, self.lidx, 1)
            else
                hero = self.context.heroData:getHeroByLayout(const.LayoutPvp, self.lidx, 1)
            end
        else
            hero = self.context.heroData:getHeroByLayout(self.inHVH, self.lidx, 1)
            if self.inHVH==const.LayoutPvh or self.inHVH==const.LayoutnPvh then
                if hero.layouts[self.inHVH].hp==0 or hero.layouts[self.inHVH].isOut == 0 then
                    hero = nil
                end
            end
        end

        if hero then
            local hiLv = 1
            local person
            --按配置增加敌方buff
            if scene.battleParams.nightmare and self.group == 2 then
                --local stagePercent = SData.getData("npvhStage",scene.battleParams.stage)
                if scene.battleParams.mul then
                    person = hero:getControlData{atkPercent=scene.battleParams.mul, hpPercent=scene.battleParams.mul}
                else
                    person = hero:getControlData()
                end
            elseif self.group == 1 and (self.inHVH==const.LayoutPvh or self.inHVH == const.LayoutnPvh) then
                --英雄远征和噩梦远征鼓舞加玩家数据
                local insPercent=0
                if scene.battleParams.nightmare then
                    insPercent = tryHids and 0 or GameLogic.getUserContext().npvh:getInspireData(true)
                else
                    insPercent = GameLogic.getUserContext().pvh:getInspireData(true)
                end
                person = hero:getControlData{atkPercent=insPercent,hpPercent=insPercent}
            else
                person = hero:getControlData()
            end
            GameLogic.addSpecialBattleBuff(hero, person, self.group, scene)
            --PersonUtil.newPersonData(hero.info,hero:getHeroData(),{id=hero.hid,level=hero.level,skillId=hero.info.mid,skillLv=hero.mSkillLevel,actSkillParams=hero:getSkillData()})
            if not tryHids and (self.inHVH==const.LayoutPvh or self.inHVH==const.LayoutnPvh) then
                local hpp = hero.layouts[self.inHVH]
                person.nowHp = math.ceil(person.hp*hpp.hp/100)
            end
            local rhero = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=self.group})

            rhero.assistHero = hero.assists
            local initDir = 3
            if self.group==2 then
                initDir = 6
            end
            local gsize = self.info.size
            rhero:addToScene(scene, gx+gsize/2,gy+gsize/2, initDir)
            if not tryHids and (self.inHVH==const.LayoutPvh or self.inHVH==const.LayoutnPvh) and rhero.avater then
                rhero.avater:damage(person.nowHp,rhero.avater.avtInfo.maxHp,rhero.avater.avtInfo.nowHp2)
            end
            rhero.groupData.heros[self.lidx] = rhero
            if scene.battleType == const.BattleTypePvb or tryHids then
                self.__ehero = rhero
            end
            --加佣兵操作
            if self.inHVH and self.inHVH~=const.LayoutPvtDef then
                rhero.groupData.troops[self.lidx] = {}
                local siLv = 1
                local sdLv = hero.soldierLevel
                local sinfo = hero:getSoldierInfo()
                local sdata = hero:getSoldierData(sdLv)
                local person = PersonUtil.newPersonData(sinfo,sdata,{id=hero.info.sid,level=sdLv})
                for i=1, sdata.num do
                    local rd = scene.replay.rd
                    local newSoldier = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=self.group})
                    newSoldier.masterHero = rhero
                    if DEBUG.DEBUG_REPLAY3 and self.vstate.scene and self.vstate.scene.replay then
                        self.vstate.scene.replay:addDebugText(self:getTag() .. "cantRandom")
                    end
                    newSoldier:addToScene(scene,gx+rd:random()*gsize,gy+rd:random()*gsize)
                    rhero.groupData.troops[self.lidx][i] = newSoldier
                    --战争挽歌装备
                    if rhero.warRequiem then
                        rhero.warRequiem:exe(newSoldier)
                    end
                    --怒风权杖装备
                    if rhero.wand then
                        rhero.wand:exe(newSoldier)
                    end
                end
            end
        end
        return true
    end
end

function HeroBasePlugin:readyInPrepare()
    local vstate = self.vstate
    if self.group==1 then
        self.canMove = true
    end
    RegTimeUpdate(vstate.view, Handler(self.updatePrepareBattle, self), 0.2)
end

function HeroBasePlugin:updatePrepareBattle(diff)
    local vstate = self.vstate
    local hero
    if self.context.forceLayouts then
        hero = self.context.forceLayouts:getHeroByLayout(self.lidx, 1)
    else
        if self.inHVH~=const.LayoutPvc then
            hero = self.context.heroData:getHeroByLayout(self.inHVH, self.lidx, 1)
            if hero and (self.inHVH == const.LayoutPvh or self.inHVH==const.LayoutnPvh) then
                if hero.layouts[self.inHVH].hp==0 or hero.layouts[self.inHVH].isOut == 0 then
                    hero = nil
                end
            end
        elseif self.inHVH==const.LayoutPvc then
            local sign = self.context:getProperty(const.ProUseLayout)
            sign = GameLogic.dnumber(sign,3)
            if sign[2]>0 or self.group == 2 then
                hero = self.context.heroData:getHeroByLayout(self.inHVH, self.lidx, 1)
            else
                hero = self.context.heroData:getHeroByLayout(const.LayoutPvp, self.lidx, 1)
            end
        end
    end
    if hero then
        if self.role and self.role.avtInfo.id~=hero.hid then
            self.role:removeFromScene()
            self.role = nil
        end
        if not self.role then
            local hiLv = 1
            local person = hero:getControlData()
            --PersonUtil.newPersonData(hero.info,hero:getHeroData(),{id=hero.hid,level=hero.level,skillId=hero.info.mid,skillLv=hero.mSkillLevel,actSkillParams=hero:getSkillData()})
            if self.inHVH == const.LayoutPvh or self.inHVH == const.LayoutnPvh then
                local hpp = hero.layouts[self.inHVH]
                person.nowHp = math.ceil(person.hp*hpp.hp/100)
            end
            local rhero = PersonUtil.C({person=person, state=AvtControlerState.PREPARE, group=self.group})
            rhero.targetGrid = {vstate.gx+vstate.gsize/2,vstate.gy+vstate.gsize/2}
            rhero.targetBuild = self.vstate
            local initDir = 3
            if self.group==2 then
                initDir = 6
            end
            rhero.freeDir = initDir
            rhero:addToScene(vstate.scene, rhero.targetGrid[1], rhero.targetGrid[2], initDir)
            if (self.inHVH==const.LayoutPvh or self.inHVH==const.LayoutnPvh) and rhero.avater then
                rhero.avater:damage(person.nowHp,rhero.avater.avtInfo.maxHp,rhero.avater.avtInfo.nowHp2)
            end
            self.role = rhero
        end
    elseif self.role then
        self.role:removeFromScene()
        self.role = nil
    end
end

function HeroBasePlugin:updateOperation(diff)
    if BU.getPlanDelegate() then
        return
    end
    --增加引导
    if self.vstate.scene.sceneType == "operation" then
        local isTF=GEngine.getConfig("isHeroBaseGuided"..self.context.sid..self.context.uid)
        if self.level>=3 and not GEngine.getConfig("isHeroBaseGuided_story"..self.context.sid..self.context.uid) then
            GEngine.setConfig("isHeroBaseGuided_story"..self.context.sid..self.context.uid,1,true)
            display.showDialog(StoryDialog.new({context=self.context,storyIdx=302,callback=nil}),false,true)
        end
        if self.level>=3 and not isTF and not GameLogic.getUserContext().guideHand.handArr["guideHeroBaseArrow"] and (not GameLogic.getUserContext().guideHand.handArr["guideHeroSeleted"] or not BU.isShowedBuildMenu()) then
            self.context.guideHand:showArrow(self.vstate.upNode,self.vstate.view:getContentSize().width/2, 100+self:getHeight(),20,"guideHeroBaseArrow")
        end
    end
    local roles = self.roles
    if not roles then
        roles = {}
        self.roles = roles
    end
    local vstate = self.vstate
    local hero = self.context.heroData:getHeroByLayout(const.LayoutPvp, self.lidx, 1)
    if hero then
        local rhero = roles.hero
        local hiLv = 1
        --装备
        local changeEquip = false
        if rhero then
            changeEquip = true
            local equip,requip = hero.equip,rhero.person.equip
            if equip and requip and equip.idx==requip.idx then
                changeEquip = false
            elseif not equip and not requip then
                changeEquip = false
            end
        end

        if not rhero or rhero.person.idx ~= hero.idx or rhero.person.level ~= hero.level or rhero.person.awakeUp ~= hero.awakeUp or changeEquip then
            if rhero then
                rhero:removeFromScene()
                self:setWorkProcess()
            end
            rhero = PersonUtil.C({person=hero:getControlData(), state=AvtControlerState.Operation, group=1})
            rhero.target = self
            rhero:addToScene(vstate.scene, vstate.gx+vstate.gsize/2,vstate.gy+vstate.gsize/2)
            roles.hero = rhero
            if vstate.focus then
                BU.showBuildMenu(self)
            end
        end
        local noTroops = false
        local dead, ld, md = hero:getDeadState(GameLogic.getSFloatTime())
        if not dead then
            if rhero.deleted then
                music.play("sounds/mercenary_upgrade.mp3")
                UIeffectsManage:showEffect_heroFuhuo(vstate.upNode,vstate.view:getContentSize().width/2, vstate.view:getContentSize().height/2,0)
                rhero:changeUndeadState(vstate.scene, vstate.bgx+vstate.gsize/2,vstate.bgy+vstate.gsize/2)
                if vstate.focus then
                    BU.showBuildMenu(self)
                end
                self:setWorkProcess()
            end
        else
            noTroops = true
            if not rhero.deleted then
                rhero:changeDeadState(vstate.upNode)
                if vstate.focus then
                    BU.showBuildMenu(self)
                end
            end
            --防止personView2未及时加载出来而导致未变灰
            if rhero.avater and rhero.avater.personView2 then
                rhero.avater.personView2:setSValue(-100)
            end
            local _heroDeadSetting = {}
            local heroView=hero:getControlData()
            local hpviewY
            if heroView.id == 4031 then
                hpviewY = AnimaConfigData[heroView.id]["hpview"][2][2]
            else
                hpviewY = AnimaConfigData[heroView.id]["hpview"][2]
            end
            _heroDeadSetting.oy=hpviewY+AnimaConfigData[heroView.id]["Ymove"]-vstate.view:getContentSize().height/2
            self:setWorkProcess(ld, md, _heroDeadSetting)
        end
        local siLv = 1
        local sdLv = hero.soldierLevel
        if sdLv<15 then
            siLv = 1
        elseif sdLv<30 then
            siLv = 2
        else
            siLv = 3
        end
        local sdata = hero:getSoldierData(sdLv)
        local rtroops = roles.troops
        if not rtroops or roles.sid~=hero.info.sid or roles.siLv~=siLv or roles.noTroops~=noTroops then
            if rtroops then
                for _, troop in ipairs(rtroops) do
                    troop:removeFromScene()
                end
            end
            rtroops = {}
            roles.troops = rtroops
            roles.sid = hero.info.sid
            roles.siLv = siLv
            roles.noTroops = noTroops
        end
        local rnum = #rtroops
        local snum = rnum
        if snum<sdata.num then
            snum = sdata.num
        end
        if noTroops then
            snum = 0
        end
        local svinfo = hero:getSoldierInfo()
        local svdata = {id=hero.info.sid,lv=sdLv,unitType=svinfo.utype,speed=svinfo.speed,aspeed=svinfo.aspeed}
        for i=1, snum do
            if i>sdata.num and rtroops[i] then
                rtroops[i]:removeFromScene()
                rtroops[i] = nil
            elseif i<=sdata.num and not rtroops[i] then
                rtroops[i] = PersonUtil.C({person=PersonUtil.newPersonData(svinfo,{id=hero.info.sid,level=sdLv}), state=AvtControlerState.Operation, group=1})
                rtroops[i].target = self
                rtroops[i]:addToScene(vstate.scene,vstate.gx+vstate.gsize*math.random(),vstate.gy+vstate.gsize*math.random(),1,nil,1)
            end
        end
    else
        if roles.hero then
            roles.hero:removeFromScene()
            roles.hero = nil
            if vstate.focus then
                BU.showBuildMenu(self)
            end
        end
        if roles.troops then
            for _, troop in ipairs(roles.troops) do
                troop:removeFromScene()
            end
            roles.troops = nil
        end
        self:setWorkProcess()
    end
end

return HeroBasePlugin
