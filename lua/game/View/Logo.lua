local LogoScene = {state="cleanup"}

function LogoScene:show(loading)
    local flashLogo = GEngine.rawConfig.flashLogo
    if self.state == "cleanup" or self.state == "exit" then
        local bg
        if flashLogo then
            bg = ui.layer(display.winSize, flashLogo.bg or GConst.Color.Black)
            local logo2 = ui.sprite(flashLogo.logo)
            display.adapt(logo2, 0, 0, GConst.Anchor.Center, {scale=ui.getUIScale()})
            self.logo2=logo2
            bg:addChild(self.logo2)
        else
            bg = ui.layer(display.winSize, GConst.Color.Black)
        end
        self.bg = bg
        self.view=display.addLayer(bg,3,1)
        self.view:setGroupMode(true)
        self.view:retain()
        self.state = "enter"
        RegLife(self.view, Handler(self.lifeCycle, self))
    else
        if not self.isVideo and self.logo then
            self.logo:stopAllActions()
        end
        self.view:stopAllActions()
    end
    self.loading = loading

    if flashLogo then
        local t1 = 0.5
        local t2 = flashLogo.t or 4
        self.logo2:setOpacity(0)
        self.logo2:runAction(ui.action.sequence({{"delay",t1},{"fadeIn",t1},{"delay",t2-3*t1},{"fadeOut",t1}, {"call",Handler(self.addLogo, self)}}))
    else
        self:addLogo()
    end
end

function LogoScene:addLogo()
    self.bg:setColor(GConst.Color.Black)
    if ccexp and ccexp.VideoPlayer then
        local vp = ccexp.VideoPlayer:create()
        local scalePolicy = display.getScalePolicy(2048,1536)
        local scaleBg = scalePolicy[GConst.Scale.Big]
        vp:setContentSize(cc.size(2048*scaleBg, 1536*scaleBg))
        display.adapt(vp, display.winSize[1]/2, display.winSize[2]/2, GConst.Anchor.Center)
        self.logo = vp
        vp:addEventListener(Handler(self.onVideoState, self))
        vp:setFileName("Game.mp4")
        vp:play()
        self.isVideo = true
    else
        local logo = ui.sprite("images/logo.png")
        display.adapt(logo, 0, 0, GConst.Anchor.Center, {scale=ui.getUIScale()})
        self.logo=logo
        self.isVideo = false
    end
    local bg = self.bg
    local loading = self.loading
    bg:addChild(self.logo)
    local t1 = 0.5
    local t2 = 4
    if self.isVideo then
        self.view:runAction(ui.action.sequence({{"delay",0.2},{"call", Handler(loading.show, loading)}}))
    else
        self.logo:setOpacity(0)
        music.play("sounds/logo.wav")
        self.logo:runAction(ui.action.sequence({{"delay",t1},{"fadeIn",t1},{"delay",t2-3*t1},{"fadeOut",t1},{"call",Handler(self.onVideoState, self, 0, 3)}}))
        self:onVideoState(0, 0)
        self.view:runAction(ui.action.sequence({{"delay",t1*2},{"call", Handler(loading.show, loading)}}))
    end
    self:checkEnd()
end

function LogoScene:onVideoState(edata, state)
    if state == 3 then
        self.actionEnd = true
    end
end

function LogoScene:checkLoadingResOver()
    self.loadingResOver = true
end

function LogoScene:checkEnd()
    if self.actionEnd then
        if self.logo then
            self.logo:removeFromParent(true)
            self.logo = nil
        end
        if self.loading and not self.loading.loadViewThread then
            self.loading = nil
            self.view:removeFromParent(true)
            self:checkLoadingResOver()
            return
        end
    end
    self.view:runAction(ui.action.sequence({{"delay",0.2},{"call",Handler(self.checkEnd, self)}}))
end

function LogoScene:lifeCycle(event)
    if event=="cleanup" then
        self.state = "cleanup"
        self.view:release()
        self.view = nil
        self.logo = nil
        self.loading = nil
        memory.releaseTexture("images/logo.png")
        music.setBgm("music/loading.mp3")
    elseif event=="exit" then
        self.state = "exit"
        if self.logo then
            self.logo:removeFromParent(true)
            self.logo = nil
        end
    elseif event=="enter" then
        music.setBgm(nil)
        self.state = "enter"
    end
end

function LogoScene:delete()
    if self.state=="enter" then
        self.view:removeFromParent(true)
    elseif self.state=="exit" then
        self.view:cleanup()
    end
end

return LogoScene
