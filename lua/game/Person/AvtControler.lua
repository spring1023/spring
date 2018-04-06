local Avater = GMethod.loadScript('game.Person.Avater')
local AvtInfo = GMethod.loadScript('game.Person.AvtInfo')
local SkillPlugin = GMethod.loadScript("game.Person.SkillPlugin")
local Aoe = GMethod.loadScript("game.GameLogic.Aoe")
local ThunderBlader = GMethod.loadScript("game.Person.EquipLogic.ThunderBlader")
local BloodBook = GMethod.loadScript("game.Person.EquipLogic.BloodBook")
local DragonHeart = GMethod.loadScript("game.Person.EquipLogic.DragonHeart")

local HolyCross = GMethod.loadScript("game.Person.EquipLogic.HolyCross")
local WarRequiem = GMethod.loadScript("game.Person.EquipLogic.WarRequiem")
local Rage = GMethod.loadScript("game.Person.EquipLogic.Rage")
local Rock = GMethod.loadScript("game.Person.EquipLogic.Rock")
local Wand = GMethod.loadScript("game.Person.EquipLogic.Wand")

local AvtControler = class()
AvtControlerState = {BUILDER = 1,ZOMBIE = 2,BATTLE = 3, Operation=4, PREPARE=5, Npc=6}

local PersonState = _G["PersonState"]
local LGBT = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

function AvtControler:ctor(params)
    self.allColdTime2 = 6 --英雄试炼技能冷却
    self.allBuff = params.buff or {}
    self.cantAddBuff = {}
    self.params = params
    self.group = params.group
    self.info = {}
    self.favSearch = 0
    if params.person then
        self.sid = params.person.id
        self.avtInfo = PersonUtil.M(params,self)
        self.M = self.avtInfo
        self.info.range = self.avtInfo.range
        self.person = params.person
        -- if self.params.group == 2 then
        --     self.avtInfo.nowHp = 1
        -- end
        -- if self.sid>1000 then
        --     self.avtInfo.atk = 100000
        -- end
        self.mSkillLevel = params.person.skillLv
        self.actSkillParams = params.person.actSkillParams
        self.bskillData = params.person.bskillData
        if self.actSkillParams then
            self.actSkillParams.x = self.actSkillParams.x or 0
        end
    else
        self.sid = params.sid
    end
    self:setControlState(params.state)

    --如果是builder 初始相关参数
    if params.state == AvtControlerState.BUILDER then
        if params.target then
            self.target = params.target
            self.target.builder = self
        end
    end
    if self.onInitComponents then
        self:onInitComponents()
    end
end

function AvtControler:getExtSkillData()
    local _extSkillData = self._extSkillData
    if not _extSkillData then
        _extSkillData = GMethod.loadScript("data.StaticData").getData("mskdatas",self.sid+300,1)
        self._extSkillData = _extSkillData
    end
    return _extSkillData
end

--设置当前控制类型
function AvtControler:setControlState(state)
    self.state = state

    if self.state == AvtControlerState.BUILDER then
        self.update = self.updateBuilder
    elseif self.state == AvtControlerState.ZOMBIE then
        self.update = self.updateZombie
    elseif self.state == AvtControlerState.BATTLE then
        self.update = self.updateBattle
    elseif self.state == AvtControlerState.Operation then
        self.update = self.updateOperation
    elseif self.state == AvtControlerState.PREPARE then
        self.update = self.updatePrepare
    elseif self.state == AvtControlerState.Npc then
        self.update = self.updateNpc
    end
end

function AvtControler:getDataDesc()
    local person = self.person
    local sp = {}
    for k, v in KTPairs(person.actSkillParams) do
        sp[k] = v
    end
    local ret = {person.id, person.hp, person.atk, person.soldierNum, person.skillLv, sp, person.speed,
        person.range, person.aspeed}
    return ret
end

--[[将addToScene和初始化分开的原因：因为有些时候人物初始化出来之后是不会加到
场景上的，比如经营页面死亡后恢复中]]--
function AvtControler:addToScene(scene, gx, gy, initDir)
    if not gx then
        local function tmpRdm()
            return math.random()
        end
        self.rd = {random2 = tmpRdm}
        gx, gy = self:getInitPos()
        self.rd = nil
    end
    if type(gx)=="table" then
        gx, gy = gx[1], gx[2]
    end

    self.scene = scene
    self.map = scene.map
    self.searchGrids = {}

    self.avater = PersonUtil.V(self.sid,scene,gx,gy,self.group,initDir or 1,self)
    self.V = self.avater
    self.BV = self.V
    if self.sid<1000 then
        self.avtInfo.ptype = 2
    else
        self.avtInfo.ptype = 1
    end

    if self.state == AvtControlerState.BATTLE or self.state == AvtControlerState.PREPARE then
        if scene.battleData then
            scene.battleData:addObj(self)
        end
    else
        self.battleMap = scene.battleMap
    end

    if self.state == AvtControlerState.Operation then
        self.avater:damage(self.avtInfo.maxHp,self.avtInfo.maxHp,self.avtInfo.nowHp2)
    end

    --加血条
    if self.state == AvtControlerState.BATTLE or self.state == AvtControlerState.PREPARE then
        if self.avtInfo then
            if self.params.reBirth then
                self.avtInfo.nowHp = self.avtInfo.nowHp*self.params.reBirth/100
            end
            self.avater:damage(self.avtInfo.nowHp, self.avtInfo.maxHp, self.avtInfo.nowHp2)
            self.addBlood = true
        end
        --当标识为出现的时候，播放动画
        if self.flagShowAppear then
            self.flagShowAppear = nil
            self.avater:showAppear()
        end

        --神兽的一些加成
        if self.initForGodBeast then
            self:initForGodBeast()
        end
    end
    --装备
    if self.M then
        self.thunderBlader = ThunderBlader.new(self)
        self.bloodBook = BloodBook.new(self)
        self.dragonHeart = DragonHeart.new(self)
        self.holyCross = HolyCross.new(self)
        self.warRequiem = WarRequiem.new(self)
        self.rage = Rage.new(self)
        self.rock = Rock.new(self)
        self.wand = Wand.new(self)
    end

    self.rd = RdUtil.new(math.floor(gx * 10000 + gy * 100))
    if scene.replay and scene.isBattle then
        scene.replay:addUpdateObj(self)
    else
        local updateNode = ui.node()
        self.V.view:addChild(updateNode)
        RegTimeUpdate(updateNode, Handler(self.update, self), 0.025)
    end

    --初始化助战英雄之类的数据
    if not self.exeInitAssistHero then
        self.exeInitAssistHero = true
        self:initAssistHero()
    end
    if self.state == AvtControlerState.BATTLE and self.rage then
        self.rage:exe()
    end
    if self.state == AvtControlerState.BATTLE and self.rock then
        self.rock:exe()
    end
    if self.state == AvtControlerState.BATTLE and self.wand then
        self.wand:exe()
    end
    if self.state == AvtControlerState.BATTLE and self.onInitRebirth then
        self:onInitRebirth()
    end
    if self.state == AvtControlerState.BATTLE and self.onInitComponentsDelay then
        self:onInitComponentsDelay()
    end
end

function AvtControler:initAssistHero()
    if self.masterHero then
        local hero = self.masterHero
        local data = hero:getAssistData()
        for _,v in pairs(data) do
            --[[4027 增加出战英雄所携佣兵的佣兵数量[a]，并且佣兵每次出击受到的
            伤害减少[b]%,移动速度增加[c]%，持续[d]秒。]]--
            if v.id == 4207 then
                BuffUtil.setBuff(self,{lastedTime=v.d, bfDefPct=v.b, bfMovePct=v.c})
                YonBingDun.new(self.V.view,0,20+self.V.animaConfig.Ymove,v.d)
            end
        end
    else
        local data,heros = self:getAssistData()
        for k,v in pairs(data) do
            --4211 出战英雄最终伤害增加[a]%，生命增加[b]%，联盟副本中效果翻倍
            if v.id == 4211 then
                if self.scene.battleType == const.BattleTypeUPve then
                    local temp = self.M.base_hurtParam/(1+v.a/100)
                    self.M.base_hurtParam = temp*(1+2*v.a/100)
                    self.M.hurtParam = self.M.base_hurtParam
                    temp = self.M.base_hp/(1+v.b/100)
                    self.M.base_hp = temp*(1+2*v.b/100)
                    self.M.maxHp = self.M.base_hp
                    self.M.nowHp = self.M.maxHp
                end
            --[[4212 出战英雄暴击率增加[a]%，暴击伤害增加[b]%；若出战英雄是的
            装备为血光之书，进入战场时，会额外获得[c]层杀气]]--
            elseif v.id == 4212 then
                BuffUtil.setBuff(self,{critical=v.a, criticalNum=v.b})
                if self.person.equip and self.person.equip.id == 2003 then
                    self.bloodBook:initKillGas(v.c)
                end
            --4213 在战斗开始时，获得一个相当于自身血量[a]%的护盾
            elseif v.id == 4213 and not self.params.isRebirth then
                local hp2 = self.M.base_hp*v.a/100
                self:addArmor(hp2)
                local eft = HeroDun.new(self.V.view,0,self.V.animaConfig.Ymove+40,1000)
                self.assistHero4213Eft = eft.viewNode
            --4214 普通攻击时，有[a]%概率在自身周围2格范围内召唤一个分身，
            --分身继承自身生命和攻击的[b]%，分身最多可以同时存在[c]个
            elseif v.id == 4214 then
                BuffUtil.setBuff(self,{ps=v},"assistHero4214")
            --4215 普通攻击，[a]%概率使对方处于静止状态[b]秒
            elseif v.id == 4215 then
                BuffUtil.setBuff(self,{ps=v},"assistHero4215")
            --4216 出战英雄收到的治疗效果提升[a]%，死后变成亡灵，攻击是死前的[b]%
            elseif v.id == 4216 then
                BuffUtil.setStaticBuff(self, "bfHealps", v.a)
                LGBT.addComponentFunc(self, "afterDie", Handler(self.rebirthToGhost, self, v))
            --4217 每次攻击时，恢复[a]%攻击力的血量
            elseif v.id == 4217 then
                BuffUtil.setBuff(self,{bfSuckBlood={0,0,{0,v.a}}})
            --4218 增加出战英雄的基础攻击力[a]%，并反弹[b]%的技能伤害和[c]%的普通伤害
            elseif v.id == 4218 then
                BuffUtil.setBuff(self,{bfRebound1=v.b, bfRebound2=v.c})
            --4220 出战英雄会每隔[a]秒回复[b]%的最大血量
            elseif v.id == 4220 then
                local value = self.M.maxHp*v.b/100
                value = value*10000/v.a
                BuffUtil.setBuff(self,{lastedTime=10000, lastAddHp=value, dtimeAppoint=v.a})
            --4222 使出战英雄每[a]次攻击触发一次拥有其伤害值[b]%的范围攻击
            elseif v.id == 4222 then
                BuffUtil.setBuff(self, {ps=v}, "assistHero4222")
            --[[4224 每[a]秒在出战英雄周围3格范围内召唤一只猴兵，同时可存在[b]只，
            攻击与血量为出战英雄的[c]%]]--
            elseif v.id == 4224 then
                local function newMonkey()
                    if self.scene.battleData.time and self.scene.battleData.state==0 then
                        self.scene.replay:addDelay(newMonkey,v.a)
                        return
                    end
                    if self.deleted or self.isHide then
                        return
                    end
                    self.scene.replay:addDelay(newMonkey,v.a)
                    if not self.childNum2 then
                        self.childNum2 = 0
                    end
                    if self.childNum2<v.b then
                        self.childNum2 = self.childNum2+1
                        local hero = heros[k]
                        local gx, gy = self:getRandomGrid(3)
                        local role = SkillPlugin.summonTroop(hero:getControlData(), self.group, gx, gy, {atkPercent = v.c,
                            hpPercent = v.c, isFenShen = true})
                        --普通分身效果
                        self.V:addFenShenEff(role.V)
                    end
                end
                self.scene.replay:addDelay(newMonkey,v.a)
            --[[4230 出战英雄攻击时有[e]%概率在自身[a]格范围内召唤[b]个火焰蛇，
            攻击和血量为召唤者的[c]%，持续[d]秒]]--
            elseif v.id == 4230 then
                if self.rd:randomInt(100)<=v.e then
                    local function newSnake()
                        if self.scene.battleData.time and self.scene.battleData.state==0 then
                            self.scene.replay:addDelay(newSnake,v.d)
                            return
                        end
                        if self.deleted or self.isHide then
                            return
                        end
                        self.scene.replay:addDelay(newSnake,v.a)
                        if not self.childNum2 then
                            self.childNum2 = 0
                        end
                        if self.childNum2<v.b then
                            self.childNum2 = self.childNum2+1
                            local hero = heros[k]
                            local gx, gy = self:getRandomGrid(3)
                            local role = SkillPlugin.summonTroop(hero:getControlData(), self.group, gx, gy, {atkPercent=v.c, hpPercent=v.c})
                            --普通分身效果
                            self.V:addFenShenEff(role.V)
                        end
                    end
                    self.scene.replay:addDelay(newSnake,v.a)
                end
            --4231 出战英雄的普通攻击有[a]%的概率可使目标受到的治疗效果减少[b]%，持续[c]秒
            elseif v.id == 4231 then
                BuffUtil.setBuff(self,{ps=v},"assistHero4231")
            end
        end
    end
