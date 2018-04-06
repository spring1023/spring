local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    local t
    if isSkill then
        mode = 1
        local gx,gy
        local target = self.C.skillTarget or self.C.attackTarget
        if not target then
            return
        end
        local viewInfo = target.battleViewInfo or (self.C.battleMap:getSoldierBattleViewInfoReal(target))
        t = self.C.actSkillParams.t
        local gx,gy = viewInfo[1],viewInfo[2]
        local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
        local check = self.C:checkPointInBuild(gridInfo)
        if check then
            gx,gy = check[2],check[3]
        end
        self.noResetFrame = true
        self:spmoveDirect(gx,gy,10)
        self.scene.replay:addDelay(function()
            self.noResetFrame = nil
            callback()
            BuffUtil.setBuff(self.C,{lastedTime=0.5, bfDizziness=0.5})
        end,self.allActionTime)
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastFourEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=t, allActionTime = self.allActionTime},callback)
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
    self.exeAtkFrame = 2
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastFourEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--距离敌方8格内，撞向敌方，使敌方及其周围半径4格内的敌人受到[a]+[c]%攻击力的伤害，并眩晕[t]秒。技能冷却时间[z]秒
function C:sg_ppexeSkill(target)
    local searchSkillTarget
    function searchSkillTarget()
        local tG = self:getMinDisTarget(1,8)
        if tG[1] then
            self.skillTarget = tG[1]
            self.isSkillAttack = true
            self.isSkillNotAttack = true
        else
            self.scene.replay:addDelay(function()
                searchSkillTarget()
            end,0.1)
        end
    end
    searchSkillTarget()
end

function C:exeSkillForGodBeast(target)
    local ps = self.actSkillParams
    local a,c,t = ps.a,ps.c,ps.t
    self.attackTarget = self.skillTarget or self
    local result = self:getCircleTarget(self.attackTarget,self.battleMap.battlerAll,4)
    for i,v in ipairs(result) do
        BuffUtil.setBuff(v,{lastedTime = t, bfDizziness = t})
        SkillPlugin.exe2(self,v,a,c)
    end
end

BeastFourEffect=class()

function BeastFourEffect:ctor(params,callback)
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

function BeastFourEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastFourEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode =self.attacker.scene.delayNode
    self.speed = params.speed or 600
    self.target = params.target or params.attacker.C.attackTarget
    self.total=params.total
    self.allActionTime = params.allActionTime
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

function BeastFourEffect:initEffect()
    if self.mode==0 then
        self:initAttack()
    elseif self.mode==1 then
        self:initSkill()
    elseif self.mode==2 then
        self:initCurrency()
    end
end
--技能通用
function BeastFourEffect:initCurrency()
local setting={{50,17},{92,71},{29,125},{-29,125},{-92,71},{-50,17}}
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
        effectManager:addEffect("views2_delay0",upNode)
        temp=views.Common_00000_11
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
        temp=views.Common_00000_11_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

    local function delayFrameIndex_20()
        effectManager:addEffect("views2_delay20",upNode)
        temp=views.Glow_16_13
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end

function BeastFourEffect:initAttack()
    self.time=0.3
    local setting={{59,-90},{144,-5},{80,109},{-80,109},{-144,-5},{-59,-90}}
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
    upNode:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    local function delayFrameIndex_19()
        effectManager:addEffect("views1_delay19",upNode)
        temp=views.Sparkless_00000_2
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",2/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
        temp=views.Sparkless_00000_1
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",2/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
        temp=views.Sparkless_00000_2_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",2/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
        temp=views.Sparkless_00000_1_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",2/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
        temp=views.Glow_16_5
        temp:setPosition(0,0)
        temp:setLocalZOrder(5)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,8.0,8.0}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",6/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_19}}))
end

function BeastFourEffect:initSkill()
    local setting={{62,-51,45},{115,26,0},{64,105,-45},{-64,105,-135},{-115,26,180},{-62,-51,135}}
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local delayNode =self.delayNode
    local views=self.views
    local direction=self.direction
    local baseScal=self.baseScal
    local initPos={}
    initPos[1]=0
    initPos[2]=0
    initPos[3]=0

    local r=setting[direction][3]
    local temp

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+100)
    moveNode:setScale(baseScal)

        local function showTargetBao()
            self:initSkill_bao()
        end
        moveNode:setRotation(r)
        moveNode:runAction(ui.action.sequence({{"delay",self.allActionTime},{"call",showTargetBao},"remove"}))
        local dir=direction
        if direction>3 then
        dir=7-direction
        end
        if dir==1 then
            effectManager:addEffect("views2_delay34_person1",moveNode)
            temp=views.Person_Blur_1
        elseif dir==2 then
            effectManager:addEffect("views2_delay34_person2",moveNode)
            temp=views.Person_Blur_2
        elseif dir==3 then
            effectManager:addEffect("views2_delay34_person3",moveNode)
            temp=views.Person_Blur_3
        end
        if direction>3 then
            temp:setFlippedX(true)
        end
        temp:setPosition(0,0)
        temp:setLocalZOrder(0)
        temp:setRotation(-r)

        effectManager:addEffect("views2_delay34",moveNode)
        temp=views.Particle_1_0_0
        temp:setLocalZOrder(1)
        temp=views.bb_2_0_0
        temp:setLocalZOrder(2)
        --temp:setRotation(-90+r)
        
        temp=views.Fire_00000_18
        temp:setLocalZOrder(3)
        --temp:setRotation(-90+r)
        temp=views.Fire_00000_18_0
        temp:setLocalZOrder(4)
        --temp:setRotation(-90+r)
        
        temp=views.Particle_2
        temp:setLocalZOrder(0)
        --temp:setRotation(-90+r)
        temp=views.Particle_5
        temp:setLocalZOrder(0)
        --temp:setRotation(-90+r)
end
--技能受击
function BeastFourEffect:initSkill_bao()
    local effectManager=self.effectManager
    local bg=self.targetView
    local delayNode=bg
    local views=self.views
    local direction=self.direction
    local baseScal=self.baseScal
    local initPos=self.offTargetPos
    local total=self.total
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+1)
    upNode:setScale(baseScal)
    upNode:runAction(ui.action.sequence({{"delay",29/60},"remove"}))

    local function delayFrameIndex_56()
        effectManager:addEffect("views3_delay56",upNode)
        temp=views.Impact_00000_20
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",3/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
        temp=views.Glow_01_21
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",3/60,3.0,3.0}}))
        temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",3/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
        temp=views.Sparkless_00000_22
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",3/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
        temp=views.Shockwave_23
        temp:setPosition(0,0)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.8,1.35},{"scaleTo",3/60,2.3,1.725}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",3/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
        temp=views.Glow_01_24
        temp:setPosition(0,0)
        temp:setLocalZOrder(5)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",8/60,3.0,3.0}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"fadeTo",8/60,216},{"fadeTo",15/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
    end
    delayFrameIndex_56()

    -- local function delayFrameIndex_59()
    --     effectManager:addEffect("views3_delay59",upNode)
    --     temp=views.Vertigo_00000_25
    --     temp:setPosition(0,60)
    --     temp:setLocalZOrder(1)
    --     temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",total-6/60},{"fadeTo",5/60,0}}))
    --     temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    -- end
    -- upNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_59}}))
end

function BeastFourEffect:update(diff)
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
