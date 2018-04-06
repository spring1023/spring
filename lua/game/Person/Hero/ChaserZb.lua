
local M = class(AvtInfo)

local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    ChaserZbEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--9006    追击者   发动技能时，全体己方单位攻击力增加[c]%，伤害减免[d]%，持续[y]秒。冷却[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,d,y = params.c,params.d,params.y
    for i,v in ipairs(self.battleMap2.battler) do
        if v.sid then
          BuffUtil.setBuff(v,{lastedTime = y,bfAtkPct = c,bfDefPct=d})
          -- ChaserZbEffect.new({attacker = self.avater, mode = 2, target = v,total = y})
        end
    end
end

ChaserZbEffect=class()

function ChaserZbEffect:ctor(params,callback)
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    self.scene = GMethod.loadScript("game.View.Scene")
    if self.time then
        if self.scene.replay then
            self.scene.replay:addUpdateObj(self)
        else
            RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
        end
    end
end
function ChaserZbEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end
function ChaserZbEffect:initParams(params)
    self.effectManager=GameEffect.new("ChaserZbEffect.json")
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

function ChaserZbEffect:initEffect()
  if self.mode==0 then
      self:attack()
      self:attack_move()
  elseif self.mode==1 then
      self:createViews_1()
  elseif self.mode==2 then
      self:createViews_2()
  end
end

--攻击
function ChaserZbEffect:createViews_1()
   local setting={{70,106},{100,189},{14,254},{-14,254},{-100,189},{-70,106}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp
   self.time=20/60
   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2]-50)
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(1.5)
   downNode:runAction(ui.action.sequence({{"delay",100/60},"remove"}))

   local upNode1=ui.node()
   upNode1:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode1,initPos[3]+10)
   upNode1:runAction(ui.action.sequence({{"delay",130/60},"remove"}))

   local upNode2=ui.node()
   upNode2:setPosition(initPos[1]+setting[direction][1],initPos[2]+setting[direction][2])
   bg:addChild(upNode2,initPos[3]+10)
   upNode2:runAction(ui.action.sequence({{"delay",100/60},"remove"}))

   local function delayFrameIndex_27()
     effectManager:addEffect("views1_delay27",upNode2)
      temp=views.koulou_00000_10_a
      temp:runAction(ui.action.sequence({{"delay",3/60},{"moveBy",20/60,0,50}}))
      temp:runAction(ui.action.sequence({{"delay",3/60},{"scaleTo",20/60,0.2,0.2},{"scaleTo",40/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"delay",15/60},{"fadeTo",40/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",63/60},"remove"}))

      temp=views.Sprite_5_0_a
      temp:runAction(ui.action.sequence({{"delay",2/60},{"moveBy",20/60,0,50}}))
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",20/60,2.0,2.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",27/60,255},{"delay",35/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",63/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_27}}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views1_delay29",downNode)
      temp=views.Glow_01_4
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.3,1.3},{"scaleTo",27/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",27/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Change_Buff_00000_7
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,6,5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",44/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
      temp=views.Glow_01_8
      temp:runAction(ui.action.sequence({{"scaleTo",15/60,1.0,0.8},{"scaleTo",30/60,1.5,1.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_29}}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views1_delay30",upNode1)
      temp=views.Glow_01_3_b
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.2,1.2},{"scaleTo",37/60,2.5,2.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,204},{"fadeTo",37/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",42/60},"remove"}))
      temp=views.Line_00000_1_b
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",70/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",100/60},"remove"}))
      temp=views.Line_00000_1_0_b
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",70/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",100/60},"remove"}))
   end
   upNode1:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_30}}))

   local function delayFrameIndex_32()
     effectManager:addEffect("views1_delay32",downNode)
      temp=views.Circle_R_00001_9
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,0.6,0.5},{"scaleTo",32/60,1.0,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",32/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
      temp=views.Circle_R_00001_9_0
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,0.6,0.5},{"scaleTo",32/60,1.0,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",32/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",7/60},{"call",delayFrameIndex_32}}))

