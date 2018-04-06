
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    local y
    if isSkill then
        mode = 1
        y = self.C.actSkillParams.y
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastOneEffect.new({attacker = self, mode = mode, target = attackTarget,total=y,scale=scal},callback)
end


function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    if self.animaConfig.skill_params then
        self.loop = false
        self.isExeRealAtk = false
        self.frameFormat = self.animaConfig.skill_fmt 
        self.animaTime = 0
        self.frameIndex = 0
        self.oneFrameTime = self.animaConfig.skill_params[1]/self.animaConfig.skill_params[2]
        self.frameMaxIndex = self.animaConfig.skill_params[2]
        self.actionTime = 0
        self.allActionTime = self.avtInfo.aspeed
        if self.animaConfig.skill_params[1]>self.avtInfo.aspeed then
            self.allActionTime = self.animaConfig.skill_params[1]
        end
        self.exeAtkFrame = self.animaConfig.skill_params[3]
    else
        self:attack(viewInfo1,viewInfo2,b)
    end
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    self.state = PersonState.SKILL

    self.skillStopNum = 6
    self.exeAtkFrame = 3
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastOneEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end



local C = class(GodBeast)

function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

--[[死亡后,英雄身上的Update被移除掉了,不再走原来的sg_updateBattle,
    但是技能需要在死后持续释放,故移到这里特殊处理]]--
local function sg_updateBattle(ptable, diff)
    if ptable.skillGBTime then
        ptable.skillGBTime = ptable.skillGBTime+diff
        local ps = ptable.role.actSkillParams
        local y,a,c,d = ps.y,ps.a,ps.c,ps.d
        if ptable.skillGBTime<y then
            ptable.utime = ptable.utime+diff
            if ptable.utime>=1 then
                ptable.utime = ptable.utime-1
                local result = ptable.role:getCircleTarget(ptable.role,
                    ptable.role.battleMap.battlerAll, 8)
                for _,v in ipairs(result) do
                    SkillPlugin.exe2(ptable.role, v, a, c)
                    BuffUtil.setBuff(v, {lastedTime = 1, bfMovePct = -d})
                end
            end
        else
            ptable.skillGBTime = nil
            ptable.utime = nil
            ptable.role.scene.replay:removeUpdateObj(ptable)
        end
    end
end

--在[y]秒内，使自身半径8格范围内的敌人每秒受到[a]+[c]%攻击力的伤害，并使其移速下降[d]%。技能冷却时间[z]秒。
function C:exeSkillForGodBeast(target)
    local ptable = {skillGBTime=0, utime=0.9, role=self, update=sg_updateBattle}
    self.scene.replay:addUpdateObj(ptable)
end


BeastOneEffect=class()
function BeastOneEffect:ctor(params,callback)
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    self.scene = GMethod.loadScript("game.View.Scene")
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
    end
end

function BeastOneEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastOneEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.attacker.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.total=params.total
    self.baseScal=params.scale or 1

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight-p[2]}
    self.offInitPos={0,y,0}
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

function BeastOneEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then   
        self:initCurrency()
    end
end
function BeastOneEffect:initCurrency()
    local setting={{20,55},{51,80},{21,114},{-21,114},{-51,80},{-20,55}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local ox=setting[direction][1]*baseScal
   local oy= setting[direction][2]*baseScal
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-1)
   downNode:setScale(baseScal)
   downNode:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
   local function delayFrameIndex_0()
     effectManager:addEffect("views2_delay0",upNode)
      temp=views.Common_00000_3
      temp:setPosition(ox,oy)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",33/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_3_0
      temp:setPosition(ox,oy)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",33/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views2_delay20",upNode)
      temp=views.Glow_16_5
      temp:setPosition(ox,oy)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
function BeastOneEffect:initAttack()
    self.time=0.2
  local setting={{51,-27,45},{124,47,0,},{63,137,-45},{-63,137,-135},{-124,47,180},{-51,-27,135}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   initPos[3]=self.initPos[3]
   local r=setting[direction][3]
   local temp

   local attNode=ui.node()
   attNode:setPosition(initPos[1],initPos[2])
   bg:addChild(attNode,initPos[3]+10000)
   attNode:setScale(baseScal)
   attNode:setRotation(r)
   attNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   local function delayFrameIndex_19()
     effectManager:addEffect("views1_delay19",attNode)
      temp=views.Sprite_18_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(0)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
      temp=views.Glow_01_20_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Glow_01_20_0_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   delayFrameIndex_19()

   local function delayFrameIndex_24()
     effectManager:addEffect("views1_delay24",attNode)
      temp=views.Strike_00000_19_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   attNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_24}}))

end

function BeastOneEffect:initSkill()
     self.time=0.2
  local setting={{20,55},{51,80},{21,114},{-21,114},{-51,80},{-20,55}}
   local effectManager=self.effectManager
   local total=self.total
   --[[创建一个节点放置技能特效,让这个节点跟着avater.view,
      主要是因为神兽死了之后,技能特效需要持续释放]]--
   local bg = self.viewsNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal

   local initPos=self.offInitPos
   local ox=setting[direction][1]*baseScal
   local oy= setting[direction][2]*baseScal
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(baseScal)
   downNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
   self.attacker.view:runAction(ActionCarry:create(total, upNode, cc.p(0, 0)))
   self.attacker.view:runAction(ActionCarry:create(total, downNode, cc.p(0, 0)))

   local function delayFrameIndex_44()
     effectManager:addEffect("views2_delay44",downNode)
      temp=views.Glow_01_10
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",16/60,255},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-44/60},"remove"}))
      temp=views.Storm_00000_9
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",16/60,127},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-44/60},"remove"}))
    effectManager:addEffect("views2_delay44_up",upNode)
      temp=views.Shockwave_00000_12
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_16_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,16.0,16.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Sparkless_00000_15
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"fadeTo",16/60,255},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-44/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_44}}))

   local function delayFrameIndex_45()
     effectManager:addEffect("views2_delay45",downNode)
      temp=views.Ground_Wave_00000_32
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-55/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-45/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_45}}))

   local function delayFrameIndex_50()
     effectManager:addEffect("views2_delay50",downNode)
      temp=views.Glow_16_16
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-50/60},"remove"}))
    effectManager:addEffect("views2_delay50_up",upNode)
      temp=views.Glow_01_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-65/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-50/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_50}}))

end

function BeastOneEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback()
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}
