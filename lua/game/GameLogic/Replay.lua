
local cmdType = {addHero=1, addSW=2, useSK=3, useGSK=4, autoBT=5}
GEngine.export("CMDTYPE",cmdType)
local Replay = class()

function Replay:ctor(scene)
    self.scene = scene
end

function Replay:init(isReplay)
    if self.updateTab then
        for i=#(self.updateTab), 1, -1 do
            self:removeUpdateObj(self.updateTab[i])
        end
    end
    self.bplayTime = 0
    self.allObjTab = {}
    self.rd = RdUtil.new(100)
    BattleUtil.setGlobalRd(self.rd)
    self.utime = 0
    self.allTime = 0
    self.updateKey = 0
    self.delta = 0.025
    self.updateTab = {}
    self.sbuilds = {}
    self.cmdTab = {}
    self.delayTab = {}

    self.lineText = ""
    self.debugText = ""

    BuffUtil.clearAll()

    self.isReplay = isReplay
    if isReplay then
        self:readData(isReplay)
    end
    self.updateThread = coroutine.create(function()
        xpcall(Handler(self.updateAll, self), _G.__G__TRACKBACK__)
    end)

    self.isStartBattle = false
    self._scheduler = cc.Director:getInstance():getScheduler()
end

function Replay:addDebugText(text)
    if self.lastAllTime and self.lastAllTime == self.allTime then
        self.lineText = self.lineText .. text .. "\t"
    else
        self.debugText = self.debugText .. self.lineText .. "\n"
        self.lastAllTime = self.allTime
        self.lineText = self.lastAllTime .. "：" .. text .. "\t"
    end
end

function Replay:addUpdateObj(bindTarget)
    if not bindTarget._upid then
        self.updateKey = self.updateKey + 1
        self.updateTab[self.updateKey] = bindTarget
        bindTarget._upid = self.updateKey
    end
end

function Replay:removeUpdateObj(bindTarget)
    local id = bindTarget._upid
    if id then
        bindTarget._upid = nil
        if id ~= self.updateKey then
            self.updateTab[id] = self.updateTab[self.updateKey]
            self.updateTab[id]._upid = id
        end
        self.updateTab[self.updateKey] = nil
        self.updateKey = self.updateKey - 1
    end
end


function Replay:update(diff)
    if not self.isStartBattle then
        return
    end
    local sstime = socket.gettime()
    if not self.ustime then
        self.ustime = sstime - diff
    end
    diff = sstime - self.ustime
    if diff < -1 then
        print("wtf???")
        GameLogic.doErrorHandler(2)
        return
    elseif diff < 0 then
        diff = 0
    end
    self.utime = self.utime + diff * self._scheduler:getTimeScale()
    self.ustime = sstime
    if self.utime > 2 then
        print("what happen???? the utime was not decrease but keep increase!")
    end
    if self.utime > 60 and not self.isReplay then
        GameLogic.doErrorHandler(2)
        return
    end
    local suc, rdiff = nil
    if self.updateThread then
        suc, rdiff = coroutine.resume(self.updateThread, self)
    end
    if not suc or not rdiff then
        if not suc then
            print("error in replay!")
            self.updateThread = nil
            self.locked = true
        end
        rdiff = 0
    end
    return rdiff
end

function Replay:stopUpdate()
    self.isBattleEnd = true
    self.utime = 0
    self.locked = true
    if self.updateThread then
        coroutine.resume(self.updateThread, self)
    end
end

function Replay:pauseReplay(ts, callback)
    self.locked = true
    local director = cc.Director:getInstance()
    local s = director:getScheduler()
    local a = director:getActionManager()
    s:retain()
    a:retain()
    local ns = cc.Scheduler:new()
    local na = cc.ActionManager:new()
    director:setScheduler(ns)
    director:setActionManager(na)

    local sid
    local function updateAction(diff)
        if sid then
            na:update(diff)
            ts = ts - diff
            if ts < 0 then
                ns:unscheduleScriptEntry(sid)
                sid = nil
                director:setScheduler(s)
                director:setActionManager(a)
                a:release()
                s:release()
                self.locked = false
                self.ustime = socket.gettime()
                GameLogic.lockReplayItems = nil
            end
        end
    end
    sid = ns:scheduleScriptFunc(updateAction, 0, false)
    --加到全局变量中；这个理论上应当直接放到引擎中，不过热更不能更引擎，所以先放这里
    GameLogic.lockReplayItems = {s, a, ns, na, sid}
    callback()
    coroutine.yield(0)
