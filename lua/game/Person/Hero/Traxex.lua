

local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    TraxexEffect.new({attacker = self, mode = mode, target = attackTarget,},callback)
end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    callback()
end
local C = class(AvtControler)

--4019    黑弓      4029    主动技能35  己方全体远程单位增加该单位自身的c%*攻击力，持续y秒，消耗x怒，冷却时间z秒
-- 修改 降低所有小兵受到的技能伤害a%，增加攻击力b，持续c秒
-- 修改2 降低[所有小兵和自身]受到的技能伤害a%，增加攻击力b，持续c秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a, b, c = params.a, params.b, params.c
    for i,v in ipairs(self.battleMap2.mer) do
        if v.M and v.avater and not v.deleted then
            BuffUtil.setBuff(v,{lastedTime = c, bfAtkAdd = b, sdefParam = a})
            TraxexEffect.new({attacker = self.V, mode = 2, target = v, lastedTime = c})
        end
    end
    if GameLogic.useTalentMatch then
        BuffUtil.setBuff(self,{lastedTime = c, bfAtkAdd = b, sdefParam = a})
        TraxexEffect.new({attacker = self.V, mode = 2, target = self, lastedTime = c})
    end
end

--天神技 对最近的[m]个英雄造成([a]+[x]%攻击力)的伤害，降低其[y]%的移动速度和攻击力，持续[t]秒。
--修改 增加场上所有小兵b生命上限，c%移动速度，d%攻速，持续n秒
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill(v)
    local params = self.person.awakeData.ps
    local b, c, d, n = params.b, params.c, params.d, params.n
    -- SkillPlugin.exe2(self,v,ps.a,ps.x)
    -- BuffUtil.setBuff(v,{lastedTime = ps.t,bfAtkSpeedPct = -ps.y,bfMovePct = -ps.y})
    for i,v in ipairs(self.battleMap2.mer) do
        if v.M and v.avater and not v.deleted then
            BuffUtil.setBuff(v,{lastedTime = n, bfHpAdd=b, bfMovePct=c, bfAtkSpeedPct=d})
            TraxexEffect.new({attacker = self.V, mode = 3, target = v, lastedTime = n})
        end
    end
end

--当英雄防御时，狙击塔增加[x]%攻击力，[y]%血量。当英雄首次濒死时，获得不死状态，同时攻速提升[z]%，伤害提升[o]%，持续[t]秒。
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
            if v.bid == 22 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.atk = v.M.atk*(1+ps.x/100)
            end
        end
        self.M.notDie = {lastedTime=ps.t, bfAtkSpeedPct=ps.z, bfHurt=ps.o}
    end
end

function C:addNotDieEffect(notDie)
    Blackbow2.new(self.V.view,0,0,notDie.lastedTime)
end

TraxexEffect = class()

function TraxexEffect:ctor(params,callback)
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

function TraxexEffect:initParams(params)
    self.lastedTime = params.lastedTime
    self.effectManager=GameEffect.new("TraxexEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.sid=params.sid

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
        view.x = 0
        view.y = self.target.avater.animaConfig.Ymove
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
        view.x = view:getContentSize().width/2
        view.y = view:getContentSize().height/2
    end
    self.target.view = view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function TraxexEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initSkillState()
    elseif self.mode == 3 then
        self:initGodSkillState()
    end
end

function TraxexEffect:initAttack()
    local setting={{10,46},{40,85},{26,100},{-26,100},{-40,85},{-10,46}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    --时间
    local moveTime=math.sqrt((self.targetPos[1]-initPos[1])^2+(self.targetPos[2]-initPos[2])^2)/self.speed
    local temp
    self.time = 24/60+5/60+moveTime
    --旋转
    local moveX=self.targetPos[1]-initPos[1]
    local moveY=self.targetPos[2]-initPos[2]
    local r=math.deg(math.atan2(moveX, moveY))
    r = r-90

    local function delayFrameIndex_24()
        local moveNode=ui.node()
        moveNode:setPosition(initPos[1],initPos[2])
        moveNode:setLocalZOrder(initPos[3]+10000)
        bg:addChild(moveNode)
        moveNode:setScale(1.2)
        moveNode:setRotation(90+r)
        moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
        local function callBao()
            self:createViews_bao()
        end
        moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",callBao},"remove"}))

        effectManager:addEffect("views2_delay24",moveNode)
        temp=views.arrowShot3_1_move
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
        temp=views.Glow_01_36_1_move
        temp:setPosition(0,25)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
        temp=views.Particle_1_0_1_move
        temp:setPosition(0,0)
        temp:setLocalZOrder(7)
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",24/60},{"call",delayFrameIndex_24}}))

    local function delayFrameIndex_10()
        effectManager:addEffect("views2_delay10",bg)
        temp=views.Charge_1
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+2)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",13/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
        temp=views.Glow_01_35_1
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+3)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,145},{"fadeTo",12/60,127},{"fadeTo",2/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))
end

