

local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local attackMode = 1
    if self.skillLastTimeAll then
        attackMode = 2
    end
    SaiyanEffect.new({attacker = self, mode = 0, target = attackTarget, attackMode = attackMode},callback)
end

function V:skillViewEffect(attackTarget,callback,skillLastTimeAll)
    skillLastTimeAll = self.C.actSkillParams.y
    SaiyanEffect.new({attacker = self, mode = 1, target = attackTarget, lastedTime = skillLastTimeAll},function()
        callback()
        self.skillLastTimeAll = skillLastTimeAll
        self.skillLastTime = 0
    end)
end

function V:skillAfter()
    self.skillLastTimeAll = nil
    self.skillLastTime = nil
end


local C = class(AvtControler)

--4004    赛亚人   主动技能20  于y秒内，提升自身及己方所有霹雳火的攻击力c%，攻击速度d%，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,d,y = params.c,params.d,params.y
    BuffUtil.setBuff(self,{bfAtkPct = c,bfAtkSpeedPct = d,lastedTime = y})
    for i,v in ipairs(self.battleMap2.mer) do
        if v.sid >= 300 and v.sid <= 500 then
            BuffUtil.setBuff(v,{bfAtkPct = c,bfAtkSpeedPct = d,lastedTime = y})
            SaiyanEffect.new({attacker = v.avater, mode = 2, target = v,lastedTime = y})
        end
    end
end

--天神技 自身与法师佣兵恢复全部血量，并且免疫伤害，增加[x]%的伤害，[y]%的攻击速度，[z]%的移动速度，持续[t]秒。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    for k,v in pairs(self.battleMap2.mer) do
        if v.sid >= 300 and v.sid <= 500 then
            BuffUtil.setBuff(v,{lastedTime = ps.t,immune = ps.t,bfHurt = ps.x,bfAtkSpeedPct = ps.y,bfMovePct = ps.z})
            v:damage(-10000000)
            SaiyanEffect.new({attacker = v.V, mode = 4, target = v})
        end
    end
    SaiyanEffect.new({attacker = self.V, mode = 3, target = self})
    BuffUtil.setBuff(self,{lastedTime = ps.t,immune = ps.t,bfHurt = ps.x,bfAtkSpeedPct = ps.y,bfMovePct = ps.z})
    self:damage(-10000000)
end

--当英雄死亡时，他会附着到哨塔上，增强哨塔[x]%的伤害，降低[y]%受到的伤害，增加[z]%的攻速。当这座塔被破坏时，他会转移到另一个上，直到所有哨塔被破坏。
local function _doAfterDie(self)
    if self:checkGodSkill2() and not self.params.godExecuted then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        self.params.godExecuted = true
        for k,v in pairs(group) do
            if v.bid == 22 then
                local px,py = self.V.view:getPosition()
                local pz = General.sceneHeight-py
                local tx,ty,tz = v:getDamagePoint()

                ShaiYaRen.new(self.scene.objs,px,py,pz,tx,ty,tz)

                BuffUtil.setBuff(v,{bfAtkPct=ps.x, bfDefPct=ps.y, bfAtkSpeedPct=ps.z,},"SaiyanGodSkill2")
                break
            end
        end
    end
end

-- @brief 通用添加逻辑组件的方法
function C:onInitComponents()
    if not self.params.isZhaoHuan then
        LGBT.addComponentFunc(self, "afterDie", _doAfterDie)
    end
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    callback()
end

SaiyanEffect = class()

function SaiyanEffect:ctor(params,callback)
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

function SaiyanEffect:initParams(params)
    self.effectManager=GameEffect.new("SaiyanEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.attackMode = params.attackMode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
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

function SaiyanEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initMer()
    elseif self.mode == 3 then
        self:initGodSkill(true)
    elseif self.mode == 4 then
        self:initGodSkill()
    end
end

function SaiyanEffect:initAttack()
    local setting1={{-50,63},{-24,26},{10,26},{-10,26},{24,26},{50,63}}
    local setting2={{45,8,1},{80,70,1},{33,140,-1},{-33,140,-1},{-80,70,1},{-45,8,1}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local attackMode=self.attackMode
    local direction=self.direction
    local initPos=self.initPos
    local temp
    local ox1,oy1=setting1[direction][1],setting1[direction][2]
    local ox2,oy2=setting2[direction][1],setting2[direction][2]
    local oz=100*setting2[direction][3]
    --时间
    local moveTime=math.sqrt((self.targetPos[1]-(initPos[1]+ox2))^2+(self.targetPos[2]-(initPos[2]+oy2))^2)/self.speed
    self.time = moveTime+19/60
    --旋转
    local moveX=self.targetPos[1]-(initPos[1]+ox2)
    local moveY=self.targetPos[2]-(initPos[2]+oy2)
    local r=math.deg(math.atan2(moveX, moveY))
    r = r - 90

    local function delayFrameIndex_19()
    effectManager:addEffect("views4_delay19",bg)
    local OR=0
    if direction<=3 then
    OR= 45*(2-direction)
    else
    OR= 45*(5-direction)
    end

    temp=views.Shockwave_00000_7_1
    temp:setRotation(OR)
    temp:setPosition(initPos[1]+ox2,initPos[2]+oy2)
    temp:setLocalZOrder(initPos[3]+5+oz)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Shockwave_00000_7_0_0
    temp:setRotation(OR)
    temp:setPosition(initPos[1]+ox2,initPos[2]+oy2)
    temp:setLocalZOrder(initPos[3]+6+oz)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,85},{"fadeTo",12/60,255},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_13_0_0
    temp:setPosition(initPos[1]+ox2,initPos[2]+oy2)
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Glow_01_13_1
    temp:setPosition(initPos[1]+ox2,initPos[2]+oy2)
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1]+ox2,initPos[2]+oy2)
    moveNode:setLocalZOrder(initPos[3]+10000)
    bg:addChild(moveNode)
    moveNode:setRotation(r)
    moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
    local function callViews5()
    self:createViews_5()
    end
    moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",callViews5},"remove"}))

    effectManager:addEffect("views4_delay19_moveBack",moveNode)
    temp=views.Glow_01_23_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    if attackMode>1 then
        moveNode:setScale(1.3)
    temp:setScaleX(1.8)
    temp:setScaleY(1.08)
    end
    if attackMode==1 then
    effectManager:addEffect("views4_delay19_move1",moveNode)
    temp=views.Sprite_4_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Sprite_4
    temp:setPosition(0,0)
    temp:setLocalZOrder(8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    else
    effectManager:addEffect("views4_delay19_move2",moveNode)
    temp=views.Sprite_1_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Sprite_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    end
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_19}}))

    local function delayFrameIndex_4()
    --蓄力特效
    effectManager:addEffect("views4_delay4",bg)
    temp=views.Particle_2_1
    temp:setPosition(initPos[1]+ox1,initPos[2]+oy1)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Particle_2_0_0
    temp:setPosition(initPos[1]+ox1,initPos[2]+oy1)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_6_0_0
    temp:setPosition(initPos[1]+ox1,initPos[2]+oy1)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_6_1
    temp:setPosition(initPos[1]+ox1,initPos[2]+oy1)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_4}}))
