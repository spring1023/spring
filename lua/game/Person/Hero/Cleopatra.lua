local M = class(AvtInfo)

local V = {}

function V:viewAttackSpecial(mode)
    if mode == 0 then
        CleopatraEffect.new({attacker = self, mode = -1})
    end
end

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        if isSkill then
            mode = 1
            local a = self.C.actSkillParams.a
            local n = self.C.actSkillParams.n
            local snakePoint = {}
            for i=1,n do
                local gx = (self.C.rd:random2()*2-1)*a/1.5+self.gx
                local gy = (self.C.rd:random2()*2-1)*a/1.5+self.gy
                local tx,ty = gx,gy
                table.insert(snakePoint,{tx,ty})
            end
            dump(snakePoint)
            self.snakePoint = snakePoint
        end
        attackTarget = nil
    end
    CleopatraEffect.new({attacker = self, mode = mode, target = attackTarget,},callback)
end

--埃及艳后专属技能 对异性英雄造成伤害增加[c]%，受到异性英雄的伤害减少[d]%
local C = class(AvtControler)
local LGBT = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local function _beforeAttack(attack, value, defence)
    local s1 = attack.avtInfo and attack.avtInfo.person.sex
    local s2 = defence.avtInfo and defence.avtInfo.person.sex
    if s1 and s2 and s1 ~= s2 then
        local extData = attack:getExtSkillData()
        value[1] = value[1] * (1 + extData.c/100)
    end
end

local function _beforeDefence(defence, value, attack)
    local s1 = attack.avtInfo and attack.avtInfo.person.sex
    local s2 = defence.avtInfo and defence.avtInfo.person.sex
    if s1 and s2 and s1 ~= s2 then
        local extData = defence:getExtSkillData()
        value[1] = value[1] * (1 - extData.d/100)
    end
end

-- 4030 专属技强化
function C:onInitComponents()
    LGBT.addComponentFunc(self, "beforeNormalAttack", _beforeAttack)
    LGBT.addComponentFunc(self, "beforeSkillAttack", _beforeAttack)
    LGBT.addComponentFunc(self, "beforeNormalDefence", _beforeAttack)
    LGBT.addComponentFunc(self, "beforeSkillDefence", _beforeAttack)
end