function TraxexEffect:createViews_bao()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.targetPos
    local temp

    effectManager:addEffect("views2_delay44",bg)
    temp=views.Sparkless_00000_37_bao
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",8/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
    temp=views.Glow_01_38_bao
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",4/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",9/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
end
function TraxexEffect:initSkill()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,0}
    self.time = 20/60
    local temp

    local function delayFrameIndex_49()
    effectManager:addEffect("views1_delay49",bg)
    temp=views.Black_Bow_Buff_00000_7
    temp:setPosition(initPos[1]-8,initPos[2]+104)
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",50/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
    temp=views.Black_Bow_Buff_00000_7_0
    temp:setPosition(initPos[1]-8,initPos[2]+104)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",6/60,178},{"delay",54/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",71/60},"remove"}))
    end
    delayFrameIndex_49()
end

function TraxexEffect:initSkillState()
    --己方全体远程单位增加攻击力使用该特效
    local effectManager=self.effectManager
    local bg=self.target.view
    local views=self.views
    local initPos={bg.x,bg.y,0}
    local temp

    local total=self.lastedTime
    bg:runAction(ui.action.sequence({{"scaleTo",35/60,1.5,1.5},{"delay",total-60/60},{"scaleTo",25/60,1,1}}))

    local stateNode=ui.node()
    stateNode:setPosition(0,0)
    bg:addChild(stateNode,10)
    if self.target.sid>=100 and self.target.sid<=700 then
        stateNode:setScale(0.3)
    end
    stateNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
    effectManager:addEffect("views1_delay69",stateNode)
    temp=views.GF_472_3
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",15/60,1.8,2.25},{"scaleTo",15/60,1,1.25}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,178},{"fadeTo",15/60,51}})))

end

function TraxexEffect:initGodSkillState()
    --己方全体远程单位增加攻击力使用该特效
    local effectManager=self.effectManager
    local bg=self.target.view
    local views=self.views
    local initPos={bg.x,bg.y,0}
    local temp

    local total=self.lastedTime
    bg:runAction(ui.action.sequence({{"scaleTo",35/60,1.5,1.5},{"delay",total-60/60},{"scaleTo",25/60,1,1}}))

    local stateNode=ui.node()
    stateNode:setPosition(0,0)
    bg:addChild(stateNode,10)
    if self.target.sid>=100 and self.target.sid<=700 then
        stateNode:setScale(0.3)
    end
    stateNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
    effectManager:addEffect("views1_delay69",stateNode)
    temp=views.GF_472_3
    temp:setColor(cc.c3b(255,0,0))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",15/60,1.8,2.25},{"scaleTo",15/60,1,1.25}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,178},{"fadeTo",15/60,51}})))

end

function TraxexEffect:update(diff)
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

--防御天神技特效
Blackbow2=class()
function Blackbow2:ctor(bg,x,y,lastedTime)
    self.effectManager=GameEffect.new("Blackbow2.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.lastedTime = lastedTime
    self.initPos={x,y,0}
    self.targetPos={x+400,y-400,0}
    self:initEffect()
end
function Blackbow2:initEffect()
    self:createViews_1()
end
function Blackbow2:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local total=self.lastedTime

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+240)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",upNode)
      temp=views.Jian_1
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.35,0.35},{"scaleTo",5/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.GF_472_3
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.6,1.6},{"scaleTo",15/60,2.0,2.0}}))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,102},{"fadeTo",15/60,76}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views1_delay20",upNode)
      temp=views.GF_472_3_0
      temp:runAction(ui.action.sequence({{"scaleTo",15/60,1.6,1.6},{"scaleTo",15/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,150},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end



return {M,V,C}




















