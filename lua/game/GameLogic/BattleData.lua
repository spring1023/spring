local const = GMethod.loadScript("game.GameLogic.Const")

local BattleData = class()

--战斗数据，用于处理战斗逻辑
--group 1表示己方，2表示敌方
--state 分为0 表示未开始，1表示正在战斗中，2表示战斗结束
--time表示时间
--mode:1、pve、pvp，人打城；2、人打人，如竞技场，远征；3、城打人，如僵尸来袭
function BattleData:ctor(scene)
    --战斗数据分为己方和敌方两组
    self.bossDamageValue = 0
    self.groups = {self:getInitData(), self:getInitData()}
    --自动施放技能
    self.groups[1].isAuto = false
    self.groups[2].isAuto = true
    local isDef = scene.battleType==const.BattleTypePvj
    self.groups[1].isDef = isDef
    self.groups[2].isDef = not isDef
    self.state = 0
    self.time = 30
    self.scene = scene
    self.heros = {}
    self.dheros = {}
    if scene.battleType==const.BattleTypePvp or scene.battleType==const.BattleTypePve then
        self.groups[1].heroCheck = true
        self.mode = 1
    elseif scene.battleType==const.BattleTypePvc or scene.battleType==const.BattleTypePvh then
        self.groups[1].heroCheck = true
        self.groups[2].heroCheck = true
        self.mode = 2
        if scene.battleType == const.BattleTypePvh then
            self:addGroupsAnger()
        end
    elseif scene.battleType==const.BattleTypePvj then
        self.groups[2].heroCheck = true
        self.mode = 3
        self.killNum = 0
    elseif scene.battleType==const.BattleTypeUPve then
        self.groups[1].heroCheck = true
        self.groups[2].bossCheck = true
        self.groups[2].bulidNoCheck = true
    elseif scene.battleType==const.BattleTypeUPvp then
        self.groups[1].heroCheck = true
    elseif scene.battleType == const.BattleTypePvz then
        self.groups[1].heroCheck = true
        self.mode = 1
    elseif scene.battleType == const.BattleTypePvb then
        self.groups[1].heroCheck = true
        self.groups[2].bossCheck = true
        self.groups[2].bulidNoCheck = true
        self.mode = 2
    end
end
function BattleData:addGroupsAnger()
    local ucontext = GameLogic.getUserContext()
    if self.scene.battleParams.nightmare then
        if self.scene.battleParams.tryHids then
            self.groups[1].anger = const.InitPvhAnger
        else
            self.groups[1].anger = ucontext.npvh.anger
        end
    else
        self.groups[1].anger = ucontext.pvh.anger
    end
end

function BattleData:addObj(obj)
    local group = obj.group
    local groupData = self.groups[group]
    obj.groupData = groupData
    local scene = self.scene
    if groupData.isDef then
        obj.battleMap = scene.battleMap2
        obj.battleMap2 = scene.battleMap
    else
        obj.battleMap = scene.battleMap
        obj.battleMap2 = scene.battleMap2
    end
    if not obj.avtInfo then
        --超级武器
        return
    end
    if scene.isBattle then
        obj.battleMap2:addBattler(obj)
        obj.battleMap:addWallWeight(obj)
        if obj.avtInfo.ptype==3 then
            if obj.info.btype<4 then
                groupData.total = groupData.total+1
            end
        else
            if not obj.params.isZhaoHuan then
                groupData.totalTroops = groupData.totalTroops+1
                if obj.markAsAdd then
                    print("re-add battle obj", obj.sid)
                    print(debug.traceback())
                end
                obj.markAsAdd = true
                if obj.avtInfo.ptype==1 then
                    groupData.totalHero = groupData.totalHero+1
                    --普通神兽不会放技能
                    if not obj.M.cantUserSkill then
                        table.insert(groupData.autoQueue, obj)
                    end
                end
                if obj.params.isRebirth and group == 2 and self.killNum then
                    self.killNum = self.killNum - 1
                end
            else
                groupData.tempTroops = groupData.tempTroops + 1
            end
        end
    end