end

function AvtControler:checkSpeAttack(target,value)
    --[[普通攻击时，有[a]%概率在自身周围2格范围内召唤一个分身，
    分身继承自身生命和攻击的[b]%，分身最多可以同时存在[c]个]]--
    local allBuff = self.allBuff
    local buff
    buff = allBuff.assistHero4214
    if buff then
        local ps = buff.ps
        if not self.childNum then
            self.childNum = 0
        end
        if self.childNum<ps.c then
            if self.rd:random2() <= ps.a/100 then
                self.childNum = self.childNum+1
                local gx, gy = self:getRandomGrid(2)
                local role = SkillPlugin.summonTroop(self.params.person, self.params.group,gx, gy,
                    {atkPercent = ps.b, hpPercent = ps.b, master = self, isFenShen = true})
                --普通分身效果
                self.V:addFenShenEff(role.V)
            end
        end
    end
    --4215 普通攻击，[a]%概率使对方处于静止状态[b]秒
    buff = allBuff.assistHero4215
    if buff then
        local ps = buff.ps
        if self.rd:random2()<=ps.a/100 then
            BuffUtil.setBuff(target,{lastedTime=ps.b, bfDizziness=ps.b})
        end
    end
    --4222 使出战英雄每[a]次攻击触发一次拥有其伤害值[b]%的3格范围攻击
    buff = allBuff.assistHero4222
    if buff then
        local ps = buff.ps
        if not self.countForAssistHero then
            self.countForAssistHero = 0
        end
        self.countForAssistHero = self.countForAssistHero+1
        if self.countForAssistHero>=ps.a then
            local sgx,sgy = target.BV.gx, target.BV.gy
            local px,py = self.scene.map.convertToPosition(sgx,sgy)
            Explosion.new(self.scene.objs,px,py)
            self.countForAssistHero = 0
            local ret = self:getCircleTarget(target, self.battleMap.battlerAll, 3)
            for _,v in pairs(ret) do
                if v~=target then
                    SkillPlugin.exe2(self,v,value*ps.b/100,0)
                end
            end
        end
    end
    --4231 出战英雄的普通攻击有[a]%的概率可使目标受到的治疗效果减少[b]%，持续[c]秒
    buff = allBuff.assistHero4231
    if buff then
        local ps = buff.ps
        if self.rd:randomInt(100) > ps.a then
            if target.deleted then
                return
            else
                BuffUtil.setBuff(target, {lastedTime = ps.c, bfHealps = -ps.b/100}, "refreshAssistHero4231")
            end
        end
    end

    --每[a]次攻击触发一次拥有其伤害值[b]%的[n]格范围攻击
    buff = self.needCountForAttack
    if buff and self.heroState == 0 then
        local ps = buff
        if not self.countForAttack then
            self.countForAttack = 0
        end
        self.countForAttack = self.countForAttack + 1
        if self.countForAttack >= ps.a then
            if self.sid == 4031 then
                self.timerN = nil
                self.timerT1 = nil
                LGBT.removeComponentFunc(self, "updateComponent", self._doUpdate1)
                LGBT.addComponentFunc(self, "updateComponent", self._doUpdate1)
            end
            local sgx,sgy = target.BV.gx, target.BV.gy
            local px,py = self.scene.map.convertToPosition(sgx, sgy)
            Explosion.new(self.scene.objs, px, py)
            self.countForAttack = 0
            local targetG = self:getHeroAndSoldier(self, ps.n)
            for _,v in pairs(targetG) do
                SkillPlugin.exe2(self , v, value*ps.b/100,0)
            end
        end
    end
end

function AvtControler:getAssistData()
    local data = {}
    local hero = {}
    for k,v in pairs(self.assistHero or {}) do
        data[k] = v:getHelpSkill()
        hero[k] = v
    end
    return data,hero
end

function AvtControler:addArmor(hp2)
    self.M.nowHp2 = self.M.nowHp2+hp2
    self.V:resetBlood()
end

function AvtControler:checkGodSkill2(notTrue)
    if not self.addGodSkill2 and self:haveGodSkill2() then
        self.addGodSkill2 = not notTrue
        return true
    end
end

function AvtControler:haveGodSkill2()
    if not self.params.isZhaoHuan and self.groupData.isDef and self.person.awakeData2
        and not self.params.isRebirth then
        return true
    end
    if DEBUG.DEBUG_GODSKILL2  and not self.params.isZhaoHuan and self.person.awakeData2
        and not self.params.isRebirth then
        return true
    end
end

function AvtControler:changeDeadState(view)
    self.deleted = true
    self.avater:changeDeadState(view)
end

function AvtControler:changeUndeadState(scene, gx, gy)
    self.deleted = nil
    self.avater:changeUndeadState(scene, gx, gy)
end

function AvtControler:removeFromScene()
    if not self.avater then
        return
    end
    self.avater:removeFromScene()
    self.avater = nil
end

--如果没有初始位置 根据各种参数初始化位置
function AvtControler:getInitPos()
    if self.target then
        return {self:getMoveArroundPosition(self.target)}
    elseif self.home then
        return {self.home.vstate.view:getPositionX(),self.home.vstate.view:getPositionY()+70}
    elseif self.arroundPos then
        return self.arroundPos
    end
end

--moveArround 是一个build 随机得到围绕建筑的一个位置
function AvtControler:getMoveArroundPosition(build)
    local vstate = build.vstate
    if not vstate then
        return
    end
    local gsize = vstate.gsize
    local edge = vstate.edge
    if vstate.isBottom then
        edge = gsize*5
    end
    local e1, e2 = edge/10, gsize-edge/10
    local gx, gy = self.rd:random2()*gsize, self.rd:random2()*gsize
    if gx>e1 and gx<e2 and gy>e1 and gy<e2 then
        if self.rd:random2()>0.5 then
            gx = (gx-e1)/(e2-e1)*edge/5
            if gx>e1 then
                gx = gx-e1+e2
            end
        else
            gy = (gy-e1)/(e2-e1)*edge/5
            if gy>e1 then
                gy = gy-e1+e2
            end
        end
    end
    local bgx, bgy = vstate.bgx, vstate.bgy
    if not gx or not gy then
        bgx, bgy = vstate.gx, vstate.gy
    end
    --return bgx,bgy
    return bgx + gx, bgy + gy
end

--设置移动目标点
function AvtControler:setMoveTarget(agx, agy)
    if self.avtInfo.utype==1 then
        local gx,gy = self.avater.gx, self.avater.gy
        local startPoint = {math.floor(gx), math.floor(gy), gx, gy}
        local endPoint = {math.floor(agx), math.floor(agy), agx, agy}
        local checkStart = self:checkPointInBuild(startPoint)
        local checkEnd = self:checkPointInBuild(endPoint)
        if checkStart and checkEnd and checkStart[1] == checkEnd[1] then
            self.avater:moveDirect(agx, agy)
        else
            if checkStart then
                self.avater:moveDirect(checkStart[2], checkStart[3])
                startPoint = {math.floor(checkStart[2]), math.floor(checkStart[3]), checkStart[2], checkStart[3]}
            end
            if checkEnd then
                endPoint = {math.floor(checkEnd[2]), math.floor(checkEnd[3]), checkEnd[2], checkEnd[3], agx, agy}
            end
            self.avater.state = PersonState.SEARCHING
            self.searchGrids = {endPoint, startPoint}
        end
    else
        self.avater:moveDirect(agx, agy)
    end
end

