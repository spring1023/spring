

local M = AvtInfo













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)   --这是攻击特效
    local mode = 0
    if isSkill then
        mode = 1
    end
    HouYiEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--4012    后羿 主动技能28  无攻击距离限制，优先攻击敌方血量最低的英雄，造成a+c%*ATK伤害，对3格内的敌人造成溅射伤害d%，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill()
    if self:searchSkillTarget() then
        self.isSkillAttack = true
        self.isSkillNotAttack = true
    end
end

function C:searchSkillTarget(again)
    local battlerArr = self.battleMap.hero
    if again then
        battlerArr = self.battleMap.battler
    end
    local target
    local minHp = 2
    for i,v in ipairs(battlerArr) do
        local hp = v.M.nowHp/v.M.maxHp
        if hp<minHp then
            minHp = hp
            target = v
        end
    end
    if target then
        self.skillTarget = target
        return true
    else
        if again then
            return false
        else
            return self:searchSkillTarget(true)
        end
    end

end

function C:sg_exeSkill(skilltarget)
    -- if not self.skillTarget then
    --     return
    -- end
    local target = skilltarget or self.skillTarget

    local params = self.actSkillParams
    local a,c,d = params.a,params.c,params.d       --Test
    if target then
        SkillPlugin.exe2(self,target,a,c)
    end
    local viewInfo = target.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(target)
    --local viewInfo = self.skillTarget.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(self.skillTarget)
    local targetG = self:getCircleTarget(target,self.battleMap.battlerAll,3)
    for k,v in ipairs(targetG) do
        if v ~= target then
            SkillPlugin.exe2(self,v,a,c,d)
        end
    end
end

--天神技 以血量最少的[m]个敌方英雄为目标，目标受到伤害增加[x]%，受到的治疗减少[y]%，死亡时无法复活，持续[t]秒。己方杀死目标的英雄将增加[z]%攻击力，持续[k]秒。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local tg = {}
    for idx=1,ps.m do
        local tempHp = 100000000
        for i,v in ipairs(self.battleMap.hero) do
            local sign = true
            for i2,v2 in ipairs(tg) do
                if v == v2 then
                    sign = false
                end
            end
            if sign and v.M.nowHp<tempHp then
                tempHp = v.M.nowHp
                tg[idx] = v
            end
        end
    end

    for i,v in ipairs(tg) do
        self.scene.replay:addDelay(function()
            BuffUtil.setBuff(v,{lastedTime = ps.t,bfDefPct = -ps.x,bfHealps = -ps.y,cantRebirth = ps.t,beKill = {lastedTime = ps.k,bfAtkPct = ps.z}})
        end,0.5)
        HouYiEffect.new({attacker = self.V, mode = 5, target = v, lastedTime=ps.t})
    end

end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    HouYiEffect.new({attacker = self, mode = 4, target = attackTarget},callback)
end

--当此英雄的血量少于[x]%时，立即额外释放一次主动技能。（每场战斗只能触发一次）。
function C:sg_updateBattle(diff)
    if self:checkGodSkill2(true) then
        local ps = self.person.awakeData2.ps
        if self.M.nowHp/self.M.maxHp<ps.x/100 then
            self:checkGodSkill2()
            self:sg_ppexeSkill()
        end
    end
end



HouYiEffect = class()

function HouYiEffect:ctor(params,callback)
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

function HouYiEffect:initParams(params)
    self.effectManager=GameEffect.new("HouYiEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1800
    self.target = params.target or params.attacker.C.attackTarget
    self.lastedTime = params.lastedTime

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

function HouYiEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode==4 then
        self.time = 0.5
        self:initGodSkill()
        --self:initGodSkill_move()
    elseif self.mode == 5 then
        self:initGodSkill_move()
    end
end

function HouYiEffect:initAttack()
    local setting={{47,11},{81,73},{35,120},{-35,120},{-81,73},{-47,11}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local temp

    --旋转
    local moveX=self.targetPos[1]-initPos[1]
    local moveY=self.targetPos[2]-initPos[2]
    local r=math.deg(math.atan2(moveX, moveY))
    r = r-90

    --时间
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime+15/60

    local function delayFrameIndex_34()
    effectManager:addEffect("views3_delay34",bg)
    temp=views.Charge_00000_7
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_8
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
    end
    delayFrameIndex_34()

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    moveNode:setLocalZOrder(initPos[3]+10000)
    bg:addChild(moveNode)
    moveNode:setRotation(r)
    moveNode:setVisible(false)
    effectManager:addEffect("views3_delay49_Particle",moveNode)
    temp=views.Particle_25
    temp:setRotation(-90)
    temp:setPosition(56,0)
    temp:setLocalZOrder(6)
    local function delayFrameIndex_49()
    moveNode:setVisible(true)
    moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
    local function callBao()
        if self.createViews_4 then
            self:createViews_4()
        end
    end
    moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",callBao},"remove"}))

    effectManager:addEffect("views3_delay49",moveNode)
    temp=views.Glow_10_10
    temp:setPosition(46,0)
    temp:setLocalZOrder(1)
    temp:setRotation(90)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Arrow_6
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Glow_10_10_0
    temp:setPosition(56,0)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

    end
    moveNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_49}}))
