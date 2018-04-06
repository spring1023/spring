GMethod.loadScript("game.BulletAnimation")

FlyObject = class()

function FlyObject:ctor(attack, speed, x, y)
    self.attackValue = attack
    self.speed = speed
    self.initPos = {x, y}
end

function FlyObject:addToScene(scene)
    self.scene = scene
    if self.targetPos then
        self:initView()
        self.stateTime = 0
    end
end
SingleShot = class(FlyObject)

function SingleShot:ctor(attack, speed, x, y, z, target,level,callback)
    self.callback = callback
    self.target = target
    self.initZorder = z
    self:resetTargetPos()
    self.level=level
end

function SingleShot:resetTargetPos()
    if self.target.deleted then
        return
    end
    local view,height
    if self.target.avater then
        view = self.target.avater.view
        height = 40 + self.target.avater.personView:getPositionY()
        self.targetZ = 41 + self.target.avater.personView:getPositionY()+10000
    else
        view = self.target.vstate.view
        height = view:getContentSize().height/2
        self.targetZ = 0
    end
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.avater.view:getPositionY()
    end
end

function shotDamage(shot, target, attackValue)
    if shot.callback then
        if not shot.callback(target) then
            return
        end
    end

    local k = 1
    if shot.attacker and attackValue>0 and target.canFt then
        local ft = target:computeMirror()
        if ft>0 then
            target:showAttackValue(shot.attacker, attackValue*ft)
            shot.attacker:damage(attackValue*ft,shot.attacker)
            k = 1-ft
        end
    end
    target:damage(attackValue*k,shot.attacker)
end

function SingleShot:update(diff)
    diff = diff * (self.scene.speed or 1)
    local stateTime = self.stateTime + diff
    local state = self.state
    if stateTime >= self.time[state] then
        self.state = state+1
        stateTime = stateTime - self.time[state]
        if state==2 then
            if self.callback then
                self.callback()
                self.deleted = true
            else
                shotDamage(self, self.target, self.attackValue)
                self.deleted = true
            end
        end
        self.view:removeFromParent(true)
        self:resetView()
    end
    if self.state==2 then
        local delta = stateTime/self.time[2]
        self.view:setPosition(self.initPos[1] + (self.targetPos[1]-self.initPos[1])*delta, self.initPos[2] + (self.targetPos[2]-self.initPos[2])*delta)
    end
    self.stateTime = stateTime
end

function SingleShot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {0.5, distance*10/self.speed, 0.5}
    self.state = 1
    self:resetView()
end

--通用受击
AttackeffectShot=class(SingleShot)
function AttackeffectShot:ctor(attack, speed, x, y, z, target,level,attackmode,t,scal,callback)
    self.callback = callback
    self.attackmode=attackmode
    self.delyTime=t
    self.scal=scal
    self.attackeTarget=target
end
function AttackeffectShot:initView()
    if  self.target.deleted then
        return
    end
    local function creatBaoZha()
        if self.callback then
            if self.target then
                self.callback(self.target)
            end
        else
            shotDamage(self, self.target, self.attackValue) 
        end
        local x = self.targetPos[1] + math.random(-30, 30)
        local y = self.targetPos[2] + math.random(60)
        if self.attackmode==1 then
            local p=ui.sprite("effects/putonggongji2.png")
            p:setPosition(x,y)
            p:setAnchorPoint(0.5,0.5)
            self.scene.effects:addChild(p)
            p:setOpacity(0)
            p:setScale(self.scal-0.4)
            p:runAction(ui.action.scaleTo(0.15,2,2))
            p:runAction(ui.action.sequence({{"fadeIn",0.15},"remove"}))
        elseif self.attackmode==2 or self.attackmode==3 then
            local view = ui.animateSprite(0.67,"Pt_",8,{beginNum=0,plist="effects/heroRes/heroGenerelRes1.plist"})
            view:setScale(1)
            view:setOpacity(178)
            display.adapt(view, self.targetPos[1], self.targetPos[2],{0.5, 0.5})
            self.scene.effects:addChild(view)
            view:runAction(ui.action.sequence({{"delay",0.67},"remove"}))
        else

        end
    end

    self.attacker.scene.replay:addDelay(creatBaoZha, self.delyTime)

end

ArrowShot = class(SingleShot)

function ArrowShot:update(diff)
    self.stateTime = self.stateTime + diff
    if self.stateTime>=self.time[1] then
        self.view:removeFromParent(true)
        self.view = nil
        if self.target then
            self.callback(self.target)
        end
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    elseif self.stateTime>0.04 then
        local x,y = self.view:getPosition()
        local ox, oy = x-self.tempx, y-self.tempy
        if ox==0 or oy == 0 then
            return
        end
        local dir = 0
        local temp = math.deg(math.atan2(oy, ox))
        dir = 90-temp
        self.view:setRotation(dir)
        self.tempx,self.tempy=x,y
        self.view:setVisible(true)
    end

    