function AvtControler:checkPointInBuild(gridInfo)
    local mapGrid = self.map
    local build = mapGrid.getGridObj(gridInfo[1], gridInfo[2])
    if build and not build.deleted then
        local vstate = build.vstate
        if vstate.isBottom then
            return
        end
        local gsize = vstate.gsize
        local edge = vstate.edge/10
        local bgx, bgy = vstate.bgx, vstate.bgy
        if not bgx then
            bgx, bgy = vstate.gx, vstate.gy
        end
        local xs = {gridInfo[3]-(bgx+edge), bgx+gsize-edge-gridInfo[3]}
        local ys = {gridInfo[4]-(bgy+edge), bgy+gsize-edge-gridInfo[4]}
        if xs[1]>0 and xs[2]>0 and ys[1]>0 and ys[2]>0 then
            local ret = {build,gridInfo[3],gridInfo[4]}
            local mi = {1,1}
            if xs[2]<xs[1] then
                mi[1] = 2
            end
            if ys[2]<ys[1] then
                mi[2] = 2
            end
            if xs[mi[1]] < ys[mi[2]] then
                ret[2] = bgx+gsize/2+(mi[1]-1.5)*(gsize-edge*2+0.2)
            else
                ret[3] = bgy+gsize/2+(mi[2]-1.5)*(gsize-edge*2+0.2)
            end
            return ret
        end
    end
end

function AvtControler:updateOperation(diff)
    if self.deleted or self.isHide or (not self.avater) or (self.avater and self.avater.deleted) then
        return
    end
    local avater = self.avater
    local vstate = self.target.vstate
    local nx, ny = vstate.bgx+vstate.gsize/2,vstate.bgy+vstate.gsize/2
    if not self.targetGrid then
        self.targetGrid = {}
    end
    if nx~=self.targetGrid[1] or ny~=self.targetGrid[2] then
        self.targetGrid[1] = nx
        self.targetGrid[2] = ny
        if self.person.utype == 1 then
            self:searchPathToGrid(self:getMoveArroundPosition(self.target))
        else
            self:setMoveTarget(self:getMoveArroundPosition(self.target))
        end
    end
    if DEBUG.DEBUG_REPLAY3 and self.scene and self.scene.replay then
        self.scene.replay:addDebugText(self:getTag() .. "cantRandom")
    end
    if avater.state==PersonState.FREE then
        local waitTime = (avater.waitTime or 0)+diff
        if waitTime>=1 then
            if self.rd:random2()>0.66 then
                waitTime = 0
                if self.person.utype == 1 then
                    self:searchPathToGrid(self:getMoveArroundPosition(self.target))
                else
                    self:setMoveTarget(self:getMoveArroundPosition(self.target))
                end
            else
                waitTime = waitTime-1
            end
        end
        avater.waitTime = waitTime
    elseif avater.state==PersonState.MOVING then
        if avater.moveComplete then
            self:resetFree()
            avater.moveComplete = false
        elseif not avater.canJumpWall then  --城墙跳跃
            if self.person.utype == 1 then
                local gx,gy = avater.gx, avater.gy
                local gix, giy = math.floor(gx), math.floor(gy)
                local key = self.battleMap:getAstarKey(gix,giy)
                if self.battleMap.searchCells[key] and self.battleMap.searchCells[key][2]>0 then
                    avater:jumpWall()
                end
            end
        end
    end
    if (avater.state~=PersonState.ATTACK) and self.searchGrids and #(self.searchGrids)>1 then
         self:searchMove()
    end
    avater:updateView(diff)
end

function AvtControler:updateNpc(diff)
    if self.deleted or self.isHide then
        return
    end
    local avater = self.avater
    if avater.state == PersonState.FREE then
        if self.isFirst or math.random() < 0.25 then
            self.isFirst = false
            local id = math.random(2)
            avater:attack(avater.gx - 1, avater.gy - 1, id == 2)
            if id == 2 then
                avater:showSkillEffect()
            end
        else
            self.isFirst = true
            local nx, ny = math.random() * 40 + 1, math.random() * 40 + 1
            local target = avater.map.getGridObj(math.floor(nx), math.floor(ny))
            if target then
                if self.person.utype == 1 then
                    self:searchPathToGrid(self:getMoveArroundPosition(target))
                else
                    self:setMoveTarget(self:getMoveArroundPosition(target))
                end
            else
                if self.person.utype == 1 then
                    self:searchPathToGrid(nx, ny)
                else
                    self:setMoveTarget(nx, ny)
                end
            end
        end
    elseif avater.state==PersonState.MOVING then
        if avater.moveComplete then
            self:resetFree()
            self.isFirst = true
        elseif not avater.canJumpWall then  --城墙跳跃
            if self.person.utype == 1 then
                local gx,gy = avater.gx, avater.gy
                local gix, giy = math.floor(gx), math.floor(gy)
                local key = self.battleMap:getAstarKey(gix,giy)
                if self.battleMap.searchCells[key] and self.battleMap.searchCells[key][2]>0 then
                    avater:jumpWall()
                end
            end
        end
    end
    if (avater.state~=PersonState.ATTACK) and self.searchGrids and #(self.searchGrids)>1 then
         self:searchMove()
    end
    avater:updateView(diff)
end

function AvtControler:updatePrepare(diff)
    local avater = self.avater
    local vstate = self.targetBuild
    local nx, ny = vstate.bgx+vstate.gsize/2,vstate.bgy+vstate.gsize/2
    if nx~=self.targetGrid[1] or ny~=self.targetGrid[2] then
        self.targetGrid[1] = nx
        self.targetGrid[2] = ny
        self:setMoveTarget(nx, ny)
    end
    if (avater.state~=PersonState.ATTACK) and self.searchGrids and #(self.searchGrids)>1 then
         self:searchMove()
    end
    if avater.state==PersonState.MOVING then
        if avater.moveComplete then
            self:resetFree()
            avater.moveComplete = false
        end
    elseif avater.state==PersonState.FREE then
        avater.direction = self.freeDir
    end
    avater:updateView(diff)
end

--builder的思维
function AvtControler:updateBuilder(diff)
    local avater = self.avater
    local astate = avater.state
    if self.home and self.home == self.target then
        if astate == PersonState.FREE then
            avater.direction = 6
        end
        if avater.effectView then
            avater.effectView:removeFromParent(true)
            avater.effectView = nil
        end
        avater:updateView(diff)
        return
    end
    if astate == PersonState.ATTACK then
        if avater.exeRealAtk then
            avater.exeRealAtk = false
            avater:showSkillEffect()
        end
    end
    avater:updateView(diff)
    if avater.state == PersonState.FREE then
        if astate == PersonState.MOVING then
            local gridSize = self.target.vstate.gsize
            local tx, ty = self.target.vstate.gx,self.target.vstate.gy
            tx = tx+gridSize/2
            ty = ty+gridSize/2
            avater:attack(tx,ty)
            avater.allActionTime = math.random(4)+1
        else
            local gx, gy = self:getMoveArroundPosition(self.target)
            if avater.effectView then
                avater.effectView:removeFromParent(true)
                avater.effectView = nil
            end
            if gx then
                avater:moveDirect(gx, gy)
            end
        end
    end
end

function AvtControler:randomBuild()
    if self.target then
        local x, y = self:getMoveArroundPosition(self.target)
        self.avater:moveDirect(x, y)
    end
end

function AvtControler:setTarget(target)
    self.target = target
    target.vstate.builder = self
    local x, y
    if self.home == target then
        local gsize = target.vstate.gsize
        x, y = target.vstate.gx+gsize/2,target.vstate.gy+gsize/2-0.4
    else
        x, y = self:getMoveArroundPosition(self.target)
    end
    self.avater:moveDirect(x, y)
end

--场景僵尸的思维
function AvtControler:updateZombie(diff)
    local avater = self.avater

    if avater.state == PersonState.FREE then
        if avater.actionTime > 1 then
            avater.actionTime = 0
            if math.random() > 0.4 then
                self:randomMoveInArea()
                return true
            end
        end
    end
    avater:updateView(diff)
end

function AvtControler:randomMoveInArea()
    local x,y = math.random(), math.random()
    local area = self.changjing_pos
    local px0 = area[1][1]*(1-x) + area[2][1]*x
    local py0 = area[1][2]*(1-x) + area[2][2]*x
    local px1 = area[4][1]*(1-x) + area[3][1]*x
    local py1 = area[4][2]*(1-x) + area[3][2]*x
    x = px0 * (1-y) + px1 * y
    y = py0 * (1-y) + py1 * y
    x, y = self.scene.map.convertToGrid(x, y)
    self.avater:moveDirect(x,y)
end

function AvtControler:onAttackCallback()
end

function AvtControler:useSkillAll(isGod)
    --技能攻击动画
    local target
    if isGod then
        if self.specialGodSkillTarget and self.heroState == 1 then
            target = self:specialGodSkillTarget() or (self.godSkillTarget or self.attackTarget)
            self.attackTarget = target
        else
            target = self.godSkillTarget or self.attackTarget
        end
    else
        target = self.skillTarget or self.attackTarget
    end
    -- 被击退中不要搞事情
    if target and not self.avater.beRepelState then
        local tgx, tgy = target.BV.gx, target.BV.gy
        if self.skillTargetGroup then
            tgx, tgy = self.skillTargetGroup[1].BV.gx, self.skillTargetGroup[1].BV.gy
        end
        if isGod then
            self.avater:godSkillAttack(target, tgx, tgy, true)
        else
            self.avater:skillAttack(target, tgx, tgy, true)
        end
    end
end

