
local ComicEffect1 = GMethod.loadScript("game.GameEffect.effectsAnimate.ComicEffect1")
local ComicEffect2 = GMethod.loadScript("game.GameEffect.effectsAnimate.ComicEffect2")
local ComicEffect3 = GMethod.loadScript("game.GameEffect.effectsAnimate.ComicEffect3")
local effectArr = {ComicEffect1,ComicEffect2,ComicEffect3}
local const = GMethod.loadScript("game.GameLogic.Const")
local ComicDialog = class2("ComicDialog",function(num,idx,sgType)
    return BaseView.new("ComicDialog" .. num ..".json",nil,sgType or "Dialog")
end)


function ComicDialog:ctor(num, idx, sgType, event)
    self.num,self.idx = num or 1,idx or 0
    self.sgType = sgType or "Dialog"
    self.event = event
    self.config = GMethod.loadConfig("configs/comic.json")[tostring(num)]
    self.dialogDepth = display.getDialogPri()+1
    self.priority = self.dialogDepth
    self:initUI()
    if self.sgType == "Dialog" then
        RegLife(self, Handler(self.onLifeCycle, self))
    end
end

function ComicDialog:onLifeCycle(event)
    if event=="enter" then
        music.pauseBgm()
        GameUI.setLoadingState(true)
    elseif event == "exit" then
        GameUI.setLoadingState(false)
    end
end

function ComicDialog:canExit()
    if self.num~=0 and self.idx<#(self.config.pageTable) then
        self:onPlay()
        return false
    end
    music.resumeBgm()
    if self.onMusic then
        music.stop(self.onMusic)
    end
    return true
end

function ComicDialog:onPlay()
    if self.idx<#(self.config.pageTable) then
        if not self.config.guideAuto then
            self.idx = self.idx+1
            self:playComic()
        else
            self:stopAllActions()
            self:initComic(true)
        end
    else
        display.closeDialog(0)
    end
end

function ComicDialog:exitAnimate()
    local rview = self
    if type(rview) == "table" then
        rview = rview.view
    end
    if rview.event then
        GameEvent.sendEvent(rview.event, self.num)
    end
    return 0
end

-- function ComicDialog:initGuide()
--     local nx,ny = 2048,1200
--     local scrollNode = ScrollNode:create(cc.size(nx,ny), 1, true, false)
--     display.adapt(scrollNode, 0, (1546-ny)/2, GConst.Anchor.LeftBottom)
--     scrollNode:setClip(true)

--     local bg = scrollNode:getScrollNode()
--     self:addChild(scrollNode)
--     local lbnode = ui.node({nx,ny})
--     display.adapt(lbnode,0,0,GConst.Anchor.LeftBottom)
--     bg:addChild(lbnode)
--     local cf = self.config
--     local temp = self:_addLabel(cf)
--     temp:setPosition(0,ny)
--     lbnode:addChild(temp)
--     lbnode:setPosition(cf.point[1],cf.point[2])
--     lbnode:runAction(ui.action.sequence(cf.act))
--     self.butPlay:setListener(function()
--         display.closeDialog(0)
--     end)
-- end

function ComicDialog:initUI()
    --已观看
    local context = GameLogic.getUserContext()
    if context then
        local key = context.uid .. "_" .. context.sid .. "comicLook" .. self.num
        GEngine.setConfig(key,1,true)
    end
    self.lbnodeArr = {}
    self:loadView("back")
    self:insertViewTo()
    self.butClose:setListener(function()
        display.closeDialog(0)
        if self.num == 0 then
            local context = GameLogic.getUserContext()
            context.guide:addStep()
        end
    end)
    self.butClose:setVisible(false)

    -- if self.num == 0 then
    --     self:initGuide()
    --     return
    -- end

    local cf = self.config.pageTable
    self.shouldShow = {}
    for i,v in ipairs(cf) do
        for i2,v2 in ipairs(v) do
            self.shouldShow[v2] = true
        end
    end
    self.butPlay:setInitSoundEnable(false)
    self.butPlay:setListener(Handler(self.onPlay, self))
    if self.sgType == "tab" then
        self.butClose:setVisible(false)
        self.butPlay:setVisible(false)
    end
    self:initComic()
    if self.sgType == "Dialog" then
        --自动播第一块
        if not self.config.guideAuto then
            if self.config.auto then
                self.idx = self.idx+1
                self:playComic()
            end
        else--全自动
            --新手漫画音效
            if self.config.guideAuto and self.config.music then
                if self.onMusic then
                    music.stop(self.onMusic)
                end
                self.onMusic=music.play("sounds/" .. self.config.music)
            end
            local length=#self.config.pageContent
                local i=0
                local delayT=0
                local function show()
                    i=i+1
                    if i>length then
                        return
                    end
                    local item=self.config.pageContent[i]
                    if item["delayTime"] then
                        delayT=item["delayTime"]
                    end
                    self.idx = self.idx+1
                    self:playComic()
                    self.scrollNode:runAction(ui.action.sequence({{"delay",delayT},{"call",show}}))
                end
                self.scrollNode:runAction(ui.action.sequence({{"delay",delayT},{"call",show}}))
        end
    end
end

