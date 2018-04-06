


local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    local y = self.C.actSkillParams.y
    UchihaEffect.new({attacker = self, mode = mode, target = attackTarget,lastedTime = y},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6

    self:attack(viewInfo1,viewInfo2,b)
    self.exeAtkFrame = 1
    --通用特效
    local off={[4002]={0,60,0.7},[4005]={0,60,0.7},[4007]={0,40,0.7},[4004]={0,40,0.7}}
    local id = 4002
    if off[id] then
        local ox,oy,scal=off[id][1],off[id][2],off[id][3]
        self:currencyEffect(ox,oy,scal)
    end
    self.state = PersonState.SKILL
end

local C = class(AvtControler)

--4015    宇智波  [y]秒内，除自身外所有单位全体眩晕（包含建筑），自身增加攻速[c]%，增加移速[d]%，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams

    local c,d,y =params.c,params.d,params.y
    for i,v in ipairs(self.battleMap.battler) do
        BuffUtil.setBuff(v,{lastedTime = y,bfDizziness = y})
    end
    for i,v in ipairs(self.battleMap2.battler) do
        if v~=self then
            BuffUtil.setBuff(v,{lastedTime = y,bfDizziness = y})
        end
    end
    BuffUtil.setBuff(self,{lastedTime = y,bfAtkSpeedPct = c,bfMovePct=d})
end

--天神技  对[m]个敌方目标造成([a]+[x]%攻击力)的伤害，目标受到的伤害提升[y]%，攻击力降低[z]%，持续[t]秒
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local n,a,b,e,f,t = 2,1000,100,30,15,5
    local ps = self.person.awakeData.ps
    local tg = self:getMinDisTarget(ps.m)
    for i,v in ipairs(tg) do
        local shot = UchihaEffect.new({attacker = self.V, mode = 5, target = v, lastedTime=ps.t},function()
          SkillPlugin.exe2(self,v,ps.a,ps.x)
          BuffUtil.setBuff(v,{lastedTime = ps.t,bfDefPct = -ps.y,bfAtkPct = -ps.z})
        end)
    end
end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    UchihaEffect.new({attacker = self, mode = 4, target = attackTarget},callback)
end

--防御时，敌方所有刚进场的英雄眩晕[t]秒，并且攻击力与攻速降低[x]%，持续[k]秒。
function C:sg_updateBattle(diff)
    if self:checkGodSkill2(true) then
        if not self.isAddedHero then
            self.isAddedHero = {}
        end
        local group = self.battleMap.hero
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap2.hero
        end
        for k,v in pairs(group) do
            if not v.params.isZhaoHuan and not v.params.isRebirth then
                if not self.isAddedHero[v] then
                    self.isAddedHero[v] = true
                    local ps = self.person.awakeData2.ps
                    BuffUtil.setBuff(v,{lastedTime=ps.k, bfAtkPct=-ps.x, bfAtkSpeedPct=-ps.x})
                    BuffUtil.setBuff(v,{lastedTime=ps.t, bfDizziness=ps.t})
                    Vertigo.new(v.V.view, 0, v.V.animaConfig.Ymove, ps.t)
                end
            end
        end
    end
end

UchihaEffect = class()

function UchihaEffect:ctor(params,callback)
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

function UchihaEffect:initParams(params)
    self.effectManager=GameEffect.new("UchihaEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
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

function UchihaEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
        self:initAttack_move()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode==4 then
        self.time = 29/60
        self:initGodSkill()
    elseif self.mode == 5 then
        self:initGodSkill_move()
    end
end
function UchihaEffect:initAttack()
  --local setting={{28,-55,45},{96,-5,0},{75,64,-45},{-75,64,-135},{-96,-5,-180},{-28,-55,135}}
  local setting={{38,27,1},{68,71,1},{29,114,-1},{-29,114,-1},{-68,71,1},{-38,27,1}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
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
   bg:addChild(upNode,initPos[3])
   upNode:setRotation(r)
   upNode:setScale(0.65)
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_26()
     effectManager:addEffect("views2_delay26",upNode)
      temp=views.Glow_02_5
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.3,0.3},{"scaleTo",9/60,0.4607,0.4607},{"scaleTo",5/60,0.55,0.55}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",7/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.Glow_02_5_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.2,0.2},{"scaleTo",14/60,0.4,0.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",4/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   delayFrameIndex_26()

   local function delayFrameIndex_29()
     effectManager:addEffect("views2_delay29",upNode)
      temp=views.Strike_00000_4
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
      temp=views.Sprite_7
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"fadeTo",8/60,110},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_29}}))
end

