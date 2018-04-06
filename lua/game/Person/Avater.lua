
GMethod.loadScript("game.GameEffect.newSkill.Hulk2ZhaoHuan")
GMethod.loadScript("game.GameEffect.newSkill.Vertigo")
GMethod.loadScript("game.GameEffect.newSkill.ShaiYaRen")
GMethod.loadScript("game.GameEffect.newSkill.ZhuchengBaozha")
GMethod.loadScript("game.GameEffect.newSkill.YonBingDun")
GMethod.loadScript("game.GameEffect.newSkill.HeroDun")
GMethod.loadScript("game.GameEffect.newSkill.Explosion")
GMethod.loadScript("game.GameEffect.newSkill.FuHuoEffect")
local gameSetting = GMethod.loadScript("game.GameSetting")

local PersonState = {FREE = 1, MOVING = 2, POSE = 3, ATTACK = 4, SEARCHING = 5, SKILL = 6, GODSKILL = 7, SPMOVING = 8}
GEngine.export("PersonState", PersonState)

local AllConfig = GMethod.loadScript('data.AllConfig')
local AnimaConfigData = GMethod.loadScript('data.AnimaConfigData')
local memory = _G["memory"]

local Avater = class()

--测试一下
local function getPersonPlist(id, level, awakeUp)
    local imgType = 1
    if id>800 and id<820 then   --神兽佣兵
        id = id*10+1
    end
    if id>8000 and id<9000 then --神兽
        imgType = id%10
    end
    if 4000<id and id<5000 then --橙色英雄
        if awakeUp and awakeUp>0 then
            if AnimaConfigData[id*10+2] then
                id = id*10+2
                imgType = 2
            end
        end
    end
    if 99<id and id<701 then
        if level<15 then
            imgType = 1
        elseif level<30 then
            imgType = 2
        else
            imgType = 3
        end
    end

    local animaConfig = AnimaConfigData[id]
    local plistFile = string.format(animaConfig.plistFile, imgType)
    return plistFile
end
GEngine.export("GetPersonPlist", getPersonPlist)

function Avater:ctor(id,scene,gx,gy,group,initDirection,parent)

    self.imgType = 1
    if id>800 and id<820 then   --神兽佣兵
        id = id*10+1
    end
    if id>8000 and id<9000 then --神兽
        self.imgType = id%10
    end
    if 4000<id and id<5000 then --橙色英雄
        if parent.person.awakeUp>0 then
            if AnimaConfigData[id*10+2] then
                id = id*10+2
                self.imgType = 2
            end
        end
    end

    if 99<id and id<701 then    --英雄佣兵
        local level = parent and parent.avtInfo and parent.avtInfo.level or 1
        if level<15 then
            self.imgType = 1
        elseif level<30 then
            self.imgType = 2
        else
            self.imgType = 3
        end
    end
    self.skillStopNum = 0

    self.C = parent
    self.M = self.C.M
    self.group = group
    self.id = id
    if parent.vstate then
        self.scene = parent.vstate.scene
    else
        self.scene = scene
    end
    self.map = self.scene.map
    self.state = PersonState.FREE
    self.frameIndex = 0
    self.frameMaxIndex = 0
    self.actionTime = 0

    self.animaTime = 0
    self.direction = initDirection or 1
    self.animaConfig = AnimaConfigData[parent.params and parent.params.acid or id]
    if not self.animaConfig then
        GameLogic.otherGlobalInfo = {"avaterId", parent.params and parent.params.acid or id}
    end
    self.plistFile = string.format(self.animaConfig.plistFile, self.imgType)
    self.frameFormat = self.animaConfig.free_fmt
    --乔巴两种形态的帧格式不一样, 特殊处理
    if self.id == 4031 then
        if self.C.heroState == 0 then--heroState.ren
            self.frameFormat = self.animaConfig.free_fmt
        elseif self.C.heroState == 1 then--heroState.shou
            self.frameFormat = self.animaConfig.skill_fmt[6]
        end
    end
    if type(self.frameFormat) == "table" then
        self.frameFormat = self.frameFormat[1]
    end
    --加一层逻辑view的包装器，以便对自己进行逻辑操作时可以批量修改
    self._logicViews = {}
    self.view = ui.node()
    self:addLogicView(self.view)
    self.personView = ui.shlNode()
    self.personView:setCascadeOpacityEnabled(true)
    self.personView:setCascadeColorEnabled(true)
    self.view:addChild(self.personView)
    self.personView:setPosition(0, self.animaConfig.Ymove)
    local x, y = gx, gy
    if not parent.vstate then
        x, y = self.map.convertToPosition(gx, gy)
        self.gx, self.gy = gx, gy
    else
        self.gx, self.gy = parent.vstate.gx + parent.vstate.gsize/2, parent.vstate.gy + parent.vstate.gsize/2
    end
    --神兽或僵尸的体积要大一圈来计算攻击范围
    if self.id >= 9000 then
        self.gsize = 1
    elseif self.id >= 8000 and self.id%10 == 3 then
        self.gsize = 2
    else
        self.gsize = 0
    end
    self.movable = true

    if not self.C.avtInfo then
        if id == 1 then
            self.C.avtInfo = {utype = 2, id=1, bfDizziness=0, attackScale = 2, attackScale_base = 2}
        else
            self.C.avtInfo = {utype = 1, id=300, bfDizziness=0, attackScale = 2, attackScale_base = 2}
        end
    end
    self.avtInfo = self.C.avtInfo
    if self.avtInfo.utype == 1 then
        self.maxZorder = General.sceneHeight
    else
        self.maxZorder = General.sceneHeight*(self.animaConfig.Ymove+1)
        if self.id>1000 then
            self.maxZorder = self.maxZorder+1000
        end
    end
    if self.C.state == AvtControlerState.ZOMBIE then
        scene.ground:addChild(self.view, self.maxZorder-y)
    elseif not parent.vstate then
        scene.objs:addChild(self.view, self.maxZorder-y)
    else
        self.maxZorder=y+self.animaConfig.Ymove
        scene:addChild(self.view)
    end
    self:resetFree()
    if group then
        self:addShadow()
    end
    self.moveGrids = {}
    RegLife(self.view, Handler(self.onLifeCycle, self))
    local inLoad = memory.loadSpriteSheetRelease(self.plistFile, false, self.view, ButtonHandler(self.onLoadPlistOver, self))
    if not inLoad then
        self:resetFrame(0)
    end

    self:setPosition(x, y)
end

function Avater:onLoadPlistOver()
    if not self.deleted then
        self:resetFrame(0)
    end
end

function Avater:onLifeCycle(event)
    if event == "cleanup" then
        memory.releasePlist(self.plistFile)
        if not self.personView2 then
            ResAsyncLoader:getInstance():removeTask(self.view)
        end
        self.deleted = true
    elseif event == "exit" then
        self.deleted = true
        if self.godSkillNode and not tolua.isnull(self.godSkillNode) then
            self.godSkillNode:removeFromParent(true)
            self.godSkillNode = nil
        end
    elseif event == "enter" then
        self.deleted = nil
    end
end

function Avater:addLogicView(view)
    table.insert(self._logicViews, view)
end

function Avater:setPosition(x, y)
    for _, view in ipairs(self._logicViews) do
        view:setPosition(x, y)
    end
end

function Avater:removeFromParent(cleanup)
    for _, view in ipairs(self._logicViews) do
        if view == self.view then
            view:removeFromParent(cleanup)
        else
            view:removeFromParent(true)
        end
    end
    if cleanup then
        self._logicViews = {}
        self.view = nil
        self.personView = nil
        self.personView2 = nil
        self.viewChanged = nil
    else
        self._logicViews = {self.view}
    end
    self.shadow = nil
    self.blood = nil
end