function AvtControler:updateBattle(diff)
    -- 隐藏时不继续update，而不是update
    if self.isHide then
        return
    end
    if self.sg_updateBattle then
        self:sg_updateBattle(diff)
    end

    if self.params.isZhaoHuan then
        if self.allLiveTime then
            self.allLiveTime = self.allLiveTime - diff
            if self.allLiveTime <= 0 then
                self:damage(10000000)
            end
        end
        if self.master and self.master.deleted then
            self:damage(10000000)
        end
    end
    LGBT.useComponent(self, "updateComponent", diff)
    --神兽独有的
    if self.updateForGodBeast then
        self:updateForGodBeast(diff)
    end
    if self.deleted or self.isHide then
        return
    end

    --中了尾兽2的伤害后时间计算
    if self.GB2stateT and self.GB2stateT.time>0 then
        self.GB2stateT.time = self.GB2stateT.time-diff
    end

    --冷却时间
    if self.coldTime and self.coldTime>0 then
        self.coldTime = self.coldTime-diff
    else
        self.coldTime = 0
    end

    --冷却时间 英雄试炼
    if self.coldTime2 and self.coldTime2>0 then
        self.coldTime2 = self.coldTime2 - diff
    elseif self.coldTime2 and self.coldTime2<=0 then
        if self.attackTarget and not self.attackTarget.deleted then
            if not self.isSkillAttack and not self.isSkillNotAttack and self.avtInfo.bfSilent<=0 then
                if self.sg_ppexeSkill then
                    self:sg_ppexeSkill(self.attackTarget)
                else
                    self:ppexeSkill(self.attackTarget)
                end
            end
        end
    end

    --更新Buff
    BuffUtil.updateBuff(self, diff)
    if self.deleted or self.isHide or self.avtInfo.bfDizziness>0 then
        return
    end

    local avater = self.avater

    --特殊位移
    if avater.state == PersonState.SPMOVING then
        avater:updateView(diff)
        return
    end

    --英雄试炼各种令
    if self.params.group == 1 then
        local lockTarget = self.scene.menu.lockTarget
        if lockTarget ~= self.realTarget and lockTarget and not lockTarget.deleted then
            self.lockTarget = lockTarget
        end
    end

    if self._coldSearchTime then
        self._coldSearchTime = self._coldSearchTime - diff
        if self._coldSearchTime <= 0 then
            self._coldSearchTime = nil
        end
    elseif avater.state ~= PersonState.ATTACK and avater.state ~= PersonState.SKILL and avater.state ~=
            PersonState.GODSKILL then
        local shouldClearMovingState = false
        if self.realTarget and (self.realTarget.deleted or self.realTarget.isHide or self.lockTarget or
                self.shouldReCheck) then
            self.realTarget = nil
            self.attackTarget = nil
            self.battackTargetPoint = nil
            shouldClearMovingState = true
            self.directSearched = false
        end

        if not self.realTarget then
            if self.lockTarget then
                self.realTarget = self.lockTarget
                self.lockTarget = nil
                self.attackTarget = nil
                self.battackTargetPoint = nil
            else
                self:searchRealTarget()
            end
            self.shouldReCheck = nil
        end
        if self.realTarget then
            if self.attackTarget and self.attackTarget.deleted then
                self.attackTarget = nil
                self.battackTargetPoint = nil
            end
            if self.skillTarget and self.skillTarget.deleted then
                self.skillTarget = nil
                self.battackTargetPoint = nil
            end
            if not self.attackTarget then
                self:searchPathToTarget(self.realTarget)

                --如果目标是会动的 记录它的目前位置
                if self.realTarget.avater then
                    self.brealTargetInfo = self.battleMap:getSoldierBattleViewInfo(self.realTarget)
                end
            end
        else
            if shouldClearMovingState then
                self:resetFree()
            end
            self._coldSearchTime = 0.5
        end
        if self.attackTarget then
            if self:canAttack(self.attackTarget) and not self.avater.canJumpWall then
                if (self.isSkillAttack or self.isGodSkillAttack) and self.avtInfo.bfSilent <= 0 then
                    self:useSkillAll(not self.isSkillAttack)
                else
                    local tgx, tgy = self.attackTarget.BV.gx, self.attackTarget.BV.gy
                    avater:attack(tgx, tgy, false)
                end
                --试炼冷却时间    不是召唤物
                if self.scene.battleType == 5 and not self.params.isZhaoHuan then
                    if not self.coldTime2 then
                        --进场迅速释放技能
                        if self.params.quickPlaySkill then
                            self.coldTime2 = 0
                        else
                            self.coldTime2 = self.allColdTime2
                        end
                    end
                end
            elseif avater.state~=PersonState.MOVING then
                self:moveStepToTarget()
            elseif self.refreshPathFrame then
                self.refreshPathFrame = self.refreshPathFrame-1
                if self.refreshPathFrame==0 then
                    self:moveStepToTarget()
                end
            end
        elseif self.targetGrid and avater.state~=PersonState.MOVING and avater.state~=PersonState.SEARCHING then
            if avater.gx ~= self.targetGrid[1] or avater.gy ~= self.targetGrid[2] then
                if self.person.utype == 1 then
                    self:searchPathToGrid(self.targetGrid[1], self.targetGrid[2])
                else
                    self:setMoveTarget(self.targetGrid[1], self.targetGrid[2])
                end
            end
        end
    end

    if (avater.state==PersonState.SEARCHING or avater.state==PersonState.MOVING) and #(self.searchGrids)>1 then
         self:searchMove()
    end

    --攻击执行
    if avater.state == PersonState.ATTACK then
        if avater.exeRealAtk then
            avater.exeRealAtk = false
            local function callback(attackTarget)
                if not attackTarget then
                    attackTarget = self.attackTarget
                end
                if not attackTarget or attackTarget.deleted then
                    return
                end
                local value = BattleUtil.getHurt(self, attackTarget)
                attackTarget:damage(value,self)
                --特殊效果
                self:checkSpeAttack(attackTarget,value)

                --反弹普攻
                SkillPlugin.exe2(attackTarget, self, attackTarget.M.bfRebound1*value/100,0,nil,true,true)
                --吸血
                if self.avtInfo.bfSuckBlood then
                    local a,b,c = self.avtInfo.bfSuckBlood[1],self.avtInfo.bfSuckBlood[2],self.avtInfo.bfSuckBlood[3]
                    if b then
                        for _,v in ipairs(self.battleMap2.battlerAll) do
                            if v ~= self then
                                local vl2 = BattleUtil.getHeal(self,v,value*b/100,0)
                                v:damage(vl2)
                            end
                        end
                    end
                    local vl = BattleUtil.getHeal(self,self,value*a/100,0)
                    if c then
                        SkillPlugin.exe7(self,self,c[1]-vl,c[2])
                    else
                        self:damage(vl)
                    end
                end

                --溅射
                if self.avtInfo.bfSputter then
                    local a,b = self.avtInfo.bfSputter[1],self.avtInfo.bfSputter[2]
                    local rt = self:getCircleTarget(attackTarget,self.battleMap.battlerAll,a)
                    for _,v in ipairs(rt) do
                        v:damage(value*b/100,self)
                    end
                end
                --装备 雷霆之刃
                self.thunderBlader:exe(self)

                if not self.attackTimes then --攻击次数
                    self.attackTimes = 0
                end
                self.attackTimes = self.attackTimes+1
                if avater.animaConfig.attack_music2 then
                    music.play("sounds/" .. avater.animaConfig.attack_music2)
                end
            end

            if avater.animaConfig.attack_music then
                music.play("sounds/" .. avater.animaConfig.attack_music)
            end
            avater:viewEffect(self.attackTarget,callback)
            if self.exeAttack then
                self:exeAttack(self.attackTarget)
            end
        end
    end

    --技能施放
    if avater.state ~= PersonState.SKILL and avater.state~= PersonState.GODSKILL and self.attackTarget and
        not self.avater.canJumpWall then
        if self.isSkillAttack and not self.isSkillNotAttack then
            if self:canAttack(self.attackTarget) then
                self:resetFree()
                self:useSkillAll()
            end
        elseif self.isSkillNotAttack and self.avtInfo.bfSilent<=0 then
            self:useSkillAll()
        elseif self.isGodSkillAttack and not self.isGodSkillNotAttack then
            if self:canAttack(self.attackTarget) then
                self:resetFree()
                self:useSkillAll(true)
            end
        elseif self.isGodSkillNotAttack then
            self:useSkillAll(true)
        end
    end

    --天神技能自动施放
    if not self.params.isZhaoHuan and not avater.finishSkill and (avater.group == 2 or (avater.group == 1 and
        self.scene.battleType == const.BattleTypePvt)) and avater.state ~= PersonState.SKILL and
        avater.state~= PersonState.GODSKILL and self.attackTarget and not self.avater.canJumpWall then
        local function useGodSkillf()
            local target = self.godSkillTarget or self.attackTarget
            if target and not avater.beRepelState then
                local viewInfo = target.BV
                if self.skillTargetGroup then
                    viewInfo = self.skillTargetGroup[1].BV
                end
                avater.finishSkill = true
                self.releasedGodSkill = self.sid
                avater:godSkillAttack(target,viewInfo.gx,viewInfo.gy,true)
            end
        end
        if avater.M and avater.M.person and avater.M.person.awakeData then
            avater.waitSkillTime = (avater.waitSkillTime or 0)+diff
            local GodSkillWaitTime = avater.M.person.awakeData.ps.cd
            if self.scene.battleType == const.BattleTypePvt then
                GodSkillWaitTime = avater.M.person.awakeData.ps.ncd
            end
            if avater.group == 2 then
                GodSkillWaitTime = GodSkillWaitTime+2
            end
            if avater.waitSkillTime >= GodSkillWaitTime then
                useGodSkillf()
            end
        end
    end

    --技能执行
    if avater.state == PersonState.SKILL then

        if self.coldTime2 then
            self.coldTime2 = self.allColdTime2
        end

        if avater.exeRealAtk then
            self.isSkillAttack = nil
            self.isSkillNotAttack = nil
            self.isSkillNow = nil

            avater.exeRealAtk = false
            local function callback(target)
                self:exeSkill(target)
                if avater.animaConfig.skill_music2 then
                    music.play("sounds/" .. avater.animaConfig.skill_music2)
                end
            end

            if avater.animaConfig.skill_music then
                music.play("sounds/" .. avater.animaConfig.skill_music)
            end
            if self.skillTargetGroup then
                for _,v in ipairs(self.skillTargetGroup) do
                    self.avater:skillViewEffect(v,callback,self.params.person.actSkillParams.t)
                end
                self.skillTargetGroup = nil
            else
                self.avater:skillViewEffect(self.skillTarget or self.attackTarget,callback,
                    self.params.person.actSkillParams.t)
            end
        end
    end

    --天神技执行
    if avater.state == PersonState.GODSKILL then
        if avater.exeRealAtk then
            self.isGodSkillAttack = nil
            self.isGodSkillNotAttack = nil
            self.isGodSkillNow = nil

            avater.exeRealAtk = false
            local function callback(target)
                self:exeGodSkill(target)
            end

            -- godSkillTargetGroup 这个东西全局只在这里用了一次,怀疑前程序写的有问题
            -- if self.godSkillTargetGroup then
            --     for _,v in ipairs(self.skillTargetGroup) do
            --         self.avater:godSkillViewEffect(v,callback,self.params.person.actSkillParams.t)
            --     end
            --     self.skillTargetGroup = nil
            -- else
                -- self.avater:godSkillViewEffect(self.godSkillTarget or self.attackTarget,callback,
                --     self.params.person.actSkillParams.t)
            -- end

            if self.avater.godSkillViewEffect then
                self.avater:godSkillViewEffect(self.godSkillTarget or self.attackTarget,callback,
                    self.params.person.actSkillParams.t)
            else
                callback(self.godSkillTarget or self.attackTarget)
            end
        end
    end


    --直接放的技能
    if self.isSkillNow then

        if self.coldTime2 then
            self.coldTime2 = self.allColdTime2
        end

        self.avater:skillState(self.params.person.actSkillParams.y)
        self:exeSkill()
    end

    --城墙跳跃
    if self.groupData.isDef then
        if avater.state == PersonState.MOVING and not self.avater.canJumpWall then
            if self.person.utype == 1 then
                local key = self.battleMap2:getAstarKey(math.floor(self.BV.gx),math.floor(self.BV.gy))
                if self.battleMap2.searchCells[key] and self.battleMap2.searchCells[key][2]>0 then
                    avater:jumpWall()
                end
            end
        end
    end
    if self.deleted or self.isHide then
        return
    end
    avater:updateView(diff)