end
function SaiyanEffect:createViews_5()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local targetPos=self.targetPos
   local temp

      local targetNode=ui.node()
       targetNode:setPosition(targetPos[1],targetPos[2])
      targetNode:setLocalZOrder(targetPos[3])
      bg:addChild(targetNode)
      targetNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      if self.attackMode>1 then--火焰状态攻击时
         targetNode:setScale(1.8)
      end
      effectManager:addEffect("views5_delay39",targetNode)
      temp=views.Glow_01_18_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.person_Sprite_17_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Glow_01_18_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,153},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
end

function SaiyanEffect:initSkill()
    local total=self.lastedTime
    self.time = 0

    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,0}
    local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   upNode:setScale(1.3)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total+20/60},"remove"}))

    local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   downNode:setScale(1.3)
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",total+20/60},"remove"}))

    local function delayFrameIndex_35()
    effectManager:addEffect("views1_delay35",downNode)
    temp=views.Glow_01_12_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(-3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,191}}))
    temp:runAction(ui.action.sequence({{"delay",total-5/60},"remove"}))
    temp=views.Glow_01_12_0_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(-1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,191}}))
    temp:runAction(ui.action.sequence({{"delay",total-5/60},"remove"}))

    effectManager:addEffect("views1_delay35_up",upNode)
    temp=views.Glow_01_12
    temp:setPosition(0,50)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",total-5/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_35}}))

    local function delayFrameIndex_39()
    total=total-4/60
    effectManager:addEffect("views1_delay39",downNode)
    temp=views.Smoke_00000_14
    temp:setPosition(0,125)
    temp:setLocalZOrder(-4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Ground_Wave_00000_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",total-1/60},"remove"}))

    effectManager:addEffect("views1_delay39_up",upNode)
    temp=views.Flame_00000_6
    temp:setPosition(0,65)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",total-1/60},"remove"}))
    temp=views.Lightning_00000_16
    temp:setPosition(0,015)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",20/60,0,75},{"moveBy",40/60,0,-75}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",4/60,0},{"delay",40/60}})))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Particle_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_39}}))

end

function SaiyanEffect:initMer()
    self.delayNode:runAction(ui.action.sequence({{"delay",27/60+1}}))
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,50,0}
    local temp

    local function delayFrameIndex_39()

    local total=self.lastedTime

    effectManager:addEffect("views6_delay39",bg)
    temp=views.Glow_01_37_0
    temp:setPosition(initPos[1],initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",5/60,0.15,0.15},{"scaleTo",5/60,0.1,0.1}})))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Glow_01_37
    temp:setPosition(initPos[1],initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.3,0.3}})))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,178},{"delay",5/60}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Attack_00000_36
    temp:setPosition(initPos[1],initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Glow_01_37_1
    temp:setPosition(initPos[1],initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.3,0.3}})))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,102}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    delayFrameIndex_39()
end

--自身或目标
function SaiyanEffect:initGodSkill(isSelf)
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,0}
    local temp

    self.delayNode:runAction(ui.action.sequence({{"delay",42/60}}))

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+100000)
   upNode:runAction(ui.action.sequence({{"delay",30/60},"remove"}))

    local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",30/60},"remove"}))

   if not isSelf then
      upNode:setScale(0.3)
      downNode:setScale(0.3)
   end

    effectManager:addEffect("god_view7_delay15_up",upNode)
      temp=views.GuangQuanT_00_7
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,204}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Sparkless_00001_5
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",9/60,1.3,1.3}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",8/60,255},{"delay",9/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    effectManager:addEffect("god_view7_delay15_down",downNode)
      temp=views.JingHuangZheng_8
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.GF_472_10
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,4.5,3.9},{"scaleTo",22/60,5.5,4.7667}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,178},{"fadeTo",22/60,102}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
      temp=views.Shockwave_00000_3_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",9/60,1.5,1.35},{"scaleTo",15/60,1.7,1.53}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",9/60,255},{"delay",9/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
      temp=views.Shockwave_00000_3
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",9/60,1.5,1.35},{"scaleTo",15/60,1.7,1.53}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",9/60,127},{"delay",9/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
end

function SaiyanEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.time = nil
        self.callback(self.target)
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}




















