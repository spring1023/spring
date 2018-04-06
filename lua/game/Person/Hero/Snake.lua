local M = class(AvtInfo)

local V = {}

function V:viewAttackSpecial(mode)
    SnakeEffect.new({attacker = self})
end

local C = class(AvtControler)

function C:sg_updateBattle(diff)
    if self.deleted then
        return
    end
    
end

SnakeEffect = class()

function SnakeEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initAttack()
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

function SnakeEffect:initParams(params)
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed =  0
    
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
    self.snakePointGod = params.snakePointGod
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

function SnakeEffect:initAttack()
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
        local temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/c_2.csb")
        display.adapt(temp, targetPos[1],targetPos[2], GConst.Anchor.Center)
        bg:addChild(temp,initPos[3]+10000)
        temp:runAction(ui.action.sequence({{"delay",0.4},"remove"}))
    end
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_4030/b_2.csb")
    display.adapt(temp,0,0,GConst.Anchor.Center)
    moveNode:addChild(temp)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",bao},"remove"}))
    self.time = moveTime
end

function SnakeEffect:update(diff)
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































