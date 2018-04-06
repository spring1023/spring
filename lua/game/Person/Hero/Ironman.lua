local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        local n = self.C.actSkillParams.n
        local fenshengPoint = {}
        for i=1,n do
            table.insert(fenshengPoint,{self.C:getRandomGrid(2)})
        end
        self.fenshengPoint = fenshengPoint
    end
    IronmanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end

local C = class(AvtControler)

--4018    钢铁侠   主动技能34  在自身3格内范围制造n个分身，血量继承c%，攻击继承d%，持续y秒，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local ps = self.actSkillParams
    local n,c,d = ps.n,ps.c,ps.d
    for i=1,n do
        local pos = self.V.fenshengPoint[i]
        local role = SkillPlugin.summonTroop(self.params.person, self.params.group,pos[1], pos[2],
            {atkPercent = d, hpPercent = c, summonTime = ps.y, master = self, isFenShen = true})
        --普通分身效果
        self.V:addFenShenEff(role.V)
    end
end

--当进攻方每次投放英雄时都会在其附近诞生一个机械分身，分身拥有本体[x]%的血量和[y]%的攻击力。杀死分身的敌方降低[z]%攻击力，并在[t]秒内总共掉血[o]%。(最多降低[a]血量。)
local function _doUpdateGod2(self, diff)
    if self.deleted then
        return
    end
    if self:checkGodSkill2(true) then
        if not self.isAddedHero then
            self.isAddedHero = {}
        end
        local group = self.battleMap.hero
        for k,v in pairs(group) do
            if not v.params.isZhaoHuan and not v.params.isRebirth then
                if not self.isAddedHero[v] then
                    local ps = self.person.awakeData2.ps
                    self.isAddedHero[v] = true
                    local gx, gy = v:getRandomGrid(2)
                    local function callback()
                        local role = SkillPlugin.summonTroop(self.params.person, self.params.group, gx, gy,
                            {atkPercent = ps.y, hpPercent = ps.x, master = self, isFenShen = true})
                        role.M.beKill = {lastedTime=ps.t, bfAtkPct=-ps.z, lastAddHp={-ps.o,-ps.a}}
                        --分身亮光
                        self.V:addFenShenEff(role.V)
                    end
                    IronmanEffect.new({attacker = v.V, mode = 2, target = v, point={gx,gy}},callback)
                end
            end
        end
    end
end

-- @brief 通用添加逻辑组件的方法
function C:onInitComponentsDelay()
    if not self.params.isZhaoHuan and self:checkGodSkill2(true) then
        LGBT.addComponentFunc(self, "updateComponent", _doUpdateGod2)
    end
end

--天神技 恢复自身血量的[x]%，召唤一个分身拥有本体[y]%血量与[z]%攻击力。给予所有分身自身半径[n]格光环BUFF，在光环范围内增加[o]%分身攻击力与攻击速度，每[t]秒减少敌人[p]%血(最多为[a]血量每个敌人)。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

-- 专属技 免疫debuff, 永久生效所以
function C:initForGodBeast()
    if not self.params.isZhaoHuan then
        BuffUtil.setBuff(self, {lastedTime=1000, allTime=0}, "ctEffectBuff")
    end
end

-- @brief 天神技分身的光环效果
local function _doUpdateGod1(self, diff)
    local ps = self.person.awakeData.ps
    if not self.forGodSkillTime then
        self.forGodSkillTime = 0
    end
    self.forGodSkillTime = self.forGodSkillTime+diff
    if self.forGodSkillTime >= 1 then
        self.forGodSkillTime = 0
        local ret = self:getCircleTarget(self, self.battleMap.hero, ps.n)
        for k,v in pairs(ret) do
            if v.sid == self.sid and v.params.isZhaoHuan then
                BuffUtil.setBuff(v, {lastedTime=1, bfAtkSpeedPct=ps.o, bfAtkPct=ps.o})
            end
        end
    end

    if not self.forGodSkillTime2 then
        self.forGodSkillTime2 = 0.5
    end
    self.forGodSkillTime2 = self.forGodSkillTime2+diff
    if self.forGodSkillTime2>=0.5 then
        self.forGodSkillTime2 = 0
        local ret = self:getCircleTarget(self,self.battleMap.battlerAll,ps.n)
        for k,v in ipairs(ret) do
            local buff = v.allBuff.IronmanGodSkill
            if buff then
                if buff.efTime >= ps.t then
                    v.allBuff.IronmanGodSkill = nil
                    local value = v.M.base_hp*ps.p/100
                    value = value>ps.a and ps.a or value
                    SkillPlugin.exe2(self,v,value)
                else
                    buff.allTime = 0
                    buff.efTime = buff.efTime+0.5
                end
            else
                BuffUtil.setBuff(v,{lastedTime=0.6, efTime=0},"IronmanGodSkill")
            end
        end
    end
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    --回血
    local value = self.M.base_hp*ps.x/100
    SkillPlugin.exe7(self,self,value)

    --召唤
    local gx = self.V.fenshengPointGod[1][1]
    local gy = self.V.fenshengPointGod[1][2]
    local role = SkillPlugin.summonTroop(self.params.person, self.params.group, gx, gy,
        {atkPercent = ps.z, hpPercent = ps.y, master = self, isFenShen = true, isGodZhaoHuan = true})
    LGBT.addComponentFunc(role, "updateComponent", _doUpdateGod1)
    IronmanEffect.new({attacker = role.V, mode = 3, target = role})
    --普通分身效果
    self.V:addFenShenEff(role.V)
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    self.fenshengPointGod = {{self.C:getRandomGrid(2)}}
    IronmanEffect.new({attacker = self, mode = 1, target = attackTarget,fenshengPointGod=self.fenshengPointGod},callback)
