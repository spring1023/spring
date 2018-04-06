local BBEffect = class()

function BBEffect:ctor(params)
    if params.attacker.deleted then
        return
    end
    self.scene = GMethod.loadScript("game.View.Scene")
    self:initParams(params)
    self:initEffect()
end

function BBEffect:initParams(params)
    self.baseEffect = GameEffect.new("Equipment3Effect.json")
    self.views=self.baseEffect.views
    self.attacker = params.attacker
    self.viewsNode = self.attacker.blood
    self.delayNode=self.scene.delayNode
    self.totalTime = params.t
end

function BBEffect:initEffect()
    local bg = self.viewsNode
    local x,y,z=bg:getContentSize().width/2,-40,0
    local upNode=ui.node()
    upNode:setPosition(x,y)
    bg:addChild(upNode,z+1)
    self:addAnimate(upNode)
    local rNode=self:rotaNode(80,80/60,360)
    rNode:setPosition(0,120)
    upNode:addChild(rNode)
end

function BBEffect:update(diff)
    self.sr=self.sr+diff*self.angle/self.time
    local radian=math.rad(self.sr)
    self.rotaP1:setPosition(self.R*math.cos(radian),self.R*math.sin(radian))
    radian=math.rad(self.sr+180)
    self.rotaP2:setPosition(self.R*math.cos(radian),self.R*math.sin(radian))
end

function BBEffect:rotaNode(R,t,angle)
    local rNode=ui.node()
    self.baseEffect:addEffect("twoRotaParticle",rNode)
    self.rotaP1=self.views.Particle_2
    self.rotaP2=self.views.Particle_2_Copy
    local sr=30  --起始角度
    self.sr=sr
    self.time=t
    self.R=R
    self.angle=angle
    self.rotaP1:setPositionType(cc.POSITION_TYPE_RELATIVE)
    self.rotaP2:setPositionType(cc.POSITION_TYPE_RELATIVE)
    local blendFunc = {}
        blendFunc.src = gl.ONE
        blendFunc.dst = gl.ONE_MINUS_SRC_ALPHA
        self.rotaP1:setBlendFunc(blendFunc)
        self.rotaP2:setBlendFunc(blendFunc)
    local radian=math.rad(sr)
    self.rotaP1:setPosition(R*math.cos(radian),R*math.sin(radian))
    radian=math.rad(sr+180)
    self.rotaP2:setPosition(R*math.cos(radian),R*math.sin(radian))
    RegTimeUpdate(rNode, Handler(self.update, self), 0.05)
    rNode:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    return rNode