function Avater:getType()
    if 9000<self.id and self.id<9000 then
        return "zombie"
    elseif 8000<self.id and self.id<9000 then
        return "god"
    else
        return "hero"
    end
end

function Avater:addShadow()
    local temp = ui.sprite("images/personShadow2.png")
    temp:setScale(self.animaConfig.shadow)
    if self.C.state == AvtControlerState.ZOMBIE then
        self.scene.ground:addChild(temp, 0)
    elseif self.scene.roleShadows then
        self.scene.roleShadows:addChild(temp)
    end
    self.shadow = temp
    self:addLogicView(temp)
    if self.avtInfo.utype == 2 then  --空中单位
        temp:setOpacity(0.6*255)
    else
        temp:setOpacity(0.85*255)
    end
    -- 专属节能特效
    if (self.C.person and self.C.person.displayColor) then
        local sx = self.shadow:getScaleX()
        local sy = self.shadow:getScaleY()
        local ssize = self.shadow:getContentSize()
        local x = ssize.width/2
        local y = ssize.height/2
        local temp2
        temp2 = ui.sprite("partiPointBlue2.png")
        temp2:setScaleX(2.40625/sx)
        temp2:setScaleY(2.0453125/sy)
        temp2:setPosition(x, y)
        ui.setBlend(temp2, 1, 1)
        self.shadow:addChild(temp2, 1)

        temp2 = ui.animateSprite(0.3, "Dian_", 3, {beginNum=0, plist="effects/effectsRes/Dian.plist", isRepeat=true})
        temp2:setScaleX(0.6/sx)
        temp2:setScaleY(0.65/sy)
        temp2:setPosition(x, y)
        self.shadow:addChild(temp2, 1)

        -- temp2 = ui.animateSprite(0.5, "DianQuan_0000", 5, {beginNum=0, plist="effects/effectsRes/shadowEffect1.plist", isRepeat=true})
        -- temp2:setScaleX(1.2/sx)
        -- temp2:setScaleY(1.2/sy)
        -- temp2:setPosition(x, y)
        -- self.shadow:addChild(temp2, 1)

        temp2 = ui.particle("particles/shadowThunder1.json")
        temp2:setPosition(0, 0)
        temp2:setScaleX(0.45)
        temp2:setScaleY(0.3825)
        self.scene.roleShadows:addChild(temp2, 1)
        temp2:setPositionType(cc.POSITION_TYPE_GROUPED)
        self:addLogicView(temp2)

        temp2 = ui.particle("particles/shadowThunder2.json")
        temp2:setPosition(0, 0)
        temp2:setScaleX(0.5)
        temp2:setScaleY(0.425)
        self.scene.roleShadows:addChild(temp2, 1)
        temp2:setPositionType(cc.POSITION_TYPE_GROUPED)
        self:addLogicView(temp2)
    end
    if (self.C.person and self.C.person.awakeUp or 0)>0 then
        local sx = self.shadow:getScaleX()
        local sy = self.shadow:getScaleY()
        local ssize = self.shadow:getContentSize()
        local x = ssize.width/2
        local y = ssize.height/2
        local temp2
        temp2 = ui.sprite("images/guangquan2.png")
        temp2:setScaleX(1.4/sx)
        temp2:setScaleY(1.05/sy)
        temp2:setPosition(x, y)
        self.shadow:addChild(temp2, 1)
        ui.setColor(temp2, 255, 179, 0)
        ui.setBlend(temp2, 1, 1)
        temp2:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",0.5,76},{"fadeTo",0.5,255}})))

        temp2 = ui.particle("particles/heroAwakeEffect2.json")
        temp2:setPosition(0, 22)
        self.view:addChild(temp2, 1)
        temp2:setScale(3)
        temp2:setPositionType(cc.POSITION_TYPE_GROUPED)

        temp2 = ui.particle("particles/heroAwakeEffect1.json")
        ui.setBlend(temp2, 1, 769)
        temp2:setScaleX(1.5)
        temp2:setScaleY(1.125)
        temp2:setGlobalZOrder(0)
        self.scene.roleShadows:addChild(temp2, 1)
        temp2:setPositionType(cc.POSITION_TYPE_GROUPED)
        self:addLogicView(temp2)
    end
end

function Avater:resetFree()
    if self.C and self.C.searchGrids then
        self.C.searchGrids = {}
    end
    if self.state == PersonState.MOVING then
        self.actionTime = 0
    end
    self.skillStopNum = 0
    self.state = PersonState.FREE
    self.loop = true
    self.frameIndex = 0
    local _config = self.animaConfig
    if type(_config.free_fmt) == "table" then
        local ft = math.random(_config.freeNum)
        self.frameMaxIndex = _config.free_params[ft][2]
        self.frameFormat = _config.free_fmt[ft]
        self.oneFrameTime = _config.free_params[1][1]/_config.free_params[1][2]
    else
        self.frameMaxIndex = _config.free_params[2]
        self.frameFormat = _config.free_fmt
        self.oneFrameTime = _config.free_params[1]/_config.free_params[2]
    end
   --乔巴两种形态的帧格式不一样, 特殊处理
    if self.id == 4031 then
        if self.C.heroState == 0 then--heroState.ren
            self.frameFormat = self.animaConfig.free_fmt
        elseif self.C.heroState == 1 then--heroState.shou
            self.frameFormat = self.animaConfig.skill_fmt[6]
        end
    end
    self.animaTime = 0
    self.actionTime = 0
end

function Avater:resetMoveState()
    self.loop = true
    local _config = self.animaConfig
    self.frameFormat = _config.move_fmt
    --乔巴两种形态的帧格式不一样, 特殊处理
    if self.id == 4031 then
        if self.C.heroState == 0 then--heroState.ren
            self.frameFormat = self.animaConfig.move_fmt
        elseif self.C.heroState == 1 then--heroState.shou
            self.frameFormat = self.animaConfig.skill_fmt[5]
        end
    end
    self.animaTime = 0
    self.frameIndex = 0
    self.oneFrameTime = _config.move_params[1]/_config.move_params[2]
    self.frameMaxIndex = _config.move_params[2]
end

function Avater:moveDirect(tx,ty)
    self.moveComplete = false

    self.targetPoint = {tx, ty}
    local fx,fy = self.gx,self.gy
    self.moveDirection = {tx-fx,ty-fy}
    self.allActionTime = math.sqrt(self.moveDirection[1]*self.moveDirection[1]+self.moveDirection[2]*self.moveDirection[2])/(self.avtInfo.speed or 2)
    self:changeDirection(tx, ty)
    if self.state ~= PersonState.MOVING then
        self:resetMoveState()
    end
    self.actionTime = 0
    self.state = PersonState.MOVING
end

function Avater:makeShadowRole()
    if self.personView2 and self.px and self.py then
        local tmp = ui.sprite(self.frameName)
        tmp:setOpacity(100)
        tmp:setScale(self.personView2:getScaleX())
        tmp:setFlippedX(self.direction > 3)
        display.adapt(tmp, self.px, self.py, GConst.Anchor.Center)
        self.scene.objs:addChild(tmp, self.maxZorder - self.py)
        tmp:runAction(ui.action.sequence({{"delay", 0.2}, {"fadeTo", 0.3, 0}, "remove"}))
    end
end

