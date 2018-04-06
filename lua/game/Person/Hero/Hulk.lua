local M = class(AvtInfo)

local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local attackMode = 1
    if self.skillLastTimeAll then
        attackMode = 2
        if self.animaConfig.skill_music11 then
            music.play("sounds/" .. self.animaConfig.skill_music11)
        end
    end
    HulkEffect.new({attacker = self, mode = 0, target = attackTarget, attackMode = attackMode},callback)
end
function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 1

    self:attack(viewInfo1,viewInfo2,b)
    self:currencyEffect(1,60,1)
    self.state = PersonState.SKILL
end

function V:skillViewEffect(attackTarget,callback,skillLastTimeAll)
    skillLastTimeAll = self.C.actSkillParams.y
    self.view:setScale(1.3)
    self.shadow:setScale(5.8)
    local function setSca( ... )
        self.view:setScale(1)
        self.shadow:setScale(4.5)
    end
    self.view:runAction(ui.action.sequence({{"delay",skillLastTimeAll},{"call",setSca}}))
    HulkEffect.new({attacker = self, mode = 1, target = attackTarget, lastedTime = skillLastTimeAll},function()
        callback()
        self.skillLastTimeAll = skillLastTimeAll
        self.skillLastTime = 0
    end)
end

function V:skillAfter()
    self.skillLastTimeAll = nil
    self.skillLastTime = nil
    print("after test")
end

local C = class(AvtControler)

--4023持续[y]秒内，每次攻击对目标1格内的敌人造成[c]%溅射伤害，增加自身[d]%的攻击力，增加减伤率[e]%，并每秒持续恢复自身血量，总共为自身最大血量的f%，消耗[x]怒，冷却时间[z]秒")
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,d,e,f,y = params.c,params.d,params.e,params.f,params.y
    local g = params.g
    BuffUtil.setBuff(self,{lastedTime = y,bfAtkPct = d,bfDefPct = e,lastAddHp = self.M.maxHp*f/100,bfSputter = {g,c}})
end


--天神技  击飞一个自身攻击范围内的敌人，使其撞向另一个目标，并且对目标[n]格范围内的敌人造成[a]+[x]%自身攻击力伤害，眩晕所有受到伤害的敌人[t]秒
-- 更改为冲向一个敌人，并且对目标[n]格范围内的敌人造成[a]+[x]%自身攻击力伤害，眩晕所有受到伤害的敌人[t]秒
function C:ppexeGodSkill()
    self.godSkillTarget = self:getMinDisTarget(1)[1]
    if self.godSkillTarget then
        self.isGodSkillNotAttack = true
    end
end

function C:exeGodSkill(gx, gy)
    local ps = self.person.awakeData.ps
    local ret = self:getCircleTarget({gx,gy},self.battleMap.battlerAll,ps.n)
    for k,v in ipairs(ret) do
        SkillPlugin.exe2(self,v,ps.a,ps.x)
        if not v.deleted then
            BuffUtil.setBuff(v,{lastedTime=ps.t, bfDizziness=ps.t})

            HulkEffect.new({attacker = self.avater, mode = 5, lastedTime=ps.t, target = v})
        end
    end

    self.isGodSkillAttack = nil
    self.isGodSkillNotAttack = nil
    self.isGodSkillNow = nil
    self.V.maxZorder = self.V.maxZorder - 300
end

--技能改了之后要换动作跳；因为没时间让美术重做了，所以程序里用比较麻烦的方式实现一下
function V:sg_godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
    --目标点坐标
    local viewInfo = attackTarget.battleViewInfo or self.C.battleMap:getSoldierBattleViewInfoReal(attackTarget)
    local gx,gy = viewInfo[1],viewInfo[2]
    local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
    local check = self.C:checkPointInBuild(gridInfo)
    if check then
        gx,gy = check[2],check[3]
    end
    --飞的人 是自己
    self.C.shouldReCheck = true
    self:spmoveDirect(gx, gy, 30)
    -- 考虑这个时间内适当延长一点做跳跃
    local allActionTime = self.allActionTime + 1
    self.allActionTime = allActionTime
    -- 考虑给自己加一个非常短暂的无敌buff；否则这种技能放到一半莫名奇妙挂掉都可能出BUG
    BuffUtil.setBuff(self.C,{lastedTime = allActionTime, immune = 1, ctDizziness=1})
    
    HulkEffect.new({attacker = self, mode = 4, target = attackTarget, allActionTime=allActionTime, moveTarget=self.C})

    self.loop = false
    local sfmt,sparams 
    if type(self.animaConfig.skill_fmt) == "string" then
        sfmt = self.animaConfig.skill_fmt
        sparams = self.animaConfig.skill_params
    else
        sfmt = self.animaConfig.skill_fmt[1]
        sparams = self.animaConfig.skill_params[1]
    end
    self.frameFormat = sfmt
    self.animaTime = 0
    self.frameIndex = 0
    -- self.oneFrameTime = sparams[1]/sparams[2]
    self.frameMaxIndex = sparams[2]
    self.actionTime = 0
    -- 增加最大像素
    self.maxZorder = self.maxZorder + 300
    self.state = PersonState.GODSKILL

    self.specialList = {{6, {0, 1, 7, 4, 5, 6}}, {-1, 2}, {-4, {7, 0}}}
    self.oneFrameTime = 0.1

    self.inSkillEffect = nil