end

function HouYiEffect:createViews_4()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.targetPos
    local temp

    effectManager:addEffect("views4_delay70",bg)
    temp=views.person_Glow_01_167
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",12/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    temp=views.Sparkless_00000_166
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))

end

function HouYiEffect:initSkill()
    local setting={{47,11},{81,73},{35,120},{-35,120},{-81,73},{-47,11}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]

    local temp

    --旋转
    local moveX=self.targetPos[1]-initPos[1]
    local moveY=self.targetPos[2]-initPos[2]
    local r=math.deg(math.atan2(moveX, moveY))
    r = r-90

    --时间
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime+20/60

    local function delayFrameIndex_34()
    effectManager:addEffect("views1_delay34",bg)
    temp=views.Charge_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_18
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
    temp=views.Particle_6_0_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    end
    delayFrameIndex_34()

    local function delayFrameIndex_46()
    effectManager:addEffect("views1_delay46",bg)
    local RR=45*(direction-2)
    if direction>3 then
    RR=45*(direction-5)
    elseif direction==2 or direction==5 then
    RR=90
    end
    temp=views.Shockwave_00000_12
    temp:setRotation(RR)
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+11)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",8/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",12/60},{"call",delayFrameIndex_46}}))

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    moveNode:setLocalZOrder(initPos[3]+10000)
    moveNode:setScale(1.8)
    bg:addChild(moveNode)
    moveNode:setRotation(r)
    moveNode:setVisible(false)
    effectManager:addEffect("views1_delay49_Particle",moveNode)
    temp=views.Particle_1
    temp:setRotation(-90)
    temp:setPosition(46,0)
    temp:setLocalZOrder(1)
    temp=views.Particle_1_0
    temp:setRotation(-90)
    temp:setPosition(46,0)
    temp:setLocalZOrder(4)
    local function delayFrameIndex_49()
    moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
    local function callBao()
    self:createViews_2()
    end
    moveNode:setVisible(true)
    moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",callBao},"remove"}))
    effectManager:addEffect("views1_delay49",moveNode)

    temp=views.Glow_10_110
    temp:setRotation(90)
    temp:setPosition(46,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Arrow_16
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Arrow_6_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

    temp=views.Glow_10_10_10
    temp:setPosition(56,0)
    temp:setLocalZOrder(10)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

    effectManager:addEffect("views1_delay54",moveNode)
    temp=views.Flare_yellow_13_2_0
    temp:setPosition(-5,-10)
    temp:setLocalZOrder(6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Flare_yellow_13_0_0_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Flare_yellow_13_1_0_0
    temp:setPosition(-8,10)
    temp:setLocalZOrder(8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    end
    moveNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_49}}))
end
function HouYiEffect:createViews_2()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.targetPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.3)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",77/60},"remove"}))

    local function delayFrameIndex_74()
    effectManager:addEffect("views2_delay74",upNode)
    temp=views.person_Glow_01_9
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,4.5,3.4}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",50/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",66/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_74}}))

    local function delayFrameIndex_69()
    effectManager:addEffect("views2_delay69",upNode)
    temp=views.Fire_Impact_00000_4
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,128},{"fadeTo",60/60,126},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",62/60},"remove"}))
    temp=views.Fire_Impact_00000_4_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",60/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",62/60},"remove"}))
    end
    delayFrameIndex_69()
end