function ComicDialog:initComic(isGuideAuto)
    if self.scrollNode then
        self.scrollNode:removeFromParent(true)
    end
    local scrollNode = ScrollNode:create(cc.size(2048,1536), 1, true, false)
    display.adapt(scrollNode, 0, 0, GConst.Anchor.LeftBottom)
    scrollNode:setClip(true)
    self.scrollNode=scrollNode
    local bg = scrollNode:getScrollNode()
    self:addChild(scrollNode)
    local cf = self.config.pageContent
    for i=1,#cf do
        local cfg = cf[i]
        self["pageNode" .. i] = ui.node({2048,1536})
        bg:addChild(self["pageNode" .. i],cfg.z or 0)
        self:loadView("page" .. i,self["pageNode" .. i])
        if isGuideAuto then
            self.idx=#cf
             if self.sgType == "Dialog" then
                if cfg.initPos then
                    self["pageNode" .. i]:setPosition(cfg.initPos[1],cfg.initPos[2])
                end
            end
        else
            if self.sgType == "Dialog" then
                if cfg.point then
                    self["pageNode" .. i]:setPosition(cfg.point[1],cfg.point[2])
                    self["pageNode" .. i]:setAnchorPoint(0,0)
                end
                if cfg.opacity then
                    self["pageNode" .. i]:setOpacity(cfg.opacity)
                end
                if cfg.rotation then
                    self["pageNode" .. i]:setRotation(cfg.rotation)
                end
                if cfg.scaleX then
                    self["pageNode" .. i]:setScaleX(cfg.scaleX)
                end
                if cfg.scaleY then
                    self["pageNode" .. i]:setScaleY(cfg.scaleY)
                end
                if cfg.anchor then
                    self["pageNode" .. i]:setAnchorPoint(cfg.anchor[1],cfg.anchor[2])
                    self["pageNode" .. i]:setPosition(cfg.point[1]+2048*cfg.anchor[1],cfg.point[2]+1536*cfg.anchor[2])
                end
                CaeHSLNode:recurSetHSL(self["pageNode" .. i], cfg.hvalue or 0,cfg.svalue or 0,cfg.lvalue or 0,100)
            else
                if not self.shouldShow[i] then
                    self["pageNode" .. i]:setVisible(false)
                end
            end
        end
    end
    self.views=self:getViewTab()
end

function ComicDialog:playComic()
    for i,v in ipairs(self.config.pageTable[self.idx]) do
        local cf = self.config.pageContent[v]
        self["pageNode" .. v]:runAction(ui.action.sequence(cf.act))
        if cf.toSvalue then
            local sv = (cf.toSvalue[2]-cf.svalue)/cf.toSvalue[1]/60
            RegUpdate(self["pageNode" .. v],function()
                cf.svalue = cf.svalue+sv
                if cf.svalue >= cf.toSvalue[2] then
                    UnregUpdate(self["pageNode" .. i])
                    return
                end
                CaeHSLNode:recurSetHSL(self["pageNode" .. i],0,cf.svalue or 0,0,100)
            end,0)
        end
        if cf.actionShake then
            local pa=cf.actionShake
            self:runAction(ui.action.sequence({{"delay",pa[1]},{"actionShake",pa[2],pa[3],pa[4]}}))
        end
        if cf.actId then
            local pa=cf.actId
            self.views[pa.id]:runAction(ui.action.sequence(pa.act))
        end
        --特效
        if cf.effect then
            self["pageNode" .. v]:runAction(ui.action.sequence({{"delay",cf.effect[2]},{"call",function()
                effectArr[cf.effect[1]].new(self["pageNode" .. v],cf.effect[3],cf.effect[4],cf.effect[5])
            end}}))
        end

        if self.sgType=="Dialog" and cf.music then
            if self.onMusic then
                music.stop(self.onMusic)
            end
            self.onMusic=music.play("sounds/" .. cf.music)
        end
    end

    local lbTb = self.config.labelTable and self.config.labelTable[self.idx]
    for i,v in ipairs(self.lbnodeArr) do
        v:removeFromParent(true)
    end
    self.lbnodeArr = {}
    if lbTb then
        for i,v in ipairs(lbTb) do
            local cf = self.config.labelContent[v]
            local temp
            local lbnode = ui.node({2048,1536})
            self.lbnodeArr[i] = lbnode
            if cf.point then
                lbnode:setPosition(cf.point[1],cf.point[2])
                lbnode:setAnchorPoint(0,0)
            end
            if cf.opacity then
                lbnode:setOpacity(cf.opacity)
            end
            if cf.rotation then
                lbnode:setRotation(cf.rotation)
            end
            if cf.scaleX then
                lbnode:setScaleX(cf.scaleX)
            end
            if cf.scaleY then
                lbnode:setScaleY(cf.scaleY)
            end
            if cf.anchor then
                lbnode:setAnchorPoint(cf.anchor[1],cf.anchor[2])
                lbnode:setPosition(cf.point[1]+2048*cf.anchor[1],cf.point[2]+1536*cf.anchor[2])
            end
            CaeHSLNode:recurSetHSL(lbnode, cf.hvalue or 0,cf.svalue or 0,cf.lvalue or 0,100)
            self:addChild(lbnode,cf.z or 0)
            local context = GameLogic.getUserContext()
            local name
            if context then
                name = context:getInfoItem(const.InfoName)
            end
            temp = ui.label(Localizef(cf.text,{name = name or "西瓜皮"}),General.font1,65,{color = {255,255,255},width = 1800})
            display.adapt(temp,1024,103,GConst.Anchor.Bottom)
            lbnode:addChild(temp,cf.z or 0)
            lbnode:runAction(ui.action.sequence(cf.act))
            if cf.toSvalue then
                local sv = (cf.toSvalue[2]-cf.svalue)/cf.toSvalue[1]/60
                RegUpdate(lbnode,function()
                    cf.svalue = cf.svalue+sv
                    if cf.svalue >= cf.toSvalue[2] then
                        UnregUpdate(lbnode)
                        return
                    end
                    CaeHSLNode:recurSetHSL(lbnode,0,cf.svalue or 0,0,100)
                end,0)
            end
        end
    end
end

return ComicDialog