end

--弓箭手
function ArrowShot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {math.ceil(distance*200/self.speed)/20}
    self.state = 1
    
    local view = ui.sprite("effects/arrowShot"..self.level..".png")
    display.adapt(view,self.initPos[1],self.initPos[2],GConst.Anchor.Top)
    local ox, oy = self.targetPos[1] - self.initPos[1], self.targetPos[2] - self.initPos[2]
    local dir = 0
    local temp = math.deg(math.atan2(oy, ox))
    dir = 90-temp
    --view:setRotation(dir)
    self.tempx,self.tempy = self.initPos[1],self.initPos[2]

    local zod = self.scene.map.maxZ
    self.scene.objs:addChild(view,zod)
    self.view = view
    view:setVisible(false)

    local g = 100
    local htpos= g*(self.time[1])^2
    local moveX=ui.action.moveTo(self.time[1],self.targetPos[1],self.targetPos[2])
    local moveY1=ui.action.moveBy(self.time[1]/2,0,htpos)
    local moveY2=ui.action.moveBy(self.time[1]/2,0,-htpos)
    view:runAction(moveX)
    view:runAction(ui.action.sequence({ui.action.easeSineOut(moveY1),ui.action.easeSineIn(moveY2)}))
    self.scene.replay:addUpdateObj(self)
end

--火人
FireBallShot = class(SingleShot)

function FireBallShot:update(diff)
    diff = diff * (self.scene.speed or 1)
    local stateTime = self.stateTime + diff
    local state = self.state
    if state>1 then
        return
    end
    if stateTime >= self.time[state] then
        self.state = state+1
        stateTime = stateTime - self.time[state]
        shotDamage(self, self.target, self.attackValue)
        if self.view then
            self.view:removeFromParent(true)
            self.view = nil
        end
        self:resetView()
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
    self.stateTime = stateTime
end

function FireBallShot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed, 0.2}
    self.state = 1
    self:resetView()
end

function FireBallShot:resetView()
    if self.state==1 then
        local ox, oy = self.targetPos[1] - self.initPos[1], self.targetPos[2] - self.initPos[2]
        local distance = self.scene.map.getGridDistance(ox, oy)

        local dir = -math.deg(math.atan2(oy, ox))
        if self.target.deleted then
            return
        end
        --子弹
        local view = ui.animateSprite(0.7,"HuoQiu_",6,{beginNum=0,plist="effects/battleEffects.plist"})
        view:setScale(0.6)
        view:setRotation(90+dir)
        view:setPosition(self.initPos[1],self.initPos[2])
        self.scene.objs:addChild(view,self.scene.map.maxZ)
        view:runAction(ui.action.moveTo(self.time[1],self.targetPos[1],self.targetPos[2]))
        self.view=view
        self.attacker.scene.replay:addUpdateObj(self)

    else
        local tz = self.scene.map.maxZ-self.targetPos[2]
        if self.target.avater then
            tz = tz+self.targetZ
        end
        local view = ui.animateSprite(0.53,"Xb_",8,{beginNum=0,plist="effects/battleEffects.plist"})
        view:setScale(1)
        display.adapt(view, self.targetPos[1], self.targetPos[2],{0.5, 0.5})
        self.scene.objs:addChild(view,self.scene.map.maxZ)
        view:runAction(ui.action.sequence({{"delay",0.53},"remove"}))
    end
end

--U2飞机
U2Shot = class(SingleShot)
function U2Shot:update(diff)
    diff = diff * (self.scene.speed or 1)
    local stateTime = self.stateTime + diff
    local state = self.state
    if self.time[state] and stateTime >= self.time[state] then
        self.state = state+1
        stateTime = stateTime - self.time[state]
        if state==1 then
            shotDamage(self, self.target, self.attackValue)
        end
        self.scene.replay:removeUpdateObj(self)
        self.deleted = true
        if self.view then
            self.view:removeFromParent(true)
        end
        self:resetView()
    end
    self.stateTime = stateTime
end

function U2Shot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed}
    self.state = 1
    self:resetView()
end