function Avater:spmoveDirect(tx, ty, speed, useSpecialFormat)
    self.moveComplete = false
    self.targetPoint = {tx, ty}
    local fx,fy = self.gx,self.gy
    self.moveDirection = {tx-fx,ty-fy}
    self.allActionTime = math.sqrt(self.moveDirection[1]*self.moveDirection[1]+self.moveDirection[2]*self.moveDirection[2])/speed
    self:changeDirection(tx, ty)
    if self.animaConfig.skill_params and not useSpecialFormat then
        self.loop = true
        local sfmt,sparams
        if type(self.animaConfig.skill_fmt) == "string" then
            sfmt = self.animaConfig.skill_fmt
            sparams = self.animaConfig.skill_params
        else
            sfmt = self.animaConfig.skill_fmt[1]
            sparams = self.animaConfig.skill_params[1]
        end
        --乔巴两种形态的帧格式不一样, 特殊处理
        if self.id == 4031 then
            if self.C.heroState == 0 then--heroState.ren
                sfmt = self.animaConfig.skill_fmt[1]
                sparams = self.animaConfig.skill_params[1]
            elseif self.C.heroState == 1 then--heroState.shou
                sfmt = self.animaConfig.skill_fmt[3]
                sparams = self.animaConfig.skill_params[3]
            end
        end
        self.frameFormat = sfmt
        self.animaTime = 0
        self.frameIndex = 0
        self.oneFrameTime = sparams[1]/sparams[2]
        self.frameMaxIndex = sparams[2]
        self.actionTime = 0
    else
        self.loop = false
        self.animaTime = 0
        self.frameIndex = 0
        self.actionTime = 0
    end
    self.state = PersonState.SPMOVING
end

--设置攻击动作，和特效无关
function Avater:attack(tx, ty, useSkill)
    self.isExeRealAtk = false
    self.attackEffectView = nil
    local fx, fy = self.gx, self.gy
    self.targetPoint = {tx, ty}
    self.moveDirection = {tx-fx, ty-fy}
    self:changeDirection(tx, ty)
    self.actionTime = 0
    self.state = PersonState.ATTACK

    local _config = self.animaConfig
    self.loop = false
    local sfmt, sparams, atype = nil
    if self.id == 4031 then
        if self.C.heroState == 0 then--heroState.ren
            sfmt = self.animaConfig.atk_fmt[1]
            sparams = self.animaConfig.atk_params[1]
        elseif self.C.heroState == 1 then--heroState.shou
            sfmt = self.animaConfig.skill_fmt[4]
            sparams = self.animaConfig.skill_params[4]
        end
    end
    if useSkill then
        if self.id == 4031 then
            if self.C.heroState == 0 then--heroState.ren
                sfmt = self.animaConfig.skill_fmt[1]
                sparams = self.animaConfig.skill_params[1]
            elseif self.C.heroState == 1 then--heroState.shou
                sfmt = self.animaConfig.skill_fmt[3]
                sparams = self.animaConfig.skill_params[3]
            end
        else
            self.skillStopNum = 6
            if _config.skill_params then
                if type(self.animaConfig.skill_fmt) == "string" then
                    sfmt = self.animaConfig.skill_fmt
                    sparams = self.animaConfig.skill_params
                else
                    sfmt = self.animaConfig.skill_fmt[1]
                    sparams = self.animaConfig.skill_params[1]
                end
            end
        end
    end
    if not sfmt then
        --没有攻击帧的 用移动动作
        if not _config.atk_params then
            self:resetMoveState()
            self.state = PersonState.ATTACK
            return
        else
            atype = self.C.rd:randomInt(self.animaConfig.atkNum)
            sfmt = _config.atk_fmt[atype]
            sparams = _config.atk_params[atype]
        end
    end
    self.frameFormat = sfmt
    self.animaTime = self.actionTime
    self.frameIndex = 0
    self.oneFrameTime = sparams[1]/sparams[2]
    self.frameMaxIndex = sparams[2]
    self.allActionTime = self.avtInfo.aspeed or 0.5
    self.exeAtkFrame = sparams[3]
    self.attackType = atype
    if self.viewAttackSpecial then
        self:viewAttackSpecial(useSkill and 1 or 0)
    end
end

--击退逻辑
function Avater:beRepel(attacker, disG, time)
    if self.deleted or self.isHide or self.avtInfo.immune > 0 then
        return
    end
    self.beRepelData = {attacker, disG, time}
    self:resetFree()
    self:changeDirection(attacker.avater.gx, attacker.avater.gy)
    self.beRepelState = true
    self:resetFrame(0)
end

--根据当前点和目标点计算方向
function Avater:changeDirection(tx, ty)
    local gx, gy = self.gx, self.gy
    local dirx, diry = tx-gx, ty-gy
    dirx, diry = (diry - dirx)*4, (diry + dirx)*3

    local dir
    local t1, t2 = math.abs(dirx), math.abs(diry)
    local t3
    if t1==0 then
        t3 = 3 - math.ceil(self.direction/3)*2
    else
        t3 = dirx/t1
    end
    if t2<=t1*0.4 then
        dir = 3.5 - 1.5 * t3
    else
        dir = 3.5 + (diry/t2 - 1.5) * t3
    end
    self.direction = dir
end

--local stat = {t=0, n=0, tt=0}   -- 没有用到

function Avater:updateView(diff)
    if self.deleted then
        return
    end
    if self.state == PersonState.GODSKILL and self.updateSpecialState then
        self:updateSpecialState(diff)
        if not self.__skip then
            return
        else
            self.__skip = nil
        end
    end
    --击退
    if self.beRepelState then
        self:beRepelEffect(diff)
        return
    end

    --local bdiff = diff   -- 没有用到
    if self.state == PersonState.MOVING or self.state == PersonState.SPMOVING then
        diff = diff*(self.avtInfo.moveScale or 1)
        self.actionTime = self.actionTime+diff
        self:resetFrame(diff)
        if self.canJumpWall then
            self:checkJump(diff)
        end
        self:resetPosition()
    else
        if self.state ~= PersonState.FREE then
            diff = diff*(self.avtInfo.attackScale or 1)
        end
        self.actionTime = self.actionTime+diff
        self:resetFrame(diff)

        --执行攻击以及完成攻击动作的逻辑
        if self.state == PersonState.ATTACK or self.state == PersonState.GODSKILL or self.state == PersonState.SKILL then
            if self.hasShadowRole then
                self:resetPosition()
            end
            if self.actionTime>=self.allActionTime then
                self.actionTime = self.actionTime-self.allActionTime
                self:resetFree()
                self.attackEffectView = nil
                return
            end
            if self.exeAtkFrame then
                if self.frameIndex >= self.exeAtkFrame and not self.isExeRealAtk then
                    self.isExeRealAtk = true
                    self.exeRealAtk = true
                end
            else
                if not self.isExeRealAtk then
                    self.isExeRealAtk = true
                    self.exeRealAtk = true
                end
            end
        end
    end

    --技能持续时间之后
    if self.skillLastTimeAll then
        self.skillLastTime = self.skillLastTime + diff
        if self.skillLastTime>=self.skillLastTimeAll then
            self:skillAfter()
        end
    end
end

--跳墙逻辑；目前用的是非常简约的做法
function Avater:jumpWall()
    self.jumpTime = 0
    self.canJumpWall = 0
    self.allJumpTime = 1.5/self.avtInfo.speed
end

local jumpAction = {
    {0, 0, 1, 1},
    {0.22, 0, 1.15, 0.85},
    {0.5, 100, 0.85, 1.1, "sineout"},
    {0.78, 0, 1.1, 0.9, "sinein"},
    {1, 0, 1, 1}
}
function Avater:checkJump(diff)
    self.jumpTime = self.jumpTime+diff
    local jp = self.jumpTime/self.allJumpTime
    if self.personView2 then
        if jp>1 then
            jp = 1
        end
        local s1 = 2
        for i=s1, #jumpAction do
            if jumpAction[i][1] >= jp then
                s1 = i
                break
            end
        end

        local hscale = 1
        if self.id<1000 then
            hscale = 0.5
        end
        local a1, a2 = jumpAction[s1-1], jumpAction[s1]
        local ap = (jp-a1[1])/(a2[1]-a1[1])
        if a2[5] == "sinein" then
            ap = math.sin(math.rad(90*ap))
        elseif a2[5] == "sineout" then
            ap = math.cos(math.rad(90*ap-90))
        end
        self.personView:setScaleX(((a2[3]-a1[3])*ap+a1[3]))
        self.personView:setScaleY(((a2[4]-a1[4])*ap+a1[4]))
        self.personView:setPositionY(hscale*((a2[2]-a1[2])*ap+a1[2]))
    end
    if jp>=1 then
        self.canJumpWall = false
    else
        self.canJumpWall = jp
    end
