local M = class(AvtInfo)













local V = {}


function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6

    self.exeAtkFrame = 1
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    self:currencyEffect(1,50,1)
    self.state = PersonState.SKILL
end

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    EVAEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)
--对直线范围内的敌方单位造成[a]+[c]%*攻击力的伤害(长度g格，宽度h格），消耗[x]怒，冷却时间[z]秒
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


EVAEffect = class2()

function EVAEffect:ctor(params,callback)
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

function EVAEffect:initParams(params)
    self.effectManager=GameEffect.new("EVAEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget

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

function EVAEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    end
end

function EVAEffect:initAttack()
    local setting={{53,-33},{100,51},{55,121},{-55,121},{-100,51},{-53,-33}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime = math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime
    local temp

    local function delayFrameIndex_64()
    effectManager:addEffect("views2_delay64",bg)
    temp=views.Sprite_16_b
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+10000)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",moveTime+0/60},{"call",delayFrameIndex_64}}))

    local function delayFrameIndex_29()

    effectManager:addEffect("views2_delay29",bg)
    temp=views.Sprite_13_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10000)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime},{"scaleTo",10/60,1.5,1.5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime+5/60},{"fadeTo",5/60,0},"remove"}))

    temp=views.Sprite_13
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10002)
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(35/60,180)))
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime+1/60},{"fadeTo",1/60,0},"remove"}))
    temp=views.Sprite_13_0_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10004)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime},{"scaleTo",10/60,0.6,0.6}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,153},{"delay",moveTime+5/60},{"fadeTo",5/60,0},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))
end

function EVAEffect:initSkill()
    local setting={{53,-33},{100,51},{55,121},{-55,121},{-100,51},{-53,-33}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local speed=2000
    local length=400
    local oX,oY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveX=length*math.cos(math.atan2(oY,oX))
    local moveY=length*math.sin(math.atan2(oY,oX))
    local length=math.sqrt(moveX*moveX+moveY*moveY)
    local r=-math.deg(math.atan2(oY,oX))
    local moveTime = math.sqrt(moveX^2+moveY^2)/speed
    local moveTime2 =math.sqrt(oY^2+oX^2)/speed
    self.time = moveTime2+0.6
    local temp
    local function delayFrameIndex_30()
    effectManager:addEffect("views1_delay30",bg)
    temp=views.Glow_01_2_0_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",15/60,153},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Glow_01_2_0_0_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,102},{"fadeTo",24/60,151},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    end
    delayFrameIndex_30()
    local function delayFrameIndex_34()
    effectManager:addEffect("views1_delay34",bg)
    temp=views.Glow_01_2_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",19/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    temp=views.Particle_1_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
    temp=views.Particle_1_0_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+11)
    temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_34}}))

    local function delayFrameIndex_59()
    effectManager:addEffect("views1_delay59",bg)
    temp=views.Particle_2_0_a
    temp:setRotation(r)
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1006)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime+1/60},"remove"}))
    temp=views.Beam_4
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1007)
    temp:setRotation(90+r)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.6,length/400},{"scaleTo",25/60,1.8,length/400}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"delay",10/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},{"tintto",15/60,{255,0,0}}}))
    temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
    temp=views.Particle_2_a
    temp:setRotation(r)
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1008)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime+1/60},"remove"}))
    temp=views.Beam_4_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:setRotation(90+r)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,6,length/400},{"scaleTo",25/60,3,length/400}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,90},{"fadeTo",5/60,153},{"fadeTo",25/60,76},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",1/60},{"tintto",31/60,{255,0,0}}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Glow_01_3_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+12)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    temp=views.Glow_01_3_0_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+13)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    temp=views.Glow_01_3_0_0_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+14)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",29/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_65()
    effectManager:addEffect("views1_delay65",bg)
    temp=views.Glow_01_3_1
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+15)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,1.05,1.05},{"scaleTo",10/60,0.9,0.9}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    temp=views.Glow_01_3_1_0
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+16)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,0.5,0.5},{"scaleTo",10/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",moveTime2+29/60},{"call",delayFrameIndex_65}}))
    local function delayFrameIndex_70()
    effectManager:addEffect("views1_delay70",bg)
    temp=views.Impact_00000_1_0
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Impact_00000_1_0_0
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",moveTime2+29/60+5/60},{"call",delayFrameIndex_70}}))

    local function delayFrameIndex_74()
    effectManager:addEffect("views1_delay74",bg)
    temp=views.Glow_01_4
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+17)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",moveTime2+29/60+9/60},{"call",delayFrameIndex_74}}))
end

function EVAEffect:update(diff)
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




















