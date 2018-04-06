
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastTenEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=3},callback)
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

    self.skillStopNum = 1
    self.exeAtkFrame = 3
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastTenEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastTenEffect.new({attacker = self, mode = 3, target = self,scale=scal,lastedTime=self.C.person.awakeData.ps.t},callback)
end

local C = class(GodBeast)
--在2个目标周围半径8格内召唤n颗陨石（可叠加），每颗陨石造成[a]+[c]%*攻击力的半径3格范围伤害。每个陨石都会造成眩晕[t]秒（眩晕不叠加）。技能冷却时间[z]秒。 
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
    local tT = self:getMinDisTarget(2)
    if not tT[2] then
      tT[2] = tT[1]
    end
    self.isSkillAttack = true
    self.skillGB10PointT1 = {}
    self.skillGB10PointT2 = {}
    self.skillGB10PointT = {}
    for i,T in ipairs(tT) do
      local gx,gy 
      if T.avater then
          gx,gy = T.avater.gx,T.avater.gy
      else
          gx,gy = T.battleViewInfo[1],T.battleViewInfo[2]
      end
      self.skillGB10PointT[i] = {gx,gy}
    end


    local n = 5
    local function getPoint(gx,gy)
      local l,r = gx-8,gx+8
      if l<0 then l = 0 end
      if r>41 then r = 41 end
      local tgx = self.rd:random2() * (r-l) + l
      local y = math.sqrt(64 - (tgx-gx)^2)
      local tgy = gy-y + self.rd:random2()*y*2
      return {tgx,tgy}
    end

    for i=1,n do
      local T = tT[i%2+1]
      if T then
          local gx,gy 
          if T.avater then
              gx,gy = T.avater.gx,T.avater.gy
          else
              gx,gy = T.battleViewInfo[1],T.battleViewInfo[2]
          end
          table.insert(self.skillGB10PointT1,getPoint(gx,gy))
      end
    end
    for i=1,n do
      local idx = i%2+1
      if idx == 1 then
        idx = 2
      else
        idx = 1
      end
      local T = tT[idx]
      if T then
          local gx,gy 
          if T.avater then
              gx,gy = T.avater.gx,T.avater.gy
          else
              gx,gy = T.battleViewInfo[1],T.battleViewInfo[2]
          end
          table.insert(self.skillGB10PointT2,getPoint(gx,gy))
      end
    end
end

function C:exeSkillForGodBeast(target)
    local ps = self.actSkillParams
    local a,c,t,k= ps.a,ps.c,ps.t,ps.k
    local dt = 0
    for i,v in ipairs(self.skillGB10PointT1) do
        self.scene.replay:addDelay(function()
            local result = self:getCircleTarget(v,self.battleMap.battlerAll,3)
            for i,v in ipairs(result) do
                SkillPlugin.exe2(self,v,a,c)
                BuffUtil.setBuff(v,{lastedTime = k,bfDizziness = k})
            end
        end,dt)
        dt = dt+0.2
    end
    for i,v in ipairs(self.skillGB10PointT2) do
        self.scene.replay:addDelay(function()
            local result = self:getCircleTarget(v,self.battleMap.battlerAll,3)
            for i,v in ipairs(result) do
                SkillPlugin.exe2(self,v,a,c)
                BuffUtil.setBuff(v,{lastedTime = k,bfDizziness = k})
            end
        end,dt)
        dt = dt+0.2
    end
end
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

local function sg_updateBattle(ptable, diff)
    if not ptable.allStateTime then
      return
    end
    local t = ptable.person.person.awakeData.ps.t
    ptable.allStateTime = ptable.allStateTime+diff
    if ptable.allStateTime>t then
      ptable.allStateTime = nil
      ptable.person.groupData.inSkillGB10Godstate = nil
    end
end

function C:exeGodSkill()
    local ptable = {allStateTime = 0, person = self, update = sg_updateBattle}
    self.scene.replay:addUpdateObj(ptable)