end

function BattleData:destroyObj(obj)
    local groupData = obj.groupData
    local scene = self.scene
    local group = obj.group
    obj.battleMap2:removeBattler(obj)
    obj.battleMap:removeWallWeight(obj)
    if groupData.isDef then
        if obj.avtInfo.ptype==3 and obj.info.btype==5 then
            obj.battleMap2:removeWallWeight(obj)
        end
    end
    if obj.avtInfo.ptype==3 then
        if obj.info.btype<4 then
            groupData.destroyed = groupData.destroyed+1
            if obj.bid==const.Town then
                groupData.townDestroyed = true
            end
        end
    else
        if not obj.params.isZhaoHuan then
            groupData.deadTroops = groupData.deadTroops+1
            if not obj.markAsAdd then
                print("remove not battle obj", obj.sid, obj.deleted)
                print(debug.traceback())
            end
            obj.markAsAdd = nil
            if obj.avtInfo.ptype==1 then
                groupData.deadHeros = groupData.deadHeros+1
                for i,hero in ipairs(groupData.autoQueue) do
                    if hero==obj then
                        table.remove(groupData.autoQueue, i)
                        break
                    end
                end
            end
            if self.killNum and group == 2 then
                self.killNum = self.killNum + 1
            end
        else
            groupData.tempTroops = groupData.tempTroops - 1
        end
    end
    if obj.avtInfo.bossIdx then
        groupData.deadBoss = groupData.deadBoss+1
    end
end

function BattleData:computePvzScore(reborn)
    local _, percent, star = self:computeBattleResult()
    if percent == nil then
        percent = 0
    end
    percent = percent and percent or 0
    star = star and star or 0
    local score = percent + star*100
    local rate = {1, 0.8, 0.6, 0.4, 0.2}
    local _rate
    if reborn>=5 then
        _rate = rate[5]
    else
        _rate = rate[reborn+1]
    end
    local _score = math.floor(score*_rate)
    return score, _score
end

function BattleData:computeBattleResult()
    local scene = self.scene
    if scene.battleType == const.BattleTypePvt then
        return
    end
    local loser = self:getLoseGroup()
    local percent, star = nil
    if self.mode==1 then
        local group = self.groups[2]
        percent = math.floor(group.destroyed*100/group.total)
        star = math.floor(percent/50)
        if group.townDestroyed then
            star = star+1
        end
        --没有主城时
        if star == 2 and self.sheildWall then
            star = 3
            local vstate = self.sheildWall.vstate
            for i=1,4 do
                vstate.bviews[i]:setVisible(false)
            end
        end
    elseif self.mode==2 then
        percent = nil
        star = 0
        if loser==2 then
            star = 3
        end
    elseif self.mode==3 then
        local group = self.groups[1]
        if group.total==0 then
            percent = 100
        else
            percent = 100-math.floor(group.destroyed*100/group.total)
        end
        star = 3
        if percent==0 then
            star = 0
        else
            if group.townDestroyed then
                star = star-1
            end
            if group.deadHeros>0 then
                star = star-1
            end
        end
        if self.state==2 and loser==0 then
            local group2 = self.groups[2]
            if group2.ready>0 or group2.totalTroops>group2.deadTroops or group2.tempTroops > 0 then
                star = 0
            end
        else
            percent = nil
        end
    end
    return loser, percent, star
end