function UchihaEffect:initAttack_move()
  --local setting={{28,-55},{96,-5},{75,64},{-75,64},{-96,-5},{-28,-55}}
  local setting={{38,27,1},{68,71,1},{29,114,-1},{-29,114,-1},{-68,71,1},{-38,27,1}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local temp

  local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setRotation(r)
   moveNode:setScale(0.9)

   local function delayFrameIndex_33()
    local function showTargetBao()
      self:initAttack_target()
    end
     moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views2_delay33",moveNode)
      temp=views.Sprite_8
      temp=views.Sprite_8_0
   end
   moveNode:runAction(ui.action.sequence({{"delay",8/60},{"call",delayFrameIndex_33}}))
end

function UchihaEffect:initAttack_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3])
   upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

     effectManager:addEffect("views2_delay55",upNode)
      temp=views.RTD0_00_3
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.RTD0_00_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
end

function UchihaEffect:initSkill()
    local setting={{38,27,1},{68,71,1},{29,114,-1},{-29,114,-1},{-68,71,1},{-38,27,1}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+setting[direction][3]*20
    local temp
    local x,y= self.attacker.scene.map.convertToPosition(20,20)
    local targetPos={x,y,0}
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    local r=-math.deg(math.atan2(moveY,moveX))

    local function delayFrameIndex_25()
    effectManager:addEffect("views1_delay25",bg)
    temp=views.Glow_01_16
    temp:setPosition(self.initPos[1],self.initPos[2]+60)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    end
    delayFrameIndex_25()

    local function delayFrameIndex_49()
    effectManager:addEffect("views1_delay49",bg)
    temp=views.lizi_00047png_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",7/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
    temp=views.lizi_00047png_1_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",7/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",24/60},{"call",delayFrameIndex_49}}))

    local function showTargetBao()
    self:createViews_3()
    end
    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setScale(1.5)
    moveNode:setVisible(false)
    moveNode:setRotation(r)
    local function delayFrameIndex_5_move()
    effectManager:addEffect("views1_delay49_move",moveNode)
    temp=views.xly_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp=views.Glow_01_2
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp=views.Particle_3_0
    temp:setRotation(-90)
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp=views.Particle_3
    temp:setRotation(-90)
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp=views.Particle_3_0_0
    temp:setRotation(-90)
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    end
    delayFrameIndex_5_move()
    local function delayFrameIndex_49_move()
    moveNode:setVisible(true)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
    end
    moveNode:runAction(ui.action.sequence({{"delay",24/60},{"call",delayFrameIndex_49_move}}))
    self.time = moveTime+24/60
end

function UchihaEffect:createViews_3()
    local effectManager=self.effectManager

    local views=self.views
    local direction=self.direction
    local x,y= self.attacker.scene.map.convertToPosition(20,20)
    local initPos={0,0,0}
    local temp
    local total=self.lastedTime

    local bg=ui.node()
    bg:setPosition(x,y)
    bg:setScale(7)
    self.viewsNode:addChild(bg)
    bg:runAction(ui.action.sequence({{"delay",total+9/60},"remove"}))

    local cNode=ui.node()
    cNode:setPosition(initPos[1],initPos[2])
    cNode:setScaleX(1)
    cNode:setScaleY(3/4)
    bg:addChild(cNode,initPos[3]-3)
    cNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
    local function delayFrameIndex_60()
    effectManager:addEffect("views3_delay60",cNode)
    temp=views.Glow_01_10
    temp:setPosition(0,0)
    --temp:setLocalZOrder(-3)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Sharingan_00000_8
    temp:setPosition(0,0)
    --temp:setLocalZOrder(-2)
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(95/60,180)))
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,179},{"delay",total-15/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.75,0.75}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    delayFrameIndex_60()
    local function delayFrameIndex_64()
    effectManager:addEffect("views3_delay64",bg)
    temp=views.Impact_00000_3_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Impact_00000_3
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    bg:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_64}}))

    local function delayFrameIndex_65()
    effectManager:addEffect("views3_delay65",bg)
    temp=views.Particle_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Sharingan_00000_9
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Glow_01_10_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"delay",total-10/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Sharingan_00000_9_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    bg:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_65}}))

    local function delayFrameIndex_69()
    effectManager:addEffect("views3_delay69",bg)
    temp=views.Particle_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-4)
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    bg:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_69}}))
end