end

BeastTenEffect=class()

function BeastTenEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
    end
end

function BeastTenEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastTenEffect.json")
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
    self.lastedTime = params.lastedTime

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight-p[2]}
    self.offInitPos={0,self.attacker.animaConfig.Ymove,0}
    --目标点坐标
    local view,height
    if self.target.avater then
        view = self.target.avater.view
        height = 40 + self.target.avater.animaConfig.Ymove
        self.targetZ = 41 + self.target.avater.animaConfig.Ymove
        self.offTargetPos={0,height,0}
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
        self.offTargetPos={view:getContentSize().width/2,view:getContentSize().height/2,0}
    end
    self.targetView=view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function BeastTenEffect:initEffect()
  if self.mode==0 then
    self:initAttack()
    self:initAttack_move()
  elseif self.mode == 3 then
    self.time = 0
    self:createViews_8()
  elseif self.mode==1 then
  	self:initSkill()
    
    local dt = 0
    self.time = 0.7

    local deT=0.2*(#self.attacker.C.skillGB10PointT1-1)
    for i,v in ipairs(self.attacker.C.skillGB10PointT) do
      self:initSkill_quan(v,deT)
    end

    for i,point in ipairs(self.attacker.C.skillGB10PointT1) do
        self.scene.replay:addDelay(function()
            self:initSkill_move(point)
        end,dt)
        dt = dt+0.2
    end

    for i,point in ipairs(self.attacker.C.skillGB10PointT2) do
        self.scene.replay:addDelay(function()
            self:initSkill_move(point)
        end,dt)
        dt = dt+0.2
    end
  end
end

--普攻攻击点
function BeastTenEffect:initAttack()
   local setting={{43,0},{82,54},{79,164},{-79,164},{-82,54},{-43,0}}
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
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",34/60},"remove"}))

   local function delayFrameIndex_9()
     effectManager:addEffect("views1_delay9",upNode)
      temp=views.Sparkless_00000_12
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_9}}))

   local function delayFrameIndex_14()
     effectManager:addEffect("views1_delay14",upNode)
      temp=views.Sparkless_00001_10
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_14}}))

end
--普攻子弹
function BeastTenEffect:initAttack_move()
   local setting={{43,0},{82,54},{79,164},{-79,164},{-82,54},{-43,0}}
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
   local targetPos=self.targetPos
   local moveX=targetPos[1]-initPos[1]
   local moveY=targetPos[2]-initPos[2]
   local moveTime=math.sqrt((self.targetPos[1]-initPos[1])^2+(self.targetPos[2]-initPos[2])^2)/self.speed
   self.time=moveTime
   local length=math.sqrt(moveX*moveX+moveY*moveY)
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

  local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+1000)
   moveNode:setScaleY(baseScal*2)
   moveNode:setRotation(r)

   local function delayFrameIndex_14()
      local function showTargetBao()
         self:initAttack_bao()
      end
      moveNode:runAction(ui.action.sequence({{"easeSineIn",ui.action.moveBy(moveTime,moveX,moveY)},{"call",showTargetBao},{"delay",8/60},"remove"}))
     effectManager:addEffect("views2_delay14",moveNode)
      temp=views.Jiguang01_4
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"scaleTo",moveTime,length/315,0.6419},{"scaleTo",2/60,length/315,0.9189},{"scaleTo",8/60,0,0.6419}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,124},{"delay",moveTime},{"fadeTo",8/60,0}}))
      temp=views.sadsfw_5
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"scaleTo",moveTime,length/315,0.3649},{"scaleTo",2/60,length/315,0.4495},{"scaleTo",8/60,0,0.3649}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime},{"fadeTo",8/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_14}}))

end
--普攻受击
function BeastTenEffect:initAttack_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=1
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal*1.5)
   upNode:runAction(ui.action.sequence({{"delay",33/60},"remove"}))

   local function delayFrameIndex_16()
     effectManager:addEffect("views3_delay16",upNode)
      temp=views.shouji_00000_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_16}}))