function BattleData:updateBattle(diff)
    if self.state==1 then
        local speed, max = GEngine.getSetting("angerSpeed"), 10
        speed = speed*(self.speedScale or 1)
        for _,group in ipairs(self.groups) do
            if group.totalTroops>group.deadTroops or group.tempTroops > 0 then
                group.anger = group.anger + speed*diff
                if group.anger>max then
                    group.anger = max
                end
            end
        end
        if GEngine.rawConfig.DEBUG_BATTLE then
            self.groups[1].anger = max
        end
        local autoQueueG =  {self.groups[1].autoQueue,self.groups[2].autoQueue}
        for i,autoQueue in ipairs(autoQueueG) do
            if self.groups[i].isAuto then
                while autoQueue[1] do
                    if autoQueue[1].deleted then
                        table.remove(autoQueue, 1)
                    else
                        if self.mode==3 and i==2 then
                            --尾兽释放技能按时间释放，因此需要加最短间隔
                            if self.groups[i].minDis then
                                self.groups[i].minDis = self.groups[i].minDis-diff
                                if self.groups[i].minDis<0 then
                                    self.groups[i].minDis = nil
                                else
                                    break
                                end
                            end

                            if not autoQueue[1].coldTime or autoQueue[1].coldTime<=0 then
                                local dhero = table.remove(autoQueue, 1)
                                dhero:ppexeSkill()
                                table.insert(autoQueue, dhero)
                                self.groups[i].minDis = 0.5
                            end
                        else
                            --萨满没有英雄死亡时放到最后
                            if autoQueue[1].sid == 4021 and #autoQueue[1].battleMap2.diedHero<=0 then
                                local dhero = table.remove(autoQueue, 1)
                                table.insert(autoQueue, dhero)
                            end

                            if autoQueue[1].actSkillParams.x/10<=self.groups[i].anger then
                                local dhero = table.remove(autoQueue, 1)
                                dhero:ppexeSkill()
                                table.insert(autoQueue, dhero)
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end