function UchihaEffect:initGodSkill()
   local setting={{38,27},{68,71},{29,114},{-29,114},{-68,71},{-38,27}}
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local views=self.views
   local direction=self.direction
   local initPos={0,0,0}

   local initPos2={setting[direction][1],setting[direction][2],0}

   local total=220/60
   local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.5)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("godSkill_views1_delay0",upNode)
      temp=views.Common_00000_32
      temp:setPosition(setting[direction][1],setting[direction][2])
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",10/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_32_0
      temp:setPosition(setting[direction][1],setting[direction][2])
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",10/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   delayFrameIndex_0()

   local function delayFrameIndex_15()
     effectManager:addEffect("godSkill_views1_delay15",downNode)
      temp=views.Sprite_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(-4)
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"delay",total-50/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    effectManager:addEffect("godSkill_views1_delay15_up",upNode)
      temp=views.Buff_00000_14
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,130},{"fadeTo",total-45/60,99},{"fadeTo",35/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_15}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("godSkill_views1_delay20",upNode)
      temp=views.Glow_01_23_0_0
      temp:setPosition(setting[direction][1],setting[direction][2])
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))

   local function delayFrameIndex_55()
     effectManager:addEffect("godSkill_views1_delay55",downNode)
      temp=views.Glow_16_2_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(-3)
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",total-63/60,255},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-40/60},"remove"}))
      temp=views.Ground_00000_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(-2)
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",total-63/60,255},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-40/60},"remove"}))
      temp=views.Glow_16_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(-1)
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",total-63/60,178},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-40/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",55/60},{"call",delayFrameIndex_55}}))
end
--子弹
function UchihaEffect:initGodSkill_move()
  local setting={{38,27},{68,71},{29,114},{-29,114},{-68,71},{-38,27}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local temp
   local targetPos=self.targetPos


   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time = moveTime+0.1
   local r=-math.deg(math.atan2(moveY,moveX))

   local function delayFrameIndex_29()

      local function showTargetBao( )
         self:initGodSkill_target()
      end
      local moveNode=ui.node()
      moveNode:setPosition(initPos[1],initPos[2])
      moveNode:setScale(1.3)
      bg:addChild(moveNode,initPos[3]+10004)
      moveNode:setRotation(r)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("godSkill_views2_delay29",moveNode)
      temp=views.Fire_Ball_00000_2_move
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Fire_Ball_00000_2_0_move
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Glow_01_3_move
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Fire_00000_4_move
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

   end
   delayFrameIndex_29()

end
--受击
function UchihaEffect:initGodSkill_target()
   local effectManager=self.effectManager
   local bg=self.targetView
   local views=self.views
   local direction=self.direction
   local initPos=self.offTargetPos
   if self.target.V then
    initPos[2] = initPos[2]+self.target.V.animaConfig.Ymove
   end
   local total=self.lastedTime  --被击燃烧持续时间
   local temp

   local function delayFrameIndex_63()
    if self.target.deleted then
        return
      end
     effectManager:addEffect("godSkill_views3_delay63",bg)
      temp=views.Shockwave_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10004)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Shockwave_00000_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10005)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Sprite_9_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10006)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Glow_01_00_11_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10007)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_15_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10011)
      temp:runAction(ui.action.sequence({{"delay",total+6/60},{"scaleTo",15/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",total-10/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total+21/60},"remove"}))
   end
   delayFrameIndex_63()

   local function delayFrameIndex_64()
      if self.target.deleted then
        return
      end
     effectManager:addEffect("godSkill_views3_delay64",bg)
      temp=views.Change_Buff_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10001)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",35/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
   end
   delayFrameIndex_64()

   local function delayFrameIndex_65()
    if self.target.deleted then
        return
      end
     effectManager:addEffect("godSkill_views3_delay65",bg)
      temp=views.Glow_01_11_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10003)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.5},{"scaleTo",10/60,1.6,1.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_65}}))

   local function delayFrameIndex_69()
    if self.target.deleted then
        return
      end
     effectManager:addEffect("godSkill_views3_delay69",bg)
      temp=views.Fire_00000_12_fff
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10000)
      temp:runAction(ui.action.sequence({{"fadeTo",19/60,255},{"delay",total-49/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_69}}))

   local function delayFrameIndex_189()
    if self.target.deleted then
        return
      end
     effectManager:addEffect("godSkill_views3_delay189",bg)
      temp=views.Glow_01_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10002)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,2.0,2.0},{"scaleTo",10/60,1.6,1.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Shockwave_00000_6_1_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10008)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Shockwave_00000_6_0_0_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10009)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Sprite_9_0_1111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10010)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",total-28/60},{"call",delayFrameIndex_189}}))

end

function UchihaEffect:update(diff)
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

return {M,V,C}




