end

function AvtControler:showHurtPerformance(s, stype)
    if self.avater and not self.deleted and not self.isHide then
        self.avater:showHurtPerformance(s, stype)
    end
end

function AvtControler:damage(value,damager)
    if self.deleted or self.isHide then
        return
    end

    if self.M.immune>0 and value>0 then
        return
    end

    if self.sg_damage then
        value = self:sg_damage(value,damager)
    end

    local flag,dv = self.avtInfo:damage(value)

    --联盟副本 boss总血量
    if flag==1 and self.avtInfo.bossIdx then
        self.scene.battleData.bossDamageValue = self.scene.menu.battleData.bossDamageValue+dv
    end

    if not self.notPlayEffectNumber and dv<0 then
        self.avater:showHurtPerformance(math.floor(-dv), 2)
    end

    self.avater:damage(self.avtInfo.nowHp,self.avtInfo.maxHp,self.avtInfo.nowHp2)

    if flag==2 then
        if self.M.nowHp2<=0 then
            if self.assistHero4213Eft then
                self.assistHero4213Eft:removeFromParent(true)
                self.assistHero4213Eft = nil
            end
        end
    end

    --反弹伤害
    if damager and damager~=self and value>0 then
        SkillPlugin.exe2(self,damager,self.avtInfo.bfRebound*value/100,0,nil,true,true)
    end

    if damager and damager~=self and value>0 then
        damager:damage(self.avtInfo.bfReAtk*self.avtInfo.atk/100)
    end

    --高度定制,乔巴兽形态下受到攻击会概率性将一定伤害转化为血量
    if self.sid == 4031 and self.heroState == 1 and damager and damager~=self and value>0 then
        local ps = GMethod.loadScript("data.StaticData").getData("mskdatas", 4131, self.mSkillLevel)
        if self.rd:randomInt(100) <= ps.d then
            self:damage(-value * ps.e/100)
        end
    end

    --高度定制,乔巴兽形态下放天神技持续攻击某目标,此期间对其造成伤害的[y]%
    --将转化为生命值
    if damager and damager~=self and value>0 and damager.sid == 4031 and damager.chaoFengHuiXue then
        local ps = damager.person.awakeData.ps
        damager:damage(-value*ps.y/100)
    end

    --尾兽普通攻击几率眩晕
    if damager and damager.avtInfo.gtype and damager.avtInfo.gtype == 4 then
        local a = 100
        if self.rd:randomInt(100)<=a then
            BuffUtil.setBuff(self,{lastedTime = 1,bfDizziness = 1})
        end
    end

    --助战9
    if self.assistGodBeast9 then
        if self.allBuff.assistGodBeast9 then
            self.avtInfo.nowHp = 1
        else
            self.avtInfo.nowHp = 0
        end
    end
    --助战9
    if not self.assistGodBeast9 and self.avtInfo.gtype == 9 and self.avtInfo.nowHp<=0 then
        local a,t = 50,5
        BuffUtil.setBuff(self,{lastedTime = t,bfAtkPct = a,notDie = true,allTime = 0},"assistGodBeast9")
        self.assistGodBeast9 = true
        self.avtInfo.nowHp = 1
    end

    local notDie = self.M.notDie
    if notDie and self.M.nowHp<=0 and not self.addNotDie then
        self.addNotDie = true
        BuffUtil.setBuff(self,notDie,"notDie")
        self:addNotDieEffect(notDie)
    end
    if self.addNotDie then
        if self.allBuff.notDie then
            self.M.nowHp = 1
        else
            self.M.nowHp = 0
        end
    end
    --击杀
    if self.avtInfo.nowHp <= 0 then
        self.deleted = true
        self.avater.deleted = true
        self.scene.replay:removeUpdateObj(self)

        LGBT.useComponent(self, "beforeDie")
        if not self.isRebirthed then
            GameEvent.sendEvent("BattleDeath", self)
            LGBT.useComponent(self, "afterDie", damager)
        end

        BuffUtil.removeAllBuffComponents(self)
        self.avater:die()
        -- 这里应该是指只要能换英雄，则试炼的该英雄不可复活
        if not self.isRebirthed and self.scene.battleType == const.BattleTypePvt then
            local heros = self.scene.battleData.heros
            if self.group == 2 then
                heros = self.scene.battleData.dheros
            end
            local hero4 = heros[4] and heros[4].hero
            if hero4 then
                if hero4.role and not hero4.role.deleted then
                    self.avtInfo.cantRebirth = 10000
                end
            end
        end

        self.scene.battleData:destroyObj(self)

        --血光之书
        if damager and damager.bloodBook and not damager.deleted then
            damager.bloodBook:exe(self)
        end
        -- 击杀逻辑
        if damager and damager.afterKill then
            damager:afterKill(self)
        end

        --被杀有加成
        if self.M.beKill and damager then
            local lastAddHp = self.M.beKill.lastAddHp
            if lastAddHp and type(lastAddHp) == "table" then
                local all = damager.M.base_hp*lastAddHp[1]
                if math.abs(all) > math.abs(lastAddHp[2]) then
                    all = lastAddHp[2]
                end
                self.M.beKill.lastAddHp = all
            end
            BuffUtil.setBuff(damager,self.M.beKill)
        end

        --中了神兽2技能后逻辑
        if self.GB2stateT and self.GB2stateT.time>0 then
            self.GB2stateT.callback()
        end

        --神兽死亡后逻辑
        if self.dieForGodBeast then
            self:dieForGodBeast()
        end

        if self.indexBattleUI then
            local params = {type =2,index = self.indexBattleUI}
            gameEvent:sendEvent(MyEvent.BATTLEUI_UPDATE,params)
        end
        --刷新battleUI英雄boss死亡
        if self.bossIndex then
            local params = {type ="boss2",ndex = self.bossIndex}
            gameEvent:sendEvent(MyEvent.BATTLEUI_UPDATE,params)
        end
        return true
    end

    --巨龙之心
    if damager and damager.avtInfo and damager.avtInfo.id>1000 and damager.avtInfo.id<10000 then
        self.dragonHeart:exe(value)
    end
end

-- @brief 宙斯的复活；理论上应该写到助战技的实现里，不应该写到这里
function AvtControler:rebirthToGhost(ps)
    local role = SkillPlugin.summonTroop(self.params.person, self.params.group, self.V.gx, self.V.gy, {atkPercent=ps.b})
    FuHuoEffect.new(role.V.view, 0, role.V.animaConfig.Ymove)
    role:hideSelf(2, false)
end

function AvtControler:moveStepToTarget()
    --一个移动的目标需要不断更新
    local battleViewInfo = self.attackTarget.battleViewInfo

    if self.person.utype == 2 then
        if battleViewInfo then
            self.avater:moveDirect(battleViewInfo[1], battleViewInfo[2])
        else
            local gx,gy = self.attackTarget.avater.gx,self.attackTarget.avater.gy
            self.avater:moveDirect(gx,gy)
            self.refreshPathFrame = 60
        end
    else
        if battleViewInfo then
            if #self.searchGrids>=2 then
                self:searchMove()
            else
                --因为一些原因没有打到攻击对象，且没有其他寻路信息时，重新寻路
                self.directSearched = false
                self:searchPathToTarget(self.realTarget)
            end
        else
            self.refreshPathFrame = 30

            local viewInfo = self.battleMap:getSoldierBattleViewInfo(self.realTarget)
            if not viewInfo then
                return
            end
            if (viewInfo[1]-self.brealTargetInfo[1])*(viewInfo[1]-self.brealTargetInfo[1])+
                    (viewInfo[2]-self.brealTargetInfo[2])*(viewInfo[2]-self.brealTargetInfo[2])>10 then
                self.directSearched = false
                self:searchPathToTarget(self.realTarget,true)
                self.brealTargetInfo = viewInfo
            end
            if self.avater.state == PersonState.FREE then
                self.directSearched = false
                self:searchPathToTarget(self.realTarget,true)
                self.brealTargetInfo = viewInfo
            end
        end
    end
end

function AvtControler:canAttack(target)
    if self.__godSkillTarget == target then
        return true
    end
    local avater =self.avater
    local dis2
    local viewInfo = target.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(target)
    local bpoint = self.battackTargetPoint
    if bpoint then
        if bpoint[1] == viewInfo[1] and bpoint[2] == viewInfo[2] and
        bpoint[3] == avater.gx and bpoint[4] == avater.gy then
            return true
        end
    end
    local rrange = self.avtInfo.range
    if self.isBoss or target.isBoss then
        rrange = rrange+1
    end
    local sgx, sgy = avater.gx,avater.gy
    local dx, dy = math.abs(sgx-viewInfo[1])-viewInfo[3], math.abs(sgy-viewInfo[2])-viewInfo[3]
    if dx<0 then dx=0 end
    if dy<0 then dy=0 end
    dis2 = dx*dx+dy*dy

    local can = rrange*rrange>=dis2
    if can then
        self.battackTargetPoint = {viewInfo[1],viewInfo[2],avater.gx,avater.gy}
    end
    return can
end