end

function V:updateSpecialState(diff)
    self.actionTime = self.actionTime+diff
    if self.inSkillEffect then
        if self.actionTime >= self.allActionTime + self.specialList[3][1]*self.oneFrameTime then
            self.animaTime = self.specialList[3][2][math.floor(self.actionTime - (self.allActionTime + self.specialList[3][1]*self.oneFrameTime)) + 1] or 0
            self:resetFrame(0)
        end
        if self.actionTime >= self.allActionTime then
            self.actionTime = self.actionTime-self.allActionTime
            self:resetFree()
            self.attackEffectView = nil
        end
    elseif self.actionTime >= self.allActionTime then
        self.allActionTime = self.allActionTime + 0.5
        self.animaTime = 3 * self.oneFrameTime
        self:resetFrame(0)
        self.gx = self.targetPoint[1]
        self.gy = self.targetPoint[2]
        self.C:exeGodSkill(self.gx, self.gy)
        local px,py = self.map.convertToPosition(self.gx,self.gy)
        for _, view in ipairs(self._logicViews) do
            view:setPosition(px, py)
        end
        self.px, self.py = px, py + self.animaConfig.Ymove
        self.view:setLocalZOrder(self.maxZorder-py)
        if self.blood then
            self.blood:setLocalZOrder(self.maxZorder-py)
        end
        self.inSkillEffect = true
    else
        if self.actionTime <= self.oneFrameTime * self.specialList[1][1] then
            self.animaTime = self.specialList[1][2][math.floor(self.actionTime/self.oneFrameTime)+1] * self.oneFrameTime
            self:resetFrame(0)
        elseif self.actionTime >= self.allActionTime + self.oneFrameTime * self.specialList[2][1] then
            self.animaTime = self.specialList[2][2] * self.oneFrameTime
            self:resetFrame(0)
        end
        self:resetPosition()
    end
end

--当英雄防御时，重机枪增加[x]%攻击力，[y]%血量。如果重机枪被消灭，重机枪会变成一个拥有[z]%血量和攻击力的此英雄复制体。
function C:sg_updateBattle(diff)
    if self.deleted then
        return
    end
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap.build
        end
        for k,v in pairs(group) do
            if v.bid == 27 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.atk = v.M.atk*(1+ps.x/100)
                BuffUtil.setBuff(v,{hero=self, z=ps.z},"HulkGodSkill2")
            end
        end
    end
end

HulkEffect = class()

function HulkEffect:ctor(params,callback)
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

function HulkEffect:initParams(params)
    self.effectManager=GameEffect.new("HulkEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 800
    self.target = params.target or params.attacker.C.attackTarget
    self.attackMode = params.attackMode
    self.lastedTime = params.lastedTime
    self.allActionTime = params.allActionTime
    self.moveTarget = params.moveTarget
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

function HulkEffect:initEffect()
    if self.mode == 0 then
        if self.attackMode == 1 then
            self:initAttack1()
        elseif self.attackMode == 2 then
            self:initAttack2()
        end
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 4 then
        self:initGodSkill()
    elseif self.mode == 5 then
        self:initGodSkill_target2()
    end
end

function HulkEffect:initAttack1()
    self.time = 0.1
    local setting={{66,-17,45},{158,79,-15},{93,176,-45},{-93,176,225},{-158,79,195},{-66,-17,135}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+10000
    local r=setting[direction][3]
    local temp

    local attNode=ui.node()
    attNode:setPosition(initPos[1],initPos[2])
    bg:addChild(attNode,initPos[3])
    attNode:setRotation(r)
    attNode:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
    local function delayFrameIndex_34()
    effectManager:addEffect("views2_delay34",attNode)
    temp=views.Shockwave_00000_6_11
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    temp=views.Strike_00000_25_11
    temp:setPosition(50,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_34}}))

    local function delayFrameIndex_29()
    effectManager:addEffect("views2_delay29",attNode)
    temp=views.Sprite_27_11
    temp:setRotation(45)
    temp:setPosition(20,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
    temp=views.Glow_01_9_11
    temp:setPosition(0,0)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_9_0_11
    temp:setPosition(0,0)
    temp:setLocalZOrder(6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_29}}))

    local function delayFrameIndex_39()
    effectManager:addEffect("views2_delay39",attNode)
    temp=views.chips_26_11
    temp:setRotation(90)
    temp:setPosition(40,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_39}}))

