local M = class(AvtInfo)

local V = {}

local HeibaoEffect = class()

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 0

    self.exeAtkFrame = 1
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    self:currencyEffect(1,50,1)
    self.state = PersonState.SKILL
end

function V:viewEffect(attackTarget,callback,isSkill)
    if not isSkill then
        -- 普攻直接执行伤害
        callback(attackTarget)
        return
    end
    -- 技能攻击搜索敌人; 感觉原来设计的不太合理
    local targets = self.C:getMinDisTarget(self.C.actSkillParams.n)
    for _, target in ipairs(targets) do
        HeibaoEffect.new({attacker = self, mode = 1, target = target, speed=20}, callback)
    end
end

function V:sg_godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 10
    self.skillStopStart = 3
    self.loop = false
    self.isExeRealAtk = false

    local sfmt,sparams
    sfmt = self.animaConfig.skill_fmt[2]
    sparams = self.animaConfig.skill_params[2]
    self.frameFormat = sfmt
    self.animaTime = 0
    self.frameIndex = 0
    self.oneFrameTime = 0.067
    self.frameMaxIndex = sparams[2]
    self.actionTime = 0
    self.notRecoverFrame = true

    self.exeAtkFrame = sparams[3]

    self.allActionTime = sparams[1]
    local temp = ui.csbNode("UICsb/HeroEffect_4033/j_6.csb")
    local action = ui.csbTimeLine("UICsb/HeroEffect_4033/j_6.csb")
    temp:setScale(1.3)
    temp:runAction(action)
    action:gotoFrameAndPlay(60,110,0,true)
    display.adapt(temp,0,10,GConst.Anchor.Center)
    self.godSkillNode=temp
    self.view:addChild(temp, 0)
    --通用特效
    --self:currencyEffect(1,50,1)
    self.state = PersonState.GODSKILL
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    -- local viewInfo = attackTarget.battleViewInfo or self.C.battleMap:getSoldierBattleViewInfoReal(attackTarget)
    -- local gx,gy = viewInfo[1],viewInfo[2]
    -- local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
    -- local check = self.C:checkPointInBuild(gridInfo)
    -- if check then
    --     gx,gy = check[2],check[3]
    -- end
    -- self.noResetFrame = true
    -- self:spmoveDirect(gx,gy,10)
    -- self.scene.replay:addDelay(function()
    --     self.noResetFrame = nil
    --     callback()
    --     BuffUtil.setBuff(self.C,{lastedTime=2, bfDizziness=2})
    -- end,self.allActionTime-0.1)
    HeibaoEffect.new({attacker = self, mode = 4, target = self.C})
    callback()
end


local C = class(AvtControler)

local function _beforeAttack(attack, value, defence)
    attack.__attackCount = attack.__attackCount + 1
    local extData = attack:getExtSkillData()
    if attack.__attackCount >= extData.a then
        local specialValue = defence.avtInfo.maxHp * extData.c / 100
        local specialValue2 = attack.avtInfo.nowHp * extData.d
        if specialValue > specialValue2 then
            specialValue = specialValue2
        end
        value[1] = specialValue
        attack.__attackCount = 0
    end
end

-- @brief 通用添加逻辑组件的方法
function C:onInitComponentsDelay()
    if not self.params.isZhaoHuan and self:checkGodSkill2(true) then
        BuffUtil.setStaticBuff(self, "atk", self.person.awakeData2.ps.x * self.avtInfo.base_atk)
        BuffUtil.setStaticBuff(self, "criticalNum", self.person.awakeData2.ps.y/100)
    end
    self.__attackCount = 0
    LGBT.addComponentFunc(self, "beforeNormalAttack", _beforeAttack)
end

function C:sg_ppexeSkill(target)
    -- 有攻击目标才能放
    if self.attackTarget then
        self.isSkillAttack = true
        self.isSkillNotAttack = true
    end
end

function C:sg_exeSkill(target)
    if not target then
        return
    end
    local params = self.actSkillParams
    local a,c = params.a,params.c
    if not target.deleted then
        SkillPlugin.exe2(self,target,a,c)
        if target.deleted and target.avtInfo.id>1000 and target.avtInfo.id<10000 then
            if self.coldTime then
                self.coldTime = self.coldTime - (params.z * params.d / 100)
            end
            if self.coldTime2 then
                self.coldTime2 = self.coldTime2 - (params.z * params.d / 100)
            end
        end
    end
end

