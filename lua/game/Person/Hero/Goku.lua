local M = class(AvtInfo)


local V = {}

-- 把逻辑写在v里面有点龊吧……
function V:viewEffect(attackTarget,callback,isSkill)
    if isSkill then
        --隐藏本体
        local n = self.C.actSkillParams.n
        if not self.deleted then
            self.C:hideSelf(0.23*(n-1)+0.6, true)
        end
        -- 释放主动技，把计数和技能参数都传进去
        GokuEffect.new({attacker = self, mode = 1, target = attackTarget, _skillParams={count=0, marked={}, params=self.C.actSkillParams}}, callback)
    else
        GokuEffect.new({attacker = self, mode = 0, target = attackTarget}, callback)
    end
end


local C = class(AvtControler)

--4024    齐天大圣   主动技能40  对n名敌方单位造成a+c%*ATK的伤害，将其中距离最远的1个单位封印技能t秒，优先英雄，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true

    -- 技能机制小改一下，先找一个目标
    local target = self:getMinDisTarget(1,nil,self.battleMap.battler)[1]
    self.skillTarget = target
end

-- 把技能数值的执行挪到计算结果的时候去做
function C:sg_exeSkill(target,last)
    -- local params = self.actSkillParams
    -- local n,a,c,t = params.n,params.a,params.c,params.t
    -- if self.skillNum then
    --     self.skillNum = self.skillNum+1
    --     SkillPlugin.exe2(self,target,a,c)
    -- else
    --     SkillPlugin.exe2(self,target,a,c)
    --     if target.V then
    --         BuffUtil.setBuff(target,{lastedTime = t,bfSilent = t})
    --         GokuEffect.new({attacker = target.avater, mode = 2, target = self,lastedTime = t})
    --     end
    -- end
end

--天神技 [t]秒内，对自身半径[n]格范围内的敌人造成[a]+[x]%自身攻击力的伤害，并且自身无敌。封印全体敌人技能[k]秒，回复怒气[c]点。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    self.godSkillLastTime = (self.godSkillLastTime or 0)+1
    if self.godSkillLastTime<=ps.t then
        local ret = self:getCircleTarget(self,self.battleMap.battlerAll,ps.n)
        for k,v in ipairs(ret) do
            local value = ps.a+self.M.atk*ps.x/100
            value = value/ps.t
            SkillPlugin.exe2(self,v,value)
            GokuEffect.new({attacker = self.V, mode = 5, target = v})
            if self.godSkillLastTime == 1 then
                BuffUtil.setBuff(v,{lastedTime=ps.k, bfSilent=ps.k})
                if v.V then
                    GokuEffect.new({attacker = v.V, mode = 2, target = self,lastedTime = ps.k})
                end
                BuffUtil.setBuff(self,{lastedTime=ps.t, immune=ps.t})
            end
        end
        if self.godSkillLastTime == 1 then
            self.groupData.anger = self.groupData.anger+ps.c
        end
        self.scene.replay:addDelay(function()
            self:exeGodSkill()
        end,1)
    else
        self.godSkillLastTime = nil
    end
end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    local ps = self.C.person.awakeData.ps
    GokuEffect.new({attacker = self, mode = 4, target = attackTarget, lastedTime=ps.t})
    BuffUtil.setBuff(self.C,{lastedTime=ps.t, viewGhost={color={255,93,00}, blend={1,1}, scale=1.5}})
    self.allActionTime = self.allActionTime+ps.t
    self.scene.replay:addDelay(callback,0.3)
end

-- @brief 齐天大圣重生的代码
-- @details 死亡后，在英雄台上重生，重生后拥有原来[x]%的血量和攻击力，只能重生[d]次。
local function _doRebirth(self)
    -- 召唤物或已重生不能重复重生
    if self.isRebirthed then
        return
    end
    if self.person.awakeData2 and self.groupData.isDef and self.targetGrid then
        local ps = self.person.awakeData2.ps
        if (self.params.reBirthNum or 0) >= ps.d then
            return
        end
        self.params.reBirthNum = (self.params.reBirthNum or 0) + 1
        -- 通用复活逻辑
        local newSelf = self:normalRebirth(self.targetGrid[1], self.targetGrid[2], true, 1)
        -- 调整复活后生命值
        local maxHp = newSelf.avtInfo.maxHp
        newSelf:damage(maxHp - maxHp * ps.x / 100)
        -- 调整复活后攻击力
        newSelf.avtInfo.base_atk = newSelf.avtInfo.base_atk*ps.x/100
        newSelf.avtInfo.atk = newSelf.avtInfo.base_atk
    end
