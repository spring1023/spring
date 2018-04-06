local LoadingScene = {state="cleanup", lstate="init", percent=0, dstate=nil}

function LoadingScene:show()
    if self.state=="cleanup" then
        local bg = ui.touchNode(display.winSize, 1, true)
        self.view = display.addLayer(bg, 1, 2)
        self.view:retain()
        self.view:setGroupMode(true)
        RegLife(self.view, Handler(self.lifeCycle, self))

        self.loadViewThread = coroutine.create(function()
            xpcall(Handler(self.loadView, self), _G.__G__TRACKBACK__)
        end)
        self.state = "enter"
        coroutine.resume(self.loadViewThread)
    elseif self.state=="exit" then
        display.addLayer(self.view, 1, 2)
    end
    self.dstate = nil
end

function LoadingScene:onLoadAsync(suc, texture)
    if self.loadingTexture then
        self.loadingTexture = false
    end
    if self.loadingThreadYield then
        self.loadingThreadYield = false
        coroutine.resume(self.loadViewThread, self)
    end
end

function LoadingScene:loadView()
    local scale = ui.getUIScale()
    local bg = self.view
    bg:retain()
    self.loadingTexture = true
    self.loadingThreadYield = false
    local channel = GEngine.rawConfig.channel
    local isOurVersion = cc.FileUtils:getInstance():isFileExist("images/loadBackGroundX.png")
    self.spriteBg = "images/loadBackGround3.png"
    if GEngine.rawConfig.spriteBg then
        self.spriteBg = GEngine.rawConfig.spriteBg
    end
    if isOurVersion then
        self.spriteBg = "images/loadBackGroundX.png"
    end
    local isSpringVersion = false
    GEngine.engine:getPackageManager():loadPackage("patchLoading.pkg")
    isSpringVersion = cc.FileUtils:getInstance():isFileExist("images/loadBackGroundSpring.png")
    if isSpringVersion then
        self.spriteBg = "images/loadBackGroundSpring.png"
        isOurVersion = nil
    end
    ResAsyncLoader:getInstance():addLuaTask(bg, nil, self.spriteBg, ButtonHandler(self.onLoadAsync, self))
    if self.loadingTexture then
        self.loadingThreadYield = true
        coroutine.yield()
    end

    local temp = ui.sprite(self.spriteBg)
    if not temp then
        temp = ui.sprite("images/loadBackGround3.png")
    end
    local scalePolicy = display.getScalePolicy(temp:getContentSize().width,temp:getContentSize().height)
    local scaleBg = scalePolicy[GConst.Scale.Big]
    display.adapt(temp, 0, 0, GConst.Anchor.Center, {scale=scaleBg})
    bg:addChild(temp)

    local logoSet = {17,208,"Center"}
    self.loadingTexture = true
    self.loadingThreadYield = false
    local language = General.language
    if GEngine.rawConfig.logoSpecial then
        self.spriteLogo = GEngine.rawConfig.logoSpecial[1]
        logoSet = {GEngine.rawConfig.logoSpecial[2], GEngine.rawConfig.logoSpecial[3], GEngine.rawConfig.logoSpecial[4]}
    elseif GEngine.rawConfig.logoSpecialQianxun then
        self.spriteLogo = GEngine.rawConfig.logoSpecialQianxun[1][language]
        logoSet = {GEngine.rawConfig.logoSpecialQianxun[2], GEngine.rawConfig.logoSpecialQianxun[3], GEngine.rawConfig.logoSpecialQianxun[4]}
    else
        self.spriteLogo = "images/coz2logo3.png"
        if General.language ~= "CN" and General.language ~= "HK" then
            self.spriteLogo="images/coz2logo3_2.png"
            logoSet = {7, 216, "Center"}
        end
    end
    local logoScale = 1
    if isOurVersion then
        logoSet = {-20, -10, "RightTop"}
        logoScale = 0.85
    end
    if isSpringVersion then
        logoSet = {20, -10, "LeftTop"}
        logoScale = 0.85
    end

    ResAsyncLoader:getInstance():addLuaTask(bg, nil, self.spriteLogo, ButtonHandler(self.onLoadAsync, self))
    if self.loadingTexture then
        self.loadingThreadYield = true
        coroutine.yield()
    end

    temp = ui.sprite(self.spriteLogo)
    if temp then
        display.adapt(temp, logoSet[1], logoSet[2], GConst.Anchor[logoSet[3]], {scale=scaleBg * logoScale})
        bg:addChild(temp, 1)
        self.logoView = temp
        if GEngine.rawConfig.hideLogo then
            self.logoView:setVisible(false)
        end
    end

    self.loadingTexture = true
    self.loadingThreadYield = false
    ResAsyncLoader:getInstance():addLuaTask(bg, "images/particles.plist", nil, ButtonHandler(self.onLoadAsync, self))
    if self.loadingTexture then
        self.loadingThreadYield = true
        coroutine.yield()
    end

    if isSpringVersion then
        if cc.FileUtils:getInstance():isFileExist("UICsb/loading/loading.csb") then
            local csbNode = ui.simpleCsbEffect("UICsb/loading/loading.csb", true, 0)
            display.adapt(csbNode, 0, 0, GConst.Anchor.Center, {scale=scaleBg})
            bg:addChild(csbNode)
        end
    elseif isOurVersion then
        local enode = ui.node()
        display.adapt(enode, 0, 0, GConst.Anchor.Center, {scale=scaleBg})
        bg:addChild(enode)
        local p = CaeParticleNode:create("images/loadIceX.png", 100, -1)
        p:setPositionType(cc.POSITION_TYPE_GROUPED)
        p:setEmissionRate(10)
        p:setAngle(265)
        p:setAngleVar(0)
        p:setLife(7)
        p:setLifeVar(3)
        p:setStartSize(32)
        p:setStartSizeVar(10)
        p:setEndSize(32)
        p:setEndSizeVar(10)
        p:setStartColor(cc.c4f(1,1,1,1))
        p:setStartColorVar(cc.c4f(0,0,0,0))
        p:setEndColor(cc.c4f(1,1,1,0))
        p:setEndColorVar(cc.c4f(0,0,0,0))
        p:setPosValues(cc.p(1024, 0), cc.p(1, 1))
        p:setStartSpin(0)
        p:setStartSpinVar(360)
        p:setEndSpin(0)
        p:setEndSpinVar(360)
        p:setEmitterMode(0)
        p:setGravity(cc.p(0, 0))
        p:setSpeed(120)
        p:setSpeedVar(40)
        p:setRadialAccel(0)
        p:setRadialAccelVar(10)
        p:setTangentialAccel(0)
        p:setTangentialAccelVar(30)
        ui.setBlend(p, 1, gl.ONE_MINUS_SRC_ALPHA)
        display.adapt(p, 0, 800)
        enode:addChild(p)
        p = CaeParticleNode:create("images/loadLightX.png", 100, -1)
        p:setPositionType(cc.POSITION_TYPE_GROUPED)
        p:setEmissionRate(10)
        p:setAngle(275)
        p:setAngleVar(0)
        p:setLife(7)
        p:setLifeVar(3)
        p:setStartSize(48)
        p:setStartSizeVar(10)
        p:setEndSize(24)
        p:setEndSizeVar(5)
        p:setStartColor(cc.c4f(0.5,0.5,0.5,1))
        p:setStartColorVar(cc.c4f(0,0,0,0))
        p:setEndColor(cc.c4f(0.5,0.5,0.5,0))
        p:setEndColorVar(cc.c4f(0,0,0,0))
        p:setPosValues(cc.p(1024, 0), cc.p(1, 1))
        p:setStartSpin(0)
        p:setStartSpinVar(360)
        p:setEndSpin(0)
        p:setEndSpinVar(360)
        p:setEmitterMode(0)
        p:setGravity(cc.p(0, 0))
        p:setSpeed(120)
        p:setSpeedVar(40)
        p:setRadialAccel(0)
        p:setRadialAccelVar(10)
        p:setTangentialAccel(0)
        p:setTangentialAccelVar(30)
        ui.setBlend(p, gl.SRC_ALPHA, 1)
        display.adapt(p, 0, 800)
        enode:addChild(p)
    elseif GEngine.rawConfig.needLoadLoginEffect or (not GEngine.rawConfig.spriteBg) then
        local XuanChuanEffects = require "game.GameEffect.XuanChuanEffects"
        XuanChuanEffects.new():showEffect_xuanchuan3(bg,display.winSize[1]/2,display.winSize[2]/2,0)
    end
    self.loadViewThread = nil

    GMethod.loadScript("game.UI.dialog.LoginDialog").new(self)
    bg:release()
end

function LoadingScene:setLoadingState(state)
    self.lstate = state
end

function LoadingScene:setPercent(percent)
    self.percent = percent
end

function LoadingScene:lifeCycle(event)
    if event=="cleanup" then
        self.state = "cleanup"
        self.view:release()
        self.view = nil
        if self.spriteBg then
            memory.releaseTexture(self.spriteBg)
        end
        if self.spriteLogo then
            memory.releaseTexture(self.spriteLogo)
        end
    elseif event=="exit" then
        self.state = "exit"
    elseif event=="enter" then
        self.state = "enter"
    end
end

function LoadingScene:delete()
    if self.state=="enter" then
        self.view:removeFromParent(true)
    elseif self.state=="exit" then
        self.view:cleanup()
    end
end

return LoadingScene