end

IronmanEffect = class()

function IronmanEffect:ctor(params,callback)
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

function IronmanEffect:initParams(params)
    self.effectManager=GameEffect.new("IronmanEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.point = params.point
    self.fenshengPointGod = params.fenshengPointGod

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

function IronmanEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self.time = 110/60
        self:targetEffect(self.point)
    elseif self.mode == 3 then
        self:initGodSkill()
    end
end

function IronmanEffect:initAttack()
    local setting={{4,22},{88,71},{71,135},{-71,135},{-88,71},{-4,22}}
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

    local targetPos= self.targetPos
    --旋转
    local moveX=self.targetPos[1]-initPos[1]
    local moveY=self.targetPos[2]-initPos[2]


    --时间
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime

    local temp

    local function showBao()
        effectManager:addEffect("views3_delay34",bg)
        temp=views.Glow_01_5
        temp:setPosition(targetPos[1],targetPos[2])
        temp:setLocalZOrder(targetPos[3]+6)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.5}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",19/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
        temp=views.Glow_01_5_0
        temp:setPosition(targetPos[1],targetPos[2])
        temp:setLocalZOrder(targetPos[3]+7)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,195},{"fadeTo",19/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    end

    local function delayFrameIndex_9()
        effectManager:addEffect("views3_delay9_a",bg)
        temp=views.Glow_01_1
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+1)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",moveTime-1/60,1,1}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-11/60},{"fadeTo",10/60,0},"remove"}))
        temp=views.Glow_01_1_0
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+2)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",moveTime-1/60,0.4,0.4}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-11/60},{"fadeTo",10/60,0},"remove"}))
        local moveNode=ui.node()
        moveNode:setPosition(initPos[1],initPos[2])
        moveNode:setLocalZOrder(initPos[3]+10000)
        moveNode:setScale(1.2)
        bg:addChild(moveNode)
        moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
        moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",showBao},"remove"}))

        effectManager:addEffect("views3_delay9",bg)
        temp=views.Particle_1_0
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+10003)
        temp:setScale(1.62)
        temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
        temp:runAction(ui.action.moveBy(moveTime,moveX,moveY))
        temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
        temp=views.Particle_1
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+10004)
        temp:setScale(1.2)
        temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
        temp:runAction(ui.action.moveBy(moveTime,moveX,moveY))
        temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
        temp=views.Particle_1_1
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+10005)
        temp:setScale(1.2)
        temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
        temp:runAction(ui.action.moveBy(moveTime,moveX,moveY))
        temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
    end
    delayFrameIndex_9()
end

