

local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    SupermanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end

local C = class(AvtControler)

--4017    超人   主动技能33  对前方扇形120°，半径5格内的所有敌人造成a+c%*攻击里的伤害，减少其d%攻击力，持续t秒，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c,d,t = params.a,params.c,params.d,params.t
    local rt = self:getSectorTarget(self.battleMap.battlerAll, self, target, 6, 120)
    for k,v in ipairs(rt) do
        SkillPlugin.exe2(self,v,a,c)
        BuffUtil.setBuff(v,{lastedTime = t,bfAtkPct = -d})
        if v.person and v.person.equip then
        else
            SupermanEffect.new({attacker = self,mode = 2, target = v,lastedTime = t})
        end
    end
end

SupermanEffect = class()

function SupermanEffect:ctor(params,callback)
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

function SupermanEffect:initParams(params)
    self.effectManager=GameEffect.new("SupermanEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker and self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker and self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.lastedTime = params.lastedTime
    --起始点坐标
    if self.mode == 2 then
    
    else
        local x,y = 0,self.attacker.animaConfig.Ymove
        local p = {self.attacker.view:getPosition()}
        p[1] = p[1] + x
        p[2] = p[2] + y
        self.initPos = {p[1],p[2],General.sceneHeight - p[2]}
    end
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

function SupermanEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:targetState()
    end
end

function SupermanEffect:initAttack()
    self.time = 0.5
    --local setting={{26,100},{26,120},{7,135},{-7,135},{-26,120},{-26,100}}
    local setting={{5,105,1000000},{8,124,1000000},{-9,143,0},{9,143,0},{-8,124,1000000},{-5,105,1000000}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+setting[direction][3]
    local targetPos=self.targetPos
    local ox, oy = targetPos[1] - initPos[1], targetPos[2] - initPos[2]
    local length = math.sqrt(ox*ox+oy*oy)
    local r=-math.deg(math.atan2(oy, ox))
    local temp


    local function delayFrameIndex_0()
    effectManager:addEffect("views3_delay0",bg)
    temp=views.Glow_01_15
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",70/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
    temp=views.Glow_01_15_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,204},{"delay",70/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
    end
    delayFrameIndex_0()

    local function delayFrameIndex_4()
        effectManager:addEffect("views3_delay4",bg)
        temp=views.Lightning_00000_14
        temp:setRotation(r)
        temp:setAnchorPoint(100/1213,172/300)
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+10000)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,length/1040,0.32}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",70/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",76/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_4}}))

    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.targetPos
    local temp

    local function delayFrameIndex_9()
    effectManager:addEffect("views4_delay9",bg)
    temp=views.Glow_01_17
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",65/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",71/60},"remove"}))
    temp=views.Glow_01_17_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,178},{"delay",65/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",71/60},"remove"}))
    temp=views.Particle_5
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",67/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}})) 
end


function SupermanEffect:initSkill()
    self.time = 0.5
    --local setting={{19,31,135},{36,73,90},{-6,106,45},{6,106,-45},{-36,73,-90},{-19,31,-135}}
    local setting={{19,61,135},{36,103,90},{-6,136,45},{6,136,-45},{-36,103,-90},{-19,61,-135}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]

    local ps = self.attacker.animaConfig.Ymove+1
    if self.direction == 3 or self.direction==4 then
        ps = self.attacker.animaConfig.Ymove-1
    end
    initPos[3]=(self.initPos[3]+self.initPos[2])*ps

    local targetPos=self.targetPos
    local initPos2={(initPos[1]+targetPos[1])/2,(initPos[2]+targetPos[2])/2}
    local r=setting[direction][3]
    local temp

    local function delayFrameIndex_59_Particle()
    local pNode=ui.node()
    pNode:setPosition(initPos[1],initPos[2])
    bg:addChild(pNode,initPos[3]+3)
    pNode:setVisible(false)
    pNode:setRotation(r)
    pNode:runAction(ui.action.sequence({{"delay",4/60},"show",{"delay",37/60},"remove"}))
    effectManager:addEffect("views1_delay59_Particle",pNode)

    temp=views.Particle_1
    temp:setPosition(0,0)
    temp=views.Particle_1_0
    temp:setPosition(0,0)
    temp=views.Particle_1_0_0
    temp:setPosition(0,0)
    end
    delayFrameIndex_59_Particle()
    local function delayFrameIndex_59()
    effectManager:addEffect("views1_delay59",bg)
    temp=views.Glow_01_10_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"delay",35/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Glow_01_10
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,103},{"fadeTo",35/60,101},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_55()
    effectManager:addEffect("views1_delay55",bg)
    temp=views.Glow_01_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",35/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    temp=views.Glow_01_2_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",35/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    end
    delayFrameIndex_55()
end

function SupermanEffect:targetState()
    local effectManager=self.effectManager
    local bg=self.target.view
    local views=self.views
    local direction=self.direction
    local initPos={bg.x,bg.y,0}
    local temp
    local tatol = self.lastedTime

    local function delayFrameIndex_64()
    effectManager:addEffect("views2_delay64",bg)
    temp=views.Ice_Particle_00000_5
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_64}}))

    local function delayFrameIndex_65()
    effectManager:addEffect("views2_delay65",bg)
    temp=views.Weapon_Broken_00000_21
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",tatol},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol+0.5},"remove"}))
    temp=views.Weapon_Broken_Glow
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,127},{"delay",tatol},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol+0.5},"remove"}))
    temp=views.Weapon_Broken_Glow_0
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,127},{"delay",tatol},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol+0.5},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_65}}))

    local function delayFrameIndex_60()
    effectManager:addEffect("views2_delay60",bg)
    temp=views.Glow_01_6
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,163},{"fadeTo",5/60,178},{"fadeTo",5/60,165}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_60}}))

    local function delayFrameIndex_55()
    effectManager:addEffect("views2_delay55",bg)
    temp=views.Glow_01_8
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
    temp=views.Glow_01_9
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
    end
    delayFrameIndex_55()
end

function SupermanEffect:update(diff)
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





























