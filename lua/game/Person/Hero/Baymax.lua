

local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    BaymaxEffect.new({attacker = self, mode = mode, target = attackTarget, lastedTime = self.C.actSkillParams.y},callback)
end


local C = class(AvtControler)

--4006    大白      4016    主动技能22  持续y秒内，提升自身和己方所有勇士a%的攻击速度，b%的移动速度,消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,b,y = params.a,params.b,params.y
    BuffUtil.setBuff(self,{bfAtkPct = a,bfAtkSpeedPct = b,lastedTime = y})
    for i,v in ipairs(self.battleMap2.mer) do
        if v.sid and v.sid == 100 then
            BuffUtil.setBuff(v,{bfAtkPct = a,bfAtkSpeedPct = b,lastedTime = y})
            BaymaxEffect.new({attacker = v.avater, mode = 2, target = v, lastedTime = y})
        end
    end
end


BaymaxEffect = class()

function BaymaxEffect:ctor(params,callback)
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

function BaymaxEffect:initParams(params)
    self.effectManager=GameEffect.new("BaymaxEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 2000
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

function BaymaxEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initSkillState()
    end
end

function BaymaxEffect:initAttack()
    self.time = 0
    local setting={{119,-31,45},{170,77,0},{45,162,-45},{-45,162,-135},{-170,77,-180},{-119,-31,135}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+10000
    local r=setting[direction][3]
    local temp

    local attNode=ui.node()
    attNode:setPosition(initPos[1],initPos[2])
    bg:addChild(attNode,initPos[3])
    attNode:setScale(1.5)
    attNode:setRotation(r)
    attNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

    local function delayFrameIndex_24()
    effectManager:addEffect("views2_delay24",attNode)
    temp=views.Strike_00000_16_222
    temp:setAnchorPoint(0.2,0.5)
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_24}}))

    local function delayFrameIndex_19()
    effectManager:addEffect("views2_delay19",attNode)
    temp=views.Sprite_19_222
    temp:setRotation(45)
    temp:setAnchorPoint(0.4,0.4)
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
    temp=views.Glow_01_17_222
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Glow_01_17_0_222
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    delayFrameIndex_19()
end

function BaymaxEffect:initSkill()
    self.time = 1
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos = {0,0,0}
    local temp

    self.delayNode:runAction(ui.action.sequence({{"delay",98/60}}))
    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",98/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.5)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",98/60},"remove"}))

    local function delayFrameIndex_35()
    effectManager:addEffect("views1_delay35",upNode)
    temp=views.Glow_01_6
    temp:setPosition(0,23)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,126},{"fadeTo",55/60,127},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",75/60},"remove"}))
    temp=views.Glow_01_6_0
    temp:setPosition(0,23)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,204},{"delay",55/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",75/60},"remove"}))
    end
    delayFrameIndex_35()

    local function delayFrameIndex_39()
    effectManager:addEffect("views1_delay39",downNode)
    temp=views.Ground_00002_4
    temp:setPosition(0,26)
    temp:setLocalZOrder(-2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",50/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",71/60},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_39}}))

    local function delayFrameIndex_49()
    effectManager:addEffect("views1_delay49",downNode)
    temp=views.UP_Line_C_00001_2
    temp:setPosition(0,241)
    temp:setLocalZOrder(-1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",50/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))

    effectManager:addEffect("views1_delay49_up",upNode)
    temp=views.UP_Line_S_00001_3
    temp:setPosition(0,241)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",50/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
    temp=views.Particle_1
    temp:setPosition(0,-4)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"delay",47/60},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_49}}))

    local function delayFrameIndex_50()
    effectManager:addEffect("views1_delay50",upNode)
    temp=views.Light_00_10_0
    temp:setPosition(0,-44)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.5,2.3}}))
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",25/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Light_00_10_0_0
    temp:setPosition(0,-44)
    temp:setLocalZOrder(6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.5,2.3}}))
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Light_00_10
    temp:setPosition(0,-44)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.5,2.3}}))
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_50}}))

    local function delayFrameIndex_95()
        if not self.attacker.C.person.equip then
            self:initSkillState()
        end
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_95}}))
end

function BaymaxEffect:initSkillState()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos = {0,0,0}
    local temp
    local total = self.lastedTime
    effectManager:addEffect("views1_delay95",bg)
    temp=views.Glow_01_33
    temp:setPosition(initPos[1],initPos[2]+152)
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.8,0.8},{"scaleTo",10/60,0.6,0.6}}))
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Glow_01_33_0
    temp:setPosition(initPos[1],initPos[2]+152)
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.3,0.3},{"scaleTo",10/60,0.2,0.2}}))
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Shoe_32
    temp:setPosition(initPos[1],initPos[2]+150)
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
end

function BaymaxEffect:update(diff)
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




