--4030    埃及艳后  主动技能   在自身[a]格范围内召唤[n]个火焰蛇（不可移动单位），火焰蛇头的攻击范围为[b]格，攻击和血量为召唤者的[c]%，存在[y]秒，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    -- local ps = self.actSkillParams
    -- local n,a,b,c = ps.n,ps.a,ps.b,ps.c
    -- for i=1,n do
    --     local params = clone(self.params,{scene = 1})--自身分身还要改
    --     params.index = nil
    --     params.isZhaoHuan = true
    --     params.pos = self.V.snakePoint[i]
    --     local role = PersonUtil.C(params)
    --     role.M.base_hp = role.M.base_hp*c/100
    --     role.M.maxHp = role.M.base_hp
    --     role.M.nowHp = role.M.maxHp
    --     role.M.base_atk = role.M.base_atk*c/100
    --     role.M.atk = role.M.base_atk
    --     role:addToScene(self.scene,params.pos[1],params.pos[2])
    --     role.master = self

    --     --TODO 火焰蛇头的攻击范围为[b]格
        
    --     --普通分身效果
    --     self.V:addFenShenEff(role.V)
    -- end




    --在自身[a]格范围内召唤[n]个火焰蛇（不可移动单位），火焰蛇头的攻击范围为[b]格，攻击和血量为召唤者的[c]%，存在[y]秒，消耗[x]怒，冷却时间[z]秒
    --每[a]秒在出战英雄周围3格范围内召唤一只猴兵，同时可存在[b]只，攻击力与生命值为出战英雄的[c]%
    -- local function newSnake()
    --     if self.scene.battleData.time and self.scene.battleData.state==0 then
    --         self.scene.replay:addDelay(newSnake,v.a)--每a秒
    --         return
    --     end
    --     if self.deleted then
    --         return
    --     end
    --     self.scene.replay:addDelay(newSnake,v.a)
    --     if not self.childNum2 then
    --         self.childNum2 = 0
    --     end
    --     if self.childNum2<v.b then
    --         self.childNum2 = self.childNum2+1
    --         local hero = heros[k]
    --         local role = PersonUtil.C({person=hero:getControlData(), state=AvtControlerState.BATTLE, group=self.group, isZhaoHuan = true})
    --         role.M.base_atk = self.M.base_atk*v.c/100
    --         role.M.atk = role.M.base_atk
    --         role.M.base_hp = self.M.base_hp*v.c/100
    --         role.M.maxHp = role.M.base_hp
    --         role.M.nowHp = role.M.maxHp
    --         local gx = self.avater.gx-3 + self.rd:random2()*6
    --         local gy = self.avater.gy-3 + self.rd:random2()*6
    --         local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
    --         local check = self:checkPointInBuild(gridInfo)
    --         if check then
    --             gx,gy = check[2],check[3]
    --         end
    --         role:addToScene(self.scene,gx,gy)
    --         --普通分身效果
    --         self.V:addFenShenEff(role.V)
    --     end
    -- end
    -- self.scene.replay:addDelay(newSnake,v.a)


    local ps = self.actSkillParams
    local n,a,b,c = ps.n,ps.a,ps.b,ps.c
    local sinfo = {aspeed = 1, autype = 3,dtype = 1,fav = 0,range = ps.b,speed = 0,utype = 1}
    local sdata = {atk = self.M.base_atk*ps.c/100, hp = self.M.base_hp*ps.c/100,num = 1}
    local person = PersonUtil.newPersonData(sinfo,sdata,{id=431, level=1})
    local newSnake = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=self.group})
    for i=1,ps.n do
        local pos = self.V.snakePoint[i]
        newSnake:addToScene(self.scene,pos[1],pos[2])
    end
    
    -- local gx, gy = self.avater.gx, self.avater.gy
    -- local function addSoldier()
    --     local newSnake = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=1})
    --     newSnake.flagShowAppear = true
    --     local ngx, ngy
    --     while true do
    --         ngx = gx + (self.rd:random2()-0.5)*a
    --         ngy = gy + (self.rd:random2()-0.5)*a
    --         if not self.scene.map.getGridObj(math.floor(ngx), math.floor(ngy)) then
    --             break
    --         end
    --     end
    --     local hero = self
    --     newSnake.masterHero = hero
    --     newSnake:addToScene(self.scene,ngx,ngy)
    --     newSnake.addTimeFlag = self.allTime
        
end

function C:sg_updateBattle(diff)
    --守护技 当英雄防御时，己方异性英雄伤害增加[x]%，防御增加[y]%
    if self.deleted then
        return
    end
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.hero
        for k,v in ipairs(group) do
            if v.avtInfo.person.sex ~= self.avtInfo.person.sex then
                BuffUtil.setBuff(v, {bfDefPct = ps.y, bfHurt=ps.x}, self)
            end
        end
    end
end

--天神技 开场[cd]秒后可释放，[x]%概率魅惑自身[n]格范围内至多[m]个英雄，持续[t]秒，魅惑失败时，使魅惑目标受到的伤害增加[y]%
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local eGroup = self.battleMap:getCircleTarget(self, self.battleMap.hero, ps.n)
    local bnum = 0
    for i,v in ipairs(eGroup) do
        if not v.deleted then
            bnum = bnum + 1
            if bnum <= ps.m then
                if v.rd:randomInt(100) <= ps.x then
                    BuffUtil.setBuff(v, {lastedTime = ps.t, isDebuff=true, bfChaos = 1, bfSilent = ps.t}, "chaos")
                else
                    BuffUtil.setBuff(v, {lastedTime = ps.t, bfDefPct = -ps.y})
                end
            end
        end
    end
end

function V:godSkillViewEffect(attackTarget, callback, skillLastTimeAll)
    CleopatraEffect.new({attacker = self, mode = 3}, callback)
end

--专属技 对异性英雄造成伤害增加[c]%，受到异性英雄的伤害减少[d]%
--特殊伤害是针对异性,放到BattleUtil.getHurt\BattleUtil.getSkillHurt中处理

CleopatraEffect = class()

function CleopatraEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    if self.scene.replay then
        if callback then
            self.scene.replay:addUpdateObj(self)
        end
    else
        RegUpdate(function(diff)
            self.updateMy(diff)
        end,0)
    end
end

function CleopatraEffect:initParams(params)
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    
    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight - p[2]}

    self.target = params.target or params.attacker.C.attackTarget
    if not self.target then
        return
    end
    self.point = params.point
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

function CleopatraEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 3 then
        self:initGodSkill()
    elseif self.mode == -1 then
        self:initAttack2()
    end
end

function CleopatraEffect:initAttack()
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
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
    local r=-math.deg(math.atan2(moveY,moveX))
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime
    local temp
    local direction=self.direction
    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setRotation(r)
    local function bao ()
        local temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/c_1.csb")
        display.adapt(temp, targetPos[1],targetPos[2], GConst.Anchor.Center)
        bg:addChild(temp,initPos[3]+10000)
        temp:runAction(ui.action.sequence({{"delay",0.4},"remove"}))
    end
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/b_1.csb")
    display.adapt(temp,0,0,GConst.Anchor.Center)
    moveNode:addChild(temp)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",bao},"remove"}))
    self.time = moveTime
end

function CleopatraEffect:initAttack2()
    -- local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]
    initPos[3]=self.initPos[3]
    local temp
    local direction=self.direction
    local a
    if direction == 1 or direction == 6 then
        a = 1
    elseif direction == 2 or direction == 5 then
        a = 2
    elseif direction == 3 or direction == 4 then
        a = 3 
    end
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/a_"..a..".csb")
    display.adapt(temp,initPos[1],initPos[2],GConst.Anchor.Center)
    temp:setScaleY(1)
    if direction > 3 then
        temp:setScaleX(-1)
    else
        temp:setScaleX(1)
    end
    bg:addChild(temp, initPos[3]+10000)
    temp:runAction(ui.action.sequence({{"delay",0.8},"remove"}))
end

function CleopatraEffect:initSkill()
    print("here.......")
    local bg=self.viewsNode
    local temp
    local direction=self.direction
    local a
    if direction == 1 or direction == 6 then
        a = 4
    elseif direction == 2 or direction == 5 then
        a = 5
    elseif direction == 3 or direction == 4 then
        a = 6
    end
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/a_"..a..".csb")
    display.adapt(temp,self.initPos[1],self.initPos[2],GConst.Anchor.Center)
    bg:addChild(temp,self.initPos[3]+10000)
    temp:setScaleY(1)
    if direction > 3 then
        temp:setScaleX(-1)
    else
        temp:setScaleX(1)
    end
    temp:runAction(ui.action.sequence({{"delay",1.5},"remove"}))
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/a_"..a.."_1.csb")
    display.adapt(temp,self.targetPos[1],self.targetPos[2],GConst.Anchor.Center)
    bg:addChild(temp,self.initPos[3]+10000)
    temp:runAction(ui.action.sequence({{"delay",1.5},"remove"}))
    self.time = 20/60
end

function CleopatraEffect:targetEffect(point)
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local x,y = self.attacker.scene.map.convertToPosition(point[1],point[2])
    local initPos={x,y,100000}
    initPos[2] = initPos[2]+self.attacker.animaConfig.Ymove-8
    initPos[1] = initPos[1]+35
    local temp

    --847,-236
    
end

function CleopatraEffect:initGodSkill()
    if true then
        self.time = 0.2
        return
    end
    local bg=self.viewsNode
    local temp
    temp = ui.csbNode("UICsb/HeroEffect_4030/a_7.csb")
    display.adapt(temp,1024,768,GConst.Anchor.Center)
    bg:addChild(temp)

    temp = ui.csbNode("UICsb/HeroEffect_4030/b_3.csb")
    display.adapt(temp,1024,768,GConst.Anchor.Center)
    bg:addChild(temp)

    temp = ui.csbNode("UICsb/HeroEffect_4030/c_3.csb")
    display.adapt(temp,1024,768,GConst.Anchor.Center)
    bg:addChild(temp)



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

end

function CleopatraEffect:update(diff)
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































