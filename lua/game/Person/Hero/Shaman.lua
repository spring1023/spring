

local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    ShamanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end



local C = class(AvtControler)

function C:onInitRebirth(target)
    local ps = self:getExtSkillData()
    self.M.range = (self.M.range or 0) + (self.M.range_bak or self.M.range or 0) * (ps.e)/100
    local newNode = ui.node()
    self.V.view:addChild(newNode)
    GameEvent.bindEvent(newNode, "BattleDeath", self, self.Rebirthcallback)
end

--4021    萨满      4031    主动技能37  复活己方最新死亡的英雄，复活后的英雄的血量为最大值血量的c%，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    if #self.battleMap2.diedHero>0 then
        self.isSkillAttack = true
        self.isSkillNotAttack = true
    end
end

function C:sg_exeSkill()
    local c = self.actSkillParams.c
    local dh = self.battleMap2.diedHero
    local target = dh[#dh]
    if not target then
        return
    end
    self.battleMap2:removeObj(dh, target, "_dhid")
    local newHero = target:normalRebirth(target.avater.gx, target.avater.gy, false, 3)
    local maxHp = newHero.avtInfo.maxHp
    newHero:damage(maxHp - maxHp * c / 100)
    local px, py = newHero.map.convertToPosition(target.avater.gx, target.avater.gy)
    local pos = {px, py+target.avater.animaConfig.Ymove}
    ShamanEffect.new({attacker = self.avater, mode = 2, target = self,pos = pos})
end

--天神技 复活[x]%数量的当前死去佣兵，复活佣兵受到伤害减少[y]%，复活时间[t]秒。并随机恢复己方[a]个英雄的天神技。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local dm = self.battleMap2.diedMer
    local num = math.ceil(#dm*ps.x/100)
    for i=1,num do
        local target = dm[#dm]
        self.battleMap2:removeObj(dm, target, "_dmid")
        local params = target.params
        local role = PersonUtil.C(params)
        role:addToScene(self.scene,target.avater.gx,target.avater.gy)
        role.params.isRebirth = true
        BuffUtil.setBuff(role,{lastedTime = ps.t,canLive = ps.t, bfDefPct=ps.y})
    end

    local released = {}--已释放天神技的友方英雄及其位置
    for i,v in ipairs(self.battleMap2.hero) do
        if v and v.releasedGodSkill and v.releasedGodSkill~=self.sid then
            table.insert(released,v)
        end
    end
    local maxId = #released
    for i=1, maxId do
        local j = self.rd:randomInt(maxId)
        released[i], released[j] = released[j], released[i]
    end
    local a = #released<ps.a and #released or ps.a
    for i=1, a do
        released[i].releasedGodSkill = nil
        released[i].avater.finishSkill = nil
    end
end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    ShamanEffect.new({attacker = self, mode = 4, target = attackTarget},callback)
end

--英雄出战时，增加离子塔[x]%攻击力，[y]%血量。每攻击[t]秒后还能打出[z]%自身攻击力的伤害，并减少目标攻击力，移动与攻击速度[o]%,持续[k]秒。
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
            if v.bid == 28 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.atk = v.M.atk*(1+ps.x/100)
                BuffUtil.setBuff(v,{ps = ps},"ShamanGodSkill2")
            end
        end
    end
end

--自身射程增加e%，且死亡后，f%概率立即复活一名死去友方英雄，回复其c%的生命值，友方英雄死亡时，有d%的概率减少主动技能冷却时间n秒。
local function _doAfterDie(self)
    local ps = self:getExtSkillData()
    local dh = self.battleMap2.diedHero
    self.M.range = (self.M.range or 0) + (self.M.range_bak or self.M.range or 0) * (ps.e)/100
    local target = dh[self.rd:randomInt(#dh)]
    if not target then
        return
    end
    self.battleMap2:removeObj(dh, target, "_dhid")
    if self.rd:randomInt(100) <= ps.f  and target.sid ~= self.sid then
        local newHero = target:normalRebirth(target.avater.gx, target.avater.gy, false, 3)
        local maxHp = newHero.avtInfo.maxHp
        newHero:damage(maxHp - maxHp * ps.c / 100)
        local px, py = newHero.map.convertToPosition(target.avater.gx, target.avater.gy)
        local pos = {px, py+target.avater.animaConfig.Ymove}
        ShamanEffect.new({attacker = self.avater, mode = 2, target = self, pos = pos})
    end
end

-- @brief 通用添加逻辑组件的方法
function C:onInitComponents()
    if not self.params.isZhaoHuan then
        LGBT.addComponentFunc(self, "afterDie", _doAfterDie)
    end
end

function C:Rebirthcallback(event, params)
    if self.deleted then
        return
    end
    local diedHero = params
    if diedHero.sid >= 1000 and diedHero.group == self.group and not diedHero.params.isZhaoHuan then
        local ps = self:getExtSkillData()
        if self.coldTime and self.rd:randomInt(100) <= ps.d then
            self.coldTime = self.coldTime - ps.n
            if self.coldTime <= 0 then
               self.coldTime = 0
            end
        end
    end
end

ShamanEffect = class()

function ShamanEffect:ctor(params,callback)
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

function ShamanEffect:initParams(params)
    self.effectManager=GameEffect.new("ShamanEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.pos = params.pos


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

function ShamanEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:targetEffect()
    elseif self.mode==4 then
        self.time = 0.5
        self:createViews_1()
        self:createViews_2()
        self:createViews_3()
        self:createViews_4()
    end
end

function ShamanEffect:initAttack()
    self.time = 0.1
    local setting={{75,141},{55,196},{-17,215},{17,215},{-55,196},{-75,141}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos

    local initPos2={}
    initPos2[1]=(initPos[1]+targetPos[1])/2
    initPos2[2]=(initPos[2]+targetPos[2])/2
    initPos2[3]=initPos[3]
    local lenth=math.sqrt((initPos[1]-targetPos[1])^2+(initPos[2]-targetPos[2])^2)
    local r=math.deg(math.atan2(initPos[1]-targetPos[1], initPos[2]-targetPos[2]))
    r = r-90
    local temp

    local function delayFrameIndex_24()
    effectManager:addEffect("views3_delay24",bg)
    temp=views.Lightning_Hue50_00000_31_111
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+10002)
    temp:setScaleX(lenth/250)
    temp:setRotation(r)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    temp=views.Lightning_Hue50_00000_31_0_111
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+10003)
    temp:setScaleX(lenth/250)
    temp:setRotation(r)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))

    temp=views.Flare_Hue50_00000_33_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",3/60,1.2,1.2}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    temp=views.Glow_01_7_0_0_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.5,1.5},{"scaleTo",9/60,0.3,0.3},{"scaleTo",1/60,0.2,0.2}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    temp=views.Glow_01_7_1_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.0,1.0},{"scaleTo",9/60,0.2,0.2},{"scaleTo",1/60,0.2,0.2}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",11/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))

    temp=views.Glow_01_7_0_0_111
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+6)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.5,1.5},{"scaleTo",9/60,0.3,0.3},{"scaleTo",1/60,0.2,0.2}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    temp=views.Glow_01_7_1_111
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+7)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.0,1.0},{"scaleTo",9/60,0.2,0.2},{"scaleTo",1/60,0.2,0.2}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",11/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    end
    delayFrameIndex_24()

    local function delayFrameIndex_28()
    effectManager:addEffect("views3_delay28",bg)
    temp=views.b_35_111
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,1.0,1.0},{"scaleTo",3/60,0.5,0.5},{"scaleTo",3/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",8/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
    temp=views.b_35_0_111
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+5)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,1.0,1.0},{"scaleTo",3/60,0.5,0.5},{"scaleTo",3/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,153},{"fadeTo",8/60,255},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_28}}))