end

function Replay:updateAll()
    while not self.isBattleEnd do
        local rdiff = 0
        while self.utime>=self.delta do
            rdiff = rdiff+self.delta
            self.utime = self.utime-self.delta
            self.allTime = self.allTime+1
            for _,v in ipairs(self.updateTab) do
                v:update(self.delta)
            end
            local key = self.allTime
            if self.cmdTab[key] then
                for _,cmd in ipairs(self.cmdTab[key]) do
                    self:exeCmd(cmd)
                end
            end

            if self.delayTab[key] then
                for _,delay in ipairs(self.delayTab[key]) do
                    delay()
                end
                self.delayTab[key] = nil
            end

            --把replay结束 和战斗开始结束判断放在这里
            if self.isReplay then
                self.remainTime = self.playTime-self.allTime*self.delta
                if self.remainTime<0 then
                    self:stopUpdate()
                end
            else
                local bdata = self.scene.battleData
                local scene = self.scene
                local menu = scene.menu
                local battle = menu.battle
                if scene.battleType ~= const.BattleTypePvt then
                    if bdata.time then
                        bdata.time = bdata.time-self.delta
                        if bdata.time<=0 then
                            if bdata.state==0 then
                                if scene.isBattle then
                                    menu:startBattle()
                                else
                                    menu:endBattle(true)
                                end
                            elseif bdata.state==1 then
                                menu:endBattle(true)
                            end
                        end
                        if bdata.time then
                            local ns = math.floor(bdata.time)
                            if ns ~= bdata._ns then
                                bdata._ns = ns
                                battle.labelTimeValue:setString(Localizet(ns))
                                if battle.timeValue2 and battle.timeValue2.isShow then
                                    local path = "images/spfont_red_" .. (ns+1) .. ".png"
                                    battle.timeValue2:setImage(path)
                                    battle.timeValue2:setScale(2.5, 2.5)
                                    battle.labelTimeValue:setVisible(false)
                                else
                                    battle.labelTimeValue:setString(Localizet(ns))
                                end
                            end
                        else
                            battle.labelTimeValue:setString("")
                        end
                    end
                end
            end
            if rdiff >= 0.2 then
                break
            end
        end
        coroutine.yield(rdiff)
    end
    self.updateThread = nil
end

function Replay:addDelay(delay,time)
    time = time<0.025 and 0.025 or time
    local key = self.allTime + math.ceil(time/0.025)
    if not self.delayTab[key] then
        self.delayTab[key] = {}
    end
    table.insert(self.delayTab[key], delay)
end

function Replay:addCmd(cmd)
    local key = self.allTime+1
    if not self.cmdTab[key] then
        self.cmdTab[key] = {}
    end
    table.insert(self.cmdTab[key],cmd)
end