function IronmanEffect:initSkill()
    self.time = 110/60
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.initPos
    local temp

    local function delayFrameIndex_35()
    local rNode=ui.node()
    rNode:setPosition(initPos[1],initPos[2])
    rNode:setLocalZOrder(initPos[3]-1)
    bg:addChild(rNode)
    rNode:setScaleX(1)
    rNode:setScaleY(3/4)
    rNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    effectManager:addEffect("views1_delay35_r",rNode)
    temp=views.Sprite_57
    temp:setPosition(0,0)
    temp:setLocalZOrder(0)
    temp:runAction(ui.action.rotateBy(150/60,360))
    temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",10/60,0.9,0.9},{"delay",10/60},{"scaleTo",10/60,0.7,0.7}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    effectManager:addEffect("views1_delay35",bg)
    temp=views.Glow_01_51
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-6)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Glow_01_51_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-5)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0
    temp:setPosition(initPos[1]+20,initPos[2]-40)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,103},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0_0
    temp:setPosition(initPos[1]+20,initPos[2]-40)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,127},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0_1
    temp:setPosition(initPos[1]-20,initPos[2]-40)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,103},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0_0_0
    temp:setPosition(initPos[1]-20,initPos[2]-40)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,127},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    end
    delayFrameIndex_35()


    local fenshengPoint = self.fenshengPointGod or self.attacker.fenshengPoint
    for i=1,#fenshengPoint do
        self:targetEffect(fenshengPoint[i])
    end
end