end

function ShamanEffect:initSkill()
    self.time = 0.1
    local setting={{75,151},{55,206},{-17,225},{17,225},{-55,206},{-75,151}}
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local bg2=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.initPos
    local initPos2={}
    initPos2[1]=initPos[1]+setting[direction][1]
    initPos2[2]=initPos[2]+setting[direction][2]
    initPos2[3]=initPos[3]
    initPos = {0,0,0}

    local temp
    local function delayFrameIndex_65()
    effectManager:addEffect("views1_delay65",bg)
    temp=views.Glow_01_2_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",130/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",145/60},"remove"}))
    temp=views.Glow_01_2_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",130/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",145/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_65}}))

    local function delayFrameIndex_40()
    effectManager:addEffect("views1_delay40",bg)
    temp=views.Glow_01_14_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-3)
    temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,1.8,1.35}}))
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",50/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
    end
    delayFrameIndex_40()

    local function delayFrameIndex_54()
    effectManager:addEffect("views1_delay54",bg)
    temp=views.Circle_Hue130_15_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.4,0.3},{"scaleTo",5/60,0.6,0.45}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))

    effectManager:addEffect("views1_delay54_2",bg2)
    temp=views.Cast_00000_5_111
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
    temp=views.Glow_01_7_111
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+5)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,3.0,3.0},{"scaleTo",10/60,0.5,0.5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",21/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
    temp=views.Glow_01_7_0_111
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+6)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,3.0,3.0},{"scaleTo",10/60,0.5,0.5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))

    temp=views.Cross_00000_11_111
    temp:setPosition(initPos[1],initPos[2]+80)
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",25/60,0,58}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Cross_00000_11_0_111
    temp:setPosition(initPos[1],initPos[2]+80)
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",25/60,0,58}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Line_00000_19_111
    temp:setPosition(initPos[1],initPos[2]+40)
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",40/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",42/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_54}}))

    local function delayFrameIndex_56()
    effectManager:addEffect("views1_delay56",bg)
    temp=views.Circle_Hue130_15_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.4,0.3},{"scaleTo",5/60,0.6,0.45}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",16/60},{"call",delayFrameIndex_56}}))
end

