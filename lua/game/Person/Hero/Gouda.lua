

local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    local y = self.C.actSkillParams.y
    local effect = GoudaEffect.new({attacker = self, mode = mode, target = attackTarget,lastedTime = y},callback)
    if mode == 1 then
        self.armorEffect1 = {effect,effect.delayNode,effect.hdNode1,effect.hdNode2}
    end
end


local C = class(AvtControler)

--4013    高达 自身出现一个可以吸收[c]%*自身最大血量的伤害的护盾，持续[y]秒。消失时造成自身g格半径范围内的敌人[a]+[d]%的伤害，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    if self.deleted then
        return
    end
    local params = self.actSkillParams
    local c,y = params.c,params.y
    self.M.nowHp2 = self.M.nowHp2+self.M.base_hp*c/100
    self.V:resetBlood()
    self.skillStateTime = y
    self.allSkillStateTime = 0
end

function C:sg_updateBattle(diff)
    if self.skillStateTime then
        self.allSkillStateTime = self.allSkillStateTime+diff
        if self.allSkillStateTime>= self.skillStateTime or self.M.nowHp2<=0 then
            self.skillStateTime = nil
            self.allSkillStateTime = nil
            self.musicTime = nil
            self:skillHurtOr()
            if self.V.animaConfig.skill_music3 then
                music.play("sounds/" .. self.V.animaConfig.skill_music3)
            end
        else
            if not self.musicTime then
                self.musicTime = 0
            end
            self.musicTime = self.musicTime+diff
            if self.musicTime>=1.8 then
                self.musicTime = 0
                if self.V.animaConfig.skill_music2 then
                    music.play("sounds/" .. self.V.animaConfig.skill_music2)
                end
            end
        end
    end
    --天神技
    if self.godSkillStateTime then
        self.allGodSkillStateTime = self.allGodSkillStateTime+diff
        if self.allGodSkillStateTime>=self.godSkillStateTime then
            self.godSkillStateTime = nil
            self.allGodSkillStateTime = nil
            for i,v in ipairs(self.battleMap2.hero) do
                if v.gd_godSkillTime then
                    v.gd_godSkillTime = nil
                    self:godSkillHurtOr(v)
                end
            end
        else
            for i,v in ipairs(self.battleMap2.hero) do
                if v.gd_godSkillTime then
                    if v.M.nowHp2<=0 then
                        v.gd_godSkillTime = nil
                        self:godSkillHurtOr(v)
                    end
                end
            end
        end
    end

    --当英雄防御时，指挥部增加[x]%防护罩血量，[y]%血量。当指挥部防护罩消失时，对敌方造成[z]%最大血量的伤害并眩晕敌人[t]秒。
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap.build
        end
        for k,v in pairs(group) do
            if v.bid == 1 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.nowHp2 = v.M.nowHp2*(1+ps.x/100)
                if v.M.nowHp2>0 then
                    BuffUtil.setBuff(v,{ps = ps},"GoudaGodSkill2")
                    local x,y = v:getCenterPoint()
                    local eft = ZhuchengBaozha.new(v.view,x,y)
                    v.forBaoZaEffect = eft.forBaoZaEffect
                    v:resetBlood()
                end
            end
        end
    end
end

function C:skillHurtOr()
    GoudaEffect.new({attacker = self.avater, mode = 2, target = self})
    local c = self.actSkillParams.c
    self.M.nowHp2 = self.M.nowHp2-self.M.base_hp*c/100
    if self.M.nowHp2<0 then
        self.M.nowHp2 = 0
        if self.assistHero4213Eft then
            self.assistHero4213Eft:removeFromParent(true)
            self.assistHero4213Eft = nil
        end
    end
    if self.V.armorEffect1 then
        for i,v in ipairs(self.V.armorEffect1) do
            if i == 1 then
                v.deleted = true
            else
                v:removeFromParent(true)
            end
        end
        self.V.armorEffect1 = nil
    end
    self.V:resetBlood()
    local params = self.actSkillParams
    local a,d = params.a,params.d
    local g = params.g
    local targetG = self:getCircleTarget(self,self.battleMap.battlerAll,g)
    for k,v in ipairs(targetG) do
        SkillPlugin.exe2(self,v,a,d)
    end
end

function C:godSkillHurtOr(v)
    local ps = self.person.awakeData.ps
    GoudaEffect.new({attacker = v.avater, mode = 2, target = v})
    v.M.nowHp2 = v.M.nowHp2-ps.a
    if v.M.nowHp2 <= 0 then
        v.M.nowHp2 = 0
        if v.assistHero4213Eft then
            v.assistHero4213Eft:removeFromParent(true)
            v.assistHero4213Eft = nil
        end
    end
    v.V:resetBlood()
    if v.armorEffect2 then
        for i,v in ipairs(v.armorEffect2) do
            if i == 1 then
                v.deleted = true
            else
                v:removeFromParent(true)
            end
        end
        v.armorEffect2 = nil
    end
    local targetG = v:getCircleTarget(v,v.battleMap.battlerAll,3)
    for k,v1 in ipairs(targetG) do
        SkillPlugin.exe2(v,v1,ps.b)
        BuffUtil.setBuff(v1,{lastedTime = ps.k,bfDizziness = ps.k})
    end
