local TBEffect = class()

function TBEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
    end
end

function TBEffect:initParams(params)
    self.baseEffect=GameEffect.new("Equipment1Effect.json")
    self.views=self.baseEffect.views
    self.attacker = params.attacker
    self.viewsNode = self.scene.objs
    self.delayNode=self.scene.delayNode
    self.target = params.target
    self.equip = params.equip
    self.skillNum=params.skillNum
    self.isAddGroup=params.isAddGroup
    --起始点坐标
    if self.attacker.animaConfig then
        local x,y = 0,self.attacker.animaConfig.Ymove
        local p = {self.attacker.view:getPosition()}
        p[1] = p[1] + x
        p[2] = p[2] + y
        self.initPos = {p[1],p[2],General.sceneHeight - p[2]}
    else
        local view = self.attacker.view
        local height = view:getContentSize().height/2
        self.initPos = {view:getPositionX(),view:getPositionY() + height}
        self.initPos[3] = General.sceneHeight-self.initPos[2]
    end

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
    self.targetView=view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function TBEffect:initEffect()
    self.time = 15/60
    local x0,y0,z0=self.initPos[1],self.initPos[2],self.initPos[3]
    local upNode=ui.node()
    local temp
    upNode:setPosition(x0,y0)
    self.viewsNode:addChild(upNode,z0+1)
    self.baseEffect:addEffect("firstViews",upNode)
    upNode:runAction(ui.action.sequence({{"delay",25/50},"remove"}))
    temp=self.views.a_1
    temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.7,0.7},{"scaleTo",5/60,0.8,0.8},{"scaleTo",5/60,0.7,0.7},{"scaleTo",5/60,0.8,0.8},{"scaleTo",5/60,0.5,0.5}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},{"fadeTo",1/60,0},"remove"}))
    temp=self.views.a_2
    temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.7,0.7},{"scaleTo",5/60,0.8,0.8},{"scaleTo",5/60,0.7,0.7},{"scaleTo",5/60,0.8,0.8},{"scaleTo",5/60,0.5,0.5}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},{"fadeTo",1/60,0},"remove"}))
    temp=self.views.Glow
    temp:runAction(ui.action.sequence({{"fadeIn",1/60},{"delay",24/50},{"fadeOut",1/60},"remove"}))

    local x,y,z=self.targetPos[1],self.targetPos[2],self.targetPos[3]
    local upNode=ui.node()
    upNode:setPosition(x,y)
    self.viewsNode:addChild(upNode,z+1)
    self.baseEffect:addEffect("upViews",upNode)
    upNode:runAction(ui.action.sequence({{"delay",25/60,"remove"}}))
    local lightNode=ui.node()
    lightNode:setPosition((x0+x)/2,(y0+y)/2)
    self.viewsNode:addChild(lightNode,z+1)
    self.baseEffect:addEffect("lightViews",lightNode)
    lightNode:runAction(ui.action.sequence({{"delay",25/60,"remove"}}))
    local ox=x-x0
    local oy=y-y0
    local length=math.sqrt(ox*ox+oy*oy)
    local r=math.deg(math.atan2(oy, ox))
    lightNode:setScaleX(length/250)
    if length>=500 then
        lightNode:setScaleY(1.5)
    end
    lightNode:setRotation(-r)

    temp=self.views.Flare1
    temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.7,0.7},{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.7,0.7},{"scaleTo",10/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",5/60,0.4*255},{"fadeTo",5/60,0},{"fadeTo",5/60,0.4*255},{"fadeTo",5/60,0},"remove"}))
    temp=self.views.Lightning1
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    temp=self.views.Lightning2
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    temp=self.views.Electricity1
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    temp=self.views.Flare2
    temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.7,0.7},{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.7,0.7},{"scaleTo",10/60,0.3,0.3}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    temp=self.views.Electricity2
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    temp=self.views.Glow1
    temp:runAction(ui.action.sequence({{"fadeOut",25/60},"remove"}))
    temp=self.views.Glow2
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,0},"remove"}))
end

function TBEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
        --链式伤害
        local equip = self.equip
        local skillNum=self.skillNum

        skillNum = skillNum-1
        if skillNum>0 then
            if equip:searchAddTarget() then
                TBEffect.new({equip=equip, attacker = self.target.V or self.target, target = equip.skillTarget,
                              skillNum=skillNum,isAddGroup=self.isAddGroup},self.callback)
            else
                skillNum = nil
                self.isAddGroup = nil
            end
        else
            skillNum = nil
            self.isAddGroup = nil
        end

    end
end

local ThunderBlader = class()

--雷霆之刃  每5次攻击后，下一次攻击会释放闪电链，闪电链击中最多m名玩家，造成普通攻击a%的伤害。
function ThunderBlader:ctor(hero)
    self.hero = hero
    self.atkTimes = 0
    local equip = hero.params.person.equip
    if equip and equip.id == 2001 and not hero.params.isZhaoHuan then
        self.haveEquip = true
    end
    if self.haveEquip then
        local bg = hero.V.blood
        if not bg then
            return
        end
        GameUI.addBattleEquipIcon(bg,equip,bg:getContentSize().width/2,50)
        if self.hero.state ~= 4 then
            self:initProgressBar(bg,hero)
        end
    end
end

function ThunderBlader:exe()
    local hero = self.hero
    local equip = hero.params.person.equip
    if not self.haveEquip or hero.deleted then
        return
    end
    local eps = equip.params
    self.atkTimes = self.atkTimes+1
    self:updateProgressBar()
    if self.atkTimes>=5 then
        self.skillNum = eps.m-1
        self.atkTimes = 0
        self.isAddGroup = {}
        self.skillTarget = hero.attackTarget
        TBEffect.new({equip = self, attacker=hero.V, target=self.skillTarget,skillNum=self.skillNum},function(target)
            if not target.deleted then
                SkillPlugin.exe2(hero,target,0,eps.a)
            end
        end)
    end
end

function ThunderBlader:searchAddTarget(again)
    local V = self.hero.V
    local allBuilds = self.hero.battleMap.hero
    if again then
        allBuilds = self.hero.battleMap.battler
    end
    local sgx, sgy = V.gx,V.gy

    local target

    local minDs = 5.1^2
    if not next(self.isAddGroup) then
        minDs = 1000000
    end

    for i,v in ipairs(allBuilds) do
        if not self.isAddGroup[v] then
            local gx,gy = V.gx,V.gy
            local sk = self.skillTarget
            if sk then
                if sk.V then
                    gx,gy = sk.V.gx,sk.V.gy
                else
                    gx,gy = sk.battleViewInfo[1],sk.battleViewInfo[2]
                end
            end
            local ds
            ds = self.hero:getSoldierDistance(gx,gy,v)

            if ds < minDs then
                target = v
                minDs = ds
            end
        end
    end

    if target then
        self.skillTarget = target
        self.isAddGroup[target] = 1
        return true
    else
        if not again then
            return self:searchAddTarget(true)
        else
            return false
        end
    end
end
--==============================--
--desc:装备特效进度条初始化
--time:2018-01-09 18:00:19
--@args:bg hero
--@return nil
--==============================--
function ThunderBlader:initProgressBar(bg,hero)
    local sp = ui.scale9("images/equipProRed.png", 0, {85, 85})
    local progressCharge=cc.ProgressTimer:create(sp)
    display.adapt(progressCharge,bg:getContentSize().width/2+bg._ox,bg._oy+50,GConst.Anchor.Center)
    bg:addChild(progressCharge,51)
    progressCharge:setReverseDirection(true)
    self.progressCharge=progressCharge
    self.progressCharge:setPercentage(100)

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
--desc:装备特效进度更新
--time:2018-01-09 18:04:40
--@return 
--==============================--
function ThunderBlader:updateProgressBar()
    if tolua.isnull(self.progressCharge) then
        return
    end

    if self.atkTimes<4 then
        self.progressCharge:setPercentage(100-self.atkTimes*25)
    elseif self.atkTimes==4 then
        self.progressCharge:setVisible(false)
        self.progressCharged:setVisible(true)
    else
        self.progressCharge:setVisible(true)
        self.progressCharged:setVisible(false)
        self.progressCharge:setPercentage(100)
    end
end

return ThunderBlader




