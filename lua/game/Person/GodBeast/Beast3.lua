
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    local y
    if isSkill then
        y = self.C.actSkillParams.y
        mode = 1
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastThreeEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=y},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 3
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastThreeEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--在[y]秒内，自身每秒恢复[c]%*自身攻击力的血量，自身和己方全体英雄减伤[d]%。技能冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:exeSkillForGodBeast(target)
    local ps = self.actSkillParams
    local c,d,y = ps.c,ps.d,ps.y
    for i,v in ipairs(self.battleMap2.hero) do
        if v~=self then
            local bss = (1/(v.V.animaConfig.scale or 0.5))
            local scals = {bss*0.25,bss*0.325,bss*0.5}
            local scal=scals[self.sid%10]
            BeastThreeEffect.new({attacker = self.V, mode = 3, target = v,scale=scal,total = y})
            BuffUtil.setBuff(v,{lastedTime = y, bfDefPct = d,})
        else
            BuffUtil.setBuff(v,{lastedTime = y, bfDefPct = d, lastAddHp = c*self.M.atk*y/100})
        end
    end
end


BeastThreeEffect=class()

function BeastThreeEffect:ctor(params,callback)
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

function BeastThreeEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastThreeEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.attacker.scene.delayNode
    self.speed = params.speed or 2000
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

function BeastThreeEffect:initEffect()
    if self.mode==0 then
        self:initAttack()
    elseif self.mode==1 then
        self:initSkill()
    elseif self.mode==2 then
        self:initCurrency()
    elseif self.mode == 3 then
        self:initSkill_bao()
    end
end
--技能通用
function BeastThreeEffect:initCurrency()
    local setting={{29,10},{46,27},{34,81},{-34,81},{-46,27},{-29,10}}
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
    bg:addChild(upNode,initPos[3]+1)
    upNode:setScale(baseScal)
    upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

    local function delayFrameIndex_0()
        effectManager:addEffect("views3_delay0",upNode)
        temp=views.Common_00000_3
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
        temp=views.Common_00000_3_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

    local function delayFrameIndex_11()
        effectManager:addEffect("views3_delay11",upNode)
        temp=views.Particle_3
        temp:setPosition(0,0)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_11}}))
    local function delayFrameIndex_20()
        effectManager:addEffect("views3_delay20",upNode)
        temp=views.Glow_16_5
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,1.0,1.0}}))
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
--普攻
function BeastThreeEffect:initAttack()
    local setting={{62,-51},{115,26},{64,105},{-64,105},{-115,26},{-62,-51}}
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
    local temp

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setScale(baseScal)
    local function delayFrameIndex_35()
        local function showTargetBao(  )
            self:initAttack_bao()
        end
        moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
        effectManager:addEffect("views1_delay0",moveNode)
        temp=views.Particle_2
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp=views.Glow_16_4
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
    end
    moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_35}}))

end
--普攻受击
function BeastThreeEffect:initAttack_bao()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local baseScal=self.baseScal
    local temp
    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+1)
    upNode:setScale(baseScal)
    upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

    effectManager:addEffect("views2_delay64",upNode)
    temp=views.Splash_00000_3
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Glow_01_5
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.5,1.5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
end
--技能攻击
function BeastThreeEffect:initSkill()
    self.time = 0.1
    local setting={{29,10},{46,27},{34,81},{-34,81},{-46,27},{-29,10}}
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local delayNode=bg
    local views=self.views
    local direction=self.direction
    local baseScal=self.baseScal
    local initPos=self.offInitPos
    local ox=setting[direction][1]*baseScal
    local oy=setting[direction][2]*baseScal
    local total=self.total
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+10000)
    upNode:setScale(baseScal*1.3)
    upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    bg:addChild(downNode,initPos[3]-10)
    downNode:setScale(baseScal*1.3)
    downNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

    local function delayFrameIndex_55()
        effectManager:addEffect("views3_delay55",downNode)
        temp=views.Glow_16_2
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp:runAction(ui.action.sequence({{"fadeTo",6/60,127},{"delay",total+9/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total+25/60},"remove"}))
        temp=views.Ground_00000_1
        temp:setPosition(0,0)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",total+16/60},{"fadeTo",3/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total+25/60},"remove"}))
        temp=views.Glow_16_2_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(5)
        temp:runAction(ui.action.sequence({{"fadeTo",6/60,178},{"delay",total+9/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total+25/60},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_55}}))

    local function delayFrameIndex_59()
        effectManager:addEffect("views3_delay59",upNode)
        temp=views.Particle_1
        temp:setPosition(0,0)
        temp:setLocalZOrder(7)
        temp:runAction(ui.action.sequence({{"delay",42/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_60()
        effectManager:addEffect("views3_delay60",downNode)
        temp=views.Glow_01_9
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total+20/60},"remove"}))
        temp=views.Glow_01_9_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",total},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total+20/60},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_60}}))

    local function delayFrameIndex_80()
        effectManager:addEffect("views3_delay80",upNode)
        temp=views.Glow_16_8
        temp:setPosition(0,0)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"fadeTo",15/60,204},{"delay",total-25/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
        temp=views.Shield_00000_6
        temp:setPosition(0,0)
        temp:setLocalZOrder(5)
        temp:runAction(ui.action.sequence({{"fadeTo",15/60,102},{"delay",total-25/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
        temp=views.Shield_00000_6_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(6)
        temp:runAction(ui.action.sequence({{"fadeTo",15/60,165},{"delay",total-25/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_80}}))

    local function delayFrameIndex_90()
        local rNode=ui.node()
        rNode:setPosition(0,0)
        downNode:addChild(rNode)
        rNode:setScaleY(0.75)
        effectManager:addEffect("views3_delay90",rNode)
        temp=views.Swirl_5
        temp:runAction(ui.action.arepeat(ui.action.rotateBy(60/60,-85)))
        temp=views.Swirl_5_0
        temp:runAction(ui.action.arepeat(ui.action.rotateBy(60/60,-85)))
    end
    downNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_90}}))
end
--技能减伤
function BeastThreeEffect:initSkill_bao()
    local effectManager=self.effectManager
    local bg=self.targetView
    local delayNode=bg
    local views=self.views
    local direction=self.direction
    local initPos=self.offTargetPos
    local baseScal=self.baseScal
    local total=self.total
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+100)
    upNode:setScale(baseScal)
    upNode:runAction(ui.action.sequence({{"delay",total+25/60},"remove"}))

    local function delayFrameIndex_80()
        effectManager:addEffect("views4_delay80",upNode)
        temp=views.Glow_16_8_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"fadeTo",15/60,204},{"delay",total-25/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
        temp=views.Shield_00000_6_1
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"fadeTo",15/60,102},{"delay",total-25/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
        temp=views.Shield_00000_6_0_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp:runAction(ui.action.sequence({{"fadeTo",15/60,165},{"delay",total-25/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_80}}))
end

function BeastThreeEffect:update(diff)
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