end

function Avater:beRepelEffect(diff)
    local attacker,disG,time = self.beRepelData[1],self.beRepelData[2],self.beRepelData[3]
    local gx,gy = attacker.avater.gx,attacker.avater.gy
    local ps = 60/(disG/time)
    if not self.beRepelData.time then
        self.beRepelData.time = 0
    end
    self.beRepelData.time = self.beRepelData.time+diff
    if self.beRepelData.time<=time then
        local tgx,tgy = self.gx,self.gy
        if tgx == gx and tgy == gy then
            tgx = tgx - 0.1
            tgy = tgy - 0.1
        end
        local dis = math.sqrt((tgx-gx)^2+(tgy-gy)^2)
        tgx, tgy = tgx + (tgx-gx)/dis/ps, tgy + (tgy-gy)/dis/ps
        if self.scene then
            if self.scene.battleType == const.BattleTypePvb then
                if tgx < 9 or tgx > 32 or tgy < 0 or tgy > 41 then
                    return
                end
            else
                if tgx < 0 or tgy < 0 or tgx > 41 or tgy > 41 then
                    return
                end
            end
        end
        local px,py = self.map.convertToPosition(tgx, tgy)
        self.gx, self.gy = tgx, tgy
        for _, view in ipairs(self._logicViews) do
            view:setPosition(px, py)
        end
    else
        self.state = PersonState.FREE
        self.beRepelState = false
        self.beRepelData = nil
    end
end

function Avater:addMoveGrid(gx, gy)
    if self.state == PersonState.SEARCHING or self.state==PersonState.FREE then
        self:moveDirect(gx, gy)
        self.moveGrids = {}
    elseif self.state==PersonState.MOVING then
        table.insert(self.moveGrids, {gx, gy})
    end
end

function Avater:resetPosition()
    local moveComplete = false
    if self.hasShadowRole then
        self:makeShadowRole()
    end
    while self.actionTime >= self.allActionTime do
        self.gx = self.targetPoint[1]
        self.gy = self.targetPoint[2]
        self.actionTime = self.actionTime-self.allActionTime
        if self.moveGrids and #(self.moveGrids)>0 then
            local nextGrid = table.remove(self.moveGrids, 1)
            -- if not nextGrid or not nextGrid[2] or not nextGrid[1] then
            --     print("wtf????", json.encode(nextPoint))
            -- end
            local tmp = self.actionTime
            self:moveDirect(nextGrid[1], nextGrid[2])
            self.actionTime = tmp
        else
            self.state = PersonState.FREE
            moveComplete = true
            self.hasShadowRole = nil
            break
        end
    end
    if not moveComplete then
        local rate = 1-self.actionTime/self.allActionTime
        self.gx = self.targetPoint[1]-self.moveDirection[1]*rate
        self.gy = self.targetPoint[2]-self.moveDirection[2]*rate
    else
        self:resetFree()
    end
    local px,py = self.map.convertToPosition(self.gx,self.gy)
    for _, view in ipairs(self._logicViews) do
        view:setPosition(px, py)
    end
    self.px, self.py = px, py + self.animaConfig.Ymove
    -- self:resetBloodPos()
    -- self:resetShadowPos()
    --改变层级
    local zoff = 0
    if self.canJumpWall then
        if 3<=self.direction and self.direction<=5 then
            if self.canJumpWall<0.7 then
                zoff = 100
            end
        else
            if 0.3<self.canJumpWall and self.canJumpWall<0.7 then
                zoff = 100
            end
        end
    end
    self.view:setLocalZOrder(zoff+self.maxZorder-py)
    if self.blood then
        self.blood:setLocalZOrder(self.maxZorder-py)
    end
end

--动画帧数设置
function Avater:resetFrame(diff)
    if self.noResetFrame or not self.personView then
        return
    end
    --增加动作时间
    self.animaTime = self.animaTime+diff

    --根据时间计算帧数
    local oneTime = self.oneFrameTime
    if oneTime < 0.01 then
        log.e("strange error with one frame time, the param is wrong! : %s", json.encode(self.animaConfig))
        self.oneFrameTime = 0.1
        oneTime = 0.1
    end

    --技能停顿帧数
    if self.skillStopNum > 0 then
        local sbegin = (self.skillStopStart or 1) * oneTime
        local sstime = oneTime * (self.skillStopNum + (self.skillStopStart or 0))
        if sbegin <= self.animaTime and self.animaTime < sstime then
            return
        elseif self.animaTime >= sstime then
            self.animaTime = self.animaTime - sstime + sbegin
            self.skillStopNum = 0
        end
    end
    if self.loop then
        while self.animaTime >= self.oneFrameTime*self.frameMaxIndex do
            self.animaTime = self.animaTime - self.oneFrameTime*self.frameMaxIndex
        end
        self.frameIndex = math.floor(self.animaTime/self.oneFrameTime)
    else
        if self.animaTime >= self.oneFrameTime*self.frameMaxIndex then
            if not self.notRecoverFrame then
                self.frameIndex = 0
            end
        else
            self.frameIndex = math.floor(self.animaTime/self.oneFrameTime)
        end
    end

    --是否翻转
    local flip = false
    local tempDir = self.direction
    if tempDir > 3 then
        tempDir = 7-tempDir
        flip = true
    end

    local frameName
    if self.id == 4031 then
        frameName = string.format(self.frameFormat,tempDir,self.frameIndex)
    elseif self.animaConfig and self.animaConfig.fixPrefix then
        frameName = string.format(self.frameFormat, tempDir, self.imgType,tempDir,self.frameIndex)
    else
        frameName = string.format(self.frameFormat,self.imgType,tempDir,self.frameIndex)
    end

    --帧数不同则改变
    if not self.personView2 then
        local frame = memory.getFrame(frameName, true)
        if not frame then
            return
        else
            self.personView2 = CaeSprite:createWithSpriteFrame(frame)
            --ui.sprite(frameName)
            if self.id>8000 and self.id<9000 then    --神兽放大
                local sc
                if self.C.person.isPet then
                    sc = self.animaConfig.scale2 or 0.5
                else
                    sc = self.animaConfig.scale or 0.5
                end
                self.personView2:setScale(1/sc)
            else
                local sc = self.animaConfig.scale or 1
                self.personView2:setScale(2/sc)
            end
            self.personView:addChild(self.personView2)
            if self.C.hsl then
                self.personView2:setHValue(self.C.hsl[1])
                self.personView2:setSValue(self.C.hsl[2])
                self.personView2:setLValue(self.C.hsl[3])
            end
            if self.deleted then
                self.personView2:setSValue(-100)
            end
            self.frameName = frameName
        end
    elseif frameName ~= self.frameName then
        local frame = ui.reuseFrame(frameName)
        if frame then
            self.personView2:setSpriteFrame(frame)
            self.frameName = frameName
            if self.personGhostView then
                self.personGhostView:setSpriteFrame(frame)
            end
        end
    end

    -- 镜像效果
    if self.viewGhost then
        if not self.personGhostView then
            local frame = memory.getFrame(frameName, true)
            if frame then
                self.personGhostView = ui.sprite(frameName)
                self.personView:addChild(self.personGhostView)
                self.personGhostView:setScale(self.personView2:getScale())
                local color,bl,scale = self.viewGhost.color,self.viewGhost.blend,self.viewGhost.scale
                if color then
                    self.personGhostView:setColor(cc.c3b(color[1],color[2],color[3]))
                end
                if bl then
                    local blend={}
                    blend.src=bl[1]
                    blend.dst=bl[2]
                    self.personGhostView:setBlendFunc(blend)
                end
                if scale then
                    self.personGhostView:setScale(self.personGhostView:getScale()*scale)
                end
                self.personGhostView:setOpacity(self.viewGhost.op or 255)
            end
        end
    else
        if self.personGhostView then
            self.personGhostView:removeFromParent(true)
            self.personGhostView = nil
        end
    end

    --本身的变换，应该是技能特效
    if self.viewChange then
        if not self.viewChanged then
            self.viewChanged = true
            local cg = self.viewChange
            self.personView2:setOpacity(cg.op or 255)
            if cg.actRp then
                local act = ui.action.arepeat(ui.action.sequence(cg.actRp))
                act:setTag(100)
                self.personView2:runAction(act)
            end
            if cg.act then
                self.personView2:runAction(ui.action.sequence(cg.act))
            end
            if cg.sc then
                self.personView:runAction(ui.action.sequence({{"scaleTo",0.5,cg.sc,cg.sc}}))
            end
            if cg.amode then
                self.personView2:setAMode(0.75)
            end
        end
    else
        if self.viewChanged then
            self.viewChanged = nil
            self.personView2:stopActionByTag(100)
            self.personView2:setColor(cc.c3b(255,255,255))
            self.personView2:setOpacity(255)
            self.personView:runAction(ui.action.sequence({{"scaleTo",0.5,1,1}}))
            self.personView2:setAMode(0)
        end
    end

    --设置翻转
    self.personView2:setFlippedX(flip)
    if self.personGhostView then
        self.personGhostView:setFlippedX(flip)
    end