function AvtControler:searchMove()
    local stackLen = #self.searchGrids
    if stackLen>=2 then
        local endBuild = self.attackTarget
        if endBuild and endBuild.deleted then return end

        local fromGrid = self.searchGrids[stackLen]
        local toGrid = self.searchGrids[stackLen-1]
        self.searchGrids[stackLen] = nil
        local mapGrid = self.map
        if math.abs(toGrid[1]-fromGrid[1])+math.abs(toGrid[2]-fromGrid[2])<=1 then
            self.avater:addMoveGrid(toGrid[3], toGrid[4])
            return
        else
            local gridInfo = {fromGrid[1], fromGrid[2], fromGrid[3], fromGrid[4], false, 1,1,0,0}
            local a,k
            local dx, dy = toGrid[3]-fromGrid[3], toGrid[4]-fromGrid[4]
            if math.abs(dy)>math.abs(dx) then
                gridInfo[7] = dy/math.abs(dy)
                if dx<0 then gridInfo[6] = -1 end
                gridInfo[5] = true
                k = dx/dy
                a = fromGrid[3]-k*fromGrid[4]
            else
                gridInfo[6] = dx/math.abs(dx)
                if dy<0 then gridInfo[7] = -1 end
                k = dy/dx
                a = fromGrid[4]-k*fromGrid[3]
            end
            gridInfo[8] = k
            gridInfo[9] = a
            local searching = true
            local loopNum = 0
            while searching do
                loopNum = loopNum+1
                if loopNum>100 then
                    break
                end

                local normalStep = false
                local build = mapGrid.getGridObj(gridInfo[1], gridInfo[2])
                local vstate = build and build.vstate
                if not vstate or vstate.isBottom or vstate.destroyed or vstate.edge*2==vstate.gsize*10 or
                        build==endBuild or build.bid == 50 then
                    normalStep = true
                else
                    local gsize = vstate.gsize
                    local edge = vstate.edge/10
                    local bgx, bgy = vstate.bgx, vstate.bgy
                    if not bgx or not bgy then
                        bgx, bgy = vstate.gx, vstate.gy
                    end
                    local rect = {bgx+edge, bgy+edge, bgx+gsize-edge, bgy+gsize-edge}
                    local xj = true
                    local xjinfo = {}
                    if (gridInfo[3]<=rect[1] and toGrid[3]<=rect[1]) or (gridInfo[4]<=rect[2] and toGrid[4]<=rect[2]) or
                        (gridInfo[3]>=rect[3] and toGrid[3]>=rect[3]) or (gridInfo[4]>=rect[4] and toGrid[4]>=rect[4])
                        then
                        xj = false
                    else
                        if gridInfo[5] then
                            local x1,x2 = k*rect[2]+a, k*rect[4]+a
                            if (x1<=rect[1] and x2<=rect[1]) or (x1>=rect[3] and x2>=rect[3]) then
                                xj = false
                            else
                                if (x1+x2)<=(rect[1]+rect[3]) then
                                    if x1>rect[1] then
                                        table.insert(xjinfo, {rect[1]-0.1, rect[2]-0.1})
                                    end
                                    if x2>rect[1] then
                                        table.insert(xjinfo, {rect[1]-0.1, rect[4]+0.1})
                                    end
                                else
                                    if x1<rect[3] then
                                        table.insert(xjinfo, {rect[3]+0.1, rect[2]-0.1})
                                    end
                                    if x2<rect[3] then
                                        table.insert(xjinfo, {rect[3]+0.1, rect[4]+0.1})
                                    end
                                end
                            end
                        else
                            local y1,y2 = k*rect[1]+a, k*rect[3]+a
                            if (y1<=rect[2] and y2<=rect[2]) or (y1>=rect[4] and y2>=rect[4]) then
                                xj = false
                            else
                                if (y1+y2)<=(rect[2]+rect[4]) then
                                    if y1>rect[2] then
                                        table.insert(xjinfo, {rect[1]-0.1, rect[2]-0.1})
                                    end
                                    if y2>rect[2] then
                                        table.insert(xjinfo, {rect[3]+0.1, rect[2]-0.1})
                                    end
                                else
                                    if y1<rect[4] then
                                        table.insert(xjinfo, {rect[1]-0.1, rect[4]+0.1})
                                    end
                                    if y2<rect[4] then
                                        table.insert(xjinfo, {rect[3]+0.1, rect[4]+0.1})
                                    end
                                end
                            end
                        end
                    end
                    if xj then
                        searching = false
                        if math.abs(fromGrid[3]-gridInfo[3])+math.abs(fromGrid[4]-gridInfo[4])>0.1 then
                            local check = self:checkPointInBuild(gridInfo)
                            if not check then
                                self.avater:addMoveGrid(gridInfo[3],gridInfo[4])
                            end
                        end
                        if #xjinfo==1 then
                            self.avater:addMoveGrid(xjinfo[1][1], xjinfo[1][2])
                            self.searchGrids[stackLen] = {math.floor(xjinfo[1][1]), math.floor(xjinfo[1][2]),
                                xjinfo[1][1],
                                xjinfo[1][2]}
                        elseif #xjinfo==2 then
                            local id = (3-((gridInfo[5] and gridInfo[7]) or gridInfo[6]))/2
                            self.avater:addMoveGrid(xjinfo[id][1], xjinfo[id][2])
                            self.avater:addMoveGrid(xjinfo[3-id][1], xjinfo[3-id][2])

                            self.searchGrids[stackLen] = {math.floor(xjinfo[3-id][1]), math.floor(xjinfo[3-id][2]),
                                xjinfo[3-id][1], xjinfo[3-id][2]}
                        end
                    else
                        rect = {bgx, bgy, bgx+gsize, bgy+gsize}
                        while true do
                            self:walkToNextGrid(gridInfo)
                            if (toGrid[1]==gridInfo[1] and toGrid[2]==gridInfo[2]) or math.abs(toGrid[3]-gridInfo[3])+
                                    math.abs(toGrid[4]-gridInfo[4])<0.1 then
                                self.avater:addMoveGrid(toGrid[3], toGrid[4])
                                searching = false
                                break
                            elseif gridInfo[1]<rect[1] or gridInfo[1]>=rect[3] or gridInfo[2]<rect[2] or gridInfo[2]>=
                                    rect[4] then
                                break
                            end
                        end
                    end
                end
                if normalStep then
                    self:walkToNextGrid(gridInfo)
                    --be careful to float
                    if (toGrid[1]==gridInfo[1] and toGrid[2]==gridInfo[2]) or math.abs(toGrid[3]-gridInfo[3])+
                            math.abs(toGrid[4]-gridInfo[4])<0.1 then
                        self.avater:addMoveGrid(toGrid[3], toGrid[4])
                        searching = false
                    end
                end
            end
        end
    end
end

function AvtControler:walkToNextGrid(gridInfo)
    if gridInfo[5] then
        gridInfo[4] = gridInfo[2]+(1+gridInfo[7])/2
        gridInfo[3] = gridInfo[8]*gridInfo[4]+gridInfo[9]
        if math.floor(gridInfo[3]+0.0001)~=gridInfo[1] then
            gridInfo[3] = gridInfo[1]+(1+gridInfo[6])/2
            gridInfo[4] = (gridInfo[3]-gridInfo[9])/gridInfo[8]
            gridInfo[1] = gridInfo[1] + gridInfo[6]
        else
            gridInfo[2] = gridInfo[2] + gridInfo[7]
        end
    else
        gridInfo[3] = gridInfo[1]+(1+gridInfo[6])/2
        gridInfo[4] = gridInfo[8]*gridInfo[3]+gridInfo[9]
        if math.floor(gridInfo[4]+0.0001)~=gridInfo[2] then
            gridInfo[4] = gridInfo[2]+(1+gridInfo[7])/2
            gridInfo[3] = (gridInfo[4]-gridInfo[9])/gridInfo[8]
            gridInfo[2] = gridInfo[2] + gridInfo[7]
        else
            gridInfo[1] = gridInfo[1] + gridInfo[6]
        end
    end
end

function AvtControler:searchRealTarget()
    local avater = self.avater
    local sgx, sgy = avater.gx,avater.gy
    self.directSearched = false
    --飞行单位直接清除移动状态
    if self.person.utype == 2 then
        self:clearMovingState()
    end

    if self.person.fav and self.person.fav~=0 and self.battleMap:hasType(self.person.fav) then
        self.realTarget = self:getFavBuildWithCache(sgx, sgy, self.person.fav)
    else
        self.realTarget = self:getNormalTargetWithCache(sgx, sgy)
    end
    if self.person.utype == 2 then
        self.attackTarget = self.realTarget
    else
        self.attackTarget = nil
    end
end

function AvtControler:getNormalTargetWithCache(sgx,sgy)
    if self.groupData.isDef and not self.noLengthLimit then
        return self:getNormalTargetWithCache2(sgx,sgy)
    end
    local cacheType = 0
    if self.person.autype == 3 then
        cacheType=-1
    end
    local cacheTarget = self.battleMap:getCachedBuild(math.floor(sgx), math.floor(sgy), cacheType)
    if not cacheTarget or cacheTarget[2].deleted or cacheTarget[2].isHide or cacheTarget[1] < self.scene.sceneTime-5 then
        local fx, fy = sgx, sgy
        local allBuilds = self.battleMap.battler
        local target
        local dis = 1000000
        for _, enemy in ipairs(allBuilds) do
            local canAttack = false
            if self.person.autype == 3 then
                canAttack = true
            else
                if enemy.avater then
                    if self.person.autype == enemy.person.utype then
                        canAttack = true
                    end
                else
                    if self.person.autype == 1 then
                        canAttack = true
                    end
                end
            end
            if canAttack then
                local tdis = self:getBuildDistance(fx, fy, enemy)
                if tdis<dis then
                    target = enemy
                    dis = tdis
                end
            end
        end
        if target then
            self.battleMap:setCachedBuild(math.floor(sgx), math.floor(sgy), cacheType, {self.scene.sceneTime, target})
            return target
        end
    else
        return cacheTarget[2]
    end
end

function AvtControler:getNormalTargetWithCache2(sgx,sgy)        --防守方
    --变成可以策划配置的
    local dfDis = const.DfDistanceNum
    if self.scene.battleType >= 3 and self.scene.battleType<=6 then
        dfDis = 1000000
    end

    local cacheType = 0
    if self.person.autype == 3 then
        cacheType=-1
    end
    local cacheTarget = self.battleMap:getCachedBuild(math.floor(sgx), math.floor(sgy), cacheType)
    if not cacheTarget or cacheTarget[2].deleted or cacheTarget[2].isHide or cacheTarget[1] < self.scene.sceneTime-5 then
        local fx, fy = sgx, sgy
        local allBuilds = self.battleMap.battler
        local target
        local dis = dfDis
        for i=1, #allBuilds do
            local canAttack = false
            if self.person.autype == 3 then
                canAttack = true
            else
                if allBuilds[i].avater then
                    if self.person.autype == allBuilds[i].person.utype then
                        canAttack = true
                    end
                else
                    if self.person.autype == 1 then
                        canAttack = true
                    end
                end
            end
            if canAttack then
                local tdis = self:getSoldierDistance(fx, fy, allBuilds[i])
                if tdis<dis then
                    target = allBuilds[i]
                    dis = tdis
                end
            end
        end
        if target then
            self.battleMap:setCachedBuild(math.floor(sgx), math.floor(sgy), cacheType, {self.scene.sceneTime, target})
            return target
        end
    else
        return cacheTarget[2]
    end