end
function BBEffect:addAnimate(upNode)
    local bg=self.viewsNode
    local temp
    local views = self.views
    self.baseEffect:addEffect("upViews2",upNode)
    temp=self.views.Glow_01_1_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",55/60},{"fadeTo",5/60,100},{"fadeTo",20/60,0}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",55/60},{"scaleTo",25/60,1.2,1.2},{"scaleTo",0/60,0.1,0.1}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=self.views.Glow_01
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",55/60},{"scaleTo",25/60,2.3,2.3},{"scaleTo",0/60,1,1}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",55/60},{"fadeTo",15/60,255},{"fadeTo",10/60,0}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    -- temp=self.views.Glow_01_0
    -- temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",40/60,0,10},{"moveBy",40/60,0,-10}})))
    -- temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=self.views.Glow_01_0_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",40/60,0,10},{"moveBy",40/60,0,-10}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=self.views.Particle_1
    --temp:setBlendFunc(blendFunc)
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=self.views.Particle_1_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",40/60,0,10},{"moveBy",40/60,0,-10}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))

    temp=views.Glow_01_2
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"scaleTo",25/60,2.3,2.3},{"scaleTo",0/60,1,1},{"delay",40/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"fadeTo",15/60,255},{"fadeTo",10/60,0},{"delay",40/60}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Glow_01_1_1
    temp:runAction(ui.action.sequence({{"delay",15/60},{"scaleTo",5/60,1.0,1.0},{"scaleTo",25/60,1.2,1.2},{"scaleTo",0/60,0.1,0.1},{"delay",35/60}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},{"fadeTo",5/60,255},{"fadeTo",25/60,0},{"delay",35/60}}))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Glow_01_1_0_0
    temp:runAction(ui.action.sequence({{"delay",15/60},{"scaleTo",5/60,0.5,0.5},{"scaleTo",25/60,0.8,0.8},{"scaleTo",0/60,0.1,0.1},{"delay",35/60}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},{"fadeTo",5/60,255},{"fadeTo",25/60,0},{"delay",35/60}}))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Circle_R_00000_3_1
    temp:runAction(ui.action.sequence({{"delay",15/60},{"scaleTo",5/60,0.4,0.4},{"scaleTo",15/60,0.8,0.8},{"scaleTo",0/60,0.1,0.1},{"delay",45/60}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},{"fadeTo",5/60,255},{"fadeTo",15/60,0},{"delay",45/60}}))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Circle_R_00000_3_0_0
    temp:runAction(ui.action.sequence({{"delay",15/60},{"scaleTo",5/60,0.4,0.4},{"scaleTo",15/60,0.8,0.8},{"scaleTo",0/60,0.1,0.1},{"delay",45/60}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},{"fadeTo",5/60,255},{"fadeTo",15/60,0},{"delay",45/60}}))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))

    temp=views.Death0000
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",40/60,0,10},{"moveBy",40/60,0,-10}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Death0000_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",40/60,0,10},{"moveBy",40/60,0,-10}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Particle_1_0_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",40/60,0,10},{"moveBy",40/60,0,-10}})))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Glow_01_1
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",55/60},{"scaleTo",5/60,1.0,1.0},{"scaleTo",10/60,1.2,1.2},{"scaleTo",0/60,0.1,0.1},{"delay",10/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",55/60},{"fadeTo",5/60,255},{"fadeTo",10/60,0},{"delay",10/60}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",self.totalTime},"remove"})))
    temp=views.Circle_R_00000_3
    temp:runAction(ui.action.sequence({{"delay",55/60},{"scaleTo",5/60,0.4,0.4},{"scaleTo",15/60,0.8,0.8},{"scaleTo",0/60,0.1,0.1},{"delay",5/60}}))
    temp:runAction(ui.action.sequence({{"delay",55/60},{"fadeTo",5/60,255},{"fadeTo",15/60,0},{"delay",5/60}}))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
    temp=views.Circle_R_00000_3_0
    temp:runAction(ui.action.sequence({{"delay",55/60},{"scaleTo",5/60,0.4,0.4},{"scaleTo",15/60,0.8,0.8},{"scaleTo",0/60,0.1,0.1},{"delay",5/60}}))
    temp:runAction(ui.action.sequence({{"delay",55/60},{"fadeTo",5/60,255},{"fadeTo",15/60,0},{"delay",5/60}}))
    temp:runAction(ui.action.sequence({{"delay",self.totalTime},"remove"}))
end


--[[血光之书 可在战斗中积累杀气，每杀死1个敌方单位获得1层杀气，
杀死敌方英雄获得20层杀气,每层杀气可提升英雄m点攻击力。最多积攒100层。
当杀气积攒满时，该英雄伤害提升a%，移动速度提升b%，受到的伤害减少c%，
持续t秒。此外该英雄携带法师佣兵进入战斗时，
每个法师佣兵为其积攒1层初始杀气。]]--
local BloodBook = class()

function BloodBook:ctor(hero)
    self.hero = hero
    self.killGas = 0
    self.baseGas = 0
    local equip = hero.person.equip
    if equip and equip.id == 2003 and not hero.params.isZhaoHuan then
        self.haveEquip = true
    end
    if self.haveEquip then
        local bg = hero.V.blood
        self.bg=bg
        if not bg then
            return
        end
        self.eicon = GameUI.addBattleEquipIcon(bg,equip,bg:getContentSize().width/2,50)
        if self.hero.state ~= 4 then      -- 4是Operation状态
            self:inintProgressBar(bg,hero)
        end
    end
end