end
--天神技 在[t]秒内，为己方英雄开启一个能吸收[a]伤害的护盾。当护盾消失时对敌人造成[b]伤害，并且眩晕敌人[k]秒。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    for i,v in ipairs(self.battleMap2.hero) do
        v.M.nowHp2 = v.M.nowHp2+ps.a
        v.V:resetBlood()
        v.gd_godSkillTime = ps.t
        local effect = GoudaEffect.new({attacker = v.V, mode = 4, target = self,lastedTime = ps.t})
        v.armorEffect2 = {effect,effect.delayNode,effect.hdNode1}
    end
    self.allGodSkillStateTime = 0
    self.godSkillStateTime = ps.t
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    callback()
end


GoudaEffect = class()

function GoudaEffect:ctor(params,callback)
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

function GoudaEffect:initParams(params)
    self.effectManager=GameEffect.new("GoudaEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = ui.node()
    self.scene.delayNode:addChild(self.delayNode)
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

function GoudaEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:skillEnd()
    elseif self.mode == 4 then
        self:initGodSkill()
    end
end

function GoudaEffect:initAttack()
    self.time = 0.3
    local setting={{5,86,45},{59,100,0},{-38,112,-45},{38,112,-135},{-59,100,-180},{-55,86,135}}
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

    local attNode=ui.node()
    attNode:setPosition(initPos[1],initPos[2])
    bg:addChild(attNode,initPos[3]+10000)
    attNode:setRotation(r)
    attNode:runAction(ui.action.sequence({{"delay",1},"remove"}))
    local function delayFrameIndex_20()
    effectManager:addEffect("views2_delay20",attNode)
    temp=views.Flare_yellow_1_111
    temp:setRotation(-30)
    temp:setPosition(240,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",1/60,5.0,3.0},{"scaleTo",3/60,3.0,3.0},{"scaleTo",2/60,2.0,2.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
    temp=views.Glow_01_8_111
    temp:setPosition(240,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_20}}))

    local function delayFrameIndex_14()
    effectManager:addEffect("views2_delay14",attNode)
    temp=views.Gundam_Weapontrail_00000_16_111
    temp:setRotation(-45)
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    temp=views.Gundam_Weapontrail_00000_16_0_111
    temp:setRotation(-45)
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    end
    delayFrameIndex_14()
end

function GoudaEffect:initSkill()
    self.time = 0.3
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={0,0,0}
    local temp
    local tatol = self.lastedTime
    local upNode=ui.node()
    upNode:setPosition(0,0)
    bg:addChild(upNode,10)
    upNode:setScale(1.3)
    local downNode=ui.node()
    downNode:setPosition(0,0)
    bg:addChild(downNode,-10)
    downNode:setScale(1.3)
    self.hdNode1 = upNode
    self.hdNode2 = downNode

    local function delayFrameIndex_35()
    effectManager:addEffect("views1_delay35",upNode)
    temp=views.Glow_01_13_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+11)
    temp:runAction(ui.action.sequence({{"fadeTo",30/60,255},{"delay",tatol-45/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_35}}))

    local function delayFrameIndex_34()
    effectManager:addEffect("views1_delay34",downNode)
    temp=views.Glow_01_14
    temp:setPosition(initPos[1],initPos[2]+20)
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,207},{"fadeTo",tatol-2/60,204},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Particle_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    effectManager:addEffect("views1_delay34_up",upNode)
    temp=views.Shield_Glow_00000_3_0
    temp:setPosition(initPos[1],initPos[2]+60)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",31/60,127},{"delay",tatol-32/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Shield_Glow_00000_3
    temp:setPosition(initPos[1],initPos[2]+60)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",31/60,127},{"delay",tatol-32/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Gundam_Shield_1_0
    temp:setPosition(initPos[1],initPos[2]+60)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.arepeat( ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",10/60,51}})))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_34}}))
end

function GoudaEffect:skillEnd()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={0,0,0}
    local temp


    local function delayFrameIndex_139()
    effectManager:addEffect("views1_delay139",bg)
    temp=views.Gundam_Shield_Glow_00000_5_0_0
    temp:setPosition(initPos[1],initPos[2]+60)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
    temp=views.Gundam_Shield_Glow_00000_5_0
    temp:setPosition(initPos[1],initPos[2]+60)
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
    end
    delayFrameIndex_139()

    local function delayFrameIndex_159()
    effectManager:addEffect("views1_delay159",bg)
    temp=views.Shield_Breaking_00000_10_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,128},{"fadeTo",6/60,127},{"fadeTo",21/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
    temp=views.Shield_Breaking_00000_10
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",21/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
    temp=views.Circle_Hue130_14
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"fadeTo",5/60,128},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Circle_Hue130_14_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_13
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",5/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))

    temp=views.base_Glow_01_13_0_0
    temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+0)
      temp:runAction(ui.action.sequence({{"scaleTo",7/60,3.9333,2.7},{"scaleTo",8/60,5.0,3.5},{"scaleTo",15/60,5.0,3.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.SDA_00_5
    temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,3.5,2.45},{"scaleTo",18/60,5.0,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
    temp=views.SDA_00_5_0
    temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,3.5,2.45},{"scaleTo",18/60,5.0,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.Circle_Hue130_14
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+15)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"fadeTo",5/60,128},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Circle_Hue130_14_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+16)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Glow_01_13
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+17)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
      temp=views.Glow_01_13_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+18)
      temp:runAction(ui.action.sequence({{"scaleTo",15/60,5.0,5.0},{"delay",15/60}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Glow_01_13_0_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+19)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",30/60,5.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",2/60,255},{"fadeTo",29/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.QuanGuang_00001_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+20)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",17/60,5,4.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,204},{"delay",10/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",21/60},{"call",delayFrameIndex_159}}))
