local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    StormFemaleEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--3005 风暴女  对直线范围内(长度g格，宽度h格）的敌人造成a+c%*攻击力的伤害，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    if not target then
        return
    end
    local params = self.actSkillParams
    local a,c,g,h = params.a,params.c,params.g, params.h
    local targetG = self:getLineTarget(self,self.battleMap.battlerAll,g,h,target)
    for i,v in ipairs(targetG) do
        SkillPlugin.exe2(self,v,a,c)
    end
end

StormFemaleEffect=class()

function StormFemaleEffect:ctor(params,callback)
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
function StormFemaleEffect:update(diff)
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
function StormFemaleEffect:initParams(params)
    self.effectManager=GameEffect.new("StormFemaleEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.attacker.scene.delayNode
    self.speed = params.speed or 500
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

function StormFemaleEffect:initEffect()
    if self.mode==0 then
        self:initAttack()
    elseif self.mode==1 then
        self:initSkill()
    end
end

--普通攻击
function StormFemaleEffect:initAttack()
    local setting={{20,40},{33,68},{19,95},{-19,95},{-33,68},{-20,40}}
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
    self.time=moveTime

    local temp

    local function delayFrameIndex_49()
        effectManager:addEffect("views1_delay49",bg)
        temp=views.Wind_Ball_00000_9_0
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+10000)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",moveTime+1/60},"remove"}))
    end
    delayFrameIndex_49()
end
--技能
function StormFemaleEffect:initSkill()
    local setting={{20,40},{33,68},{19,95},{-19,95},{-33,68},{-20,40}}
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
    local moveTime=math.sqrt(moveX^2+moveY^2)/(self.speed+800)
    self.time=moveTime
    local r=-math.deg(math.atan2(moveY,moveX))
    local leng=800
    local oX=leng*math.cos(math.atan2(moveY,moveX))
    local oY=leng*math.sin(math.atan2(moveY,moveX))
    local moveTime2=math.sqrt(oX^2+oY^2)/(self.speed+800)

    local temp

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    moveNode:setScale(2)
    bg:addChild(moveNode,initPos[3]+10000)


    local function delayFrameIndex_50()
    moveNode:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime2,oX,oY},"remove"}))

    effectManager:addEffect("views2_delay50",moveNode)
    temp=views.Tornado_00001_3_0
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",moveTime2-9/60},{"fadeTo",5/60,0}}))
    temp=views.Particle_1
    temp:setRotation(-90+r)
    temp=views.Particle_1_1
    temp:setRotation(-5+r)

    end
    moveNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_50}}))
end


return {M,V,C}