end

--受伤害血条动画
function Avater:damage(nowHp,maxHp,nowHp2)
    if not self.blood then
        local mode
        if self.avtInfo.ptype==1 and not self.C.params.isZhaoHuan then
            if self.group==1 then
                mode = ProgressBarMode.HERO_MY
            else
                mode = ProgressBarMode.HERO_HE
            end
        else
            if self.group==1 then
                mode = ProgressBarMode.SOLDIER_MY
            else
                mode = ProgressBarMode.SOLDIER_HE
            end
        end
        self.blood = ProgressBar.new(mode,maxHp,self.avtInfo.person.color)
        if self.C.params.isZhaoHuan then
            self.blood:setScale(1.5)
        end
        if nowHp2 and nowHp2>0 then
            self.blood:addHpBar(nowHp,nowHp2)
        end
        self.blood:setLevel(self.avtInfo.level)
        local x, y = self.map.convertToPosition(self.gx,self.gy)
        local px,py = self.personView:getPosition()
        local ox = 0
        local oy = 100
        local hpview = self.animaConfig.hpview
        if hpview then
            if self.id == 4031 then
                if self.C.heroState == 0 then--heroState.ren
                    ox = self.animaConfig.hpview[1][1]
                    oy = self.animaConfig.hpview[1][2]
                elseif self.C.heroState == 1 then--heroState.shou
                    ox = self.animaConfig.hpview[2][1]
                    oy = self.animaConfig.hpview[2][2]
                end
            else
                ox = hpview[1]
                oy = hpview[2]
            end
        end
        self.blood:setHpOffset(ox + px, oy + py)
        display.adapt(self.blood, x, y, GConst.Anchor.Bottom)
        self.scene.upNode:addChild(self.blood.view, self.maxZorder-y)
        self:addLogicView(self.blood.view)
    end
    self.blood:changeValue(nowHp)
    self.blood:changeValue2(nowHp2)
end

-- function Avater:resetBloodPos()
--     if self.C and self.C.state == AvtControlerState.ZOMBIE then
--         return
--     end
--     if self.blood and self.personView then
--         local x, y = self.map.convertToPosition(self.gx,self.gy)
--         local px,py = self.personView:getPosition()
--         x,y = x+px,y+py
--         local ox=0
--         local oy=100
--         local hpview = self.animaConfig.hpview
--         if hpview then
--             ox = hpview[1]
--             oy = hpview[2]
--         end
--         x,y = x+ox,y+oy
--         self.blood:setPosition(x,y)
--         --local parent = self.blood:getParent()
--         --parent:reorderChild(self.blood.view,self.maxZorder-y)
--         self.blood.view:setLocalZOrder(self.maxZorder-y)
--     end
-- end

function Avater:resetBlood()
    if self.C and self.C.state == AvtControlerState.ZOMBIE then
        return
    end
    self:damage(self.C.M.nowHp,self.C.M.maxHp,self.C.M.nowHp2)
end

--死亡
function Avater:die()
    self.deleted = true

    if self.personView then
        self.personView:removeFromParent(true)
        self.personView = nil
        self.personView2 = nil
        self.personGhostView = nil
        self.viewChanged = nil
    end
    for _, view in ipairs(self._logicViews) do
        if view ~= self.view then
            view:removeFromParent(true)
        end
    end
    self._logicViews = {self.view}
    self.blood = nil
    self.shadow = nil
    if self.replayUpdateKey then
        self.scene.replay:removeUpdate(self.replayUpdateKey)
        self.replayUpdateKey = nil
    end
    self.view:stopAllActions()
    self.view:removeAllChildren(true)
    if self.C.params.isZhaoHuan then
        self:zhaoHuanDie()
        return
    end

    local x, by = self.view:getPosition()
    local y = by
    -- if self.info.unitType==2 then
    --     y = y + self.viewInfo.y-20
    -- end
    --死亡特效
    if self.id>=9001 and self.id<=9006 then
        local death = LogicEffects.DeathZombie
        death:runAnimation(self.scene.effects, x, y+self.animaConfig.Ymove)
    elseif self.id>=8013 and self.id<=8103 and (self.id)%10==3 then
        local death = LogicEffects.DeathGod
        death:runAnimation(self.scene.effects, x, y+self.animaConfig.Ymove, (1/(self.animaConfig.scale or 0.5))*0.5)
    else
        local death = LogicEffects.DeathNormal
        death:runAnimation(self.scene.effects, x, y)
    end
    if not self.noTomb then
        local map = self.map
        local gx,gy = map.convertToGrid(x, by, 1)
        gx = math.floor(gx)
        gy = math.floor(gy)
        if not map.checkGridUse(gx, gy, 1) then
            local tomb = Tomb.new(gx, gy)
            tomb:addToScene(self.scene)
        end

        if self:getType() == "zombie" then
            music.play("sounds/zombieDead.wav")
        elseif self:getType() == "god" then
            music.play("sounds/godDead.wav")
        else
            music.play("sounds/troopDead.wav")
        end
    end
    --理论上应该把自己的节点也移除。暂时不做这个修改
    --self:removeFromParent(true)
end

function Avater:zhaoHuanDie()
    self.view:removeAllChildren(true)
    --self:removeFromParent(true)
end

local GF_SETTING={{11, 3, 1, 60}, {35, 23, 1, 0}, {27, 48, -1, -60}, {-27, 48, -1, -120}, {-35, 23, 1, 180}, {-11, 3, 1, 120}}
local FB_SETTING={{34, -5, 1}, {39, 24, 1}, {14, 40, -1}, {-14, 40, -1}, {-39, 24, 1}, {-34, -5, 1}}
local U2_SETTING={{10,-5, -1}, {27,15, -1}, {15, 35, -1}, {-10, -5, -1}, {-27, 15, -1}, {-15, 35, -1}}
local U2_SETTING2_1={{-30,-2, -1}, {-6,-18, -1}, {25, -11, -1}, {30,-2, -1}, {6,-18, -1}, {-25, -11, -1}}
local U2_SETTING2_2={{27,20, -1}, {-4,30, -1}, {-30, 15, -1},{-27,20, -1}, {4,30, -1}, {30, 15, -1}}

