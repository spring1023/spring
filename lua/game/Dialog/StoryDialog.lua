local SData = GMethod.loadScript("data.StaticData")
--PVE剧情界面
StoryDialog = class(DialogViewLayout)

function StoryDialog:onInitDialog(params)
    self:setLayout("StoryDialog.json")
    self:loadViewsTo()
    if self.customStory then
        self.storyItems = self.customStory
    else
        self.storyItems = SData.getData("story",self.storyIdx)
    end
    self.btnBackground:setScriptCallback(ButtonHandler(self.onTouchBack, self))
    self.bgAlpha = GEngine.getSetting("storyBackAlpha")
end

function StoryDialog:onEnter()
    RegActionUpdate(self.view, Handler(self.onUpdateTime, self, 0.2), 0.2)
    self.talkId = 1
    self:showTalk()
    GameUI.setLoadingState(true)
    if self.hideMenu then
        local scene = GMethod.loadScript("game.View.Scene")
        scene.menu.view:setVisible(false)
    end
end

function StoryDialog:onExit()
    GameUI.setLoadingState(false)

    if self.hideMenu then
        local scene = GMethod.loadScript("game.View.Scene")
        scene.menu.view:setVisible(true)
    end
end

function StoryDialog:onTouchBack()
    if self.waitTime then
        return
    end
    if self.locked then
        return
    end
    self:onNext()
end

function StoryDialog:onNext()
    self.talkId = self.talkId+1
    self:showTalk()
end

function StoryDialog:onUpdateTime(diff)
    if self.waitTime then
        self.waitTime = self.waitTime-diff
        if self.waitTime<=0 then
            self.waitTime = nil
        end
    end
end