end
--buff
function ChaserZbEffect:createViews_2()
   local effectManager=self.effectManager
   local bg=self.target.avater.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos=self.offTargetPos

   local total=self.total
   local temp
   local baseScal=1
   local oy=120
   if self.target.sid and self.target.sid>=901 and self.target.sid<=905 then
      baseScal=0.3
      oy=40
   end
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+oy)
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

   local function delayFrameIndex_70()
     effectManager:addEffect("views2_delay70",upNode)
      temp=views.Glow_01_9_1
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,0.7,0.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,178},{"fadeTo",total-15/60,153},{"fadeTo",10/60,0}}))
      temp=views.Attack_1111_6_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-15/60},{"fadeTo",10/60,0}}))
      temp=views.Attack_1111_6_0_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-15/60},{"fadeTo",10/60,0}}))
      temp=views.Attack_1111_6_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",total-15/60,255},{"fadeTo",10/60,0}}))
      temp=views.Attack_1111_6
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,1.5,1.5},{"scaleTo",15/60,1.75,1.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_9
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.6,0.6},{"scaleTo",25/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Glow_01_9_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",20/60,0.5,0.5},{"scaleTo",20/60,0.7,0.7}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",25/60,204},{"fadeTo",20/60,76}})))
      temp=views.Sprite_15
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",25/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_70}}))

   local function delayFrameIndex_73()
     effectManager:addEffect("views2_delay73",upNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",351/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_73}}))

   local function delayFrameIndex_75()
     effectManager:addEffect("views2_delay75",upNode)
      temp=views.Attack_1111_6_1
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,1.5,1.5},{"scaleTo",15/60,1.75,1.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",5/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_75}}))

   local function delayFrameIndex_80()
     effectManager:addEffect("views2_delay80",upNode)
      temp=views.Sprite_15_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",25/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_80}}))

   local function delayFrameIndex_90()
     effectManager:addEffect("views2_delay90",upNode)
      temp=views.Sprite_15_0_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",25/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_90}}))

end

--普通攻击开火
function ChaserZbEffect:attack()
    local setting={{72,-98,45},{196,17,0},{133,158,-45},{-133,158,-135},{-196,17,180},{-72,-98,135}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local delayNode=self.delayNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]

    local r=setting[direction][3]
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+10000)
    upNode:setRotation(r)
    upNode:runAction(ui.action.sequence({{"delay",72/60},"remove"}))

    local function delayFrameIndex_9()
        effectManager:addEffect("attack_views1_delay9",upNode)
        temp=views.Sprite_17_0_0_0
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",22/60},{"fadeTo",1/60,0},"remove"}))
        temp=views.Glow_02_25
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",22/60},{"fadeTo",1/60,0},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}}))
end
--普攻子弹
function ChaserZbEffect:attack_move()
  local setting={{72,-98,45},{196,17,0},{133,158,-45},{-133,158,-135},{-196,17,180},{-72,-98,135}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime+15/60
   local r=-math.deg(math.atan2(moveY,moveX))

   local temp

  local moveNode=ui.node()
  moveNode:setPosition(initPos[1],initPos[2])
  bg:addChild(moveNode,initPos[3]+10000)
  moveNode:setRotation(r)

 
   local function delayFrameIndex_14()
      local pos={{0,0},{-60,-15},{-120,15},{-180,0},{-240,-15},{-300,15},{-360,0}}
      local i=0
      local function createBullte(  )
          i=i+1
          if i>7 then
            return 
          end
          effectManager:addEffect("attack_views2_delay14",moveNode)
          temp=views.Bullet_1_Y
          temp:setPosition(pos[i][1],pos[i][2])

          temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      end

      local function showTargetBao()
          self:attack_bao()
      end
      moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",showTargetBao}}))
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime*10,moveX*10,moveY*10,"remove"}}))
      moveNode:runAction(ui.action.arepeat(ui.action.sequence({{"call",createBullte},{"delay",3/60}}),7))
   end
   moveNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_14}}))

end
--普通攻击受击
function ChaserZbEffect:attack_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",45/60},"remove"}))

     effectManager:addEffect("attack_views3_delay37",upNode)
      temp=views.Glow_01_29
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0},{"delay",5/60}}),3))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.Glow_01_29_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0},{"delay",5/60}}),3))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.Particle_16
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
end

return {M,V,C}