function IronmanEffect:targetEffect(point)
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local x,y = self.attacker.scene.map.convertToPosition(point[1],point[2])
    local initPos={x,y,100000}
    initPos[2] = initPos[2]+self.attacker.animaConfig.Ymove-8
    initPos[1] = initPos[1]+35
    local temp

    --847,-236
    local function delayFrameIndex_35()
    effectManager:addEffect("views2_delay35",bg)
    temp=views.person_Body
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+0)
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",60/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",85/60},"remove"}))
    temp=views.Glow_01_51
    temp:setPosition(initPos[1]-36,initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+22)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Glow_01_51_1
    temp:setPosition(initPos[1]-36,initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+23)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_35}}))

    local function delayFrameIndex_45()
    effectManager:addEffect("views2_delay45",bg)
    temp=views.Rightleg
    temp:setPosition(initPos[1]-30,initPos[2]-94)
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"delay",20/60},{"moveBy",10/60,23,84},{"moveBy",3/60,-2,-5},{"moveBy",3/60,2,5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"delay",58/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",75/60},"remove"}))
    temp=views.Sprite_44_0_2

    temp:setAnchorPoint(0.5,1)
    temp:setPosition(initPos[1]-60,initPos[2]+600)
    temp:setLocalZOrder(initPos[3]+24)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,103},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0_0_2

    temp:setAnchorPoint(0.5,1)
    temp:setPosition(initPos[1]-60,initPos[2]+600)
    temp:setLocalZOrder(initPos[3]+25)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0_1_2

    temp:setAnchorPoint(0.5,1)
    temp:setPosition(initPos[1]-20,initPos[2]+600)
    temp:setLocalZOrder(initPos[3]+26)
    temp:runAction(ui.action.sequence({{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,103},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Sprite_44_0_0_0_2

    temp:setAnchorPoint(0.5,1)
    temp:setPosition(initPos[1]-20,initPos[2]+600)
    temp:setLocalZOrder(initPos[3]+27)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,1.6}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,127},{"delay",10/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",45/60},{"call",delayFrameIndex_45}}))
    local function delayFrameIndex_50()
    effectManager:addEffect("views2_delay50",bg)
    temp=views.Leftleg
    temp:setPosition(initPos[1]+30,initPos[2]-85)
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",20/60},{"moveBy",10/60,-22,81},{"moveBy",3/60,2,-8},{"moveBy",3/60,-2,8}}))
    temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"delay",53/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",70/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",50/60},{"call",delayFrameIndex_50}}))
    local function delayFrameIndex_55()
    effectManager:addEffect("views2_delay55",bg)
    temp=views.Righthand
    temp:setPosition(initPos[1]+746-847,initPos[2]-218+236)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",20/60},{"moveBy",10/60,97,-3},{"moveBy",3/60,-6,0},{"moveBy",3/60,6,0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"delay",48/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",55/60},{"call",delayFrameIndex_55}}))
    local function delayFrameIndex_60()
    effectManager:addEffect("views2_delay60",bg)
    temp=views.Lefthand
    temp:setPosition(initPos[1]+938-847,initPos[2]-218+236)
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"delay",20/60},{"moveBy",10/60,-89,2},{"moveBy",3/60,5,0},{"moveBy",3/60,-5,0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"delay",43/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))
    local function delayFrameIndex_65()
    effectManager:addEffect("views2_delay65",bg)
    temp=views.Head
    temp:setPosition(initPos[1]+847-847,initPos[2]-148+236)
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"delay",20/60},{"moveBy",10/60,0,-79},{"moveBy",3/60,0,5},{"moveBy",3/60,0,-5}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"delay",38/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",65/60},{"call",delayFrameIndex_65}}))
    local function delayFrameIndex_74()
    effectManager:addEffect("views2_delay74",bg)
    temp=views.Glow_01_20
    temp:setPosition(initPos[1]+797-847,initPos[2]-195+236)
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_20_1
    temp:setPosition(initPos[1]+797-847,initPos[2]-195+236)
    temp:setLocalZOrder(initPos[3]+12)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",74/60},{"call",delayFrameIndex_74}}))
    local function delayFrameIndex_79()
    effectManager:addEffect("views2_delay79",bg)
    temp=views.Glow_01_20_0
    temp:setPosition(initPos[1]+829-847,initPos[2]-195+236)
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_20_0_1
    temp:setPosition(initPos[1]+829-847,initPos[2]-195+236)
    temp:setLocalZOrder(initPos[3]+13)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",79/60},{"call",delayFrameIndex_79}}))
    local function delayFrameIndex_84()
    effectManager:addEffect("views2_delay84",bg)
    temp=views.Glow_01_20_0_0
    temp:setPosition(initPos[1]+788-847,initPos[2]-135+236)
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_20_0_0_1
    temp:setPosition(initPos[1]+788-847,initPos[2]-135+236)
    temp:setLocalZOrder(initPos[3]+14)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",84/60},{"call",delayFrameIndex_84}}))
    local function delayFrameIndex_89()
    effectManager:addEffect("views2_delay89",bg)
    temp=views.Glow_01_20_0_0_0
    temp:setPosition(initPos[1]+832-847,initPos[2]-133+236)
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_20_0_0_0_1
    temp:setPosition(initPos[1]+832-847,initPos[2]-133+236)
    temp:setLocalZOrder(initPos[3]+15)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",89/60},{"call",delayFrameIndex_89}}))
    local function delayFrameIndex_94()
    effectManager:addEffect("views2_delay94",bg)
    temp=views.Glow_01_20_0_0_0_0
    temp:setPosition(initPos[1]+809-847,initPos[2]-157+236)
    temp:setLocalZOrder(initPos[3]+11)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_20_0_0_0_0_0
    temp:setPosition(initPos[1]+809-847,initPos[2]-157+236)
    temp:setLocalZOrder(initPos[3]+16)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",94/60},{"call",delayFrameIndex_94}}))





    local function delayFrameIndex_52()
    effectManager:addEffect("views2_delay52",bg)
    temp=views.Lightning_00000_14
    temp:setPosition(initPos[1]+779-847,initPos[2]-242+236)
    temp:setLocalZOrder(initPos[3]-4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",52/60},{"call",delayFrameIndex_52}}))
    local function delayFrameIndex_57()
    effectManager:addEffect("views2_delay57",bg)
    temp=views.Lightning_00000_14_0
    temp:setPosition(initPos[1]+842-847,initPos[2]-241+236)
    temp:setLocalZOrder(initPos[3]-3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",57/60},{"call",delayFrameIndex_57}}))

    local function delayFrameIndex_62()
    effectManager:addEffect("views2_delay62",bg)
    temp=views.Lightning_00000_14_0_0
    temp:setPosition(initPos[1]+740-847,initPos[2]-135+236)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",62/60},{"call",delayFrameIndex_62}}))
    local function delayFrameIndex_67()
    effectManager:addEffect("views2_delay67",bg)
    temp=views.Lightning_00000_14_0_0_0
    temp:setPosition(initPos[1]+876-847,initPos[2]-136+236)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",67/60},{"call",delayFrameIndex_67}}))
    local function delayFrameIndex_72()
    effectManager:addEffect("views2_delay72",bg)
    temp=views.Lightning_00000_14_0_0_0_0
    temp:setPosition(initPos[1]+813-847,initPos[2]-100+236)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",72/60},{"call",delayFrameIndex_72}}))

    local function delayFrameIndex_100()
    effectManager:addEffect("views2_delay100",bg)
    temp=views.Glow_01_34
    temp:setPosition(initPos[1]-36,initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+20)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Glow_01_34_0
    temp:setPosition(initPos[1]-36,initPos[2]+64)
    temp:setLocalZOrder(initPos[3]+21)
    temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",10/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",100/60},{"call",delayFrameIndex_100}}))
    local function delayFrameIndex_104()
    effectManager:addEffect("views2_delay104",bg)
    temp=views.Boom_00000_32
    temp:setPosition(initPos[1]-60,initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+17)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",21/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",104/60},{"call",delayFrameIndex_104}}))

    local function delayFrameIndex_110()
    --此时出现分身
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",110/60},{"call",delayFrameIndex_110}}))
end