function HouYiEffect:initGodSkill()
   local setting={{22,79},{60,116},{30,155},{-30,155},{-60,116},{-22,79}}
   local setting2={{-31,124},{-30,103},{4,96},{-4,96},{30,103},{31,124}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]

   local initPos2={}
   initPos2[1]=self.initPos[1]+setting2[direction][1]
   initPos2[2]=self.initPos[2]+setting2[direction][2]
   initPos2[3]=self.initPos[3]
   local temp

   local function delayFrameIndex_0()
     effectManager:addEffect("godSkill_views1_delay0",bg)
      temp=views.Sprite_8
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+6)
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,0.1,0.1},{"scaleTo",5/60,0.25,0.25},{"scaleTo",10/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},{"fadeTo",5/60,179},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   delayFrameIndex_0()

   local function delayFrameIndex_8()
     effectManager:addEffect("godSkill_views1_delay8",bg)
      temp=views.Sparkless_00000_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",9/60},{"scaleTo",8/60,0.1,0.1},{"scaleTo",1/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",8/60},{"call",delayFrameIndex_8}}))

   local function delayFrameIndex_9()
     effectManager:addEffect("godSkill_views1_delay9",bg)
      temp=views.Sprite_10
      temp:setPosition(initPos2[1],initPos2[2])
      temp:setLocalZOrder(initPos2[3]+10)
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",9/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}}))

   local function delayFrameIndex_10()
     effectManager:addEffect("godSkill_views1_delay10",bg)
      temp=views.Glow_02_7
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,1.0,1.0},{"scaleTo",10/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))

   local function delayFrameIndex_12()
     effectManager:addEffect("godSkill_views1_delay12",bg)
     local rs={0,-45,-90,90,45,0}
      temp=views.shengui_00016_9
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+7)
      if direction<=3 then
         temp:setFlippedX(true)
      end
      temp:setRotation(rs[direction])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.shengui_00016_9_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+8)
      if direction<=3 then
         temp:setFlippedX(true)
      end
      temp:setRotation(rs[direction])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",12/60},{"call",delayFrameIndex_12}}))

   local function delayFrameIndex_13()
     effectManager:addEffect("godSkill_views1_delay13",bg)
      temp=views.Glow_01_25
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+5)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,1.0,1.0},{"scaleTo",5/60,1.3,1.3}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",13/60},{"call",delayFrameIndex_13}}))

   local function delayFrameIndex_18()
     effectManager:addEffect("godSkill_views1_delay18",bg)
      temp=views.guang_00000_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      local rs={135,90,45,-45,-90,-135}
      temp:setRotation(rs[direction])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",8/60,255},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",18/60},{"call",delayFrameIndex_18}}))

   local function delayFrameIndex_19()
     effectManager:addEffect("godSkill_views1_delay19",bg)
     local rs={45,0,-45,-135,-180,135}
      temp=views.Strike_00001_6
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setRotation(rs[direction])
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",8/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_19}}))

end
--箭
function HouYiEffect:initGodSkill_move()
   local setting={{22,79},{60,116},{30,155},{-30,155},{-60,116},{-22,79}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]

   local targetPos=self.targetPos
   local moveTime=0.5
   local moveX=targetPos[1]-initPos[1]
   local moveY=targetPos[2]-initPos[2]
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local function delayFrameIndex_24()
      local moveNode=ui.node()
      moveNode:setPosition(initPos[1],initPos[2])
      moveNode:setLocalZOrder(initPos[3]+10000)
      bg:addChild(moveNode)
      moveNode:setScale(2)
      moveNode:setRotation(r)
      local function showTargetBao()
         self:initGodSkill_target()
      end
      moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
      moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("godSkill_views2_delay24",moveNode)
      temp=views.Sprite_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

      temp=views.Sprite_1_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

   end
   delayFrameIndex_24()
end
--受击
function HouYiEffect:initGodSkill_target()
   local effectManager=self.effectManager
   local bg = self.target.V.view
   if self.target.person.equip then
        return
   end
   local views=self.views
   local initPos={}
   initPos[1]=0
   initPos[2]=self.target.V.animaConfig.Ymove+40
   initPos[3]=self.targetPos[3]
   local hpview = self.target.V.animaConfig.hpview
   if hpview and type(hpview[2]) == "table" then
        hpview = hpview[self.target.heroState == 0 and 1 or 2]
   end
   local hpv = hpview or {0, 160}
   local oy = hpv[2]+10
   local temp
     effectManager:addEffect("godSkill_views3_delay42",bg)
      temp=views.Boom_17
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10001)
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.6,1.6},{"scaleTo",6/60,1.7,1.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Sparkless_00000_7
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10002)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Fire_Impact_00001_12
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10003)
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",17/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))


      temp=views.A01_2
      temp:setPosition(initPos[1],initPos[2]+oy)
      temp:setLocalZOrder(initPos[3]+10004)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",self.lastedTime-15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",self.lastedTime+28/60},"remove"}))
      temp=views.Glow_02_6
      temp:setPosition(initPos[1],initPos[2]+oy)
      temp:setLocalZOrder(initPos[3]+10005)
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,1.0,1.0},{"scaleTo",5/60,1.2,1.2},{"delay",self.lastedTime-18/60},{"scaleTo",5/60,0.2,0.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,51},{"delay",self.lastedTime-19/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",self.lastedTime+28/60},"remove"}))
end



function HouYiEffect:update(diff)
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




