function Replay:exeCmd(cmd)
    local bdata = self.scene.battleData
    local ctype = cmd.t
    local ps = cmd.ps
    local groupData = bdata.groups[1]
    local context = GameLogic.getUserContext()
    if ctype == CMDTYPE.addHero then
        groupData.ready = groupData.ready-1
        local gx,gy = ps[2],ps[3]
        local hitem = groupData.hitems[ps[1]]
        local hhero = hitem.hero
        if not hhero then
            return
        end
        local otherSettings = {}

        local atkBuff = self.scene.battleData.preAtkBuffs
        if context.guide:getCurrentState()<=6 then
            if not DEBUG.DEBUG_BATTLE then
                otherSettings.atkPercent = 400
                otherSettings.hpPercent = 400
            end
        else
            otherSettings.atkPercent = (atkBuff and ((atkBuff.atkPct or 0)+(atkBuff.heroAtk or 0)) or 0) * 100
            otherSettings.hpPercent = (atkBuff and ((atkBuff.hpPct or 0)+(atkBuff.heroHp or 0)) or 0) * 100
        end
        local _person = hhero:getControlData(otherSettings)
        GameLogic.addSpecialBattleBuff(hhero, _person, 1, self.scene)
        local hero = PersonUtil.C({person=_person, state=AvtControlerState.BATTLE, group=1, hpos=hitem.hpos})
        if self.atkHs then
            table.insert(self.atkHs, hero:getDataDesc())
        end
        hero.assistHero = hitem.assistHero
        hero.flagShowAppear = true
        hero.dataIdx = hhero.idx
        hero:addToScene(self.scene,gx,gy)
        groupData.heros[hitem.hpos] = hero

        local sinfo = hitem.sinfo
        local sdata = hitem.sdata
        if sdata and self.scene.battleType ~= const.BattleTypePvb then
            local person = PersonUtil.newPersonData(sinfo,sdata,{id=hhero.info.sid,level=hhero.soldierLevel})
            if atkBuff then
                person.atk = person.atk * (1 + (atkBuff.atkPct or 0) + (atkBuff.soldierAtk or 0))
                person.hp = person.hp * (1 + (atkBuff.hpPct or 0) + (atkBuff.soldierHp or 0))
            end
            local function addSoldier()
                local newSoldier = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=1})
                newSoldier.flagShowAppear = true
                local ngx, ngy
                while true do
                    ngx = gx+(self.rd:random2()-0.5)*3
                    ngy = gy+(self.rd:random2()-0.5)*3
                    if not self.scene.map.getGridObj(math.floor(ngx), math.floor(ngy)) then
                        break
                    end
                end
                newSoldier.masterHero = hero
                newSoldier:addToScene(self.scene,ngx,ngy)
                newSoldier.addTimeFlag = self.allTime
                --战争挽歌装备
                if hero.warRequiem then
                    hero.warRequiem:exe(newSoldier)
                end
                --怒风权杖装备
                if hero.wand then
                    hero.wand:exe(newSoldier)
                end

            end
            if not GEngine.rawConfig.DEBUG_NOSD then
                for i=1, sdata.num do
                    self.scene.replay:addDelay(addSoldier, i*0.15)
                end
            end
        end
        self.scene.menu:startBattle()
        self.scene.menu.realStart = true
    elseif ctype == CMDTYPE.addSW then
        local witem = groupData.witems[ps[1]]
        SwControler.new({id=witem.wid, effect=witem.data, scene=self.scene, gx=ps[2], gy=ps[3]})
        witem.use = witem.use + 1
        self.scene.menu:startBattle()
        self.scene.menu.realStart = true
    elseif ctype == CMDTYPE.useSK then
        local hero = groupData.heros[ps[1]]
        --debug.sethook(hook, "c")
        -- profile:start()
        if hero then
            hero:ppexeSkill()
        end
    elseif ctype == CMDTYPE.useGSK then
        -- debug.sethook()
        -- for func, count in pairs(Counters) do
        --     print(getname(func), count)
        -- end
        -- profile:stop()
        -- profile:writeReport( 'MyProfilingReport.txt' )
        local hero = groupData.heros[ps[1]]
        if hero then
            hero:ppexeGodSkill()
            hero.releasedGodSkill = hero.sid
        end
    elseif ctype == CMDTYPE.autoBT then
        groupData.isAuto = not groupData.isAuto
    end
end

function Replay:setFoeData(data)
    self.foeData = clone(data)
end
function Replay:setMyData(data)
    self.myData = clone(data)
end
function Replay:encodeData()
    local allData = {
        foeData=self.foeData, myData=self.myData,
        cmdTab=self.cmdTab, time=self.allTime*self.delta, vtime=self.scene.startTime,
        btype=self.scene.battleType, atkHs=self.atkHs, defHs=self.defHs
    }
    return json.encode(allData)
end
function Replay:readData(data)
    local allData = json.decode(data)
    self.foeData = allData.foeData
    self.myData = allData.myData
    self.cmdTab = {}
    for k, v in pairs(allData.cmdTab) do
        self.cmdTab[tonumber(k)] = v
    end
    self.playTime = allData.time

end


return Replay