end
--技能攻击方
function BeastTenEffect:initSkill()
   local setting1={{{-59,-16},{56,18},{105,79},{-105,79},{-56,18},{59,-16}},
                   {{-29,41},{89,103},{106,178},{-106,178},{-89,103},{29,41}}}
   local setting2={{{116,71},{51,149},{-68,135},{68,135},{-51,149},{-116,71}},
                   {{127,109},{95,201},{-25,237},{25,237},{-95,201},{-127,109}}}


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
   local temp

   local upNode1=ui.node()
   upNode1:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode1,initPos[3]+10)
   upNode1:setScale(baseScal)
   upNode1:runAction(ui.action.sequence({{"delay",60/60},"remove"}))


   local upNode2=ui.node()
   upNode2:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode2,initPos[3]+10)
   upNode2:setScale(baseScal)
   upNode2:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_14()
      local frameI=0
      local function setPos()
         frameI=frameI+1
         local ox=setting1[frameI][direction][1]*baseScal
         local oy=setting1[frameI][direction][2]*baseScal
         upNode1:setPosition(initPos[1]+ox,initPos[2]+oy)
         ox=setting2[frameI][direction][1]*baseScal
         oy=setting2[frameI][direction][2]*baseScal
         upNode2:setPosition(initPos[1]+ox,initPos[2]+oy)
      end
      upNode1:runAction(ui.action.arepeat(ui.action.sequence({{"call",setPos},{"delay",5/60}}),2))
     effectManager:addEffect("views4_delay14_right",upNode1)
      temp=views.Cast_00000
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Sparkless_00000_12_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",4/60,0.3329,0.3463},{"scaleTo",1/60,0.6278,0.6336},{"scaleTo",9/60,0.6278,0.6336},{"scaleTo",1/60,0.5897,0.5701},{"scaleTo",5/60,0.4274,0.4561},{"scaleTo",5/60,0.3968,0.4063},{"scaleTo",5/60,0.1631,0.165}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,81},{"fadeTo",5/60,115},{"delay",9/60},{"fadeTo",1/60,179},{"fadeTo",16/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))

     effectManager:addEffect("views4_delay14_left",upNode2)
      temp=views.Cast_00001
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Sparkless_00000_12_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",4/60,0.3329,0.3463},{"scaleTo",1/60,0.6278,0.6336},{"scaleTo",9/60,0.6278,0.6336},{"scaleTo",1/60,0.5897,0.5701},{"scaleTo",5/60,0.4274,0.4561},{"scaleTo",5/60,0.3968,0.4063},{"scaleTo",5/60,0.1631,0.165}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,81},{"fadeTo",5/60,115},{"fadeTo",9/60,117},{"fadeTo",1/60,179},{"fadeTo",16/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
   end
   upNode1:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_14}}))

end
function BeastTenEffect:initSkill_quan(point,deT)
  local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=1 
   local initPos={}
   local x,y = self.scene.map.convertToPosition(point[1],point[2])
   initPos[1]=x
   initPos[2]=y
   initPos[3]=self.scene.map.maxZ-y
   local oy=390*baseScal
   local moveTime=oy/self.speed
   local temp

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(baseScal*2.4)
   local function delayFrameIndex_19()
      effectManager:addEffect("views5_delay19",downNode)
      temp=views.Circle_R_00000
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",30/60,255},{"delay",moveTime+deT},{"fadeTo",30/60,0}}))
   end
   downNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_19},{"delay",moveTime+deT+1},"remove"}))
end