end

-- @brief 通用添加逻辑组件的方法
function C:onInitComponents()
    if not self.params.isZhaoHuan then
        LGBT.addComponentFunc(self, "beforeDie", _doRebirth)
    end
end

GokuEffect = class()

function GokuEffect:ctor(params,callback)
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

function GokuEffect:initParams(params)
    self.effectManager=GameEffect.new("GokuEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.lastedTime = params.lastedTime
    self._skillParams = params._skillParams
    --起始点坐标
    local x,y = 0, self.attacker.animaConfig.Ymove
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

function GokuEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:targetState()
    elseif self.mode == 3 then
        self:createViews_targetEffect()
    elseif self.mode == 4 then
        self:godSkill_target()
    elseif self.mode == 5 then
        self:godSkill_state()
    end
end

function GokuEffect:initAttack()
    self.time = 0
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.initPos
    local temp

    local setR={{0,0,-25},{0,0,-70},{30,40,-130},{-30,40,130},{0,0,70},{0,0,25}}
    local ox=setR[direction][1]
    local oy=setR[direction][2]
    local r=setR[direction][3]
    local function delayFrameIndex_19()
    effectManager:addEffect("views2_delay19",bg)
    temp=views.Weapontrail_00000_2
    temp:setRotation(r)
    if direction>3 then
    temp:setFlippedX(true)
    end
    temp:setPosition(initPos[1]+ox,initPos[2]+oy)
    temp:setLocalZOrder(initPos[3]+10000)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    delayFrameIndex_19()
end

function GokuEffect:initSkill()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.initPos
    local targetPos={}
    targetPos[1]=self.targetPos[1]
    targetPos[2]=self.targetPos[2]
    targetPos[3]=self.targetPos[3]+10000
    local temp

    local function delayFrameIndex_44()--攻击到特效
        effectManager:addEffect("views1_delay44",bg)
        temp=views.Flare_yellow_14
        temp:setPosition(targetPos[1],targetPos[2])
        temp:setLocalZOrder(targetPos[3]+9)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",3/60,8.0,2.0},{"scaleTo",2/60,5.0,1.25}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
        temp=views.Glow_01_15
        temp:setPosition(targetPos[1],targetPos[2])
        temp:setLocalZOrder(targetPos[3]+10)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",3/60,0.7,0.7}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    end

    local attDir={180,45,-135,135,-45}
    local attName={{"Monkey_King_skill2_",false},{"Monkey_King_skill1_",true},{"Monkey_King_skill3_",false},{"Monkey_King_skill1_",false},{"Monkey_King_skill3_",true},}
    local _skillParams = self._skillParams
    _skillParams.count = _skillParams.count + 1
    _skillParams.marked[self.target] = true
    local k = _skillParams.count
    local R = 500--以目标的半径
    local moveSpeed = 2200
    local moveTime = R/moveSpeed
    self.time = moveTime
    if k>5 then
        k = 1
    end
    if self.attacker.animaConfig["skill_music" .. 10+k] then
        music.play("sounds/" .. self.attacker.animaConfig["skill_music" .. 10+k])
    end
    local oR=attDir[k]
    local radR=oR/180*3.14
    local ox,oy=R*math.cos(radR),R*math.sin(radR)
    local attPos={targetPos[1]+ox,targetPos[2]+oy,targetPos[3]}

    local attNode=ui.node()
    attNode:setPosition(attPos[1],attPos[2])
    bg:addChild(attNode,attPos[3])
    attNode:setScale(1.2)
    attNode:runAction(ui.action.sequence({{"moveBy",moveTime,-ox,-oy},{"call",delayFrameIndex_44},{"moveBy",moveTime/4,-ox/4,-oy/4},"remove"}))
    local ops={63,102,140,178,216,255,126}
    local blend1={}
    blend1.src=1
    blend1.dst=771
    local blend2={}
    blend2.src=770
    blend2.dst=1
    local off={{20,0},{-20,-25},{20,25},{20,-25},{-20,25}}
    for i=1,7 do
        local temp = ui.animateSprite(moveTime*3/4,attName[k][1],2,{beginNum=0,plist="effects/effectsRes/Monkey_King_skill.plist",isRepeat=false})
        temp:setFlippedX(attName[k][2])
        temp:setAnchorPoint(0.5,0.44)
        if i<7 then
            temp:setPosition((i-1)*off[k][1],(i-1)*off[k][2])
        else
            temp:setPosition((5)*off[k][1],(5)*off[k][2])
        end
        attNode:addChild(temp)
        temp:setOpacity(ops[i])
        if i==7 then
            temp:setBlendFunc(blend2)
            temp:runAction(ui.action.sequence({{"delay",moveTime},{"fadeTo",10/60,0}}))
        else
            temp:setBlendFunc(blend1)
            temp:runAction(ui.action.sequence({{"delay",moveTime},{"fadeTo",10/60,0}}))
        end
    end
end

function GokuEffect:createViews_targetEffect()
    self.time = 20/60
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.targetPos
    local targetPos = {}
    targetPos[1] = self.targetPos[1]
    targetPos[2] = self.targetPos[2]
    targetPos[3] = 10000
    local temp

    effectManager:addEffect("views1_delay110",bg)
    temp=views.Monkey_King_60_00002_60
    temp:setPosition(targetPos[1]-203,targetPos[2]+416)
    temp:setLocalZOrder(targetPos[3]+11)
    temp:runAction(ui.action.sequence({{"delay",9/60},{"fadeTo",3/60,63},{"delay",8/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Monkey_King_60_00002_60_0
    temp:setPosition(targetPos[1]-197,targetPos[2]+391)
    temp:setLocalZOrder(targetPos[3]+12)
    temp:runAction(ui.action.sequence({{"delay",9/60},{"fadeTo",3/60,102},{"delay",8/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Monkey_King_60_00002_60_1
    temp:setPosition(targetPos[1]-188,targetPos[2]+366)
    temp:setLocalZOrder(targetPos[3]+13)
    temp:runAction(ui.action.sequence({{"delay",9/60},{"fadeTo",3/60,140},{"delay",8/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Monkey_King_60_00002_60_2
    temp:setPosition(targetPos[1]-180,targetPos[2]+337)
    temp:setLocalZOrder(targetPos[3]+14)
    temp:runAction(ui.action.sequence({{"delay",9/60},{"fadeTo",3/60,178},{"fadeTo",8/60,179},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Monkey_King_60_00002_60_3
    temp:setPosition(targetPos[1]-175,targetPos[2]+311)
    temp:setLocalZOrder(targetPos[3]+15)
    temp:runAction(ui.action.sequence({{"delay",9/60},{"fadeTo",3/60,216},{"fadeTo",8/60,217},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    temp=views.Monkey_King_60_00002_60_4
    temp:setPosition(targetPos[1]-166,targetPos[2]+285)
    temp:setLocalZOrder(targetPos[3]+16)
    temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    temp=views.Monkey_King_60_00002_60_4_0
    temp:setPosition(targetPos[1]-166,targetPos[2]+285)
    temp:setLocalZOrder(targetPos[3]+17)
    temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    if self.attacker.animaConfig.skill_music16 then
        music.play("sounds/" .. self.attacker.animaConfig.skill_music16)
    end

    local function delayFrameIndex_129()
    effectManager:addEffect("views1_delay129",bg)
    temp=views.Boom_80
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+18)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",3/60,1.08,1.08}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    temp=views.Boom_80_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+19)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",3/60,1.08,1.08}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",18/60},{"call",delayFrameIndex_129}}))

    local function delayFrameIndex_130()
    effectManager:addEffect("views1_delay130",bg)
    temp=views.Shockwave_77
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-3)
    temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",10/60,0.8,0.68},{"scaleTo",25/60,1.0,0.85}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",25/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))

    temp=views.Light_00002_84
    temp:setPosition(initPos[1],initPos[2]+300)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
    temp=views.Particle_1
    temp:setPosition(initPos[1],initPos[2]+29)
    temp:setLocalZOrder(initPos[3]+20)
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_130}}))


end

function GokuEffect:targetState()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,self.attacker.animaConfig.Ymove,0}
    local temp
    local tatol = self.lastedTime
    effectManager:addEffect("views1_delay134",bg)
    temp=views.Glow_01_87
    temp:setPosition(initPos[1],initPos[2]+151)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",tatol-16/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_87_0
    temp:setPosition(initPos[1],initPos[2]+151)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",tatol-16/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Lock
    temp:setPosition(initPos[1],initPos[2]+151)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",75/60},{"fadeTo",tatol-16/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
end

function GokuEffect:initGodSkill()

end
--爆炸伤害
function GokuEffect:godSkill_target()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.targetPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+100000)
    local total = self.lastedTime+1
    upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",function()
        self.lastedTime=self.lastedTime-30/60
        if self.lastedTime>0 then
            local gx = (math.random()-0.5)*4+self.attacker.gx
            local gy = (math.random()-0.5)*4+self.attacker.gy
            local x,y = self.scene.map.convertToPosition(gx,gy)
            self.targetPos = {x,y,self.targetPos[3]}
            self:godSkill_target()
        end
    end},{"delay",20/60},"remove"}))

    effectManager:addEffect("god_views3_delay24",upNode)
      temp=views.GF_472_9
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,5.0,5.0},{"scaleTo",36/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",11/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
      temp=views.Light_00000_10
      temp:setPosition(0,353)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",15/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Crack_14
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",2/60,255},{"delay",19/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.SDA_00_5
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",6/60},{"scaleTo",5/60,3.0,2.55},{"scaleTo",10/60,4.0,3.4}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",3/60,255},{"delay",16/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.C_00_1
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Shockwave_2
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,1.0,1.0},{"scaleTo",30/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_4
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",14/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.TESBaozha_00_6
      temp:setPosition(0,413)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
      temp=views.BaoZa_00_1
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
      temp=views.TESBaozha_00_6_0
      temp:setPosition(0,413)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
end
--持续锁
function GokuEffect:godSkill_state()
    local effectManager=self.effectManager
    local bg = self.target.V and self.target.V.view or self.target.view
    local views=self.views
    local initPos={0,self.attacker.animaConfig.Ymove,0}
    local temp
    local tatol = self.lastedTime

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode)

    upNode:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
    initPos={0,0,0}
    if self.target.V then
        initPos = {0,self.target.V.animaConfig.Ymove+40,0}
    else
        local x,y = self.target:getCenterPoint()
        initPos = {x,y,0}
    end
    effectManager:addEffect("god_views4_delay24",upNode)
      temp=views.BaoZa_00_5
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",21/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
      temp=views.BaoZa_00_5_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",21/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
end

function GokuEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.time = nil
        self.deleted = true
        local control = self.attacker.C

        -- 先把齐天大圣主动技的逻辑放到这里执行了
        local _skillParams = self._skillParams
        if _skillParams then
            local params = self.actSkillParams
            local ps = _skillParams.params
            local n, a, c, t = ps.n, ps.a, ps.c, ps.t
            if self.mode == 1 then
                SkillPlugin.exe2(control, self.target, a, c)
            elseif self.mode == 3 then
                SkillPlugin.exe2(control, self.target, a, c)
                -- 还没死
                if not self.target.deleted and self.target.avater then
                    BuffUtil.setBuff(self.target, {lastedTime = t, bfSilent = t})
                    GokuEffect.new({attacker = self.target.avater, mode = 2, target = control, lastedTime = t})
                end
            end
        end
        self.callback(self.target)
        self.scene.replay:removeUpdateObj(self)
        if self.mode == 1 then
            -- 主动技能
            local _useLast = false
            local params = self.actSkillParams
            local ps = _skillParams.params
            local nextTarget
            -- 最后一次攻击就不用追加了；理论上也不可能
            if _skillParams.count >= ps.n then
                return
            elseif _skillParams.count == ps.n - 1 then
                _useLast = true
            else
                local marked = _skillParams.marked
                -- 找寻去重的最近单位
                local minDis = 10000
                local minTarget = nil
                local minIsHero = false
                local tmpDis, isHero = 0, false
                local gx, gy = control.BV.gx, control.BV.gy
                for i, v in ipairs(control.battleMap.battler) do
                    if not marked[v] then
                        tmpDis = control:getSoldierDistance(gx, gy, v)
                        isHero = v.sid and v.sid>1000 or false
                        if (tmpDis < minDis and minIsHero==isHero) or (not minIsHero and isHero) then
                            minDis = tmpDis
                            minTarget = v
                            minIsHero = isHero
                        end
                    end
                end
                nextTarget = minTarget
            end
            -- 如果是最后一个，因为带封技所以优先找英雄（即使打过）
            if not nextTarget then
                _useLast = true
                nextTarget = control:getMaxDisTarget()
            end
            -- 万一没有目标就只能提前结束了……
            if not nextTarget then
                return
            end

            if _useLast then
                GokuEffect.new({attacker = self.attacker, mode = 3, target = nextTarget, _skillParams=_skillParams}, self.callback)
            else
                GokuEffect.new({attacker = self.attacker, mode = 1, target = nextTarget, _skillParams=_skillParams}, self.callback)
            end
        end
    end
end

return {M,V,C}