function StoryDialog:showTalk()
    local tdata = self.storyItems[self.talkId]
    if not tdata then
        display.closeDialog(0)
        if self.callback then
            self.callback()
        end
        return
    end
    if tdata.sound_b then
        music.play("sounds/" .. tdata.sound_b .. ".mp3")
    end
    local function showNewTalk()
        if tdata.sound then
            music.play("sounds/" .. tdata.sound .. ".mp3")
        end
        self.talkText:setString(Localize(tdata.text))
        self.featureNode:setRotation(self.R)
        local spawn=ui.action.spawn({{"fadeTo",0.4,255},{"scaleTo",0.4,1,1},{"rotateBy",0.4,-self.R*1.2}})
        self.featureNode:runAction(ui.action.sequence({{"delay",0.1},spawn,{"rotateBy", 0.1, 0.4*self.R},{"rotateBy", 0.1, -0.3*self.R},{"rotateBy", 0.1, 0.1*self.R}}))
    end
    if self.bImg and tdata.ptype == self.bImg[1] and tdata.pid == self.bImg[2] and tdata.pos == self.bImg[3] then
        if self.featureNode then
            local featureNode=self.featureNode
            featureNode:stopAllActions()
            local spawn=ui.action.spawn({{"fadeTo",0.2,0},{"scaleTo",0.2,0,0}})
            featureNode:runAction(ui.action.sequence({spawn,{"call",showNewTalk}}))
        end
    else

        self.nodeLeftBottom1:removeAllChildren(true)
        self.nodeLeftBottom1:removeAllChildren(true)

        self.nodeLeftBottom:removeAllChildren(true)
        self.nodeRightBottom:removeAllChildren(true)
        local bg = ui.node()
        local bg1 = ui.node()
        local isLeft = (tdata.pos==0)
        local moveL = 1200
        local moveR = 500
        local offL=0

        if tdata.isShowBut and tdata.isShowBut == 1 then
            self.locked = true
        else
            self.locked = false
        end
        local dt=0
        if tdata.shadow and tdata.shadow==1 then
            dt=0.3
        end
        if isLeft then
            self.nodeLeftBottom:addChild(bg)
            bg:setPosition(-moveL, 0)
            bg:runAction(ui.action.sequence({{"delay",dt},{"easeSineOut",ui.action.moveBy(0.4,moveL+moveR,0)}}))
            if tdata.shadow and tdata.shadow==1 then
                self.nodeLeftBottom1:addChild(bg1)
                bg1:setPosition(0, -1000)
                bg1:runAction(ui.action.easeSineOut(ui.action.moveBy(0.4,0,1000)))

                local shadown = ui.sprite("images/pvePlotTree.png")
                display.adapt(shadown, -95, -77, GConst.Anchor.LeftBottom)
                bg1:addChild(shadown)
            end
            self.R=-60
        else
            self.nodeRightBottom:addChild(bg)
            bg:setPosition(moveL, 0)
            bg:runAction(ui.action.sequence({{"delay",dt},{"easeSineOut",ui.action.moveBy(0.4,-moveL-moveR,0)}}))
            if tdata.shadow and tdata.shadow==1 then
                self.nodeRightBottom1:addChild(bg1)
                bg1:setPosition(0, -1000)
                bg1:runAction(ui.action.easeSineOut(ui.action.moveBy(0.4,0,1000)))

                local shadown = ui.sprite("images/pvePlotTentacle.png")
                display.adapt(shadown, 1194-2048, -16, GConst.Anchor.LeftBottom)
                bg1:addChild(shadown)
            end
            self.R=60
        end

        if tdata.ptype==1 then
            local offPos={{-50,-496},{0,-423},{0,-255},{0,-378},{0,-292},{0,-420}}
            local person = ui.sprite("images/pvePlotPerson" .. tdata.pid .. ".png")
            if tdata.adapt==1 then
                display.adapt(person, tdata.pos2[1], tdata.pos2[2], GConst.Anchor.Bottom, {scale=tdata.pos2[3]})
            else
                display.adapt(person, offPos[tdata.pid][1], offPos[tdata.pid][2], GConst.Anchor.Bottom)
            end
            bg:addChild(person)

        else
            local pid = tdata.pid
            if pid==0 then
                pid = self.heroId or 4007
            end
            if tdata.adapt == 2 then
                GameUI.addHeroFeature(bg, pid, tdata.scale or 1.2, tdata.x or 0, tdata.y or 0, 0, nil, 0, tdata.flip == 1)
                local lockBut = ui.button({137, 130}, tdata.callback, {cp1=self, image="images/btnClickDemo.png"})
                display.adapt(lockBut, 55, 100, GConst.Anchor.Center)
                bg:addChild(lockBut)
            elseif tdata.adapt==1 then
                local hero=GameUI.addHeroFeature(bg, pid, tdata.pos2[3],tdata.pos2[1],tdata.pos2[2], 0, false)
                local flip=false
                if tdata.pos2[4] and tdata.pos2[4]==1 then
                    flip=true
                end
                hero:setFlippedX(flip)
            else
                local hero=GameUI.addHeroFeature(bg, pid, 1.2, -30, -230, 0, false)
                hero:setFlippedX(true)
            end
            if tdata.hasSSR then
                GameUI.addSSR(bg, tdata.hasSSR, 1, -460, 10, 2, GConst.Anchor.LeftBottom)
            end
        end
        local featureNode=ui.node()
        display.adapt(featureNode, 150, 500, GConst.Anchor.LeftBottom)
        bg:addChild(featureNode)
        featureNode:setOpacity(0)
        featureNode:setScale(0)
        self.featureNode = featureNode

        local triangle=ui.sprite("images/pvePlotFeatureBack1.png",{52,37})
        display.adapt(triangle, 0, -24, GConst.Anchor.LeftBottom)
        featureNode:addChild(triangle)
        local talkFeatureNode=ui.node()
        display.adapt(talkFeatureNode, 42, -202, GConst.Anchor.LeftBottom)
        featureNode:addChild(talkFeatureNode)
        if not isLeft then
            triangle:setFlippedX(true)
            featureNode:setPositionX(-381)
            talkFeatureNode:setPosition(-708,-89)
        end
        local talkBack=ui.scale9("images/pvePlotFeatureBack2.png", 81, {715,303})
        display.adapt(talkBack, 0,0, GConst.Anchor.LeftBottom)
        talkFeatureNode:addChild(talkBack)
        local talkText=ui.label(Localize(tdata.text), General.font2, 48, {color={0,0,0},width =624,fontW=624,fontH=285,GConst.Align.Left})
        display.adapt(talkText, 43, 151, GConst.Anchor.Left)
        talkFeatureNode:addChild(talkText)
        if self.locked then
            display.adapt(talkText, 43, 181, GConst.Anchor.Left)
            local lockBut = ui.button({400, 120}, self.onNext, {cp1=self, image="images/btnGreen.png"})
            display.adapt(lockBut, 355, 0, GConst.Anchor.Center)
            talkFeatureNode:addChild(lockBut)
            lockBut:setHValue(-79)
            local butText = ui.label(Localize(tdata.butText), General.font1, 48)
            display.adapt(butText, 200, 72, GConst.Anchor.Center)
            lockBut:getDrawNode():addChild(butText)
        end
        self.waitTime = 1
        self.talkText = talkText
        featureNode:runAction(ui.action.sequence({{"delay", 0.7},{"call",showNewTalk}}))
    end
    self.bImg = {tdata.ptype,tdata.pid,tdata.pos}
end