function BloodBook:initKillGas(value)
    value=value or 0
    local hero = self.hero
    if hero.deleted then
        return
    end
    local equip = hero.person.equip
    self.baseGas = self.baseGas+value
    local m = equip.params.m
    hero.M.atk = hero.M.atk+m*value
    self.killGas = self.baseGas
    if not tolua.isnull(self.progressCharge) then
        self.progressCharge:setPercentage(100-self.baseGas)
    end
end

function BloodBook:exe(target)
    local hero = self.hero
    if not self.haveEquip or hero.deleted then
        return
    end
    self.bloodFury=hero.allBuff.bloodFury
    if self.bloodFury then
        return
    end
    local equip = hero.person.equip
    local eps = equip.params
    local m,t,a,b,c = eps.m,eps.t,eps.a,eps.b,eps.c

    local addNum
    if type(target) == "number" then
        addNum = target
    elseif target.sid and target.sid>1000 then
        addNum=20
    else
        addNum=4
    end

    self.killGas = self.killGas+addNum
    if self.killGas>100 then self.killGas=100 end
    hero.M.atk = hero.M.atk+m*addNum
    self:updateProgressBar(self.killGas,t)
    if self.killGas>=100 then
        local d=(100-self.baseGas)*m
        local buff = {
            lastedTime = t,
            bfHurt = a,
            bfMovePct = b,
            bfDefPct = c,
            bfAtkAdd=d
        }
        BuffUtil.setBuff(hero,buff,"bloodFury")
        self.killGas=self.baseGas
        hero.M.atk = hero.M.atk-d
        BBEffect.new({attacker = hero.V,t=t})
    end
end
--==============================--
--desc:装备特效进度条初始化
--time:2018-01-09 16:34:48
--author:aoyue
--@args:parentNode hero
--@return nil
--==============================--
function BloodBook:inintProgressBar(bg,hero)
    local sp = ui.scale9("images/equipProRed.png", 0, {85, 85})
    local progressCharge=cc.ProgressTimer:create(sp)
    display.adapt(progressCharge,bg:getContentSize().width/2+bg._ox,bg._oy+50,GConst.Anchor.Center)
    bg:addChild(progressCharge,51)
    progressCharge:setReverseDirection(true)
    self.progressCharge=progressCharge
    self.progressCharge:setPercentage(100)
    self.bloodFury=false     --新增加血怒状态
    local baseGas=0
    if hero.person.soldierId == 400 then         --霹雳火
        baseGas = hero.person.soldierNum
    end
    self:initKillGas(baseGas)
    local sp = ui.scale9("images/equipProGreen.png", 0, {85, 85})
    local progressCharged=cc.ProgressTimer:create(sp)
    display.adapt(progressCharged,bg:getContentSize().width/2+bg._ox,bg._oy+50,GConst.Anchor.Center)
    bg:addChild(progressCharged,51)
    progressCharged:setReverseDirection(true)
    self.progressCharged=progressCharged
    self.progressCharged:setPercentage(100)
    self.progressCharged:setVisible(false)
end
--==============================--
--desc:装备特效进度条状态更新
--time:2018-01-09 16:37:02
--@args:killGas t
--@return nil
--==============================--
function BloodBook:updateProgressBar(killGas,t)
    local function onEffectFinished()
        self.progressCharged:setVisible(false)
        self.progressCharge:setPercentage(100)
    end
    if tolua.isnull(self.progressCharge) or tolua.isnull(self.progressCharged) then
        return
    end
    self.progressCharged:setVisible(false)
    self.progressCharge:setPercentage(100-killGas)
    if killGas>=100 then
        self.progressCharge:setPercentage(0)
        self.progressCharged:setVisible(true)
        self.progressCharged:setPercentage(100)
        local action=cc.ProgressTo:create(t,0)
        self.progressCharged:runAction(ui.action.sequence{action,{"call",onEffectFinished}})
    end
  
    local function onEffectFinished()
        self.progressCharged:setVisible(false)
        self.progressCharge:setPercentage(self.baseGas)
    end
end
return BloodBook