--根据场景的类型加载双方数据
function BattleData:initMenuDatas(ucontext)
    local scene = self.scene
    local lid = const.LayoutPvp
    local lid2
    local groupData = self.groups[1]
    groupData.hitems = {}
    for i=1, 5 do
        groupData.hitems[i] = {}
    end
    local addEnemy = false
    local sign = ucontext:getProperty(const.ProUseLayout)
    sign = GameLogic.dnumber(sign, 6)
    if scene.battleParams.tryHids then
        for j, hero in ipairs(scene.battleParams.tryHids) do
            if scene.battleType == const.BattleTypePvj and not ucontext.heroData.bases[j] then
                break
            end
            local sinfo = hero:getSoldierInfo()
            local sdata = hero:getSoldierData(hero.info.type,hero.level)
            local hitem = {
                hpos=j, hid=hero.hid, sid=hero.info.sid, num=sdata.num, mid=hero.info.mid, awake=hero.awakeUp,
                hero=hero,sinfo=sinfo,sdata=sdata,assistHero=hero.assists
            }
            groupData.hitems[j] = hitem
            if scene.battleType == const.BattleTypePvp or scene.battleType == const.BattleTypePvb then
                groupData.ready = groupData.ready+1
                groupData.uiReady = groupData.uiReady+1
            end
        end
        self:initOtherBoss()
        return
    elseif scene.battleType==const.BattleTypePvc then
        lid2 = const.LayoutPvc
        if sign[2]>0 then
            lid = const.LayoutPvc
        end
        addEnemy = true
    elseif scene.battleType == const.BattleTypePvb then
        lid2 = const.LayoutUPve
        if sign[scene.battleParams.aid - 100]>0 then
            lid = const.LayoutUPve + (scene.battleParams.aid - 103)
        end
    elseif scene.battleType==const.BattleTypePvh then
        lid = scene.battleParams.nightmare and const.LayoutnPvh or const.LayoutPvh
        lid2 = lid
        addEnemy = true
    elseif scene.battleType == const.BattleTypePvp or scene.battleType == const.BattleTypePve or scene.battleType == const.BattleTypeUPvp then
        if scene.battleType == const.BattleTypePve and scene.battleParams.stage == const.HeroInfoNewTry then
            local hero = GameLogic.getUserContext().heroData:makeHero(scene.battleParams.id)
            local awakeLv = 0
            hero.level = 200
            if hero.info.awake==1 then
                awakeLv = 12
                hero.awakeUp = 12
            elseif hero.hid/1000==3 then
                hero.level = 160
            end
            hero.mSkillLevel = 20
            hero.soldierLevel = 50
            hero.soldierSkillLevel1 = 5
            hero.soldierSkillLevel2 = 5
            local sinfo = hero:getSoldierInfo()
            local sdata = hero:getSoldierData(hero.info.type,hero.level)
            local hitem = {
                hpos=1, hid=hero.hid, sid=hero.info.sid, num=sdata.num, mid=hero.info.mid, awake=hero.awakeUp,
                hero=hero,sinfo=sinfo,sdata=sdata,assistHero=hero.assists
            }
            groupData.anger = 10
            groupData.hitems[1] = hitem
            local function useSpeArrow(heros)
                for j, hdata in ipairs(heros) do
                    hero = GameLogic.getUserContext().heroData:makeHero(hdata[1])
                    local awakeLv = 0
                    hero.level = hdata[2]
                    hero.mSkillLevel = hdata[3]
                    hero.soldierLevel = hdata[4]
                    hero.soldierSkillLevel1 = hdata[5]
                    hero.soldierSkillLevel2 = hdata[7]
                    hero.awakeUp = hdata[6]
                    local sinfo = hero:getSoldierInfo()
                    local sdata = hero:getSoldierData(hero.info.type,hero.level)
                    local hitem = {
                        hpos=j+1, hid=hero.hid, sid=hero.info.sid, num=sdata.num, mid=hero.info.mid, awake=hero.awakeUp,
                        hero=hero,sinfo=sinfo,sdata=sdata,assistHero=hero.assists
                    }
                    groupData.hitems[j+1] = hitem
                end
                scene.battleParams.hnum = #heros+1
            end
            if scene.battleParams.id == 4021 then
                local heros = {{3004,1,1,1,0,0,0},{1003,1,1,1,0,0,0},{4018,30,1,1,0,5,0},{4023,30,1,1,0,5,0}}
                useSpeArrow(heros)
            elseif scene.battleParams.id == 4032 then
                local heros = {{4013,200,1,1,0,12,0}}
                useSpeArrow(heros)
            end
        elseif scene.battleParams.useSpecialHero then

            local group = scene.battleParams.useSpecialHero
            local hero = GameLogic.getUserContext().heroData:makeHero(group[1].id)
            if group[1].eid then
                local equip = GameLogic.getUserContext().equipData:makeEquip(group[1].eid)
                equip.level = group[1].elv or 150
                hero:setEquip(equip)
            end
            --这里视传过来的参数而定, 可能要添加一些字段
            hero.level = group[1].level or 200
            hero.mSkillLevel = group[1].slv or 20
            hero.soldierLevel = 50
            hero.soldierSkillLevel1 = 5
            hero.soldierSkillLevel2 = 5
            local sinfo = hero:getSoldierInfo()
            local sdata = hero:getSoldierData(hero.info.type,hero.level)
            local hitem = {
                hpos=1, hid=hero.hid, sid=hero.info.sid, num=sdata.num, mid=hero.info.mid,
                hero=hero,sinfo=sinfo,sdata=sdata
            }
            groupData.anger = 10
            groupData.hitems[1] = hitem
            for i=2,#group do
                groupData.hitems[i] = {hpos = i, hid = group[i].hid, sid = group[i].info.sid, hero = group[i],
                num=group[i]:getSoldierData(group[i].info.type,group[i].level).num, mid = group[i].info.mid,
                sinfo = group[i]:getSoldierInfo(), sdata = group[i]:getSoldierData(group[i].info.type,group[i].level)}
            end
        else
            if sign[1]>0 then
                lid = const.LayoutPve
            end
            lid2 = const.LayoutPve
        end
    elseif scene.battleType == const.BattleTypeUPve then
        if sign[3]>0 then
            lid = const.LayoutUPve
        end
        lid2 = const.LayoutUPve
    end

    if DEBUG.DEBUG_BATTLE then
        lid = const.LayoutPvp
    end

    --序列化ucontext
    if scene.battleType == const.BattleTypePvp then
        if scene.battleParams.isReplay then
            ucontext = GameLogic.newContext(ucontext.uid)
            ucontext:loadContext(scene.replay.myData)
            self.replayUcontext = ucontext
            if scene.replay.foeData then
                self.preAtkBuffs = scene.replay.foeData.preAtkBuffs
            else
                self.preAtkBuffs = nil
            end
        else
            local uid = ucontext.uid
            local data = {heros={}, hlayouts={}, hbskills={}, hmics={}, equips={}}
            for i=1,5 do
                for j=1,4 do
                    local hero = ucontext.heroData:getHeroByLayout(lid,i,j)
                    if hero then
                        table.insert(data.heros,hero:dctor())

                        local lpos = hero.layouts[lid].pos
                        local ltype = hero.layouts[lid].type
                        local hlayout = {hero.idx,const.LayoutPvp,lpos*10+ltype}
                        table.insert(data.hlayouts,hlayout)

                        for k,v in pairs(hero.mics) do
                            table.insert(data.hmics,{hero.idx,k,v.level,v.exp})
                        end

                        local equipModel = hero.equip
                        if equipModel then
                            local eidx,edata = equipModel:dctor()
                            data.equips[tostring(eidx)] = edata
                        end
                    end
                end
            end
            local wdata = ucontext.weaponData:dload()
            for k,v in pairs(wdata) do
                data[k] = v
            end

            data.info = ucontext.info

            scene.replay:setMyData(data)
            if self.foeData then
                self.foeData.preAtkBuffs = self.preAtkBuffs
            end
            scene.replay:setFoeData(self.foeData)

            ucontext = GameLogic.newContext(uid)
            ucontext:loadContext(data)
        end
        lid = const.LayoutPvp
    elseif scene.battleType == const.BattleTypePvz then
        if scene.battleParams.isReplay then
            ucontext = GameLogic.newContext(ucontext.uid)
            ucontext:loadContext(scene.replay.myData)
            self.replayUcontext = ucontext
            if scene.replay.foeData then
                self.preAtkBuffs = scene.replay.foeData.preAtkBuffs
            else
                self.preAtkBuffs = nil
            end
        else
            local uid = ucontext.uid
            local data = {heros={}, hlayouts={}, hbskills={}, hmics={}, equips={}}
            for i=1,5 do
                for j=1,4 do
                    local hero = ucontext.heroData:getHeroByLayout(lid,i,j)
                    if hero then
                        table.insert(data.heros,hero:dctor())

                        local lpos = hero.layouts[lid].pos
                        local ltype = hero.layouts[lid].type
                        local hlayout = {hero.idx,const.LayoutPvp,lpos*10+ltype}
                        table.insert(data.hlayouts,hlayout)

                        for k,v in pairs(hero.mics) do
                            table.insert(data.hmics,{hero.idx,k,v.level,v.exp})
                        end

                        local equipModel = hero.equip
                        if equipModel then
                            local eidx,edata = equipModel:dctor()
                            data.equips[tostring(eidx)] = edata
                        end
                    end
                end
            end
            local wdata = ucontext.weaponData:dload()
            for k,v in pairs(wdata) do
                data[k] = v
            end

            data.info = ucontext.info

            scene.replay:setMyData(data)
            if self.foeData then
                self.foeData.preAtkBuffs = self.preAtkBuffs
            end
            scene.replay:setFoeData(self.foeData)

            ucontext = GameLogic.newContext(uid)
            ucontext:loadContext(data)
        end
        lid = const.LayoutPvp
    elseif scene.battleType == const.BattleTypePvc then
        if scene.battleParams.isReplay then
            ucontext = GameLogic.newContext(ucontext.uid)
            ucontext:loadContext(scene.replay.myData)
            self.replayUcontext = ucontext
            if scene.replay.foeData then
                self.preAtkBuffs = scene.replay.foeData.preAtkBuffs
            else
                self.preAtkBuffs = nil
            end
        else
            local data = {heros={}, hlayouts={}, hbskills={}, hmics={}, equips={}}
            for i=1,5 do
                for j=1,4 do
                    local hero = ucontext.heroData:getHeroByLayout(lid,i,j)
                    if hero then
                        table.insert(data.heros,hero:dctor())
                        local lpos = hero.layouts[lid].pos
                        local ltype = hero.layouts[lid].type

                        local ps=ucontext.heroData:getHeroLayoutPos(const.LayoutPvc, lpos)
                        local pos = lpos*10+ltype
                        pos=pos*10000
                        pos=pos+ps.x*100+ps.y
                        local hlayout = {hero.idx,const.LayoutPvc,pos}
                        table.insert(data.hlayouts,hlayout)

                        for k,v in pairs(hero.mics) do
                            table.insert(data.hmics,{hero.idx,k,v.level,v.exp})
                        end

                        local equipModel = hero.equip
                        if equipModel then
                            local eidx,edata = equipModel:dctor()
                            data.equips[tostring(eidx)] = edata
                        end
                    end
                end
            end
            local wdata = ucontext.weaponData:dload()
            for k,v in pairs(wdata) do
                data[k] = v
            end
            local myData=scene.battleParams.myData or {}
            if not myData.heros then
                myData.heros=data.heros
            end
            if not myData.hlayouts then
                myData.hlayouts=data.hlayouts
            end
            if not myData.hbskills then
                myData.hbskills=data.hbskills
            end
            if not myData.hmics then
                myData.hmics=data.hmics
            end
            if not myData.equips then
                myData.equips=data.equips
            end
            --出战台数量发生变化则重置位置
            local uhdata = ucontext.heroData
            local outNum = #(uhdata.bases)
            local initPos = uhdata:getHVHLayouts(const.LayoutPvc, outNum)
            for i=1, outNum do
                myData.builds[i] = {i, const.HeroBase, uhdata.bases[i].level}
                myData.layouts[i] = {i, initPos[i].x, initPos[i].y, 0, 0, 0, 0}
            end

            myData.properties={{const.ProUseLayout,10}}
            scene.replay:setMyData(myData)
            if scene.battleParams.foeData then
                scene.battleParams.foeData.preAtkBuffs = self.preAtkBuffs
            end
            scene.replay:setFoeData(scene.battleParams.foeData)

            self.myHeros = myData.heros
            self.eHeros = scene.battleParams.foeData.heros
        end
    elseif scene.battleType == const.BattleTypeUPvp then
        if scene.battleParams.isReplay then
            lid = const.LayoutPvp
            ucontext = GameLogic.newContext(ucontext.uid)
            ucontext:loadContext(scene.replay.myData)
            self.replayUcontext = ucontext
            if scene.replay.myData and scene.replay.myData.pets then
                local pets = scene.replay.myData.pets

                local hero = ucontext.heroData:makePet(pets,0)
                local hitem = {
                    hpos=6, hid=hero.hid,mid=math.floor(hero.info.mid/10)*10,
                    hero=hero,
                }
                groupData.hitems[6] = hitem
                --神兽需再加一次
                groupData.ready = groupData.ready+1
                groupData.uiReady = groupData.uiReady+1
            end
            if scene.replay.foeData then
                self.preAtkBuffs = scene.replay.foeData.preAtkBuffs
            else
                self.preAtkBuffs = nil
            end
        else
            local uid = ucontext.uid
            local data = {heros={}, hlayouts={}, hbskills={}, hmics={}, equips={}}
            for i=1,5 do
                for j=1,4 do
                    local hero = ucontext.heroData:getHeroByLayout(lid,i,j)
                    if hero then
                        table.insert(data.heros,hero:dctor())

                        local lpos = hero.layouts[lid].pos
                        local ltype = hero.layouts[lid].type
                        local hlayout = {hero.idx,const.LayoutPvp,lpos*10+ltype}
                        table.insert(data.hlayouts,hlayout)

                        for k,v in pairs(hero.mics) do
                            table.insert(data.hmics,{hero.idx,k,v.level,v.exp})
                        end

                        local equipModel = hero.equip
                        if equipModel then
                            local eidx,edata = equipModel:dctor()
                            data.equips[tostring(eidx)] = edata
                        end
                    end
                end
            end
            local wdata = ucontext.weaponData:dload()
            for k,v in pairs(wdata) do
                data[k] = v
            end

            data.info = ucontext.info
            data.pets = ucontext:getUnionPets()

            scene.replay:setMyData(data)
            if self.foeData then
                self.foeData.preAtkBuffs = self.preAtkBuffs
            end
            scene.replay:setFoeData(self.foeData)
        end
    end

    if scene.battleType == const.BattleTypePve and (scene.battleParams.stage == const.HeroInfoNewTry or scene.battleParams.useSpecialHero) then
        return
    end
    local midx = 0
    for i=1, 5 do
        local hero
        if ucontext.forceLayouts then
            hero = ucontext.forceLayouts:getHeroByLayout(i,1)
        else
            hero = ucontext.heroData:getHeroByLayout(lid,i,1)
            if hero and (scene.battleType==const.BattleTypePve or scene.battleType==const.BattleTypePvp) then
                if not hero:isAlive(scene.startTime) then
                    hero = nil
                end
            end
        end
        if not hero then
            hero = nil
        else
            hero:getControlData()
            local sinfo = hero:getSoldierInfo()
            local sdata = hero:getSoldierData()
            local hitem = {
                hpos=i, hid=hero.hid, sid=hero.info.sid, num=sdata.num, mid=hero.info.mid, awake=hero.awakeUp,
                hero=hero,sinfo=sinfo,sdata=sdata,assistHero=hero.assists
            }
            midx = midx+1
            groupData.hitems[midx] = hitem
            if ucontext.bheroData and ucontext.bheroData ~= ucontext.heroData then
                hitem.num = math.ceil(hitem.num*3/10)
                hitem.sdata.num = hitem.num
            end
            if scene.battleType == const.BattleTypePvp or scene.battleType == const.BattleTypePve
                or scene.battleType == const.BattleTypeUPvp or scene.battleType == const.BattleTypeUPve
                or scene.battleType == const.BattleTypePvz or scene.battleType == const.BattleTypePvb then
                groupData.ready = groupData.ready+1
                groupData.uiReady = groupData.uiReady+1
            elseif scene.battleType == const.BattleTypePvj then
                --复活中英雄不加入战斗
                if hitem.hero and hitem.hero.recoverTime>GameLogic.getSTime() then
                    groupData.hitems[midx]={}
                end
            end
        end
    end
    if scene.battleType==const.BattleTypeUPvp and not scene.battleParams.isReplay then
        local pets = ucontext:getUnionPets()
        if pets then
            local hero = ucontext.heroData:makePet(pets,0)
            local hitem = {
                hpos=6, hid=hero.hid,mid=math.floor(hero.info.mid/10)*10,
                hero=hero,
            }
            groupData.hitems[6] = hitem
            --神兽需再加一次
            groupData.ready = groupData.ready+1
            groupData.uiReady = groupData.uiReady+1
        end
    end
    groupData.witems = {}
    if ucontext.weaponData then
        if scene.battleType ~= const.BattleTypePvc then
            local weapons = ucontext.weaponData:getAllWeapons()
            for i=1, 3 do
                if weapons[i] then
                    local witem = {
                        wid=weapons[i][1], num=weapons[i][2], use=0,
                        data=ucontext.weaponData:getBattleWeaponData(weapons[i][1])
                    }
                    table.insert(groupData.witems, witem)
                end
            end
        end
        groupData.wboosts = ucontext.weaponData:getBoostWeaponData()
    end
    if ucontext.enemy and addEnemy then
        local econtext = ucontext.enemy
        groupData = self.groups[2]
        groupData.hitems = {}
        local midx = 0
        for i=1, 5 do
            local hero = econtext.heroData:getHeroByLayout(lid2,i,1)
            if hero then
                local hitem = {hpos=i, hid=hero.hid, hero=hero}
                hitem.sid = hero.info.sid
                midx = midx+1
                groupData.hitems[midx] = hitem
            end
        end
        if econtext.weaponData then
            groupData.wboosts = econtext.weaponData:getBoostWeaponData()
        end
    end
    self:initOtherBoss()