end

function AvtControler:getFavBuildWithCache(sgx, sgy, fav)
    if self.groupData.isDef then
        return self:getFavBuildWithCache2(sgx, sgy, fav)
    end

    local cacheTarget = self.battleMap:getCachedBuild(math.floor(sgx), math.floor(sgy), fav)
    if not cacheTarget or cacheTarget[2].deleted or cacheTarget[1] < self.scene.sceneTime-5 then
        local fx, fy = sgx, sgy
        local allBuilds = self.battleMap:getFavBuilds(fav)
        local target = allBuilds[1]
        local dis
        if target then
            dis = self:getBuildDistance(fx, fy, target)
            for i=2, #allBuilds do
                local tdis = self:getBuildDistance(fx, fy, allBuilds[i])
                if tdis<dis then
                    target = allBuilds[i]
                    dis = tdis
                end
            end
        end
        if target then
            self.scene.battleMap:setCachedBuild(math.floor(sgx), math.floor(sgy), fav, {self.scene.sceneTime, target})
        end
        return target
    else
        return cacheTarget[2]
    end
end

function AvtControler:getFavBuildWithCache2(sgx, sgy, fav)
    local cacheTarget = self.battleMap:getCachedBuild(math.floor(sgx), math.floor(sgy), fav)
    if not cacheTarget or cacheTarget[2].deleted or cacheTarget[1] < self.scene.sceneTime-5 then
        local fx, fy = sgx, sgy
        local allBuilds = self.battleMap:getFavBuilds(fav)
        local target = nil
        --变成可以策划配置的
        local dis = const.DfDistanceNum
        for i=1, #allBuilds do
            local tdis = self:getSoldierDistance(fx, fy, allBuilds[i])
            if tdis<dis then
                target = allBuilds[i]
                dis = tdis
            end
        end
        if target then
            self.scene.battleMap:setCachedBuild(math.floor(sgx), math.floor(sgy), fav, {self.scene.sceneTime, target})
        end
        return target
    else
        return cacheTarget[2]
    end
    return target
end

function AvtControler:getBuildDistance(fgx, fgy, build)
    local battleV = build.BV
    local tgx, tgy, tgw = battleV.gx, battleV.gy, battleV.gsize or 0
    local dx, dy = math.abs(fgx-tgx)-tgw, math.abs(fgy-tgy)-tgw
    return (((dy>0) and dy) or 0)+(((dx>0) and dx) or 0)
end

function AvtControler:getSoldierDistance(fgx, fgy, build)
    local battleV = build.BV
    local tgx, tgy, tgw = battleV.gx, battleV.gy, battleV.gsize or 0
    local dx, dy = math.abs(fgx-tgx)-tgw, math.abs(fgy-tgy)-tgw
    return (((dy>0) and dy) or 0)^2+(((dx>0) and dx) or 0)^2
end

function AvtControler:searchPathToGrid(tgx,tgy)
    local path
    local avater = self.avater
    local sgx, sgy = avater.gx,avater.gy
    local battleMap = self.battleMap
    path = battleMap:canMoveWithDirectMove(sgx,sgy,tgx,tgy)
    if not path then
        path = battleMap:searchPathUsingAstarSample(sgx,sgy,tgx,tgy)
    end
    local mapGrid = self.map
    local grid
    local prevGrid = {sgx, sgy}
    local curBuild
    local truePath = {}
    local pathLength = #path
    if pathLength>0 then
        for i=1,pathLength do
            grid = path[i]
            local normalPathGrid = {math.floor(grid[1]), math.floor(grid[2]), grid[1], grid[2]}
            curBuild = mapGrid.getGridObj(normalPathGrid[1], normalPathGrid[2])
            if curBuild and not curBuild.deleted then
                local check = self:checkPointInBuild(normalPathGrid)
                if check then
                    normalPathGrid = {math.floor(check[2]), math.floor(check[3]), check[2], check[3]}
                end
            end
            truePath[i] = normalPathGrid
            prevGrid = grid
        end
    end
    truePath[pathLength+1] = {math.floor(sgx), math.floor(sgy), sgx, sgy}
    self:clearMovingState()
    self.searchGrids = truePath
    avater.state = PersonState.SEARCHING
end

function AvtControler:searchPathToTarget(realTarget,dontFree)
    --肯定是地面单位
    local avater = self.avater
    local sgx, sgy = avater.gx,avater.gy
    local battleMap = self.battleMap

    local path = nil
    if not self.directSearched then
        path = battleMap:canAttackWithDirectMove(sgx, sgy, self, realTarget)
        self.directSearched = true
    end
    if path then
        self.realTarget, self.attackTarget = realTarget, realTarget
    else
        self.realTarget, self.attackTarget, path = battleMap:searchPathUsingAstar(self, sgx, sgy, realTarget)
    end
    --path是一个反过来的数组
    if not path then return end
    --搜索到路径后，如果目标不是初始目标，则检测
    if self.realTarget~=realTarget then
        local directPath = battleMap:canAttackWithDirectMove(sgx, sgy, self, self.realTarget)
        if directPath then
            path = directPath
            self.attackTarget = realTarget
        end
    end

    local mapGrid = self.map
    local grid
    local prevGrid = {sgx, sgy}
    local curBuild
    local truePath = {}
    local pathLength = #path
    if pathLength>0 then
        --使小兵分散
        path[1][1],path[1][2] = path[1][1]+(-1)^self.rd:randomInt(2)*self.rd:random2()*0.3,
            path[1][2]+(-1)^self.rd:randomInt(2)*self.rd:random2()*0.3
        for i=1,pathLength do
            grid = path[i]
            local normalPathGrid = {math.floor(grid[1]), math.floor(grid[2]), grid[1], grid[2]}
            curBuild = mapGrid.getGridObj(normalPathGrid[1], normalPathGrid[2])
            if curBuild and not curBuild.deleted then
                local check = self:checkPointInBuild(normalPathGrid)
                if check then
                    normalPathGrid = {math.floor(check[2]), math.floor(check[3]), check[2], check[3]}
                end
            end
            truePath[i] = normalPathGrid
            prevGrid = grid
        end
    end
    truePath[pathLength+1] = {math.floor(sgx), math.floor(sgy), sgx, sgy}
    local battleViewInfo = self.attackTarget and self.attackTarget.battleViewInfo
    if battleViewInfo and self.attackTarget==self.realTarget then
        --test if the end point in beside wall
        local allWalls = battleMap.allWalls
        local directions = {{-1,0},{0,-1}, {1,0}, {0,1}}
        local canReset = true
        for i=1, 4 do
            if allWalls[battleMap:getAstarKey(truePath[1][1]+directions[i][1], truePath[1][2]+directions[i][2])] then
                canReset = false
                break
            end
        end
        if canReset then
            local rx, ry = battleViewInfo[1]+(self.rd:random2()*2-1)*battleViewInfo[3],  battleViewInfo[2]+
                (self.rd:random2()*2-1)*battleViewInfo[3]
            truePath[1] = {math.floor(rx), math.floor(ry), rx, ry}
        end
    end
    if not dontFree then
        self:clearMovingState()
    end
    self.searchGrids = truePath
    avater.state = PersonState.SEARCHING
end

--设置free时要清空 searchGrids 不然会穿墙

function AvtControler:resetFree()
    if self.searchGrids then
        self.searchGrids = {}
    end
    if self.avater then
        self.avater:resetFree()
    end
end
--被击退
function AvtControler:beRepel(attacker,disG,time)
    local ltime = time or disG*0.1
    BuffUtil.setBuff(self,{lastedTime = ltime,bfDizziness = ltime})
    self.avater:beRepel(attacker,disG,ltime)
end

function AvtControler:crashTarget(target,disG,time)
    local ltime = time or disG*0.1
    BuffUtil.setBuff(self,{lastedTime = ltime,bfDizziness = ltime})
    self.avater:crashTarget(target,disG,ltime)
end

-- @brief hideSelf接口的回调
local function _showHeroBack(self)
    if self.battleMap2 then
        self.isHide = nil
        self.battleMap2:addObj(self.battleMap2.hero, self, "_hid")
        self.battleMap2:addObj(self.battleMap2.battler, self, "_btid")
        self.battleMap2:addObj(self.battleMap2.battlerAll, self, "_btaid")
    end
end

-- @brief 从逻辑世界中移除自身，避免被buff、攻击波及，释放自己的动画
-- @params htime 移除时间
-- @params useAnimate 是否要播放隐藏动画
function AvtControler:hideSelf(htime, useAnimate)
    self.isHide = true
    self.battleMap2:removeObj(self.battleMap2.hero, self, "_hid")
    self.battleMap2:removeObj(self.battleMap2.battler, self, "_btid")
    self.battleMap2:removeObj(self.battleMap2.battlerAll, self, "_btaid")
    self.scene.replay:addDelay(Handler(_showHeroBack, self), htime)
    if useAnimate then
        self.V.personView:runAction(ui.action.sequence({"hide", {"delay",htime}, "show"}))
        if self.V.blood then
            self.V.blood:runAction(ui.action.sequence({"hide", {"delay",htime}, "show"}))
        end
        if self.V.shadow then
            self.V.blood:runAction(ui.action.sequence({"hide", {"delay",htime}, "show"}))
        end
    end
end

-----------得到各种目标
function AvtControler:getCircleTarget(sobj,tT,r)
    local pointT = {}
    local sgx,sgy
    if not sobj then
        return {}
    end
    if sobj.avater then
        sgx,sgy = sobj.avater.gx,sobj.avater.gy
    elseif sobj.battleViewInfo then
        sgx,sgy = sobj.battleViewInfo[1],sobj.battleViewInfo[2]
    else
        sgx,sgy = sobj[1],sobj[2]
    end
    for _,v in pairs(tT) do
        local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
        table.insert(pointT,{viewInfo[1],viewInfo[2],viewInfo[3],v})
    end
    local result = Aoe.circlePoint(pointT,{sgx,sgy},r)
    local rs = {}
    for i,v in ipairs(result) do
        rs[i] = v[4]
    end
    return rs
end

function AvtControler:getLineTarget(sobj,tT,l,w,target)
    local allBuilds = tT
    local sgx, sgy
    if not sobj.avater then
        sgx,sgy = sobj[1], sobj[2]
    else
        sgx,sgy = sobj.avater.gx,sobj.avater.gy
    end
    local pointT = {}
    for _,v in ipairs(allBuilds) do
        local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
        table.insert(pointT,{viewInfo[1],viewInfo[2],viewInfo[3],v})
    end
    local viewInfo = target.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(target)
    local result = Aoe.line(pointT,{sgx,sgy},l,w,{viewInfo[1],viewInfo[2]})
    local rs = {}
    for k,v in pairs(result) do
        rs[k] = v[4]
    end
    return rs