end

function HulkEffect:initAttack2()
    self.time = 0.1
    local setting={{66,-17,45},{158,79,-15},{93,176,-45},{-93,176,225},{-158,79,195},{-66,-17,135}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]
    initPos[3]=self.initPos[3]+10000
    local ox,oy=setting[direction][1],setting[direction][2]
    local r=setting[direction][3]
    local temp
    local attNode=ui.node()
    attNode:setPosition(initPos[1]+ox,initPos[2]+oy)
    bg:addChild(attNode,initPos[3])
    attNode:setRotation(r)
    attNode:setScale(1.5)
    attNode:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
    local function delayFrameIndex_49()
    local orr={0,-60,-90,-90,-120,-180}
    effectManager:addEffect("views1_delay49",bg)
    temp=views.Strike_00000_5_111
    if direction<=3 then
    temp:setAnchorPoint(0.733,0.261)
    temp:setFlippedY(true)
    else
    temp:setAnchorPoint(0.733,0.739)
    end
    temp:setRotation(orr[direction])
    temp:setPosition(initPos[1]+ox,initPos[2]+oy)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"delay",4/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    delayFrameIndex_49()
    local function delayFrameIndex_64()
    effectManager:addEffect("views1_delay64",attNode)
    temp=views.Shockwave_00000_6_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_64}}))

    local function delayFrameIndex_59()
    effectManager:addEffect("views1_delay59",attNode)
    temp=views.Spin_00000_10_111
    temp:setRotation(45)
    temp:setPosition(40,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    temp=views.Spin_00000_10_0_111
    temp:setRotation(45)
    temp:setPosition(40,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_54()
    effectManager:addEffect("views1_delay54",attNode)
    temp=views.Glow_01_9_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Glow_01_9_0_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    delayFrameIndex_54()
end

function HulkEffect:initSkill()
    self.time = 0.1
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={0,0,0}
    local temp
    local tatol = self.lastedTime

     local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.3)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",tatol+5/60},"remove"}))

    local function delayFrameIndex_30()
    effectManager:addEffect("views1_delay30",downNode)
    temp=views.Glow_01_14_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(-3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,153},{"delay",tatol-10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Ground_Wave_00000_13_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_14_0_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(-1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,191},{"delay",tatol-10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_14_0_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,216},{"delay",tatol-10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end
    delayFrameIndex_30()
end

function HulkEffect:initGodSkill()
  --根据方向设定落地位置
  local setting={{400,-300,150},{400,0,200},{400,300,450},{-400,300,450},{-400,0,200},{-400,-300,150}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction

   local initPos=self.initPos
   --落地坐标
   local targetPos2=self.targetPos
   self.targetPos2=targetPos2


   --被击英雄曲线加360度飞到落地点

   local moveX=targetPos2[1]-initPos[1]
   local moveY=targetPos2[2]-initPos[2]
   local spareTime = math.sqrt(moveX^2+moveY^2)/self.speed
    local moveTime=self.allActionTime or spareTime
    self.time = moveTime+14/60

   local moveH1=setting[direction][3]
   local moveH2=moveY-moveH1
   local temp

   --飞的人
   local moveTarget = self.moveTarget
    if moveTarget and moveTarget.V.personView then
        moveTarget.V.personView:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(moveTime/2,0,200)),ui.action.easeSineIn(ui.action.moveBy(moveTime/2,0,-200))}))
        -- moveTarget.V.personView:runAction(ui.action.action({"rotateBy",moveTime,720}))
    end

   local function delayFrameIndex_14()
        if moveTarget and moveTarget.V.personView then
            initPos[1] = 0
            initPos[2] = 50+moveTarget.V.animaConfig.Ymove
            bg = moveTarget.V.personView
        else
            return
        end
     effectManager:addEffect("godSkill_views1_delay14",bg)

     local function showTargetBao( )
       self:initGodSkill_target1()
     end
      temp=views.Particle_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10010)
      temp:runAction(ui.action.sequence({{"delay",moveTime},{"call",showTargetBao},"remove"}))
      if not moveTarget then
        temp:runAction(ui.action.moveBy(moveTime,moveX,0))
        temp:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(moveTime/2,0,moveH1)),ui.action.easeSineIn(ui.action.moveBy(moveTime/2,0,moveH2))}))
      end
      temp=views.Particle_1_Copy
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10011)
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      if not moveTarget then
        temp:runAction(ui.action.moveBy(moveTime,moveX,0))
        temp:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(moveTime/2,0,moveH1)),ui.action.easeSineIn(ui.action.moveBy(moveTime/2,0,moveH2))}))
      end
      temp=views.Particle_1_Copy_Copy_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10012)
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      if not moveTarget then
        temp:runAction(ui.action.moveBy(moveTime,moveX,0))
        temp:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(moveTime/2,0,moveH1)),ui.action.easeSineIn(ui.action.moveBy(moveTime/2,0,moveH2))}))
      end
      temp=views.Particle_1_Copy_Copy
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10013)
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      if not moveTarget then
        temp:runAction(ui.action.moveBy(moveTime,moveX,0))
        temp:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(moveTime/2,0,moveH1)),ui.action.easeSineIn(ui.action.moveBy(moveTime/2,0,moveH2))}))
      end
      temp=views.Particle_1_Copy_Copy_Copy
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10014)
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      if not moveTarget then
        temp:runAction(ui.action.moveBy(moveTime,moveX,0))
        temp:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(moveTime/2,0,moveH1)),ui.action.easeSineIn(ui.action.moveBy(moveTime/2,0,moveH2))}))
      end
   end
   delayFrameIndex_14()