local FB_SETTING2={{14,-7,1},{28,12,1},{14,29,1},{-14,29,1},{-28,12,1},{-14,-7,1}}

function Avater:viewEffect(attackTarget,callback,isSkill)
    local skillmode = 0
    if isSkill then
        skillmode = 1
    end

    local id = self.id
    if id==100 or id==200 or id==600 or id==700 or id==2001 or id==2003 or id==3002 or id==3006 or id==4010 then
        if attackTarget.avater then
            callback(attackTarget)
            return
        end
        local mode = self.C.rd:randomInt(3)
        local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    elseif self.id == 300 then           --神射手
        local setting = GF_SETTING[self.direction]
        local p = {self.view:getPosition()}
        p[3] = General.sceneHeight - p[2]+setting[3]*20
        local x,y = self.personView:getPosition()
        p[1] = p[1] + x + setting[1]
        p[2] = p[2] + y + setting[2]
        local shot = ArrowShot.new(nil, 90, p[1], p[2], p[3],attackTarget,1,callback)
        shot.attacker = self
        shot:addToScene(self.scene)

    elseif self.id == 400 then           --霹雳火
        -- if true then
        --     callback()
        --     return
        -- end
        local setting = FB_SETTING[self.direction]
        local p = {self.view:getPosition()}
        p[3] = General.sceneHeight - p[2]+setting[3]*20
        local x,y = self.personView:getPosition()
        p[1] = p[1] + x + setting[1]
        p[2] = p[2] + y + setting[2]
        local shot = FireBallShot.new(nil, 90, p[1], p[2], p[3],attackTarget,nil,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    elseif self.id == 500 then           --U2

        local level=1 --u2等级为1时
        if level==1 then
            local setting=U2_SETTING[self.direction]
            local p = {self.view:getPosition()}
            p[3] = General.sceneHeight - p[2]+setting[3]*20
            local x,y = self.personView:getPosition()
            p[1] = p[1] + x + setting[1]
            p[2] = p[2] + y + setting[2]
            local shot = U2Shot.new(nil, 120, p[1], p[2], p[3],attackTarget,level,callback)
            shot.attacker = self
            shot:addToScene(self.scene)
        else
            --右边
            local setting=U2_SETTING2_1[self.direction]
            local p = {self.view:getPosition()}
            p[3] = General.sceneHeight - p[2]+setting[3]*20
            local x,y = self.personView:getPosition()
            p[1] = p[1] + x + setting[1]
            p[2] = p[2] + y + setting[2]
            local shot = U2Shot.new(nil, 120, p[1], p[2], p[3],attackTarget,level,callback)
            shot.attacker = self
            shot:addToScene(self.scene)

            --左边
            setting=U2_SETTING2_2[self.direction]
            p = {self.view:getPosition()}
            p[3] = General.sceneHeight - p[2]+setting[3]*20
            local x,y = self.personView:getPosition()
            p[1] = p[1] + x + setting[1]
            p[2] = p[2] + y + setting[2]
            local shot = U2Shot.new(0, 120, p[1], p[2], p[3],attackTarget,level)
            shot.attacker = self
            shot:addToScene(self.scene)
        end
    elseif self.id == 901 then           --僵尸鸟
        local setting = FB_SETTING2[self.direction]
        local p = {self.view:getPosition()}
        p[3] = General.sceneHeight - p[2]+setting[3]*20
        local x,y = self.personView:getPosition()
        p[1] = p[1] + x + setting[1]
        p[2] = p[2] + y + setting[2]
        local shot = JiangShiNiao.new(nil, 90, p[1], p[2], p[3],attackTarget,nil,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    else
        callback()
    end
end

--技能持续状态
function Avater:skillState(skillLastTimeAll)
    self.skillLastTimeAll = skillLastTimeAll
    self.skillLastTime = 0
    local id = self.id
    if id == 2001 then              --金属人
        if self.personView and self.shadow then
            self.personView:setScale(1.2)
            self.personView:setHValue(-170)
            self.personView:setSValue(23)
            self.shadow:setScale(2.5*1.2)
        end
    elseif id == 3002 then          --美国队长
        self:CreateTongYong(2,46,1)

        local tempDir = self.direction
        local flip = false
        if tempDir>3 then
            tempDir = 7-tempDir
            flip = true
        end
        local sprite = ui.sprite("heroeffects/hero26skill" .. tempDir .. ".png")
        sprite:setScale(1)
        sprite:setFlippedX(flip)
        display.adapt(sprite,0,self.personView:getPositionY(),GConst.Anchor.Center)
        self.view:addChild(sprite)
        sprite:runAction(ui.action.sequence({{"delay",0.3},{"fadeOut",0.28},"remove"}))

        sprite = ui.sprite("heroeffects/hero26skill.png")
        sprite:setOpacity(0)
        sprite:setScale(1.4)
        sprite:setAnchorPoint(0.538,0.489)
        sprite:setPosition(0,self.personView:getPositionY()+10)
        local blend = {}
        blend.src = 770
        blend.dst = 1
        sprite:setBlendFunc(blend)
        sprite:runAction(ui.action.fadeTo(0.6,153))
        sprite:runAction(ui.action.scaleTo(0.6,0.9,0.9))
        sprite:runAction(ui.action.rotateBy(3,360))
        sprite:runAction(ui.action.sequence({{"delay",3},"remove"}))
        self.view:addChild(sprite,100,172)
    elseif id == 3006 then    --蝙蝠侠
        if not self.act then
            self.personView:setOpacity(0.7*255)
            self.act=ui.action.arepeat(ui.action.sequence({{"fadeTo",0.12,0.4*255},{"fadeTo",0.12,0.7*255}}))
            self.personView:runAction(self.act)
        end
    end
end

function Avater:skillAfter()
    local id = self.id
    if id == 2001 then      --金属人
        if self.personView and self.shadow then
            self.personView:setScale(1)
            self.personView:setHValue(0)
            self.personView:setSValue(0)
            self.shadow:setScale(2.5)
            self.skillLastTimeAll = nil
            self.skillLastTime = nil
        end
    elseif id ==3006 then    --蝙蝠侠
        if self.act then
            self.personView:setOpacity(255)
            self.personView:stopAction(self.act)
            self.act=nil
        end
    end
end

--技能执行特效
function Avater:skillAttack(attackTarget,viewInfo1,viewInfo2,b,npcUser)
    local skillId, skillLv = self.avtInfo.person.skillId, self.avtInfo.person.skillLv
    if not npcUser then
        self:showHurtPerformance(Localizef("dataSkillNameFormat",{name=Localize("dataSkillName1_" .. skillId), level=skillLv}), 0)
    end
    if self.sg_skillAttack then
        self:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
        return
    end
    self.skillStopNum = 6
    if self.animaConfig.skill_params then
        self.loop = false
        self.isExeRealAtk = false

        local sfmt,sparams
        if type(self.animaConfig.skill_fmt) == "string" then
            sfmt = self.animaConfig.skill_fmt
            sparams = self.animaConfig.skill_params
        else
            sfmt = self.animaConfig.skill_fmt[1]
            sparams = self.animaConfig.skill_params[1]
        end
        if self.id == 4031 then
            if self.C.heroState == 0 then--heroState.ren
                sfmt = self.animaConfig.skill_fmt[1]
                sparams = self.animaConfig.skill_params[1]
            elseif self.C.heroState == 1 then--heroState.shou
                sfmt = self.animaConfig.skill_fmt[3]
                sparams = self.animaConfig.skill_params[3]
            end
        end
        self.frameFormat = sfmt
        self.animaTime = 0
        self.frameIndex = 0
        self.oneFrameTime = sparams[1]/sparams[2]
        self.frameMaxIndex = sparams[2]
        self.actionTime = 0
        self.allActionTime = self.avtInfo.aspeed
        if sparams[1]>self.avtInfo.aspeed then
            self.allActionTime = sparams[1]
        end
        self.exeAtkFrame = sparams[3]
    else
        self:attack(viewInfo1,viewInfo2,b)
    end
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    --通用特效
    local off=AllConfig.heroCurrencyEffect
    local id = self.id
    if off[id] then
        local mode,oy,scal=off[id][1],off[id][2],off[id][3]
        self:currencyEffect(mode,oy,scal)
    end
    self.state = PersonState.SKILL
end

function Avater:showHurtPerformance(s, ftype)
    if self.personView then
        local effect = LogicEffects.SPFont
        local x, y = self.map.convertToPosition(self.gx,self.gy)
        local px,py = self.personView:getPosition()
        x,y = x+px,y+py
        local ox=0
        local oy=160
        local hpview = self.animaConfig.hpview
        if hpview then
            if self.id == 4031 then
                if self.C.heroState == 0 then--heroState.ren
                    ox = self.animaConfig.hpview[1][1]
                    oy = self.animaConfig.hpview[1][2]+60
                elseif self.C.heroState == 1 then--heroState.shou
                    ox = self.animaConfig.hpview[2][1]
                    oy = self.animaConfig.hpview[2][2]+60
                end
            else
                ox = hpview[1]
                oy = hpview[2]+60
            end
        end
        x,y = x+ox,y+oy

        effect:runAnimation(self.scene.upNode, x, y, s, ftype)
    end
end

function Avater:showAppear()
    local sprite
    local scale = 1
    local x, y = self.view:getPosition()
    sprite = ui.sprite("images/guangquan2.png")
    if self.avtInfo.id>=1000 then
        music.play("sounds/troopSet.wav")
        sprite:setScaleX(0.6)
        sprite:setScaleY(0.45)
        sprite:runAction(ui.action.sequence({{"scaleTo",0.12,2.1,1.575},{"scaleTo",0.07,2.5,1.875}}))
    else
        sprite:setScaleX(0.4)
        sprite:setScaleY(0.3)
        sprite:runAction(ui.action.sequence({{"scaleTo",0.12,1.4,1.05},{"scaleTo",0.07,2,1.5}}))
    end
    sprite:runAction(ui.action.sequence({{"fadeTo",0.12,204},{"fadeTo",0.07,0},"remove"}))
    display.adapt(sprite, x, y, GConst.Anchor.Center)
    self.scene.roleShadows:addChild(sprite, 0)
    if self.avtInfo.id>=1000 then
        self.personView:setScaleX(0.9)
        if self.avtInfo.utype==1 then
            self.personView:setScaleY(2*0.8)
        else
            self.personView:setScaleY(1.6*0.7)
        end
        self.personView:runAction(ui.action.sequence({{"scaleTo", 0.25, 1, 0.95}, {"scaleTo", 0.125, 1, 1.1}, {"scaleTo", 0.125, 1, 1}}))
    else
        self.personView:setScaleY(2*0.8)
        self.personView:runAction(ui.action.sequence({{"scaleTo", 0.25, 1, 0.85}, {"scaleTo", 0.125, 1, 1}}))
    end
end

function Avater:showGodSkill()
    music.play("sounds/godSkillCry_"..string.sub(self.id, 1,4)..".mp3")
    local awakeData = self.M.person.awakeData
    local skillId, skillLv = awakeData.id,awakeData.lv
    local fname = Localize("dataSkillName5_" .. skillId .. "_2")
    if self.M.id == 4031 then
        fname = Localize("dataSkillName5_403102_2")
    end
    local group = self.group
    local temp
    temp = ui.colorNode(display.winSize, {0, 0, 0, 128})
    local bg = display.addLayer(temp, 20, 20)
    self.godSkillNode = bg
    local ccnode = ui.colorNode({2048, 1536}, {0,0,0,1})
    ccnode:setPositionY(10)
    local cnode = cc.ClippingNode:create(ccnode)
    cnode:setContentSize(2048, 1536)
    local angle = 7
    local fontType = 7
    if General.language == "HK" then
        fontType = 1
    end
    if group == 1 then
        cnode:setRotation(-angle)
        display.adapt(cnode, 0, 152, GConst.Anchor.LeftBottom, {scale = ui.getUIScale2()})
        bg:addChild(cnode)
        bg = ui.node()
        bg:setRotation(angle)
        cnode:addChild(bg)

        temp = ui.sprite("effects/godSkillBackLeft.png")
        temp:setScaleX(2)
        temp:setScaleY(0.4)
        display.adapt(temp, -988, 81, GConst.Anchor.Center)
        bg:addChild(temp)
        local label = ui.label(fname, fontType, 50, {color={0, 8, 35}})
        display.adapt(label, 440, 151, GConst.Anchor.Center)
        temp:addChild(label)
        label:setRotation(-angle)
        label:setOutlineColor(cc.c4b(79,224,240,255))
        temp:runAction(ui.action.sequence({
            {"spawn", {{"moveBy", 0.167, 1970, 208}, {"scaleTo", 0.167, 2.2, 2.4}, {"skewBy", 0.167, 20, 0}}},
            {"spawn", {{"moveBy", 0.083, -63, 0}, {"scaleTo", 0.083, 2, 2}, {"skewBy", 0.083, -20, 0}}}
        }))
        local id = self.M.id
        if 8000<id and id<9000 then
            id = math.floor(id/10)*10
        end
        local afile
        if id == 4031 then
            if self.C.heroState == 0 then
                afile = GameUI.getHeroFeature(4031, false, 0)
            elseif self.C.heroState == 1 then
                afile = GameUI.getHeroFeature(40312, false, 0)
            end
        else
            afile = GameUI.getHeroFeature(id, false, 1)
        end
        temp = ui.sprite(afile)
        if not temp then
            return
        end
        display.adapt(temp, -742, 212, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setScaleX(1.85)
        temp:setScaleY(0.57)
        temp:setVisible(false)
        temp:runAction(ui.action.sequence({
            {"delay", 0.133},
            "show",
            {"spawn", {{"moveBy", 0.167, 1040, 0}, {"scaleTo", 0.167, 1.1, 1.1}}},
            {"scaleTo", 0.083, 1, 1}
        }))
    else
        cnode:setRotation(angle)
        display.adapt(cnode, 0, -790, GConst.Anchor.RightBottom, {datum=GConst.Anchor.RightTop, scale = ui.getUIScale2()})
        bg:addChild(cnode)
        bg = ui.node()
        display.adapt(bg, 2048, 0, GConst.Anchor.RightBottom)
        bg:setRotation(-angle)
        cnode:addChild(bg)

        temp = ui.sprite("effects/godSkillBackRight.png")
        temp:setScaleX(2)
        temp:setScaleY(0.4)
        display.adapt(temp, 988, 81, GConst.Anchor.Center)
        bg:addChild(temp)
        local label = ui.label(fname, fontType, 50, {color={35, 0, 0}})
        display.adapt(label, 483, 151, GConst.Anchor.Center)
        temp:addChild(label)
        label:setRotation(angle)
        label:setOutlineColor(cc.c4b(255,105,105,255))

        temp:runAction(ui.action.sequence({
            {"spawn", {{"moveBy", 0.167, -1970, 208}, {"scaleTo", 0.167, 2.2, 2.4}, {"skewBy", 0.167, 20, 0}}},
            {"spawn", {{"moveBy", 0.083, 63, 0}, {"scaleTo", 0.083, 2, 2}, {"skewBy", 0.083, -20, 0}}}
        }))
        local id = self.M.id
        if 8000<id and id<9000 then
            id = math.floor(id/10)*10
        end
        local afile
        if id == 4031 then
            if self.C.heroState == 0 then
                afile = GameUI.getHeroFeature(4031, false, 0)
            elseif self.C.heroState == 1 then
                afile = GameUI.getHeroFeature(40312, false, 0)
            end
        else
            afile = GameUI.getHeroFeature(id, false, 1)
        end
        temp = ui.sprite(afile)
        if not temp then
            return
        end
        temp:setFlippedX(true)
        display.adapt(temp, 742, 212, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setScaleX(1.85)
        temp:setScaleY(0.57)
        temp:setVisible(false)
        temp:runAction(ui.action.sequence({
            {"delay", 0.133},
            "show",
            {"spawn", {{"moveBy", 0.167, -1040, 0}, {"scaleTo", 0.167, 1.1, 1.1}}},
            {"scaleTo", 0.083, 1, 1}
        }))
    end
end

--天神技执行动作
function Avater:godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
    if not gameSetting.getSetting(gameSetting.GskEffect) then
        self.scene.replay:pauseReplay(1, Handler(self.showGodSkill, self))
    end

    if self.godSkillNode then
        self.godSkillNode:removeFromParent(true)
        self.godSkillNode = nil
    end
    if self.sg_godSkillAttack then
        self:sg_godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
        if not self.__skip then
            return
        else
            self.__skip = nil
        end
    end
    self.skillStopNum = 6
    if self.animaConfig.skill_params then
        self.loop = false
        self.isExeRealAtk = false

        local sfmt,sparams
        if type(self.animaConfig.skill_fmt) == "string" then
            sfmt = self.animaConfig.skill_fmt
            sparams = self.animaConfig.skill_params
        else
            sfmt = self.animaConfig.skill_fmt[1]
            sparams = self.animaConfig.skill_params[1]
        end
        if self.id == 4031 then
            if self.C.heroState == 0 then--heroState.ren
                sfmt = self.animaConfig.skill_fmt[1]
                sparams = self.animaConfig.skill_params[1]
            elseif self.C.heroState == 1 then--heroState.shou
                sfmt = self.animaConfig.skill_fmt[3]
                sparams = self.animaConfig.skill_params[3]
            end
        end
        self.frameFormat = sfmt
        self.animaTime = 0
        self.frameIndex = 0
        self.oneFrameTime = sparams[1]/sparams[2]
        self.frameMaxIndex = sparams[2]
        self.actionTime = 0
        self.allActionTime = self.avtInfo.aspeed
        if sparams[1]>self.avtInfo.aspeed then
            self.allActionTime = sparams[1]
        end
        self.exeAtkFrame = sparams[3]
    else
        self:attack(viewInfo1,viewInfo2,b)
    end
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    --通用特效
    local off=AllConfig.heroCurrencyEffect
    local id = self.id
    if off[id] then
        local mode,oy,scal=off[id][1],off[id][2],off[id][3]
        self:currencyEffect(mode,oy,scal)
    end
    self.state = PersonState.GODSKILL
end

--使用技能后的状态
function Avater:skillViewEffect(attackTarget,callback,skillLastTimeAll)
    self:viewEffect(attackTarget,callback,true,skillLastTimeAll)
end

function Avater:removeFromScene()
    self.deleted = true
    self:removeFromParent(true)

    self.C = nil
    self.M = nil
    self.map = nil
    self.scene = nil
end

function Avater:changeDeadState(view)
    local size = view:getContentSize()
    local x, y = size.width/2, size.height/2
    self.view:retain()
    self:removeFromParent(false)
    self.deleted = true
    if self.personView2 then
        self.personView2:setSValue(-100)
    end
    self.view:setPosition(x, y)
    view:addChild(self.view,2)
    self.view:release()
end

function Avater:changeUndeadState(scene, gx, gy)
    self.view:retain()
    self:removeFromParent(false)
    self.deleted = nil
    local px,py = self.map.convertToPosition(gx, gy)
    self.gx,self.gy = gx, gy
    if self.personView2 then
        self.personView2:setSValue(0)
    end
    self.scene.objs:addChild(self.view, self.maxZorder-py)
    self.view:release()
    self:resetBlood()
    self:addShadow()
    self:setPosition(px, py)
end

--加普通分身效果
function Avater:addFenShenEff(avater)
    local temp = ui.sprite("Glow_01.png")
    temp:setColor(cc.c3b(255,24,0))
    local y = avater.animaConfig.Ymove+50
    temp:setPosition(0,y)
    temp:setOpacity(0.5*255)
    avater.view:addChild(temp,10)
    avater.personView:setOpacity(0.64*255)
    local blend={}
    blend.src=1
    blend.dst=1
    temp:setBlendFunc(blend)
    return temp
end

--英雄技能通用特效
function Avater:currencyEffect(mode,oy,scal)
    oy=oy or 0
    scal=scal or 1
    local pos={self.personView:getPosition()}
    local efNode=ui.node()
    efNode:setPosition(pos[1],pos[2]+oy)
    self.view:addChild(efNode,100)
    efNode:setScale(3*scal)
    --橙色，紫色，蓝色，绿色
    local temp
    if mode==1 then
        temp=ui.animateSprite(0.55,"Common_",12,{beginNum=0,plist="effects/effectsRes/Common.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        temp:setScale(2.3)
        efNode:addChild(temp)
        temp:runAction(ui.action.sequence({{"delay",33/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))

        temp=ui.animateSprite(0.55,"Common_",12,{beginNum=0,plist="effects/effectsRes/Common.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        temp:setScale(2.3)
        efNode:addChild(temp)
        temp:runAction(ui.action.sequence({{"delay",3/60},{"fadeTo",3/60,153},{"fadeTo",6/60,196},{"fadeTo",6/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))

        temp=ui.sprite("effects/effectsRes/Glow_01.png")
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",3/60,2.0,2.0}}))
        temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,191},{"delay",3/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",5/60},"remove"}))
    elseif mode==2 then
        temp=ui.animateSprite(0.55,"Common_P_",12,{beginNum=0,plist="effects/effectsRes/Common_P.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:setScale(2.3)
        temp:runAction(ui.action.sequence({{"delay",55/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
        local blend={}
        blend.src=1
        blend.dst=771
        temp:setBlendFunc(blend)

        temp=ui.animateSprite(0.55,"Common_P_",12,{beginNum=0,plist="effects/effectsRes/Common_P.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:setScale(2.3)
        temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,196},{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
        blend={}
        blend.src=774
        blend.dst=1
        temp:setBlendFunc(blend)
    elseif mode==3 then
        temp=ui.animateSprite(0.55,"Common_B_",12,{beginNum=0,plist="effects/effectsRes/Common_B.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:setScale(2.3)
        temp:runAction(ui.action.sequence({{"delay",34/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
        local blend={}
        blend.src=1
        blend.dst=771
        temp:setBlendFunc(blend)

        temp=ui.animateSprite(0.55,"Common_B_",12,{beginNum=0,plist="effects/effectsRes/Common_B.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:setScale(2.3)
        temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"fadeTo",3/60,196},{"fadeTo",3/60,255},{"delay",25/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
        blend={}
        blend.src=772
        blend.dst=1
        temp:setBlendFunc(blend)
    elseif mode==4 then
        temp=ui.animateSprite(0.55,"Common_G_",12,{beginNum=0,plist="effects/effectsRes/Common_G.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:setScale(2.3)
        temp:runAction(ui.action.sequence({{"delay",34/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
        local blend={}
        blend.src=1
        blend.dst=771
        temp:setBlendFunc(blend)

        temp=ui.animateSprite(0.55,"Common_G_",12,{beginNum=0,plist="effects/effectsRes/Common_G.plist",isRepeat=false})
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(0,0)
        efNode:addChild(temp)
        temp:setScale(2.3)
        temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"fadeTo",3/60,196},{"fadeTo",3/60,255},{"delay",25/60},{"fadeTo",1/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
        blend={}
        blend.src=770
        blend.dst=1
        temp:setBlendFunc(blend)
    end

    return efNode
end

return Avater