end

-- @brief 初始化敌方BOSS信息
function BattleData:initOtherBoss()
    local scene = self.scene
    local groupData
    --联盟副本
    if scene.battleType == const.BattleTypeUPve or scene.battleType == const.BattleTypePvb then
        groupData = self.groups[2]
        groupData.totalBoss = 0
        groupData.bsitems = {}
        for _,v in ipairs(scene.battleMap.battler) do
            if v.avtInfo.bossIdx then
                groupData.totalBoss = groupData.totalBoss+1
                groupData.bsitems[v.avtInfo.bossIdx] = {role = v}
                --加boss标志
                if scene.battleType==const.BattleTypeUPve then
                    local img = "images/yzBossSilver.png"
                    if v.avtInfo.bossIdx == 1 then
                        img = "images/yzBossGold.png"
                    end
                    local temp = ui.sprite(img)
                    if v.avater then
                        local ox=0
                        local oy=100
                        local hpview = v.avater.animaConfig.hpview
                        if hpview then
                            ox = hpview[1]
                            oy = hpview[2]
                        end
                        display.adapt(temp,ox,oy+50,GConst.Anchor.Bottom)
                        v.avater.personView:addChild(temp)
                    else
                        local view = v.vstate.build
                        display.adapt(temp,v.vstate.view:getContentSize().width/2, v:getHeight(), GConst.Anchor.Bottom)
                        v.vstate.view:addChild(temp)
                    end
                end
            end
        end
    end