end
--爆炸
function HulkEffect:initGodSkill_target1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos2
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+80)
   bg:addChild(upNode,initPos[3]+100000)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",90/60},"remove"}))

   local function delayFrameIndex_35()
     effectManager:addEffect("godSkill_views2_delay35",upNode)
      temp=views.Explosion_00000_5
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",7/60,0,-42}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",7/60,4.2,4.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"delay",25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",48/60},"remove"}))
      temp=views.Explosion_00000_5_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",7/60,0,-42}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",7/60,4.2,4.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",13/60,104},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",48/60},"remove"}))
      temp=views.Impact_00000_4
      temp:runAction(ui.action.sequence({{"delay",5/60},{"moveBy",25/60,0,77}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",4/60,3.5,3.5},{"scaleTo",1/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",10/60,255},{"delay",30/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
   end
   delayFrameIndex_35()

   local function delayFrameIndex_36()
     effectManager:addEffect("godSkill_views2_delay36",upNode)
      temp=views.Glow_02_9
      temp:runAction(ui.action.sequence({{"scaleTo",9/60,2.8,2.0},{"scaleTo",15/60,2.0,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
      temp=views.Glow_02_9_0
      temp:runAction(ui.action.sequence({{"scaleTo",9/60,2.8,2.0},{"scaleTo",5/60,2.8,2.0},{"scaleTo",10/60,2.0,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
   end
   delayFrameIndex_36()

   local function delayFrameIndex_37()
     effectManager:addEffect("godSkill_views2_delay37",upNode)
      temp=views.Shockwave_00000_7
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",8/60,1.8,1.44},{"scaleTo",8/60,2.6,2.07},{"scaleTo",8/60,2.8,2.23}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,72},{"fadeTo",8/60,255},{"delay",12/60},{"fadeTo",5/60,0},{"delay",3/60}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
      temp=views.Shockwave_00000_7_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",8/60,1.8,1.44},{"scaleTo",8/60,2.6,2.07},{"scaleTo",8/60,2.8,2.23}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,72},{"fadeTo",8/60,255},{"delay",12/60},{"fadeTo",5/60,0},{"delay",3/60}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_37}}))

   local function delayFrameIndex_39()
     effectManager:addEffect("godSkill_views2_delay39",upNode)
      temp=views.Shockwave_00000_4
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.4,1.2},{"scaleTo",10/60,1.6,1.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Shockwave_00000_4_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.4,1.2},{"scaleTo",10/60,1.6,1.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Shockwave_00000_3
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

      temp=views.Shockwave_00001_3
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",33/60,5,3.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))
      temp=views.Shockwave_00001_3_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",33/60,5,3.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))
      temp=views.Stone_00001_5
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"delay",30/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Stone_00001_5_0
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"delay",30/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_39}}))

end
--被动用晕眩
function HulkEffect:initGodSkill_target2()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local total = self.target.avtInfo.bfDizziness
    if total <= 0 then
        return
    end
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2]+80)
    bg:addChild(upNode,initPos[3]+100000)
    upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

    effectManager:addEffect("godSkill_views3_delay0",upNode)
    temp=views.Vertigo_00000_7
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))

end



function HulkEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        if self.mode == 4 then
            -- self.callback(self.targetPos)
        else
            self.callback(self.target)
        end
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}




