function U2Shot:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end

        self.attacker.scene.replay:addUpdateObj(self)
        local ox, oy = self.targetPos[1] - self.initPos[1], self.targetPos[2] - self.initPos[2]
        local dir = 0
        local temp = math.deg(math.atan2(oy, ox))
        dir = -temp
        local dis = math.sqrt(ox*ox+oy*oy)

        --子弹
        self.view = ui.sprite("effects/u2ZiDan.png")
        if self.view then
            self.view:setAnchorPoint(cc.p(0.25, 0.5))
            self.view:setPosition(self.initPos[1], self.initPos[2])
            self.view:setRotation(dir)
            self.scene.objs:addChild(self.view,self.scene.map.maxZ)
            self.view:runAction(ui.action.moveBy(self.time[1],ox,oy))

            if self.level==3 then
                self.view:setScaleX(3)
            end
        end
    else
        --炸开特效
        local view = ui.animateSprite(0.25,"u2_zhakai",6,{beginNum=0,plist="effects/u2zidanzhakai.plist"})
        view:setScale(1)
        display.adapt(view, self.targetPos[1], self.targetPos[2],{0.512, 0.402})
        self.scene.objs:addChild(view,self.scene.map.maxZ)
        view:runAction(ui.action.sequence({{"delay",0.25},"remove"}))

        view = ui.sprite("commonGlow.png")
        display.adapt(view, self.targetPos[1], self.targetPos[2],{0.5, 0.5})
        self.scene.objs:addChild(view,self.scene.map.maxZ)
        view:setColor(cc.c3b(126,182,255))
        local blend={}
        blend.src=gl.SRC_ALPHA
        blend.dst=gl.ONE
        view:setBlendFunc(blend)
        view:setScale(0.38*4)
        view:runAction(ui.action.scaleTo(0.25,1,1))
        view:runAction(ui.action.sequence({{"delay",0.1},{"fadeOut",0.15}}))
        view:runAction(ui.action.sequence({{"delay",0.25},"remove"}))
    end
end

--僵尸鸟
JiangShiNiao = class(SingleShot)
function JiangShiNiao:update(diff)
    diff = diff * (self.scene.speed or 1)
    local stateTime = self.stateTime + diff
    local state = self.state
    if self.time[state] and stateTime >= self.time[state] then
        self.state = state+1
        stateTime = stateTime - self.time[state]
        if state==1 then
            shotDamage(self, self.target, self.attackValue)
            --music.playCleverEffect("music/laserBomb.mp3")
        end
        self.view:removeFromParent(true)
        self:resetView()
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
    self.stateTime = stateTime
end

function JiangShiNiao:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed}
    self.state = 1
    self:resetView()
end

function JiangShiNiao:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end

        local temp=ui.sprite("commonGlow.png")
        temp:setAnchorPoint(cc.p(0.5, 0.5))
        temp:setPosition(self.initPos[1], self.initPos[2])
        self.scene.objs:addChild(temp,self.scene.map.maxZ)
        temp:setOpacity(0)
        temp:setColor(cc.c3b(101,255,0))
        temp:setScale(1.1)
        temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"fadeTo",7/60,0},"remove"}))

        local ox, oy = self.targetPos[1] - self.initPos[1], self.targetPos[2] - self.initPos[2]
        local dir = 0
        local temp = math.deg(math.atan2(oy, ox))
        dir = -temp
        local dis = math.sqrt(ox*ox+oy*oy)

        --子弹
        self.view = ui.animateSprite(self.time[1],"SDuqiu_",5,{beginNum=0,plist="effects/battleEffects.plist"})
        self.view:setAnchorPoint(cc.p(0.5, 0.5))
        self.view:setPosition(self.initPos[1], self.initPos[2])
        self.view:setRotation(-90+dir)
        self.scene.objs:addChild(self.view,self.scene.map.maxZ)
        self.view:runAction(ui.action.moveBy(self.time[1],ox,oy))
        self.view:setScale(0.3)
        self.view:runAction(ui.action.scaleTo(self.time[1],0.8,0.8))

        self.scene.replay:addUpdateObj(self)

    else
        --炸开特效
        local view = ui.animateSprite(0.5,"poisonBomb_",7,{beginNum=0,plist="effects/battleEffects.plist"})
        view:setScale(1.25)
        display.adapt(view, self.targetPos[1], self.targetPos[2],{0.5, 0.5})
        self.scene.objs:addChild(view,self.scene.map.maxZ)
        view:setOpacity(0)
        view:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",23/60},{"fadeTo",5/60,0},"remove"}))
    end
end

GroupTypes = {Attack=1, Defense=2}
AreaSplash = class(FlyObject)

function AreaSplash:ctor(attackValue, speed, x, y, targetX, targetY, damageRange, group, unitType)
    self.targetPos = {targetX, targetY}
    self.unitType = unitType
    self.group = group
    self.damageRange = damageRange
end

function AreaSplash:executeDamage()
    if self.attacker.vconfig.attackMusic2 then
        music.play(self.attacker.vconfig.attackMusic2)
    end
    local ret = {}
    local p = {self.scene.map.convertToGrid(self.targetPos[1],self.targetPos[2])}
    local ret = self.attacker.battleMap:getCircleTarget(p,self.attacker.battleMap.battlerAll,self.damageRange)
    for k,v in ipairs(ret) do
        v:damage(self.attackValue)
    end
    if self.callback then
        self.callback(ret)
    end
    return ret
end