--技能攻击子弹
function BeastTenEffect:initSkill_move(point)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal  
   local initPos={}
   local x,y = self.scene.map.convertToPosition(point[1],point[2])
   initPos[1]=x
   initPos[2]=y
   initPos[3]=self.scene.map.maxZ-y
   local oy=390*baseScal
   local moveTime=oy/self.speed
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2]+oy)
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setScale(baseScal)
   moveNode:setVisible(false)
   effectManager:addEffect("views5_delay33",moveNode)

   -- local downNode=ui.node()
   -- downNode:setPosition(initPos[1],initPos[2])
   -- bg:addChild(downNode,initPos[3]-10)
   -- downNode:setScale(baseScal)
   -- local function delayFrameIndex_19()
   --    effectManager:addEffect("views5_delay19",downNode)
   --    temp=views.Circle_R_00000
   --    temp:setPosition(0,0)
   --    temp:setLocalZOrder(1)
   --    temp:runAction(ui.action.sequence({{"fadeTo",30/60,255},{"delay",moveTime},{"fadeTo",30/60,0}}))
   -- end
   -- delayNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_19}}))
   local function delayFrameIndex_33()
      local function showTargetBao()
         self:initSkill_bao(point)
         --self:initSkill_yunxuan()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,0,-oy},{"call",showTargetBao},"remove"}))

      temp=views.tuowei02
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp=views.tuoweih01
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.AE_00_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.tuoweiz
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
   end
   moveNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_33}}))

end
--技能受击
function BeastTenEffect:initSkill_bao(point)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local x,y = self.scene.map.convertToPosition(point[1],point[2])
   local initPos={x,y,self.scene.map.maxZ-y}
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",56/60},"remove"}))

     effectManager:addEffect("views6_delay44",upNode)
      temp=views.base_T_dilie005_1774_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",35/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
      temp=views.Stone_00000
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",45/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
      temp=views.Stone_00000_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",45/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
      temp=views.Dankeng_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",19/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Shockwave
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.7,0.6},{"scaleTo",10/60,1.0,0.85}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",12/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Glow_02_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,1.7,1.36},{"scaleTo",35/60,2.2,1.76}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",35/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
      temp=views.Glow_02_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,1.7,1.36},{"scaleTo",35/60,2.2,1.76}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,127},{"fadeTo",35/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
      temp=views.SDA_00_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",22/60,2.4,1.92}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",13/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.SDA_00_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",22/60,2.4,1.92}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",13/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.BaoZa_00_5
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",22/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
      temp=views.Explosion_00000
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
      temp=views.Explosion_00000_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
end
--主动技能受击晕眩
function BeastTenEffect:initSkill_yunxuan()
   local effectManager=self.effectManager
   local bg=self.targetView
   local views=self.views
   local direction=self.direction
   local initPos=self.offTargetPos
   local baseScal=self.baseScal
   local oy=80*baseScal
   local total=self.total
   local temp
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

     effectManager:addEffect("views7_delay0",upNode)
      temp=views.Vertigo_00000_8
      temp:setPosition(0,oy)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",total-1/60},{"fadeTo",1/60,0}}))
end
--技能时间限制
function BeastTenEffect:createViews_8()
   local effectManager=self.effectManager
   local bg=self.attacker.blood
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=self.lastedTime
   local oy=60*baseScal
   local initPos={}
   initPos[1]=bg:getContentSize().width/2
   initPos[2]=70
   initPos[3]=10
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views8_delay0",upNode)
      temp=views.Circle_R_00000_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,0.18,0.18}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.Circle_R_00000_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",20/60,0.18,0.18}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Glow_02_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,153},{"fadeTo",10/60,76}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Sprite_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_02_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_10()
     effectManager:addEffect("views8_delay10",upNode)
      temp=views.Circle_R_00000_3_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,0.095,0.095}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))

end
--被动技能自爆
function BeastTenEffect:createViews_9()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local oy=60*baseScal
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]+oy
   initPos[3]=self.initPos[3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",61/60},"remove"}))
   local function delayFrameIndex_9()
     effectManager:addEffect("views9_delay9",upNode)
      temp=views.Fire_Impact_00001_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",45/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}}))
end

function BeastTenEffect:update(diff)
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