end

function AvtControler:getMinDisTarget(n,limitDis,targetG)
    local gx, gy = self.avater.gx, self.avater.gy

    local exeNum = 0
    limitDis = (limitDis or 100)^2
    if not targetG then
        targetG = self.battleMap.battler
    end
    if n == 1 then
        local minDis = limitDis
        local minTarget = nil
        local minIsHero = false
        local tmpDis, isHero
        for _, v in ipairs(targetG) do
            tmpDis = self:getSoldierDistance(gx, gy, v)
            isHero = v.sid and v.sid>1000 or false
            if (tmpDis < minDis and minIsHero==isHero) or (not minIsHero and isHero and tmpDis < limitDis) then
                minDis = tmpDis
                minTarget = v
                minIsHero = isHero
            end
        end
        return {minTarget}
    else
        local skillTargetGroup = {}
        local allTarget = {}
        local allDis = {}
        for i, v in ipairs(targetG ) do
            allTarget[i] = v
            allDis[i] = self:getSoldierDistance(gx, gy, v)
        end

        --距离从小到大排序
        if #allTarget > 1 then
            for i=1,#allTarget-1 do
                for j=1,#allTarget-i do
                    if allDis[j] > allDis[j+1] then
                        allDis[j], allDis[j+1] = allDis[j+1], allDis[j]
                        allTarget[j], allTarget[j+1] = allTarget[j+1], allTarget[j]
                    end
                end
            end
        end
        --优先英雄
        for i,v in ipairs(allTarget) do
            if v.sid and v.sid>1000 and allDis[i] <= limitDis then
                table.insert(skillTargetGroup, v)
                exeNum = exeNum+1
                if exeNum >= n then
                    break
                end
            end
        end
        if exeNum<n then
            for i,v in ipairs(allTarget) do
                if not (v.sid and v.sid>1000) and allDis[i]<=limitDis then
                    table.insert(skillTargetGroup,v)
                    exeNum = exeNum+1
                    if exeNum>=n then
                        break
                    end
                end
            end
        end
        return skillTargetGroup
    end
end

function AvtControler:getMaxDisTarget()
    local allBuilds = self.battleMap.battler

    local maxDis = 0
    local maxTarget = nil
    local maxIsHero = false
    local tmpDis, isHero
    local gx, gy = self.avater.gx, self.avater.gy
    for _, v in ipairs(allBuilds) do
        tmpDis = self:getBuildDistance(gx, gy, v)
        isHero = v.sid and v.sid>1000 or false
        if (tmpDis > maxDis and maxIsHero==isHero) or (not maxIsHero and isHero) then
            maxDis = tmpDis
            maxTarget = v
            maxIsHero = isHero
        end
    end
    return maxTarget
end

function AvtControler:getSectorTarget(targetG,sp,tp,radius,angle)
    local sgx, sgy = sp.avater.gx,sp.avater.gy
    local pointTab = {}
    for _,v in ipairs(targetG) do
        local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
        table.insert(pointTab,{viewInfo[1],viewInfo[2],viewInfo[3],v})
    end
    local viewInfo = tp.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(tp)

    local result = Aoe.sectorPoint(pointTab,{sgx,sgy},radius,angle,{viewInfo[1],viewInfo[2]})
    local rs = {}
    for k,v in ipairs(result) do
        rs[k] = v[4]
    end
    return rs
end

function AvtControler:getMinHpTarget(targetG,n)
    if n and n>1 then
        local result = {}
        local allTarget = {}
        local allHp = {}
        for i, v in ipairs(targetG) do
            allTarget[i] = v
            allHp[i] = targetG[i].avtInfo.nowHp/targetG[i].avtInfo.maxHp
        end
        local tn = #targetG
        if tn > 1 then
            for i=1, tn do
                for j=1, tn-i do
                    if allHp[j] > allHp[j+1] then
                        allTarget[j], allTarget[j+1] = allTarget[j+1], allTarget[j]
                        allHp[j], allHp[j+1] = allHp[j+1], allHp[j]
                    end
                end
            end
        end
        for i=1, n do
            if not allTarget[i] then
                break
            else
                table.insert(result, allTarget[i])
            end
        end
        return result
    else
        local temp = 2
        local target
        for _,v in ipairs(targetG) do
            local hp = v.avtInfo.nowHp/v.avtInfo.maxHp
            if hp<temp then
                temp = hp
                target = v
            end
        end
        return target
    end
end

--获取敌方英雄和佣兵
function AvtControler:getHeroAndSoldier(person, n)
    local targetG = {}
    local enemySoldier = person:getCircleTarget(person, person.battleMap.mer, n)
    local enemyHero = person:getCircleTarget(person, person.battleMap.hero, n)
    for _,v in ipairs(enemySoldier) do
        table.insert(targetG, v)
    end
    for _,v in ipairs(enemyHero) do
        table.insert(targetG, v)
    end
    return targetG
end

function AvtControler:clearMovingState()
    local avater = self.avater
    avater.state = PersonState.FREE
    if self.searchGrids then
        self.searchGrids = {}
    end
end

function AvtControler:ppexeSkill()
    --只有黄金boss才可以放技能
    if self.cantUseSkill then
        return true
    end

    if self.deleted or self.isHide then
        return true
    end
    --萨满在没有本方英雄死亡时技能不能施放
    if self.sid == 4021 and #self.battleMap2.diedHero<=0 then
        return  true
    end
    if self.avtInfo.bfSilent>0 then
        return true
    end
    if self.isSkillAttack or self.isSkillNotAttack then
        --print('前一次技能还没有施放')
        return true
    end
    if self.coldTime and self.coldTime>0 then
        --print("冷却时间未到")
        return true
    end

    local params = self.avtInfo.person.actSkillParams
    local need = params.x/10
    if self.scene.battleType==5 then
        need = 0
    end
    local groupData = self.groupData
    local anger = groupData.anger

    if need <= anger or self.groupData.inSkillGB10Godstate then  --怒气足够或者10尾天神技buff
        if self.sg_ppexeSkill then
            self:sg_ppexeSkill(self.attackTarget)
        else
            self.isSkillAttack = true
            self.isSkillNotAttack = true
        end
        local itype =  (self.scene.battleType == const.BattleTypePve) and
            (self.scene.battleParams.stage == const.HeroInfoNewTry) or false
        if (not itype) and (not self.groupData.inSkillGB10Godstate) then
            --得到各种目标10尾天神技buff时不消耗怒气//试玩的时候也是不消耗怒气的
            groupData.anger = groupData.anger-need
        end
        if itype then
            self.coldTime = 2
        else
            self.coldTime = DEBUG.DEBUG_NOCOLD and 0 or params.z
        end
        return true
    --else
        --print('怒气不足')
    end
end

function AvtControler:ppexeGodSkill()
    print("准备释放天神技")
end

function AvtControler:exeSkill(target)
    --print('技能使用',self.sid)
    local skillSet = {
        [2001] = SkillPlugin.exeJinShuRen,
        [2003] = SkillPlugin.exeJianDaoShou,
        [2004] = SkillPlugin.exeNvJianXian,
        [3002] = SkillPlugin.exeMeiGuoDuiZhang,
        [3004] = SkillPlugin.exeZhiZhuXia,
        [3006] = SkillPlugin.exeBianFuXia
    }
    if self.exeSkillForGodBeast then
        return self:exeSkillForGodBeast(target or self.attackTarget)
    end
    if self.sg_exeSkill then
        return self:sg_exeSkill(target or self.attackTarget)
    end
    return skillSet[self.sid](self,target or self.attackTarget)
end

--得到debug replay的tag
function AvtControler:getTag()
    local tag = self.group .. "_" .. self.sid
    if self.addTimeFlag then
        tag = tag .. "_" .. self.addTimeFlag
    end
    return tag
end

-- @brief 英雄通用复活逻辑
-- @params gx, gy 复活时的坐标
-- @params normalEffect 复活时是否使用通用特效
-- @params animateTime 复活的动画时间
function AvtControler:normalRebirth(gx, gy, normalEffect, animateTime)
    -- 破坏尸体，避免被重复复活
    self.isRebirthed = true
    self.avtInfo.cantRebirth = 1000000
    local params = self.params
    -- TODO 这是干啥的呀？没找到用到的地方啊。
    params.index = nil
    -- 正常复活的单位不属于召唤物
    params.isZhaoHuan = false
    params.isRebirth = true
    local role = PersonUtil.C(params)
    local scene = GMethod.loadScript("game.View.Scene")
    if normalEffect then
        local px, py = scene.map.convertToPosition(gx, gy)
        Hulk2ZhaoHuan.new(scene.objs, px, py)
    end
    role.M.nowHp = role.M.maxHp
    role.dataIdx = self.dataIdx
    role.assistHero = self.assistHero
    role.targetGrid = self.targetGrid
    role.releasedGodSkill = self.releasedGodSkill
    role:addToScene(scene, gx, gy)
    role.avater.finishSkill = self.avater.finishSkill
    --为了UI显示
    if params.hpos then
        if scene.battleType == const.BattleTypePvt then
            local heros
            if params.group == 1 then
                heros = scene.battleData.heros
            else
                heros = scene.battleData.dheros
            end
            heros[params.hpos].role = role
        else
            scene.battleData.groups[params.group].heros[params.hpos] = role
        end
    end
    --本体
    if animateTime and animateTime > 0 then
        -- 复活的时候动画要自己放
        role:hideSelf(animateTime, false)
        if role.V.personView and normalEffect then
            role.V.personView:setOpacity(0)
            role.V.personView:runAction(ui.action.fadeTo(animateTime, 255))
            if role.V.shadow then
                role.V.shadow:setOpacity(0)
                role.V.shadow:runAction(ui.action.fadeTo(animateTime, 255))
            end
            if role.V.blood then
                role.V.blood:setOpacity(0)
                role.V.blood:runAction(ui.action.fadeTo(animateTime, 255))
            end
        end
    end
    return role
end

-- @brief 获取周围随机一个点
-- @params radius半径
function AvtControler:getRandomGrid(radius)
    local gx = self.avater.gx - radius + self.rd:random2()*radius*2
    local gy = self.avater.gy - radius + self.rd:random2()*radius*2
    local gridInfo = {math.floor(gx), math.floor(gy), gx, gy}
    local check = self:checkPointInBuild(gridInfo)
    if check then
        gx,gy = check[2],check[3]
    end
    return gx, gy
end

_G["AvtControler"] = AvtControler
return AvtControler