end

function BattleData:getInitData()
    --战斗数据包括：
    --总建筑数，总摧毁数，指挥所是否被摧毁
    --总英雄数，总部队数，总死亡英雄数，总死亡部队数; 总待机数，是否检查英雄
    --怒气值，自动释放技能的列表，所有英雄
    return {
        total=0, destroyed=0, townDestroyed=false, tempTroops=0,
        totalHero=0, totalTroops=0, deadHeros=0, deadTroops=0, ready=0,uiReady=0, heroCheck=false,
        anger = 0, autoQueue={}, heros={}, troops={}, totalBoss=0, deadBoss=0,bulidNoCheck=false
    }
end

--获取失败者一方的Group ID
function BattleData:getLoseGroup()
    if self.state>=1 then
        for gid, group in ipairs(self.groups) do
            local flag = true
            if group.bossCheck then
                if group.totalBoss==group.deadBoss then
                    return gid
                end
                flag = false
            end
            if not group.bulidNoCheck then
                if group.total>0 then
                    if group.total==group.destroyed then
                        return gid
                    end
                    flag = false
                end
            end
            if group.heroCheck then
                if group.ready==0 and group.totalTroops<=group.deadTroops and group.tempTroops <= 0 then
                    return gid
                end
                flag = false
            end
            if flag then
                return gid
            end
        end
    end
    return 0
end

return BattleData