end

function GoudaEffect:initGodSkill()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local views=self.views
   local direction=self.direction
   local initPos={0,0,10}

   local total=self.lastedTime
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+70)
   upNode:setScale(1.5)
   bg:addChild(upNode,initPos[3]+10000)
   self.hdNode1 = upNode
   local function delayFrameIndex_34()
     effectManager:addEffect("godSkill_views1_delay34",upNode)
      temp=views.Glow_01_14
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,207},{"delay",total-2/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shield_Glow_00000_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",31/60,127},{"delay",total-32/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shield_Glow_00000_3
      temp:runAction(ui.action.sequence({{"fadeTo",31/60,127},{"delay",total-32/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Gundam_Shield_1_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",10/60,51}})))
      temp:runAction(ui.action.sequence({{"delay",total-13/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_35()
     effectManager:addEffect("godSkill_views1_delay35",upNode)
      temp=views.Glow_01_13_0
      temp:runAction(ui.action.sequence({{"delay",total-4/60},{"scaleTo",15/60,5.0,5.0},{"scaleTo",15/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",30/60,255},{"delay",total-19/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total+26/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_35}}))

   local function delayFrameIndex_40()
     effectManager:addEffect("godSkill_views1_delay40",upNode)
      temp=views.Particle_3
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,2.5,2.125}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_139()
     effectManager:addEffect("godSkill_views1_delay139",upNode)
      temp=views.Gundam_Shield_Glow_00000_5_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
      temp=views.Gundam_Shield_Glow_00000_5_0
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",total-20/60},{"call",delayFrameIndex_139}}))

   local function delayFrameIndex_159()
     effectManager:addEffect("godSkill_views1_delay159",upNode)
      temp=views.Shield_Breaking_00000_10_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,128},{"fadeTo",6/60,127},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Shield_Breaking_00000_10
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Circle_Hue130_14
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"fadeTo",5/60,128},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Circle_Hue130_14_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Glow_01_13
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))

      temp=views.base_Glow_01_13_0_0
      temp:runAction(ui.action.sequence({{"scaleTo",7/60,3.9333,2.7},{"scaleTo",8/60,5.0,3.5},{"scaleTo",15/60,5.0,3.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.SDA_00_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,3.5,2.45},{"scaleTo",18/60,5.0,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.SDA_00_5_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,3.5,2.45},{"scaleTo",18/60,5.0,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))

      temp=views.Circle_Hue130_14
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"fadeTo",5/60,128},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Circle_Hue130_14_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.125},{"scaleTo",5/60,1.8,1.35}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Glow_01_13
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
      temp=views.Glow_01_13_0
      temp:runAction(ui.action.sequence({{"delay",125/60},{"scaleTo",15/60,5.0,5.0},{"scaleTo",15/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",30/60,255},{"delay",110/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",155/60},"remove"}))
      temp=views.Glow_01_13_0_1
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",30/60,5.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",2/60,255},{"fadeTo",29/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.QuanGuang_00001_2
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",17/60,5,4.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,204},{"delay",10/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",total},{"call",delayFrameIndex_159}}))

    -- local function shwoBao( ... )
    --     --self:skillEnd()
    -- end
    -- self.delayNode:runAction(ui.action.sequence({{"delay",total},{"call",shwoBao}}))
end



function GoudaEffect:update(diff)
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




