function ShamanEffect:targetEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={self.pos[1],self.pos[2],0}
   local temp

   local function delayFrameIndex_65()
     effectManager:addEffect("views2_delay65",bg)
      temp=views.Circle_Hue130_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1,0.75}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.Glow_01_2_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
      temp=views.Glow_01_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_65}}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views2_delay59",bg)
      temp=views.Relive_00000_18
      temp:setPosition(initPos[1],initPos[2]+40)
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",36/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   end
   delayFrameIndex_59()

   local function delayFrameIndex_94()
     effectManager:addEffect("views2_delay94",bg)
      temp=views.Line_00000_19_0
      temp:setPosition(initPos[1],initPos[2]+40)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",95/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",97/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_94}}))

end


--脚底
function ShamanEffect:createViews_1()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local views=self.views
   local direction=self.direction
   local initPos={0,0,0}
   local temp

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

      local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",230/60},"remove"}))

   local function delayFrameIndex_40()
     effectManager:addEffect("godSkill_views1_delay40",downNode)
      temp=views.Glow_01_14
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_54()
     effectManager:addEffect("godSkill_views1_delay54",downNode)
      temp=views.Circle_Hue130_15
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.4,0.3},{"scaleTo",5/60,0.6,0.45}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))

    effectManager:addEffect("godSkill_views1_delay54_up",upNode)
      temp=views.Line_00000_19
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",135/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",137/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",54/60},{"call",delayFrameIndex_54}}))

   local function delayFrameIndex_56()
     effectManager:addEffect("godSkill_views1_delay56",downNode)
      temp=views.Circle_Hue130_15_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.4,0.3},{"scaleTo",5/60,0.6,0.45}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",56/60},{"call",delayFrameIndex_56}}))

    local function delayFrameIndex_65()
     effectManager:addEffect("godSkill_views1_delay65",upNode)
      temp=views.Glow_01_2_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
      temp=views.Glow_01_2
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",65/60},{"call",delayFrameIndex_65}}))

end
--虚影
function ShamanEffect:createViews_2()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]+150
   initPos[3]=self.initPos[3]
   local temp

    local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   downNode:setScale(1.3)
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("godSkill_views2_delay0",downNode)
      temp=views.Guihun_00_5
      temp:runAction(ui.action.sequence({{"scaleTo",15/60,11,12},{"scaleTo",35/60,12,13},{"delay",33/60},{"scaleTo",3/60,10.67,14},{"scaleTo",10/60,0,18}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",60/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",95/60},"remove"}))
      temp=views.Guihun_00_5_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",25/60,15,17}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,195},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   delayFrameIndex_0()

   local function delayFrameIndex_9()
     effectManager:addEffect("godSkill_views2_delay9",downNode)
      temp=views.Smoke_00000_14
      temp:runAction(ui.action.sequence({{"fadeTo",11/60,76},{"delay",35/60},{"fadeTo",11/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}}))

   local function delayFrameIndex_34()
     effectManager:addEffect("godSkill_views2_delay34",downNode)
      temp=views.Smoke_00000_14_0
      temp:runAction(ui.action.sequence({{"fadeTo",26/60,76},{"delay",20/60},{"fadeTo",11/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_34}}))

end

function ShamanEffect:createViews_3()
  local setting={{55,127},{34,158},{-23,166},{23,166},{-34,158},{-55,127}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",230/60},"remove"}))

   local function delayFrameIndex_54()
     effectManager:addEffect("godSkill_views3_delay54",upNode)
      temp=views.Cast_00000_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
      temp=views.Glow_01_7
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,3.0,3.0},{"scaleTo",10/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",11/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
      temp=views.Glow_01_7_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,3.5,3.5},{"scaleTo",10/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
   end
   delayFrameIndex_54()
end

function ShamanEffect:createViews_4()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",230/60},"remove"}))


   local function delayFrameIndex_54()
     effectManager:addEffect("godSkill_views4_delay54",upNode)
      temp=views.Siwang0000_1
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",34/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",47/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",54/60},{"call",delayFrameIndex_54}}))

   local function delayFrameIndex_65()
     effectManager:addEffect("godSkill_views4_delay65",upNode)
      temp=views.Glow_01_2_0_d
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,177},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
      temp=views.Glow_01_2_d
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",110/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",125/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",65/60},{"call",delayFrameIndex_65}}))

   local function delayFrameIndex_84()
     effectManager:addEffect("godSkill_views4_delay84",upNode)
      temp=views.Relive_00000_18
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",36/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",84/60},{"call",delayFrameIndex_84}}))

   local function delayFrameIndex_90()
     effectManager:addEffect("godSkill_views4_delay90",upNode)
      temp=views.Circle_Hue130_1
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",90/60},{"call",delayFrameIndex_90}}))

   local function delayFrameIndex_124()
     effectManager:addEffect("godSkill_views4_delay124",upNode)
      temp=views.Line_00000_19_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",95/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",97/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",124/60},{"call",delayFrameIndex_124}}))
end



function ShamanEffect:update(diff)
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




