-- 天神技
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    if self.deleted then
        return
    end
    local ps = self.person.awakeData.ps
    BuffUtil.setBuff(self, {lastedTime=ps.t, bfAtkSpeedPct=ps.x, bfMovePct=ps.y, criticalNum=ps.z,effect=self.V.godSkillNode}, "Heibao")
    -- self.scene.replay:addDelay(function()
    --     local ps = self.person.awakeData.ps
    --     local tg = self:getCircleTarget(self.attackTarget,self.battleMap.battlerAll,ps.n)
    --     for i,v in ipairs(tg) do
    --         SkillPlugin.exe2(self,v,ps.a,ps.x)
    --         BuffUtil.setBuff(v,{lastedTime = ps.t,bfAtkSpeedPct = -ps.y,lastAddHp = -ps.z*self.M.atk*ps.t/100})
    --     end
    -- end,1)
end

function C:afterKill(target)
    if self.allBuff and self.allBuff["Heibao"] then
        if target.avtInfo.id > 1000 and target.avtInfo.id < 10000 then
            self.allBuff["Heibao"].lastedTime = self.allBuff["Heibao"].lastedTime + self.person.awakeData.ps.k
        end
    end
end

function HeibaoEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegUpdate(function(diff)
            self.updateMy(diff)
        end,0)
    end
end

function HeibaoEffect:initParams(params)
    -- self.effectManager=GameEffect.new("HeibaoEffect.json")
    -- self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight - p[2]}

    --目标点坐标
    local view,height
    if self.target.avater then
        view = self.target.avater.view
        height = 40 + self.target.avater.animaConfig.Ymove
        self.targetZ = 41 + self.target.avater.animaConfig.Ymove
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
    end
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function HeibaoEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 4 then
        self:initGoldSkill()
    end
end

function HeibaoEffect:initAttack()
    local setting={{53,-33},{100,51},{55,121},{-55,121},{-100,51},{-53,-33}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime = math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime
    local temp

    local function delayFrameIndex_64()
    effectManager:addEffect("views2_delay64",bg)
    temp=views.Sprite_16_b
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+10000)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",moveTime+0/60},{"call",delayFrameIndex_64}}))

    local function delayFrameIndex_29()

    effectManager:addEffect("views2_delay29",bg)
    temp=views.Sprite_13_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10000)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime},{"scaleTo",10/60,1.5,1.5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime+5/60},{"fadeTo",5/60,0},"remove"}))

    temp=views.Sprite_13
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10002)
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(35/60,180)))
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime+1/60},{"fadeTo",1/60,0},"remove"}))
    temp=views.Sprite_13_0_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10004)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime},{"scaleTo",10/60,0.6,0.6}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,153},{"delay",moveTime+5/60},{"fadeTo",5/60,0},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))
end

function HeibaoEffect:initSkill()
    local initGridX, initGridY = self.attacker.gx, self.attacker.gy
    local targetGridX, targetGridY = self.target.BV.gx, self.target.BV.gy
    local moveX, moveY = targetGridX - initGridX, targetGridY - initGridY
    local moveTime = math.sqrt(moveX*moveX + moveY*moveY) / self.speed
    self.time = moveTime
    local bg = self.viewsNode

    local temp = ui.csbNode("UICsb/HeroEffect_4033/b_0.csb")
    local action = ui.csbTimeLine("UICsb/HeroEffect_4033/b_0.csb")
    action:gotoFrameAndPlay(0,0,0,false)
    temp:runAction(action)
    temp:setScale(2.5)
    temp:runAction(ui.action.sequence{{"moveTo",self.time,self.targetPos[1],self.targetPos[2]},"remove"})
    display.adapt(temp,self.initPos[1],self.initPos[2],GConst.Anchor.Center)
    bg:addChild(temp,self.targetPos[3])

    temp = ui.csbNode("UICsb/HeroEffect_4033/c_0.csb")
    temp:runAction(ui.action.sequence{{"delay",self.time},{"call",function()
        local action = ui.csbTimeLine("UICsb/HeroEffect_4033/c_0.csb")
        action:gotoFrameAndPlay(0,60,0,false)
        temp:runAction(action)
    end}})
    display.adapt(temp,self.targetPos[1],self.targetPos[2],GConst.Anchor.Center)
    bg:addChild(temp,self.targetPos[3])
end

function HeibaoEffect:initGoldSkill()
    self.time = nil
end

function HeibaoEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target,true)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}