function IronmanEffect:initGodSkill()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,100000}
    initPos[2] = initPos[2]+self.attacker.animaConfig.Ymove-8
    initPos[1] = initPos[1]
    local temp
    local total=100000

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+100000)

    initPos={0,0,0}
    local function delayFrameIndex_115()
      upNode:runAction(ui.action.sequence({{"delay",total+10/60},"remove"}))
      effectManager:addEffect("god_views4_delay115",upNode)
      local node = ui.node()
      node:setScaleX(0.5)
      node:setScaleY(0.375)
      node:setPosition(initPos[1], initPos[2])
      node:runAction(ui.action.action({"scaleTo", 15/60, 1.9, 1.5}))
      node:runAction(ui.action.sequence({{"delay",total},"remove"}))
      upNode:addChild(node, 1)

      temp = views.Dianquangu_00_31
      temp:setPosition(0, 0)
      temp:retain()
      temp:removeFromParent(false)
      node:addChild(temp)
      temp:release()
      temp:setScale(1.333)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.071},{"rotateBy", 0, 52}})))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,204},{"delay",total-30/60},{"fadeTo",15/60,0}}))

      temp = views.Dianquangu_00_31_0
      temp:setPosition(0, 0)
      temp:retain()
      temp:removeFromParent(false)
      node:addChild(temp)
      temp:release()
      temp:setScale(1.333)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.071},{"rotateBy", 0, 52}})))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,204},{"delay",total-30/60},{"fadeTo",15/60,0}}))

      temp=views.DIan_00000_1_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.action({"scaleTo",10/60,5.67,5.67}))
      temp:runAction(ui.action.arepeat(ui.action.sequence({
        {"fadeTo",10/60,255},{"fadeTo",2/60,0},{"delay",13/60},{"fadeTo",1/60,255},
        {"delay",6/60},{"fadeTo",1/60,0},
        {"delay",3/60},{"fadeTo",3/60,255},{"fadeTo",2/60,0},
        {"delay",6/60},{"fadeTo",2/60,255},{"fadeTo",3/60,0},
        {"delay",6/60},{"fadeTo",2/60,255},{"fadeTo",3/60,0},
        {"delay",5/60},{"fadeTo",3/60,255},{"fadeTo",2/60,0},
        {"delay",5/60},{"fadeTo",4/60,255},{"fadeTo",4/60,0},
        {"delay",3/60},{"fadeTo",3/60,255},
        {"delay",2/60},{"fadeTo",4/60,0},
        {"delay",2/60},{"fadeTo",3/60,255},{"fadeTo",2/60,0},
        {"delay",4/60},{"fadeTo",2/60,255},{"fadeTo",2/60,0},
        {"delay",4/60},{"fadeTo",3/60,255},{"fadeTo",2/60,0},
        {"delay",4/60},{"fadeTo",2/60,255},{"fadeTo",2/60,0},
        {"delay",1/60},{"fadeTo",2/60,127},{"fadeTo",2/60,0}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.DIanqn_00000_4
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,5,5.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.DIanqn_00000_4_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,5,5.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Glow_01_7
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,3.0,3.0},{"scaleTo",total-10/60,4.0,4.0}}))
      temp:runAction(ui.action.arepeat(ui.action.sequence({
        {"fadeTo",10/60,255},{"fadeTo",5/60,127},{"fadeTo",8/60,255},{"fadeTo",5/60,76},{"fadeTo",9/60,255},{"fadeTo",5/60,0},{"fadeTo",10/60,255},{"fadeTo",6/60,127},{"fadeTo",3/60,255},{"fadeTo",4/60,51},{"fadeTo",7/60,76},{"fadeTo",8/60,255},{"fadeTo",4/60,76},{"fadeTo",5/60,127},{"fadeTo",7/60,25},{"fadeTo",9/60,255},{"fadeTo",5/60,76},{"fadeTo",6/60,204},{"fadeTo",7/60,51},{"fadeTo",12/60,0}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))

      temp=views.Sprite_6
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"delay",1/60},{"fadeTo",1/60,255},{"fadeTo",1/60,0},{"delay",2/60},{"fadeTo",2/60,255},{"fadeTo",2/60,0},{"delay",3/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
      temp=views.Sprite_6_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"delay",1/60},{"fadeTo",1/60,255},{"fadeTo",1/60,0},{"delay",2/60},{"fadeTo",2/60,255},{"fadeTo",2/60,0},{"delay",3/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_115}}))
end

function IronmanEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target,true)
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end


return {M,V,C}































